*** Settings ***
Documentation     This test brings down the current leader of the "car" shard and then executes CRUD
...               operations on the new leader
Default Tags      3-node-cluster
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${50}
${NUM_ORIG_CARS}    ${10}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    300s

*** Test Cases ***
Get Old Car Leader
    [Documentation]    Find leader in the car shard
    ${OLD_CAR_LEADER}    Get Leader And Verify    ${CAR_SHARD}
    Set Suite Variable    ${OLD_CAR_LEADER}

Delete Cars On Old Leader
    [Documentation]    Delete cars in Leader
    Delete All Cars And Verify    ${OLD_CAR_LEADER}

Add Original Cars On Old Leader
    [Documentation]    Add new cars in Leader and verify
    Add Cars And Verify    ${OLD_CAR_LEADER}    ${NUM_ORIG_CARS}

Switch Car Leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    Stop One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Down    ${STOP_TIMEOUT}    ${OLD_CAR_LEADER}
    ${NEW_CAR_LEADER}    Wait Until Keyword Succeeds    60s    2s    Get Leader And Verify    ${CAR_SHARD}    ${OLD_CAR_LEADER}
    Set Suite Variable    ${NEW_CAR_LEADER}

Get Original Cars On New Leader
    [Documentation]    Get cars in new Leader
    Get Cars And Verify    ${NEW_CAR_LEADER}    ${NUM_ORIG_CARS}

Delete Cars On New Leader
    [Documentation]    Delete cars in new Leader
    Delete All Cars And Verify    ${NEW_CAR_LEADER}

Add New Cars And Get Cars From New Leader
    [Documentation]    Add cars and get added cars from the Leader
    Add Cars And Verify    ${NEW_CAR_LEADER}    ${NUM_CARS}

Get Car Followers
    [Documentation]    Find followers in the car shard
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}    ${OLD_CAR_LEADER}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get Added Cars From Follower
    [Documentation]    Get the added cars from the Follower
    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Delete Cars On Follower
    [Documentation]    Delete cars in follower
    Delete All Cars And Verify    @{CAR_FOLLOWERS}[0]

Add Cars From Follower
    [Documentation]    Add more cars from the Follower
    Add Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Get Added Cars From New Leader
    [Documentation]    Get added cars from the new leader
    Get Cars And Verify    ${NEW_CAR_LEADER}    ${NUM_CARS}

Restart Old Car Leader
    [Documentation]    Start old car Leader
    Start One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Sync    ${START_TIMEOUT}    ${OLD_CAR_LEADER}

Get Added Cars From Old Leader
    [Documentation]    Get the added cars from the old leader
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    ${OLD_CAR_LEADER}    ${NUM_CARS}
