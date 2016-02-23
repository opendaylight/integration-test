*** Settings ***
Documentation     This test brings down the current leader of the "car" shard and then executes CRUD
...               operations on the new leader
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/CarsAndPeople.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${CAR_SHARD}      shard-car-config
${NUM_CARS}       ${50}
${NUM_ORIG_CARS}    ${10}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    180s

*** Test Cases ***
Run until failure
    [Setup]  session setup
	:FOR  ${index}    IN RANGE    200
	\  Get old car leader
	\  Switch car leader
	\  Restart old Car leader
	\  Get old car leader
	\  Assertion

*** Keywords ***
Get Old Car Leader
    [Documentation]    Find leader in the car shard
    ${OLD_CAR_LEADER}    Get Leader And Verify    ${CAR_SHARD}
    Set Suite Variable    ${OLD_CAR_LEADER}
Switch Car Leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    Stop One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Down    ${STOP_TIMEOUT}    ${OLD_CAR_LEADER}
    ${NEW_CAR_LEADER}    Wait Until Keyword Succeeds    30s    2s    Get Leader And Verify    ${CAR_SHARD}    ${OLD_CAR_LEADER}
    Set Suite Variable    ${NEW_CAR_LEADER}
Restart Old Car Leader
    [Documentation]    Start old car Leader
    Start One Or More Controllers    ${OLD_CAR_LEADER}
    Wait For Controller Sync    ${START_TIMEOUT}    ${OLD_CAR_LEADER}
Assertion
    Assert Ownership  ${CAR_SHARD}
session setup
    ${controller_IPs}       Get Controller List
    :FOR    ${ip}   IN  @{controller_IPs}
    \    Create Session      ${ip}    http://${ip}:8181/restconf        auth=${AUTH}    headers=${HEADERS}