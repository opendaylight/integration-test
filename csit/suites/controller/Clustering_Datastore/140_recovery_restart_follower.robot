*** Settings ***
Documentation     This test kills any of the followers and verifies that when that follower is restarted it can join the cluster
Default Tags      3-node-cluster
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${60}
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
Stop All Controllers
    [Documentation]    Stop all the controllers in the cluster
    Stop One Or More Controllers    @{controllers}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    Clean One Or More Journals    @{controllers}

Start All Controllers
    [Documentation]    Start all the controllers in the cluster
    Start One Or More Controllers    @{controllers}

Get car leader and followers
    ${CURRENT_CAR_LEADER}    Wait For Leader To Be Found    ${CAR_SHARD}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}
    Set Suite Variable    ${CAR_FOLLOWERS}

Stop both of the followers
    @{followers} =    Create List    @{CAR_FOLLOWERS}[0]    @{CAR_FOLLOWERS}[1]
    Stop One Or More Controllers    @{followers}

Attempt to add a car to the leader
    [Documentation]    Should fail as both followers are down
    AddCar    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${1}    500
    Sleep    2
    ${resp}    Getcars    ${CURRENT_CAR_LEADER}    ${RESTCONFPORT}    ${1}
    Should Not Be Equal As Strings    ${resp.status_code}    200

Restart the first follower
    Start One Or More Controllers    @{CAR_FOLLOWERS}[0]

Add cars to the first follower
    Log    Adding ${NUM_CARS} cars to @{CAR_FOLLOWERS}[0]
    Add Cars And Verify Without Init    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}    4s

Restart the second follower
    Start One Or More Controllers    @{CAR_FOLLOWERS}[1]

Get all the cars from the second follower
    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_CARS}

*** Keywords ***
Expect No Leader
    ${leader}    GetLeader    ${CAR_SHARD}    ${3}    ${1}    ${1}    ${RESTCONFPORT}
    ...    ${CURRENT_CAR_LEADER}
    Should Be Equal As Strings    ${leader}    None
