*** Settings ***
Documentation     This test restarts all controllers to verify recovery of car data from persistene
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/CarsAndPeople.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${50}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
@{controllers}    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    180s

*** Test Cases ***
Get Car Leader
    [Documentation]    Find leader in the car shard
    ${CAR_LEADER}    Get Leader And Verify    ${CAR_SHARD}
    Set Suite Variable    ${CAR_LEADER}

Delete Cars From Leader
    [Documentation]    Delete cars in Leader
    Delete All Cars And Verify    ${CAR_LEADER}

Stop All Controllers After Delete
    [Documentation]    Stop all controllers
    Stop One Or More Controllers    @{controllers}
    Wait For Cluster Down    ${STOP_TIMEOUT}    @{controllers}

Start All Controllers After Delete
    [Documentation]    Start all controller
    Start One Or More Controllers    @{controllers}
    Wait For Cluster Sync    ${START_TIMEOUT}    @{controllers}

Get Car Leader After First Restart
    [Documentation]    Find leader in the car shard
    ${CAR_LEADER}    Get Leader And Verify    ${CAR_SHARD}
    Set Suite Variable    ${CAR_LEADER}

Verify No Cars On Leader After Restart
    [Documentation]    Verify no cars after restart
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Check Cars Deleted    ${CAR_LEADER}

Add Cars On Leader
    [Documentation]    Add cars in Leader
    Add Cars And Verify    ${CAR_LEADER}    ${NUM_CARS}

Stop All Controllers After Add
    [Documentation]    Stop all controllers
    Stop One Or More Controllers    @{controllers}
    Wait For Cluster Down    ${STOP_TIMEOUT}    @{controllers}

Start All Controllers After Add
    [Documentation]    Start all controllers
    Start One Or More Controllers    @{controllers}
    Wait For Cluster Sync    ${START_TIMEOUT}    @{controllers}

Get Car Leader After Second Restart
    [Documentation]    Find leader in the car shard
    ${CAR_LEADER}    Get Leader And Verify    ${CAR_SHARD}
    Set Suite Variable    ${CAR_LEADER}

Get Cars From Leader After Restart
    [Documentation]    Get cars from Leader and verify
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Get Cars And Verify    ${CAR_LEADER}    ${NUM_CARS}

Get Car Followers
    [Documentation]    Find followers in the car shard
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get Cars From Follower1 After Restart
    [Documentation]    Get cars in follower and verify
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Get Cars From Follower2 After Restart
    [Documentation]    Get cars in follower and verify
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_CARS}
