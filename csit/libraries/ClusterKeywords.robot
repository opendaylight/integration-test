*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           UtilLibrary.py
Library           ClusterStateLibrary.py
Library           ./HsfJson/hsf_json.py
Resource          Utils.robot

*** Variables ***
${jolokia_conf}    /jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
${jolokia_oper}    /jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore
${jolokia_read}    /jolokia/read/org.opendaylight.controller

*** Keywords ***
Create Controller Index List
    [Documentation]    Reads number of controllers and returns a list with all controllers indexes.
    ${controller_index_list}    Create List
    ${NUM_ODL_SYSTEM}=    Convert to Integer    ${NUM_ODL_SYSTEM}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Append To List    ${controller_index_list}    ${i+1}
    [Return]    ${controller_index_list}

Create Controller Sessions
    [Documentation]    Creates REST session to all controller instances.
    ${NUM_ODL_SYSTEM}=    Convert to Integer    ${NUM_ODL_SYSTEM}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Log    Create Session ${ODL_SYSTEM_${i+1}_IP}
    \    RequestsLibrary.Create Session    controller${i+1}    http://${ODL_SYSTEM_${i+1}_IP}:${RESTCONFPORT}    auth=${AUTH}

Get Cluster Shard Status
    [Arguments]    ${controller_index_list}    ${shard_type}    ${shard}
    [Documentation]    Checks ${shard} status and returns Leader index and a list of Followers from a ${controller_index_list}.
    ...    ${shard_type} is either config or operational.
    ${lenght}=    Get Length    ${controller_index_list}
    Run Keyword If    '${shard_type}' == 'config'    Set Test Variable    ${type}    DistributedConfigDatastore
    Run Keyword If    '${shard_type}' == 'operational'    Set Test Variable    ${type}    DistributedOperationalDatastore
    Should Not Be Empty    ${type}    Wrong type, valid values are config and operational.
    ${leader}=    Set Variable    0
    ${follower_list}=    Create List
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${data}=    Utils.Get Data From URI    controller${i}    ${jolokia_read}:Category=Shards,name=member-${i}-shard-${shard}-${shard_type},type=${type}
    \    Log    ${data}
    \    ${json}=    RequestsLibrary.To Json    ${data}
    \    ${status}=    Get From Dictionary    &{json}[value]    RaftState
    \    Log    Controller ${ODL_SYSTEM_${i}_IP} is ${status} for shard ${shard}
    \    Run Keyword If    '${status}' == 'Leader'    Set Test Variable    ${leader}    ${i}
    \    Run Keyword If    '${status}' == 'Follower'    Append To List    ${follower_list}    ${i}
    Should Not Be Equal    ${leader}    0    No Leader elected in shard ${shard_type} ${shard}
    Length Should Be    ${follower_list}    ${lenght-1}    Not enough or too many Followers in shard ${shard_type} ${shard}
    [Return]    ${leader}    ${follower_list}

