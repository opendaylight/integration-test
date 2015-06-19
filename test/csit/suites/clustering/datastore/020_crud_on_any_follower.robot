*** Settings ***
Documentation     This test finds the followers of certain shards in a 3-Node cluster and executes CRUD operations on any one follower
Default Tags      3-node-cluster
Library           Collections
Library           ../../../libraries/Common.py
Library           ../../../libraries/CrudLibrary.py
Library           ../../../libraries/SettingsLibrary.py
Library           ../../../libraries/UtilLibrary.py
Library           ../../../libraries/ClusterStateLibrary.py
Resource          ../../../libraries/ClusterKeywords.txt
Variables         ../../../variables/Variables.py

*** Variables ***
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${NUM_ENTRIES}    ${40}

*** Test Cases ***
Get Car Followers
    ${CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get People Followers
    ${PEOPLE_FOLLOWERS}    Get All Followers    ${SHARD_PEOPLE_NAME}
    Set Suite Variable    ${PEOPLE_FOLLOWERS}

Get Car-Person Followers
    ${CAR_PERSON_FOLLOWERS}    Get All Followers    ${SHARD_CAR_PERSON_NAME}
    Set Suite Variable    ${CAR_PERSON_FOLLOWERS}

Delete cars from Follower1
    Delete All Cars And Verify    @{CAR_FOLLOWERS}[0]

Delete people from Follower1
    Delete All People And Verify    @{PEOPLE_FOLLOWERS}[0]

Delete car-persons from Follower1
    Delete All Cars-Persons And Verify    @{CAR_PERSON_FOLLOWERS}[0]

Add cars and get cars from Follower1
    [Documentation]    Add cars and get added cars from Follower1
    Add Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get added cars from Follower2
    [Documentation]    Get added cars from Follower2
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_ENTRIES}

Add people and get people from Follower1
    [Documentation]    Add people and get people from Follower1
    Add People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get added people from Follower2
    [Documentation]    Get added people from Follower2
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    @{PEOPLE_FOLLOWERS}[1]    ${NUM_ENTRIES}

Add car-person mapping and get car-person mapping from Follower1
    Add Car Person And Verify    @{CAR_PERSON_FOLLOWERS}[0]

Purchase cars on Follower1
    [Documentation]    Purchase cars using Follower1
    Buy Cars And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get car-person mappings from Follower1
    [Documentation]    Get car-person mappings from Follower1 to see all entries
    Wait Until Keyword Succeeds    60s    2s    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get car-person mappings from Leader
    [Documentation]    Get car-person mappings from the Leader to see all entries
    ${CURRENT_CAR_LEADER}    Wait For Leader    ${SHARD_CAR_PERSON_NAME}
    Wait Until Keyword Succeeds    60s    2s    Get Car-Person Mappings And Verify    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Get car-person mappings from Follower2
    [Documentation]    Get car-person mappings from Follower2 to see all entries
    Wait Until Keyword Succeeds    60s    2s    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[1]    ${NUM_ENTRIES}
