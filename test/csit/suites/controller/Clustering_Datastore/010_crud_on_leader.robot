*** Settings ***
Documentation     This test finds the leader for shards in a 3-Node cluster and executes CRUD operations on them
Default Tags      3-node-cluster
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
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${NUM_ENTRIES}    ${30}

*** Test Cases ***
Get Car Leader And Followers
    ${CURRENT_CAR_LEADER}    Wait For Leader To Be Found    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    ${CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Add cars and get cars from Leader
    [Documentation]    Add some cars and get added cars from Leader
    Add Cars And Verify    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Get added cars from Follower1
    [Documentation]    Get added cars from Follower1
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get added cars from Follower2
    [Documentation]    Get added cars from Follower2
    Wait Until Keyword Succeeds    60s    2s    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_ENTRIES}

Get People Leader And Followers
    ${CURRENT_PEOPLE_LEADER}    Wait For Leader To Be Found    ${SHARD_PEOPLE_NAME}
    Set Suite Variable    ${CURRENT_PEOPLE_LEADER}
    ${PEOPLE_FOLLOWERS}    Get All Followers    ${SHARD_PEOPLE_NAME}
    Set Suite Variable    ${PEOPLE_FOLLOWERS}

Add people and get people from Leader
    [Documentation]    Add some people and get people from Leader.
    Add People And Verify    ${CURRENT_PEOPLE_LEADER}    ${NUM_ENTRIES}

Get added people from Follower1
    [Documentation]    Get added people from Follower1
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get added people from Follower2
    [Documentation]    Get added people from Follower2
    Wait Until Keyword Succeeds    60s    2s    Get People And Verify    @{PEOPLE_FOLLOWERS}[1]    ${NUM_ENTRIES}

Get Car-Person Leader And Followers
    ${CURRENT_CAR_PERSON_LEADER}    Wait For Leader To Be Found    ${SHARD_CAR_PERSON_NAME}
    Set Suite Variable    ${CURRENT_CAR_PERSON_LEADER}
    ${CAR_PERSON_FOLLOWERS}    Get All Followers    ${SHARD_CAR_PERSON_NAME}
    Set Suite Variable    ${CAR_PERSON_FOLLOWERS}

Add car-person mapping and get car-person mapping from Leader
    Add Car Person And Verify    ${CURRENT_CAR_PERSON_LEADER}

Purchase cars on Leader
    [Documentation]    Purchase some cars on the Leader
    ${NUM_BUY_CARS_ON_LEADER}    Evaluate    ${NUM_ENTRIES}/3
    ${NUM_BUY_CARS_ON_FOLLOWER1}    Evaluate    ${NUM_ENTRIES}/3
    ${NUM_BUY_CARS_ON_FOLLOWER2}    Evaluate    ${NUM_ENTRIES}-${NUM_BUY_CARS_ON_LEADER}-${NUM_BUY_CARS_ON_FOLLOWER1}
    Set Suite Variable    ${NUM_BUY_CARS_ON_LEADER}
    Set Suite Variable    ${NUM_BUY_CARS_ON_FOLLOWER1}
    Set Suite Variable    ${NUM_BUY_CARS_ON_FOLLOWER2}
    Buy Cars And Verify    ${CURRENT_CAR_PERSON_LEADER}    ${NUM_BUY_CARS_ON_LEADER}

Purchase cars on Follower1
    [Documentation]    Purchase some cars on Follower1
    Buy Cars And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_BUY_CARS_ON_FOLLOWER1}    ${NUM_BUY_CARS_ON_LEADER}

Purchase cars on Follower2
    [Documentation]    Purchase some cars on Follower2
    ${start}    Evaluate    ${NUM_BUY_CARS_ON_LEADER}+${NUM_BUY_CARS_ON_FOLLOWER1}
    Buy Cars And Verify    @{CAR_PERSON_FOLLOWERS}[1]    ${NUM_BUY_CARS_ON_FOLLOWER2}    ${start}

Get car-person mappings from Leader
    [Documentation]    Get car-person mappings from Leader to see all entries
    Wait Until Keyword Succeeds    60s    2s    Get Car-Person Mappings And Verify    ${CURRENT_CAR_PERSON_LEADER}    ${NUM_ENTRIES}

Get car-person mappings from Follower1
    [Documentation]    Get car-person mappings from Follower1 to see all entries
    Wait Until Keyword Succeeds    60s    2s    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get car-person mappings from Follower2
    [Documentation]    Get car-person mappings from Follower2 to see all entries
    Wait Until Keyword Succeeds    60s    2s    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[1]    ${NUM_ENTRIES}
