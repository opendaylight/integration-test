*** Settings ***
Documentation     This test brings down the current leader of the "car" shard and then executes CRUD operations on the new leader
Default Tags      3-node-cluster
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
${PEOPLE_SHARD}    shard-people-config
${NUM_ENTRIES}    ${50}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    300s

*** Test Cases ***
Get Old People Leader
    [Documentation]    Find leader in the people shard
    ${OLD_PEOPLE_LEADER}    Get Leader And Verify    ${PEOPLE_SHARD}
    Set Suite Variable    ${OLD_PEOPLE_LEADER}

Switch People Leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    Stop One Or More Controllers    ${OLD_PEOPLE_LEADER}
    Wait For Controller Down    ${STOP_TIMEOUT}    ${OLD_PEOPLE_LEADER}
    ${NEW_CAR_LEADER}    Wait Until Keyword Succeeds    60s    2s    Get Leader And Verify    ${PEOPLE_SHARD}    ${OLD_PEOPLE_LEADER}
    Set Suite Variable    ${OLD_PEOPLE_LEADER}

Delete People From New Leader
    [Documentation]    Delete people in new Leader
    Delete All People And Verify    ${NEW_PEOPLE_LEADER}

Add People And Get From New Leader
    [Documentation]    Add people and get people from new leader
    Add People And Verify    ${NEW_PEOPLE_LEADER}    ${NUM_ENTRIES}

Get People Followers
    [Documentation]    Find followers in the people shard
    ${PEOPLE_FOLLOWERS}    Get All Followers    ${PEOPLE_SHARD}    ${OLD_PEOPLE_LEADER}
    Set Suite Variable    ${PEOPLE_FOLLOWERS}

Get Added People From Follower
    [Documentation]    Get people in follower and verify
    Get People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Delete People From New Follower
    [Documentation]    Delete people in follower and verify
    Delete All People And Verify    @{PEOPLE_FOLLOWERS}[0]

Add People From New Follower
    [Documentation]    Add people in follower and verify
    Add People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Added People From New Leader
    [Documentation]    Get people in Leader and verify
    Get People And Verify    ${NEW_PEOPLE_LEADER}    ${NUM_ENTRIES}

Restart Old People Leader
    [Documentation]    Start old people Leader
    Start One Or More Controllers    ${OLD_PEOPLE_LEADER}
    Wait For Controller Sync    ${START_TIMEOUT}    ${OLD_PEOPLE_LEADER}

Get Added People From Old Leader
    [Documentation]    Get people in old Leader and verify
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    ${OLD_PEOPLE_LEADER}    ${NUM_ENTRIES}