Get Cluster Entity Owner
    [Arguments]    ${controller_index_list}    ${device_type}    ${device}
    [Documentation]    Checks Entity Owner status for a ${device} and returns owner index and list of candidates from a ${controller_index_list}.
    ...    ${device_type} can be openflow, ovsdb, etc.
    ${length}=    Get Length    ${controller_index_list}
    ${candidates_list}=    Create List
    ${data}=    Utils.Get Data From URI    controller@{controller_index_list}[0]    /restconf/operational/entity-owners:entity-owners
    Log    ${data}
    ${clear_data}=    Run Keyword If    '${device_type}' == 'openflow'    Extract OpenFlow Device Data    ${data}
    ...    ELSE IF    '${device_type}' == 'ovsdb'    Extract Ovsdb Device Data    ${data}
    ...    ELSE    Fail    Not recognized device type: ${device_type}
    ${json}=    RequestsLibrary.To Json    ${clear_data}
    ${entity_type_list}=    Get From Dictionary    &{json}[entity-owners]    entity-type
    ${entity_type_index}=    Get Index From List Of Dictionaries    ${entity_type_list}    type    ${device_type}
    Should Not Be Equal    ${entity_type_index}    -1    No Entity Owner found for ${device_type}
    ${entity_list}=    Get From Dictionary    @{entity_type_list}[${entity_type_index}]    entity
    ${entity_index}=    Utils.Get Index From List Of Dictionaries    ${entity_list}    id    ${device}
    Should Not Be Equal    ${entity_index}    -1    Device ${device} not found in Entity Owner ${device_type}
    ${entity_owner}=    Get From Dictionary    @{entity_list}[${entity_index}]    owner
    Should Not Be Empty    ${entity_owner}    No owner found for ${device}
    ${owner}=    Replace String    ${entity_owner}    member-    ${EMPTY}
    ${owner}=    Convert To Integer    ${owner}
    List Should Contain Value    ${controller_index_list}    ${owner}    Owner ${owner} not exisiting in ${controller_index_list}
    ${entity_candidates_list}=    Get From Dictionary    @{entity_list}[${entity_index}]    candidate
    ${list_length}=    Get Length    ${entity_candidates_list}
    : FOR    ${entity_candidate}    IN    @{entity_candidates_list}
    \    ${candidate}=    Replace String    &{entity_candidate}[name]    member-    ${EMPTY}
    \    ${candidate}=    Convert To Integer    ${candidate}
    \    Append To List    ${candidates_list}    ${candidate}
    List Should Contain Sublist    ${candidates_list}    ${controller_index_list}    Candidates are missing in ${candidates_list}
    Remove Values From List    ${candidates_list}    ${owner}
    [Return]    ${owner}    ${candidates_list}

