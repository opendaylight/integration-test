*** Settings ***
Documentation     This test finds the leader for shards in a 3-Node cluster and executes CRUD operations on them
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
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${NUM_ENTRIES}    ${30}
${START_TIMEOUT}    300s
${STOP_TIMEOUT}    300s

*** Test Cases ***
Get Car Leader And Followers
    [Documentation]    Find leader and followers in the car shard
    ${CURRENT_CAR_LEADER}    Get Leader And Verify    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CURRENT_CAR_LEADER}
    ${CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Add Cars And Get Cars From Leader
    [Documentation]    Add some cars and get added cars from Leader
    Add Cars And Verify    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Get Added Cars From Follower1
    [Documentation]    Get added cars from Follower1
    Get Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Added Cars From Follower2
    [Documentation]    Get added cars from Follower2
    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_ENTRIES}

Get People Leader And Followers
    [Documentation]    Find leader and followers in the people shard
    ${CURRENT_PEOPLE_LEADER}    Get Leader And Verify    ${SHARD_PEOPLE_NAME}
    Set Suite Variable    ${CURRENT_PEOPLE_LEADER}
    ${PEOPLE_FOLLOWERS}    Get All Followers    ${SHARD_PEOPLE_NAME}
    Set Suite Variable    ${PEOPLE_FOLLOWERS}

Add People And Get People From Leader
    [Documentation]    Add some people and get people from Leader.
    Add People And Verify    ${CURRENT_PEOPLE_LEADER}    ${NUM_ENTRIES}

Get Added People From Follower1
    [Documentation]    Get added people from Follower1
    Get People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Added People From Follower2
    [Documentation]    Get added people from Follower2
    Get People And Verify    @{PEOPLE_FOLLOWERS}[1]    ${NUM_ENTRIES}

Get Car-Person Leader And Followers
    [Documentation]    Find leader and followers in the car-person shard
    ${CURRENT_CAR_PERSON_LEADER}    Get Leader And Verify    ${SHARD_CAR_PERSON_NAME}
    Set Suite Variable    ${CURRENT_CAR_PERSON_LEADER}
    ${CAR_PERSON_FOLLOWERS}    Get All Followers    ${SHARD_CAR_PERSON_NAME}
    Set Suite Variable    ${CAR_PERSON_FOLLOWERS}

Add Car-Person Mapping And Get Car-Person Mapping From Leader
    [Documentation]    Initialize car-person shard
    Add Car Person And Verify    ${CURRENT_CAR_PERSON_LEADER}

Purchase Cars On Leader
    [Documentation]    Purchase some cars on the Leader
    ${NUM_BUY_CARS_ON_LEADER}    Evaluate    ${NUM_ENTRIES}/3
    ${NUM_BUY_CARS_ON_FOLLOWER1}    Evaluate    ${NUM_ENTRIES}/3
    ${NUM_BUY_CARS_ON_FOLLOWER2}    Evaluate    ${NUM_ENTRIES}-${NUM_BUY_CARS_ON_LEADER}-${NUM_BUY_CARS_ON_FOLLOWER1}
    Set Suite Variable    ${NUM_BUY_CARS_ON_LEADER}
    Set Suite Variable    ${NUM_BUY_CARS_ON_FOLLOWER1}
    Set Suite Variable    ${NUM_BUY_CARS_ON_FOLLOWER2}
    Buy Cars And Verify    ${CURRENT_CAR_PERSON_LEADER}    ${NUM_BUY_CARS_ON_LEADER}

Purchase Cars On Follower1
    [Documentation]    Purchase some cars on Follower1
    Buy Cars And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_BUY_CARS_ON_FOLLOWER1}    ${NUM_BUY_CARS_ON_LEADER}

Purchase Cars On Follower2
    [Documentation]    Purchase some cars on Follower2
    ${start}    Evaluate    ${NUM_BUY_CARS_ON_LEADER}+${NUM_BUY_CARS_ON_FOLLOWER1}
    Buy Cars And Verify    @{CAR_PERSON_FOLLOWERS}[1]    ${NUM_BUY_CARS_ON_FOLLOWER2}    ${start}

Get Car-Person Mappings From Leader
    [Documentation]    Get car-person mappings from Leader to see all entries
    Get Car-Person Mappings And Verify    ${CURRENT_CAR_PERSON_LEADER}    ${NUM_ENTRIES}

Get Car-Person Mappings From Follower1
    [Documentation]    Get car-person mappings from Follower1 to see all entries
    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Car-Person Mappings From Follower2
    [Documentation]    Get car-person mappings from Follower2 to see all entries
    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[1]    ${NUM_ENTRIES}
