*** Settings ***
Documentation     This test kills any of the followers and verifies that when that follower is restarted it can join the cluster
Default Tags      3-node-cluster
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/CrudLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/CarsAndPeople.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${60}
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    180s

*** Test Cases ***
Stop All Controllers
    [Documentation]    Stop all the controllers in the cluster
    Stop One Or More Controllers    @{controllers}
    Wait For Cluster Down    ${STOP_TIMEOUT}    @{controllers}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    Clean One Or More Journals    @{controllers}

Start All Controllers
    [Documentation]    Start all the controllers in the cluster
    Start One Or More Controllers    @{controllers}
    Wait For Cluster Sync    ${START_TIMEOUT}    @{controllers}

Get Car Leader And Followers
    [Documentation]    Find leader and followers in the car shard
    ${CURRENT_CAR_LEADER}    Get Leader And Verify    ${CAR_SHARD}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}
    Set Suite Variable    ${CAR_FOLLOWERS}

Verify No Cars On Leader After Restart
    [Documentation]    Verify no cars after restart
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Check Cars Deleted    ${CURRENT_CAR_LEADER}

Stop Both Of The Followers
    [Documentation]    Stop car followers
    @{followers} =    Create List    @{CAR_FOLLOWERS}[0]    @{CAR_FOLLOWERS}[1]
    Stop One Or More Controllers    @{followers}
    Wait For Cluster Down    ${STOP_TIMEOUT}    @{followers}

Attempt To Add A Car To The Leader
    [Documentation]    Add car should fail as both followers are down
    AddCar    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${1}    500
    Sleep    2
    ${resp}    Getcars    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${1}
    Should Not Be Equal As Strings    ${resp.status_code}    200

Restart The First Follower
    [Documentation]    Start one follower
    Start One Or More Controllers    @{CAR_FOLLOWERS}[0]
    Wait For Controller Sync    ${START_TIMEOUT}    @{CAR_FOLLOWERS}[0]

Add Cars To The First Follower
    [Documentation]    Add cars to the follower and verify
    Log    Adding ${NUM_CARS} cars to @{CAR_FOLLOWERS}[0]
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Add Cars And Verify Without Init    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Restart The Second Follower
    [Documentation]    Start another follower
    Start One Or More Controllers    @{CAR_FOLLOWERS}[1]
    Wait For Controller Sync    ${START_TIMEOUT}    @{CAR_FOLLOWERS}[1]

Get All The Cars From The Second Follower
    [Documentation]    Add cars to the follower and verify
    Wait Until Keyword Succeeds    ${START_TIMEOUT}    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_CARS}