Extract OpenFlow Device Data
    [Arguments]    ${data}
    [Documentation]    Remove superfluous OpenFlow device data from Entity Owner printout.
    ${clear_data}=    Replace String    ${data}    /general-entity:entity[general-entity:name='    ${EMPTY}
    ${clear_data}=    Replace String    ${clear_data}    ']    ${EMPTY}
    Log    ${clear_data}
    [Return]    ${clear_data}

Extract Ovsdb Device Data
    [Arguments]    ${data}
    [Documentation]    Remove superfluous OVSDB device data from Entity Owner printout.
    ${clear_data}=    Replace String    ${data}    /network-topology:network-topology/network-topology:topology[network-topology:topology-id='ovsdb:1']/network-topology:node[network-topology:node-id='    ${EMPTY}
    ${clear_data}=    Replace String    ${clear_data}    ']    ${EMPTY}
    Log    ${clear_data}
    [Return]    ${clear_data}

Check Item Occurrence At URI In Cluster
    [Arguments]    ${controller_index_list}    ${dictionary_item_occurrence}    ${uri}
    [Documentation]    Send a GET with the supplied ${uri} to all cluster instances in ${controller_index_list}
    ...    and check for occurrences of items expressed in a dictionary ${dictionary_item_occurrence}.
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${data}    Utils.Get Data From URI    controller${i}    ${uri}
    \    Log    ${data}
    \    Utils.Check Item Occurrence    ${data}    ${dictionary_item_occurrence}

Put And Check At URI In Cluster
    [Arguments]    ${controller_index_list}    ${controller_index}    ${uri}    ${body}
    [Documentation]    Send a PUT with the supplied ${uri} and ${body} (json string) to a ${controller_index}
    ...    and check the data is replicated in all instances in ${controller_index_list}.
    ${expected_body}=    Hsf Json    ${body}
    Log    ${body}
    ${resp}    RequestsLibrary.Put Request    controller${controller_index}    ${uri}    data=${body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Log    ${resp.status_code}
    ${status_code}=    Convert To String    ${resp.status_code}
    Should Match Regexp    ${status_code}    20(0|1)
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${data}    Wait Until Keyword Succeeds    5s    1s    Get Data From URI    controller${i}
    \    ...    ${uri}
    \    Log    ${data}
    \    ${received_body}    Hsf Json    ${data}
    \    Should Be Equal    ${expected_body}    ${received_body}

Delete And Check At URI In Cluster
    [Arguments]    ${controller_index_list}    ${controller_index}    ${uri}
    [Documentation]    Send a DELETE with the supplied ${uri} to a ${controller_index}
    ...    and check the data is removed from all instances in ${controller_index_list}.
    ${resp}    RequestsLibrary.Delete Request    controller${controller_index}    ${uri}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN    @{controller_index_list}
    \    Wait Until Keyword Succeeds    5s    1s    No Content From URI    controller${i}    ${uri}

Kill Multiple Controllers
    [Arguments]    @{controller_index_list}
    [Documentation]    Give this keyword a scalar or list of controllers to be stopped.
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${output}=    Utils.Run Command On Controller    ${ODL_SYSTEM_${i}_IP}    ps axf | grep karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
    \    ClusterKeywords.Controller Down Check    ${ODL_SYSTEM_${i}_IP}

Start Multiple Controllers
    [Arguments]    ${timeout}    @{controller_index_list}
    [Documentation]    Give this keyword a scalar or list of controllers to be started.
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${output}=    Utils.Run Command On Controller    ${ODL_SYSTEM_${i}_IP}    ${WORKSPACE}/${BUNDLEFOLDER}/bin/start
    : FOR    ${i}    IN    @{controller_index_list}
    \    ClusterKeywords.Wait For Controller Sync    ${timeout}    ${ODL_SYSTEM_${i}_IP}

Get Controller List
    [Arguments]    ${exclude_controller}=${EMPTY}
    [Documentation]    Creates a list of all controllers minus any excluded controller.
    Log    ${exclude_controller}
    @{searchlist}    Create List    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    Remove Values From List    ${searchlist}    ${exclude_controller}
    Log    ${searchlist}
    [Return]    ${searchlist}

Get Leader And Verify
    [Arguments]    ${shard_name}    ${old_leader}=${EMPTY}
    [Documentation]    Returns the IP addr or hostname of the leader of the specified shard.
    ...    Controllers are specifed in the pybot command line.
    ${searchlist}    Get Controller List    ${old_leader}
    ${leader}    GetLeader    ${shard_name}    ${3}    ${3}    ${1}    ${RESTCONFPORT}
    ...    @{searchlist}
    Should Not Be Equal As Strings    ${leader}    None
    Run Keyword If    '${old_leader}'!='${EMPTY}'    Should Not Be Equal    ${old_leader}    ${leader}
    [Return]    ${leader}

Expect No Leader
    [Arguments]    ${shard_name}
    [Documentation]    No leader is elected in the car shard
    ${leader}    GetLeader    ${shard_name}    ${3}    ${1}    ${1}    ${RESTCONFPORT}
    ...    ${CURRENT_CAR_LEADER}
    Should Be Equal As Strings    ${leader}    None

Get All Followers
    [Arguments]    ${shard_name}    ${exclude_controller}=${EMPTY}
    [Documentation]    Returns the IP addresses or hostnames of all followers of the specified shard.
    ${searchlist}    Get Controller List    ${exclude_controller}
    ${followers}    GetFollowers    ${shard_name}    ${3}    ${3}    ${1}    ${RESTCONFPORT}
    ...    @{searchlist}
    Log    ${followers}
    Should Not Be Empty    ${followers}
    [Return]    ${followers}

Stop One Or More Controllers
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers to be stopped.
    ${cmd} =    Set Variable    ${KARAF_HOME}/bin/stop
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}

Kill One Or More Controllers
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers to be stopped.
    ${cmd} =    Set Variable    ps axf | grep karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
    log    ${cmd}
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}

Wait For Cluster Down
    [Arguments]    ${timeout}    @{controllers}
    [Documentation]    Waits for one or more clustered controllers to be down.
    : FOR    ${ip}    IN    @{controllers}
    \    ${status}=    Run Keyword And Return Status    Wait For Controller Down    ${timeout}    ${ip}
    \    Exit For Loop If    '${status}' == 'FAIL'

Wait For Controller Down
    [Arguments]    ${timeout}    ${ip}
    [Documentation]    Waits for one controllers to be down.
    Wait Until Keyword Succeeds    ${timeout}    2s    Controller Down Check    ${ip}

Controller Down Check
    [Arguments]    ${ip}
    [Documentation]    Checks to see if a controller is down by verifying that the karaf process isn't present.
    ${cmd} =    Set Variable    ps axf | grep karaf | grep -v grep | wc -l
    ${response}    Run Command On COntroller    ${ip}    ${cmd}
    Log    Number of controller instances running: ${response}
    Should Start With    ${response}    0    Controller process found or there may be extra instances of karaf running on the host machine.

Start One Or More Controllers
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers to be started.
    ${cmd} =    Set Variable    ${KARAF_HOME}/bin/start
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}

