*** Settings ***
Documentation     This test restarts all controllers to verify recovery of car data from persistene
Default Tags      3-node-cluster
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.txt
Variables         ../../../variables/Variables.py

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${50}

*** Test Cases ***
Get car leader
    ${CAR_LEADER}    Wait For Leader    ${CAR_SHARD}
    Set Suite Variable    ${CAR_LEADER}

Delete cars from leader
    Delete All Cars And Verify    ${CAR_LEADER}

Stop all controllers after delete
    @{controllers} =    Create List    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
    Stop One Or More Controllers    @{controllers}

Start all controllers after delete
    @{controllers} =    Create List    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
    Start One Or More Controllers    @{controllers}

Verify no cars on leader after restart
    ${resp}    Getcars    ${CAR_LEADER}    ${RESTCONFPORT}    ${0}
    Should Be Equal As Strings    ${resp.status_code}    404

Add cars on leader
    Add Cars And Verify    ${CAR_LEADER}    ${NUM_CARS}

Stop all controllers after add
    @{controllers} =    Create List    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
    Stop One Or More Controllers    @{controllers}

Start all controllers after add
    @{controllers} =    Create List    ${CONTROLLER}    ${CONTROLLER1}    ${CONTROLLER2}
    Start One Or More Controllers    @{controllers}

Get cars from leader after restart
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    ${CAR_LEADER}    ${NUM_CARS}

Get car followers
    ${CAR_FOLLOWERS}    Get All Followers    ${CAR_SHARD}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get cars from Follower1 after restart
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_CARS}

Get cars from Follower2 after restart
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_CARS}
