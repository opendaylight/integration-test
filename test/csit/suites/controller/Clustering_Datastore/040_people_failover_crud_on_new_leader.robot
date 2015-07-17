*** Settings ***
Documentation     This test brings down the current leader of the "car" shard and then executes CRUD operations on the new leader
Default Tags      3-node-cluster
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.txt

*** Variables ***
${PEOPLE_SHARD}    shard-people-config
${NUM_ENTRIES}    ${50}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
Switch People Leader
    [Documentation]    Stop the leader to cause a new leader to be elected
    ${OLD_PEOPLE_LEADER}    Wait For Leader To Be Found    ${PEOPLE_SHARD}
    ${NEW_PEOPLE_LEADER}    Switch Leader    ${PEOPLE_SHARD}    ${OLD_PEOPLE_LEADER}
    Set Suite Variable    ${OLD_PEOPLE_LEADER}
    Set Suite Variable    ${NEW_PEOPLE_LEADER}

Delete people from new leader
    Delete All People And Verify    ${NEW_PEOPLE_LEADER}

Add people and get from new leader
    [Documentation]    Add people and get people from new leader
    Add People And Verify    ${NEW_PEOPLE_LEADER}    ${NUM_ENTRIES}

Get People Followers
    ${PEOPLE_FOLLOWERS}    Get All Followers    ${PEOPLE_SHARD}    ${OLD_PEOPLE_LEADER}
    Set Suite Variable    ${PEOPLE_FOLLOWERS}

Get added people from Follower
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Delete people from new Follower
    Delete All People And Verify    @{PEOPLE_FOLLOWERS}[0]

Add people from new Follower
    [Documentation]    Add people and get people from follower
    Add People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get added people from new leader
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    ${NEW_PEOPLE_LEADER}    ${NUM_ENTRIES}

Restart old People leader
    Start One Or More Controllers    ${OLD_PEOPLE_LEADER}

Get added people from old leader
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    ${OLD_PEOPLE_LEADER}    ${NUM_ENTRIES}
