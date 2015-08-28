*** Settings ***
Library           RequestsLibrary
Resource          Utils.robot
Library           Collections
Library           ClusterStateLibrary.py

*** Variables ***

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
    ${leader}    GetLeader    ${shard_name}    ${3}    ${3}    ${1}    ${PORT}
    ...    @{searchlist}
    Should Not Be Equal As Strings    ${leader}    None
    Run Keyword If    '${old_leader}'!='${EMPTY}'    Should Not Be Equal    ${old_leader}    ${leader}
    [Return]    ${leader}

Wait For Leader To Be Found
    [Arguments]    ${shard_name}
    [Documentation]    Waits until the leader of the specified shard is found.
    ${leader}    Wait Until Keyword Succeeds    12s    2s    Get Leader And Verify    ${shard_name}
    Log    ${leader}
    [Return]    ${leader}

Switch Leader
    [Arguments]    ${shard_name}    ${current_leader}
    [Documentation]    Forces a change of leadership by shutting down the current leader.
    Stop One Or More Controllers    ${current_leader}
    ${new_leader}    Wait Until Keyword Succeeds    60s    2s    Get Leader And Verify    ${shard_name}    ${current_leader}
    # TODO: Future enhanement: make sure the other controller is a follower and not a master or candidate.
    Log    ${new_leader}
    [Return]    ${new_leader}

Get All Followers
    [Arguments]    ${shard_name}    ${exclude_controller}=${EMPTY}
    [Documentation]    Returns the IP addresses or hostnames of all followers of the specified shard.
    ${searchlist}    Get Controller List    ${exclude_controller}
    ${followers}    GetFollowers    ${shard_name}    ${3}    ${3}    ${1}    ${PORT}
    ...    @{searchlist}
    Log    ${followers}
    Should Not Be Empty    ${followers}
    [Return]    ${followers}

Add Cars And Verify
    [Arguments]    ${controller_ip}    ${num_cars}    ${timeout}=12s
    [Documentation]    Initializes shard and then adds the specified number of cars and performs a GET as a check.
    ${resp}    InitCar    ${controller_ip}    ${PORT}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    AddCar    ${controller_ip}    ${RESTCONFPORT}    ${num_cars}    204
    Should Be Equal As Strings    ${resp.status_code}    204
    Wait Until Keyword Succeeds    ${timeout}    2s    Get Cars And Verify    ${controller_ip}    ${num_cars}

Add Cars And Verify Without Init
    [Arguments]    ${controller_ip}    ${num_cars}    ${timeout}=12s
    [Documentation]    Adds cars to an initialized cars shard then performs a GET as a check.
    Comment    First car add may return 409, but subsequent should be 204
    ${resp}    AddCar    ${controller_ip}    ${RESTCONFPORT}    ${num_cars}    204    409
    Should Be Equal As Strings    ${resp.status_code}    204
    Wait Until Keyword Succeeds    ${timeout}    2s    Get Cars And Verify    ${controller_ip}    ${num_cars}

Get Cars And Verify
    [Arguments]    ${controller_ip}    ${num_cars}
    [Documentation]    Gets cars and verifies that the manufacturer is correct.
    # TODO: Future enhanement: verify all fields.
    ${resp}    Getcars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN RANGE    1    ${num_cars}+1
    \    Should Contain    ${resp.content}    manufacturer${i}

Add People And Verify
    [Arguments]    ${controller_ip}    ${num_people}
    [Documentation]    Note: The first AddPerson call passed with 0 posts directly to the data store to get
    ...    the people container created so the subsequent AddPerson RPC calls that put to the
    ...    person list will succeed.
    ${resp}    AddPerson    ${controller_ip}    ${RESTCONFPORT}    ${0}    204
    Should Be Equal As Strings    ${resp.status_code}    204
    Wait Until Keyword Succeeds    12s    2s    Get One Person And Verify    ${controller_ip}    ${0}
    ${resp}    AddPerson    ${controller_ip}    ${RESTCONFPORT}    ${num_people}    200
    Wait Until Keyword Succeeds    12s    2s    Get People And Verify    ${controller_ip}    ${num_people}

Get One Person And Verify
    [Arguments]    ${controller_ip}    ${number}
    [Documentation]    Gets a person and verifies that the user ID is correct.
    # TODO: Future enhanement: verify all fields.
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user${number}

Get People And Verify
    [Arguments]    ${controller_ip}    ${num_people}
    [Documentation]    Gets multiple people and verifies that the user IDs are correct.
    # TODO: Future enhanement: verify all fields.
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN RANGE    1    ${num_people}+1
    \    Should Contain    ${resp.content}    user${i}

Add Car Person And Verify
    [Arguments]    ${controller_ip}
    [Documentation]    Add a car-person via the data store and get the car-person from Leader.
    ...    Note: This is done to get the car-people container created so subsequent
    ...    BuyCar RPC puts to the car-person list will succeed.
    AddCarPerson    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    60s    2s    Get One Car-Person Mapping And Verify    ${controller_ip}    ${0}

Get One Car-Person Mapping And Verify
    [Arguments]    ${controller_ip}    ${number}
    [Documentation]    Gets a car person mapping and verifies that the user ID is correct.
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user${number}

