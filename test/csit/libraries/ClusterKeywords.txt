*** Settings ***
Resource          Utils.robot
Library           Collections

*** Variables ***

*** Keywords ***
Get Controller List
    [Arguments]    ${exclude_controller}=${EMPTY}
    [Documentation]  Creates a list of all controllers minus any excluded controller.
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
    \    Wait Until Keyword Succeeds    120 s   3 s    Controller Down Check    ${ip}

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
