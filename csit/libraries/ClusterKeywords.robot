*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           UtilLibrary.py
Library           ClusterStateLibrary.py
Resource          Utils.robot

*** Variables ***
${smc_node}       /org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore

*** Keywords ***
Get Controller List
    [Arguments]    ${exclude_controller}=${EMPTY}
    [Documentation]    Creates a list of all controllers minus any excluded controller.
    Log    ${exclude_controller}
    @{searchlist}    Create List    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
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
    ${response}    Run Command On Remote System    ${ip}    ${cmd}
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
    Should Be Equal    ${SyncStatus}    ${True}

Controller Sync Status Should Be False
    [Arguments]    ${ip}
    [Documentation]    Checks if Sync Status is false.
    ${SyncStatus}=    Get Controller Sync Status    ${ip}
    Should Be Equal    ${SyncStatus}    ${False}

Get Controller Sync Status
    [Arguments]    ${controller_ip}
    [Documentation]    Return Sync Status.
    ${api}    Set Variable    /jolokia/read
    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${api}    headers=${HEADERS}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get    session    ${smc_node}
    Log    ${resp.json()}
    Log    ${resp.content}
    ${json}=    Set Variable    ${resp.json()}
    ${value}=    Get From Dictionary    ${json}    value
    Log    value: ${value}
    ${SyncStatus}=    Get From Dictionary    ${value}    SyncStatus
    Log    SyncSatus: ${SyncStatus}
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
