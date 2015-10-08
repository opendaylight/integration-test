*** Settings ***
Documentation     Test suite for Routed RPC.
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    180s

*** Test Cases ***
Delete All Entries From Shards
    [Documentation]    Make sure the shards are cleared for testing.
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All Cars And Verify    ${ip}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All People And Verify    ${ip}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All Cars-Persons And Verify    ${ip}

Get Car Leader And Followers
    [Documentation]    Find leader and followers in the car shard
    ${CURRENT_CAR_LEADER}    Get Leader And Verify    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    @{CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Add Cars And Get Cars From Leader
    [Documentation]    Add 100 cars and get added cars from Leader
    ${resp}=    InitCar    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}
    ${resp}=    AddCar    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${100}
    ${resp}=    Getcars    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1    cars not added!

Add Persons And Get Persons From Leader
    [Documentation]    Add 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${0}
    ${resp}    AddPerson    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${100}
    ${resp}    GetPersons    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5    people not added!

Add Car-Person Mapping And Get Car-Person Mapping From Follower1
    [Documentation]    Add car-person and get car-person from Leader Note: This is done to enable working of rpc
    Log    @{CAR_FOLLOWERS}[0]
    ${resp}    AddCarPerson    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    GetCarPersonMappings    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user0    car-person not initialized!

Purchase 100 Cars Using Follower1
    [Documentation]    Purchase 100 cars using Follower1
    BuyCar    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    ${100}

Check Contents Of Leader Shards
    [Documentation]    Check all content using Leader
    wait until keyword succeeds    3    1    Check Cars    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check People    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check CarPeople    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    100

Check Contents Of First Follower Shards
    [Documentation]    Check all content using first follower
    wait until keyword succeeds    3    1    Check Cars    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check People    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check CarPeople    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    100

Check Contents Of Second Follower Shards
    [Documentation]    Check all content using second follower
    wait until keyword succeeds    3    1    Check Cars    @{CAR_FOLLOWERS}[1]    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check People    @{CAR_FOLLOWERS}[1]    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check CarPeople    @{CAR_FOLLOWERS}[1]    ${RESTCONFPORT}    100

Get Old Car Leader
    [Documentation]    Find leader in the car shard
    ${OLD_CAR_LEADER}    Get Leader And Verify    ${SHARD_CAR_NAME}
    Set Suite Variable    ${OLD_CAR_LEADER}

Switch Car Leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    Stop One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Down    ${STOP_TIMEOUT}    ${OLD_CAR_LEADER}
    ${NEW_CAR_LEADER}    Wait Until Keyword Succeeds    30s    2s    Get Leader And Verify    ${SHARD_CAR_NAME}    ${OLD_CAR_LEADER}
    Set Suite Variable    ${NEW_CAR_LEADER}

Get New Car Followers
    [Documentation]    Find the new followers for the car shard.
    @{CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}
    Log    @{CAR_FOLLOWERS}[0]

Overwrite Cars And Get Cars From New Leader
    [Documentation]    Overwrite 100 cars and get added cars from Leader
    ${resp}=    AddCar    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    ${100}
    ${resp}=    Getcars    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1    cars not added!

Overwrite Persons And Get Persons From New Leader
    [Documentation]    Overwrite 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    ${100}
    ${resp}    GetPersons    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5    people not added!

RePurchase 100 Cars Using New Follower1
    [Documentation]    RePurchase 100 cars using Follower1
    BuyCar    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    ${100}

Check Contents Of New Leader Shards
    [Documentation]    Check all content using Leader
    Log    ${NEW_CAR_LEADER}
    wait until keyword succeeds    3    1    Check Cars    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check People    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check CarPeople    ${NEW_CAR_LEADER}    ${RESTCONFPORT}    100

Check Contents Of New First Follower Shards
    [Documentation]    Check all content using first follower
    wait until keyword succeeds    3    1    Check Cars    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check People    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    100
    wait until keyword succeeds    3    1    Check CarPeople    @{CAR_FOLLOWERS}[0]    ${RESTCONFPORT}    100

Start Leader
    [Documentation]    Start Leader controller
    Start One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Sync    ${START_TIMEOUT}    ${OLD_CAR_LEADER}