Wait For Cluster Sync
    [Arguments]    ${timeout}    @{controllers}
    [Documentation]    Waits for one or more clustered controllers to report Sync Status as true.
    : FOR    ${ip}    IN    @{controllers}
    \    ${status}=    Run Keyword And Return Status    Wait For Controller Sync    ${timeout}    ${ip}
    \    Exit For Loop If    '${status}' == 'FAIL'

Wait For Controller Sync
    [Arguments]    ${timeout}    ${ip}
    [Documentation]    Waits for one controllers to report Sync Status as true.
    Wait Until Keyword Succeeds    ${timeout}    2s    Controller Sync Status Should Be True    ${ip}

Controller Sync Status Should Be True
    [Arguments]    ${ip}
    [Documentation]    Checks if Sync Status is true.
    ${SyncStatus}=    Get Controller Sync Status    ${ip}
    Should Be Equal    ${SyncStatus}    ${TRUE}

Controller Sync Status Should Be False
    [Arguments]    ${ip}
    [Documentation]    Checks if Sync Status is false.
    ${SyncStatus}=    Get Controller Sync Status    ${ip}
    Should Be Equal    ${SyncStatus}    ${FALSE}

Get Controller Sync Status
    [Arguments]    ${controller_ip}
    [Documentation]    Return Sync Status.
    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}    headers=${HEADERS}    auth=${AUTH}    max_retries=0
    ${data}=    Get Data From URI    session    ${jolokia_conf}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    ${ConfSyncStatus}=    Get From Dictionary    ${value}    SyncStatus
    Log    Configuration Sync Status: ${ConfSyncStatus}
    ${data}=    Get Data From URI    session    ${jolokia_oper}
    Log    ${data}
    ${json}=    To Json    ${data}
    ${value}=    Get From Dictionary    ${json}    value
    ${OperSyncStatus}=    Get From Dictionary    ${value}    SyncStatus
    Log    Operational Sync Status: ${OperSyncStatus}
    Run Keyword If    ${OperSyncStatus} and ${ConfSyncStatus}    Set Test Variable    ${SyncStatus}    ${TRUE}
    ...    ELSE    Set Test Variable    ${SyncStatus}    ${FALSE}
    [Return]    ${SyncStatus}

Clean One Or More Journals
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers on which to clean journals.
    ${del_cmd} =    Set Variable    rm -rf ${KARAF_HOME}/journal
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${del_cmd}

Clean One Or More Snapshots
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers on which to clean snapshots.
    ${del_cmd} =    Set Variable    rm -rf ${KARAF_HOME}/snapshots
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${del_cmd}

Show Cluster Configuation Files
    [Arguments]    @{controllers}
    [Documentation]    Prints out the cluster configuration files for one or more controllers.
    Log    controllers: @{controllers}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/akka.conf
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/modules.conf
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/module-shards.conf
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/jolokia.xml
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/etc/initial/org.apache.karaf.management.cfg
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/etc/org.apache.karaf.features.cfg
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}