Get Car-Person Mappings And Verify
    [Arguments]    ${controller_ip}    ${num_entries}
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN RANGE    1    ${num_entries}+1
    \    Should Contain    ${resp.content}    user${i}

Buy Cars And Verify
    [Arguments]    ${controller_ip}    ${num_entries}    ${start}=${0}
    Wait Until Keyword Succeeds    60s    2s    BuyCar    ${controller_ip}    ${RESTCONFPORT}    ${num_entries}
    ...    ${start}

Check Cars Deleted
    [Arguments]    ${controller_ip}
    ${resp}    Getcars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete All Cars And Verify
    [Arguments]    ${controller_ip}
    DeleteAllCars    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    60s    2s    Check Cars Deleted    ${controller_ip}

Check People Deleted
    [Arguments]    ${controller_ip}
    ${resp}    GetPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete All People And Verify
    [Arguments]    ${controller_ip}
    DeleteAllPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    60s    2s    Check People Deleted    ${controller_ip}

Check Cars-Persons Deleted
    [Arguments]    ${controller_ip}
    ${resp}    GetCarPersonMappings    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete All Cars-Persons And Verify
    [Arguments]    ${controller_ip}
    DeleteAllCarsPersons    ${controller_ip}    ${RESTCONFPORT}    ${0}
    Wait Until Keyword Succeeds    60s    2s    Check Cars-Persons Deleted    ${controller_ip}

Stop One Or More Controllers
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers to be stopped.
    ${cmd} =    Set Variable    ${KARAF_HOME}/bin/stop
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    : FOR    ${ip}    IN    @{controllers}
    \    Wait Until Keyword Succeeds    120 s    3 s    Controller Down Check    ${ip}

Start One Or More Controllers
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers to be started.
    ${cmd} =    Set Variable    ${KARAF_HOME}/bin/start
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    # TODO: This should throw an error if controller never comes up.
    : FOR    ${ip}    IN    @{controllers}
    \    UtilLibrary.Wait For Controller Up    ${ip}    ${RESTCONFPORT}

Kill One Or More Controllers
    [Arguments]    @{controllers}
    [Documentation]    Give this keyword a scalar or list of controllers to be stopped.
    ${cmd} =    Set Variable    ps axf | grep karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
    log    ${cmd}
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}
    : FOR    ${ip}    IN    @{controllers}
    \    Wait Until Keyword Succeeds    12 s    3 s    Controller Down Check    ${ip}

Controller Down Check
    [Arguments]    ${ip}
    [Documentation]    Checks to see if a controller is down by verifying that the karaf process isn't present.
    ${cmd} =    Set Variable    ps axf | grep karaf | grep -v grep | wc -l
    ${response}    Run Command On Remote System    ${ip}    ${cmd}
    Log    Number of controller instances running: ${response}
    Should Start With    ${response}    0    Controller process found or there may be extra instances of karaf running on the host machine.

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

Check Cars
    [Arguments]    ${selected controller}    ${PORT}    ${nth car}
    [Documentation]    Verifies that the first through nth car is present.
    ${resp}    Getcars    ${selected controller}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${INDEX}    IN RANGE    1    ${nth car}
    \    ${counter}=    Convert to String    ${INDEX}
    \    Log    manufacturer${counter}
    \    Should Contain    ${resp.content}    manufacturer${counter}

Check People
    [Arguments]    ${selected controller}    ${PORT}    ${nth person}
    [Documentation]    Verifies that the first through nth person is present.
    ${resp}    GetPersons    ${selected controller}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${INDEX}    IN RANGE    1    ${nth person}
    \    ${counter}=    Convert to String    ${INDEX}
    \    Log    user${counter}
    \    Should Contain    ${resp.content}    user${counter}

Check CarPeople
    [Arguments]    ${selected controller}    ${PORT}    ${nth carperson}
    [Documentation]    Verifies that the first through nth car-person is present.
    ${resp}    GetCarPersonMappings    ${selected controller}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${INDEX}    IN RANGE    1    ${nth carperson}
    \    ${counter}=    Convert to String    ${INDEX}
    \    Log    user${counter}
    \    Should Contain    ${resp.content}    user${counter}

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

Wait for Cluster Sync
    [Arguments]    ${timeout}    @{controllers}
    [Documentation]    Waits for one or more clustered controlers to report Sync Status as true.
    : FOR    ${ip}    IN    @{controllers}
    \    ${resp}=    Wait Until Keyword Succeeds     90s    2s   Check Controller Sync    ${ip}

Check Controller Sync
    [Arguments]    ${controller_ip}
    [Documentation]   Checks if Sync Status is true.
    ${api}    Set Variable    /jolokia/read
    ${node}    Set Variable    /org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
    Create_Session    session    http://${controller_ip}:${RESTCONFPORT}${api}    headers=${HEADERS}    auth=${AUTH}
    ${resp}=    RequestsLibrary.Get    session    ${node}
    Log    ${resp.json()}
    Log    ${resp.content}
    ${json}=    Set Variable  ${resp.json()}
    ${value}=    Get From Dictionary  ${json}  value
    Log   value: ${value}
    ${SyncStatus}=    Get From Dictionary  ${value}    SyncStatus
    Log   SyncSatus: ${SyncStatus}
    Should Be Equal    ${resp.status_code}  ${200}
    Should Be Equal    ${SyncStatus}    ${True}
