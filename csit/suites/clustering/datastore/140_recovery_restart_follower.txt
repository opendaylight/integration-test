*** Settings ***
Documentation     This test kills any of the followers and verifies that when that follower is restarted it can join the cluster
Default Tags  3-node-cluster

Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.txt
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CONTEXT}    /restconf/config/
${CAR_SHARD}	   shard-car-config
${NUM_CARS}     ${60}

*** Test Cases ***
Stop All Controllers
    [Documentation]    Stop all the controllers in the cluster
    StopAllControllers    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}    ${MEMBER1}    ${MEMBER2}    ${MEMBER3}

Clean All Journals
    [Documentation]    Clean the journals of all the controllers in the cluster
    CleanJournal    ${MEMBER1}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    CleanJournal    ${MEMBER2}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}
    CleanJournal    ${MEMBER3}    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}

Start All Controllers
    [Documentation]    Start all the controllers in the cluster
    ${rc}   StartAllControllers    ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}    ${RESTCONFPORT}
    ...    ${MEMBER1}    ${MEMBER2}    ${MEMBER3}
    Should Be True    ${rc}

Get car leader and followers
    ${CURRENT_CAR_LEADER}   Wait For Leader   ${CAR_SHARD}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    ${CAR_FOLLOWERS}  Get All Followers  ${CAR_SHARD}
    Set Suite Variable    ${CAR_FOLLOWERS}

Stop both of the followers
    StopAllControllers    ${USER_NAME}   ${PASSWORD}   ${KARAF_HOME}   @{CAR_FOLLOWERS}[0]    @{CAR_FOLLOWERS}[1]
    Wait Until Keyword Succeeds   30s  2s  Expect No Leader

Attempt to add a car from the leader
    [Documentation]    Should fail as both followers are down
    AddCar  ${CURRENT_CAR_LEADER}    ${PORT}    ${1}
    Sleep  2
    ${resp}    Getcars    ${CURRENT_CAR_LEADER}    ${PORT}    ${1}
    Should Not Be Equal As Strings    ${resp.status_code}    200

Restart the first follower
    StartController    @{CAR_FOLLOWERS}[0]   ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}    ${PORT}
    Sleep    1

Add cars from the first follower
    Wait Until Keyword Succeeds   60s  2s  Add Cars And Verify   @{CAR_FOLLOWERS}[0]   ${NUM_CARS}  4s

Restart the second follower
    StartController    @{CAR_FOLLOWERS}[1]   ${USER_NAME}    ${PASSWORD}    ${KARAF_HOME}    ${PORT}

Get all the cars from the second follower
    Wait Until Keyword Succeeds   60s  2s  Get Cars And Verify   @{CAR_FOLLOWERS}[1]   ${NUM_CARS}

*** Keywords ***
Expect No Leader
    ${leader}   GetLeader   ${CAR_SHARD}   ${3}    ${1}    ${1}    ${PORT}     ${CURRENT_CAR_LEADER}
    Should Be Equal As Strings   ${leader}   None
