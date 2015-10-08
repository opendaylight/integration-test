*** Settings ***
Documentation     This test restarts all controllers to verify recovery of car data from persistene
Default Tags      3-node-cluster
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${50}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    300s

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

Verify No Cars On Leader After Restart
    [Documentation]    Verify no cars after restart
    ${resp}    Getcars    ${CAR_LEADER}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

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

Get Cars From Leader After Restart
    [Documentation]    Get cars from Leader and verify
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    ${CAR_LEADER}    ${NUM_CARS}

Get Car Followers
    [Documentation]    Find followers in the car shard
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get Cars From Follower1 After Restart
    [Documentation]    Get cars in follower and verify
    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Get Cars From Follower2 After Restart
    [Documentation]    Get cars in follower and verify
    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_CARS}
