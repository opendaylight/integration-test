*** Settings ***
Documentation     Test suite for Routed RPC.
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/CrudLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/CarsAndPeople.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{controllers}    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${NUM_ENTRIES}    ${100}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    180s

*** Test Cases ***
Delete All Entries
    [Documentation]    Make sure the shards are cleared for testing.
    Delete All Entries From Shards    @{controllers}

Get Car Leader And Followers
    [Documentation]    Find leader and followers in the car shard
    ${CURRENT_CAR_LEADER}    Get Leader And Verify    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    @{CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Add Cars And Get Cars From Leader
    [Documentation]    Add 100 cars and get added cars from Leader
    Add Cars And Verify    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Add Persons And Get Persons From Car Leader
    [Documentation]    Add 100 persons and get persons from Leader
    Add People And Verify    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Add Car-Person Mapping And Get Car-Person Mapping From Car Follower1
    [Documentation]    Add car-person and get car-person from Leader
    Add Car Person And Verify    @{CAR_FOLLOWERS}[0]

Purchase 100 Cars Using Car Follower1
    [Documentation]    Purchase 100 cars using Follower1
    Buy Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Check Contents Of Car Leader Shards
    [Documentation]    Check all content using Leader
    Check Elements In Shards    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Check Contents Of Car Follower1 Shards
    [Documentation]    Check all content using first follower
    Check Elements In Shards    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Check Contents Of Car Follower2 Shards
    [Documentation]    Check all content using second follower
    Check Elements In Shards    @{CAR_FOLLOWERS}[1]    ${NUM_ENTRIES}

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

Check Cars In New Car Leader
    [Documentation]    Check cars in new Leader
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Check Cars    ${NEW_CAR_LEADER}    ${NUM_ENTRIES}

Check Contents Of New Car Leader Shards
    [Documentation]    Check all content using new Leader
    Check Elements In Shards    ${NEW_CAR_LEADER}    ${NUM_ENTRIES}

Check Contents Of New Car Follower1 Shards
    [Documentation]    Check all content using first follower
    Check Elements In Shards    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Readd People From New Car Leader
    [Documentation]    Add 100 persons and get persons from Leader
    Add People And Verify Without Init    ${NEW_CAR_LEADER}    ${NUM_ENTRIES}

Repurchase 100 Cars Using New Car Follower1
    [Documentation]    Repurchase 100 cars using Follower1
    Buy Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Check Contents Of New Car Leader Shards After Repurchase
    [Documentation]    Check all content using new Leader
    Check Elements In Shards    ${NEW_CAR_LEADER}    ${NUM_ENTRIES}

Check Contents Of New Car First Follower Shards After Repurchase
    [Documentation]    Check all content using first follower
    Check Elements In Shards    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Start Old Car Leader
    [Documentation]    Start Leader controller
    Start One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Sync    ${START_TIMEOUT}    ${OLD_CAR_LEADER}

Check Cars In Old Car Leader
    [Documentation]    Check cars in old Leader
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Check Cars    ${OLD_CAR_LEADER}    ${NUM_ENTRIES}

Check Contents Of Old Leader Shards
    [Documentation]    Check all content using old Leader
    Check Elements In Shards    ${OLD_CAR_LEADER}    ${NUM_ENTRIES}

Readd People From Old Leader
    [Documentation]    Add 100 persons and get persons from Leader
    Wait Until Keyword Succeeds    30    2s    Add People And Verify Without Init    ${OLD_CAR_LEADER}    ${NUM_ENTRIES}

Repurchase 100 Cars Using Old Leader
    [Documentation]    Repurchase 100 cars using Follower1
    Buy Cars And Verify    ${OLD_CAR_LEADER}    ${NUM_ENTRIES}

Check Contents Of Old Leader Shards After Repurchase
    [Documentation]    Check all content using Leader
    Check Elements In Shards    ${OLD_CAR_LEADER}    ${NUM_ENTRIES}