Isolate a Controller From Cluster
    [Arguments]    ${isolated controller}    @{controllers}
    [Documentation]    Use IPTables to isolate one controller from the cluster.
    ...    On the isolated controller it blocks IP traffic to and from each of the other controllers.
    : FOR    ${controller}    IN    @{controllers}
    \    ${other controller}=    Evaluate    "${isolated controller}" != "${controller}"
    \    Run Keyword If    ${other controller}    Isolate One Controller From Another    ${isolated controller}    ${controller}

Rejoin a Controller To Cluster
    [Arguments]    ${isolated controller}    @{controllers}
    [Documentation]    Use IPTables to rejoin one controller to the cluster.
    ...    On the isolated controller it unblocks IP traffic to and from each of the other controllers.
    : FOR    ${controller}    IN    @{controllers}
    \    ${other controller}=    Evaluate    "${isolated controller}" != "${controller}"
    \    Run Keyword If    ${other controller}    Rejoin One Controller To Another    ${isolated controller}    ${controller}

Isolate One Controller From Another
    [Arguments]    ${isolated controller}    ${controller}
    [Documentation]    Inserts an IPTable rule to disconnect one controller from another controller in the cluster.
    Modify IPTables    ${isolated controller}    ${controller}    -I

Rejoin One Controller To Another
    [Arguments]    ${isolated controller}    ${controller}
    [Documentation]    Deletes an IPTable rule, allowing one controller to reconnect to another controller in the cluster.
    Modify IPTables    ${isolated controller}    ${controller}    -D

Modify IPTables
    [Arguments]    ${isolated controller}    ${controller}    ${rule type}
    [Documentation]    Adds a rule, usually inserting or deleting an entry between two controllers.
    ${base string}    Set Variable    sudo iptables ${rule type} OUTPUT -p all --source
    ${cmd string}    Catenate    ${base string}    ${isolated controller} --destination ${controller} -j DROP
    Run Command On Remote System    ${isolated controller}    ${cmd string}
    ${cmd string}    Catenate    ${base string}    ${controller} --destination ${isolated controller} -j DROP
    Run Command On Remote System    ${isolated controller}    ${cmd string}
    ${cmd string}    Set Variable    sudo iptables -L -n
    ${return string}=    Run Command On Remote System    ${isolated controller}    ${cmd string}
    #If inserting rules:
    Run Keyword If    "${rule type}" == '-I'    Should Match Regexp    ${return string}    [\s\S]*DROP *all *-- *${isolated controller} *${controller}[\s\S]*
    Run Keyword If    "${rule type}" == '-I'    Should Match Regexp    ${return string}    [\s\S]*DROP *all *-- *${controller} *${isolated controller}[\s\S]*
    #If deleting rules:
    Run Keyword If    "${rule type}" == '-D'    Should Match Regexp    ${return string}    (?![\s\S]*DROP *all *-- *${isolated controller} *${controller}[\s\S]*)
    Run Keyword If    "${rule type}" == '-D'    Should Match Regexp    ${return string}    (?![\s\S]*DROP *all *-- *${controller} *${isolated controller}[\s\S]*)

Rejoin All Isolated Controllers
    [Arguments]    @{controllers}
    [Documentation]    Wipe all IPTables rules from all controllers, thus rejoining all controllers.
    : FOR    ${isolated controller}    IN    @{controllers}
    \    Flush IPTables    ${isolated controller}

Flush IPTables
    [Arguments]    ${isolated controller}
    [Documentation]    This keyword is generally not called from a test case but supports a complete wipe of all rules on
    ...    all contollers.
    ${cmd string}    Set Variable    sudo iptables -v -F
    ${return string}=    Run Command On Remote System    ${isolated controller}    ${cmd string}
    Log    return: ${return string}
    Should Contain    ${return string}    Flushing chain `INPUT'
    Should Contain    ${return string}    Flushing chain `FORWARD'
    Should Contain    ${return string}    Flushing chain `OUTPUT'
