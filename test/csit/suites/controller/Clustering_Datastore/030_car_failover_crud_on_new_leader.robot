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

*** Test Cases ***
Get old car leader
    ${OLD_CAR_LEADER}    Wait For Leader To Be Found    ${CAR_SHARD}
    Set Suite Variable    ${OLD_CAR_LEADER}

Delete cars on old leader
    Delete All Cars And Verify    ${OLD_CAR_LEADER}

Add original cars on old leader
    Add Cars And Verify    ${OLD_CAR_LEADER}    ${NUM_ORIG_CARS}

Switch car leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    ${NEW_CAR_LEADER}    Switch Leader    ${CAR_SHARD}    ${OLD_CAR_LEADER}
    Set Suite Variable    ${NEW_CAR_LEADER}

Get original cars on new leader
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    ${NEW_CAR_LEADER}    ${NUM_ORIG_CARS}

Delete cars on new leader
    Delete All Cars And Verify    ${NEW_CAR_LEADER}

Add new cars and get cars from new leader
    [Documentation]    Add cars and get added cars from the Leader
    Add Cars And Verify    ${NEW_CAR_LEADER}    ${NUM_CARS}

Get Car Followers
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}    ${OLD_CAR_LEADER}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get added cars from Follower
    [Documentation]    Get the added cars from the Follower
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Delete cars on Follower
    Delete All Cars And Verify    @{CAR_FOLLOWERS}[0]

Add cars from Follower
    [Documentation]    Add more cars from the Follower
    Add Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Get added cars from new leader
    [Documentation]    Get added cars from the new leader
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    ${NEW_CAR_LEADER}    ${NUM_CARS}

Restart old Car leader
    Start One Or More Controllers    ${OLD_CAR_LEADER}

Get added cars from old leader
    [Documentation]    Get the added cars from the old leader
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    ${OLD_CAR_LEADER}    ${NUM_CARS}
