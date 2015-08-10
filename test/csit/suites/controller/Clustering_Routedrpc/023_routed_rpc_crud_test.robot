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

*** Test Cases ***
Delete all entries from shards
    [Documentation]    Make sure the shards are cleared for testing.
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All Cars And Verify    ${ip}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All People And Verify    ${ip}
    : FOR    ${ip}    IN    @{controllers}
    \    Delete All Cars-Persons And Verify    ${ip}

Get Car Leader And Followers
    ${CURRENT_CAR_LEADER}    Wait For Leader To Be Found    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    @{CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Add cars and get cars from Leader
    [Documentation]    Add 100 cars and get added cars from Leader
    ${resp}=    InitCar    ${CURRENT_CAR_LEADER}    ${PORT}
    ${resp}=    AddCar    ${CURRENT_CAR_LEADER}    ${PORT}    ${100}
    ${resp}=    Getcars    ${CURRENT_CAR_LEADER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1    cars not added!

Add persons and get persons from Leader
    [Documentation]    Add 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${CURRENT_CAR_LEADER}    ${PORT}    ${0}
    ${resp}    AddPerson    ${CURRENT_CAR_LEADER}    ${PORT}    ${100}
    ${resp}    GetPersons    ${CURRENT_CAR_LEADER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5    people not added!

Add car-person mapping and get car-person mapping from Follower1
    [Documentation]    Add car-person and get car-person from Leader Note: This is done to enable working of rpc
    Log    @{CAR_FOLLOWERS}[0]
    ${resp}    AddCarPerson    @{CAR_FOLLOWERS}[0]    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    GetCarPersonMappings    @{CAR_FOLLOWERS}[0]    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user0    car-person not initialized!

Purchase 100 cars using Follower1
    [Documentation]    Purchase 100 cars using Follower1
    BuyCar    @{CAR_FOLLOWERS}[0]    ${PORT}    ${100}

Check Contents of Leader Shards
    [Documentation]    Check all content using Leader
    wait until keyword succeeds    30    1    Check Cars    ${CURRENT_CAR_LEADER}    ${PORT}    100
    wait until keyword succeeds    30    1    Check People    ${CURRENT_CAR_LEADER}    ${PORT}    100
    wait until keyword succeeds    30    1    Check CarPeople    ${CURRENT_CAR_LEADER}    ${PORT}    100

Check Contents of First Follower Shards
    [Documentation]    Check all content using first follower
    wait until keyword succeeds    30    1    Check Cars    @{CAR_FOLLOWERS}[0]    ${PORT}    100
    wait until keyword succeeds    30    1    Check People    @{CAR_FOLLOWERS}[0]    ${PORT}    100
    wait until keyword succeeds    30    1    Check CarPeople    @{CAR_FOLLOWERS}[0]    ${PORT}    100

Check Contents of Second Follower Shards
    [Documentation]    Check all content using second follower
    wait until keyword succeeds    30    1    Check Cars    @{CAR_FOLLOWERS}[1]    ${PORT}    100
    wait until keyword succeeds    30    1    Check People    @{CAR_FOLLOWERS}[1]    ${PORT}    100
    wait until keyword succeeds    30    1    Check CarPeople    @{CAR_FOLLOWERS}[1]    ${PORT}    100

Switch Car leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    ${OLD_CAR_LEADER}=    Set Variable    ${CURRENT_CAR_LEADER}
    Set Suite Variable    ${OLD_CAR_LEADER}
    ${NEW_CAR_LEADER}    Switch Leader    ${SHARD_CAR_NAME}    ${CURRENT_CAR_LEADER}
    Set Suite Variable    ${NEW_CAR_LEADER}

Get New Car Follower
    [Documentation]    Find the new leader for the car shard.
    @{CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}
    Log    @{CAR_FOLLOWERS}[0]

Overwrite cars and get cars from New Leader
    [Documentation]    Overwrite 100 cars and get added cars from Leader
    ${resp}=    AddCar    ${NEW_CAR_LEADER}    ${PORT}    ${100}
    ${resp}=    Getcars    ${NEW_CAR_LEADER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    manufacturer1    cars not added!

Overwrite persons and get persons from New Leader
    [Documentation]    Overwrite 100 persons and get persons Note: There should be one person added first to enable rpc
    ${resp}    AddPerson    ${NEW_CAR_LEADER}    ${PORT}    ${100}
    ${resp}    GetPersons    ${NEW_CAR_LEADER}    ${PORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    user5    people not added!

RePurchase 100 cars using New Follower1
    [Documentation]    RePurchase 100 cars using Follower1
    BuyCar    @{CAR_FOLLOWERS}[0]    ${PORT}    ${100}

Check Contents of New Leader Shards
    [Documentation]    Check all content using Leader
    Log    ${NEW_CAR_LEADER}
    wait until keyword succeeds    30    1    Check Cars    ${NEW_CAR_LEADER}    ${PORT}    100
    wait until keyword succeeds    30    1    Check People    ${NEW_CAR_LEADER}    ${PORT}    100
    wait until keyword succeeds    30    1    Check CarPeople    ${NEW_CAR_LEADER}    ${PORT}    100

Check Contents of New First Follower Shards
    [Documentation]    Check all content using first follower
    wait until keyword succeeds    30    1    Check Cars    @{CAR_FOLLOWERS}[0]    ${PORT}    100
    wait until keyword succeeds    30    1    Check People    @{CAR_FOLLOWERS}[0]    ${PORT}    100
    wait until keyword succeeds    30    1    Check CarPeople    @{CAR_FOLLOWERS}[0]    ${PORT}    100

Start Leader
    [Documentation]    Start Leader controller
    Start One Or More Controllers    ${OLD_CAR_LEADER}
