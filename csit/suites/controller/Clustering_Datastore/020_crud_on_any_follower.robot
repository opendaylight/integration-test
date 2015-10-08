*** Settings ***
Documentation     This test finds the followers of certain shards in a 3-Node cluster and executes CRUD operations on any one follower
Default Tags      3-node-cluster
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/CarsAndPeople.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${NUM_ENTRIES}    ${40}

*** Test Cases ***
Get Car Followers
    [Documentation]    Find followers in the car shard
    ${CAR_FOLLOWERS}    Get All Followers    ${SHARD_CAR_NAME}
    Set Suite Variable    ${CAR_FOLLOWERS}

Get People Followers
    [Documentation]    Find followers in the people shard
    ${PEOPLE_FOLLOWERS}    Get All Followers    ${SHARD_PEOPLE_NAME}
    Set Suite Variable    ${PEOPLE_FOLLOWERS}

Get Car-Person Followers
    ${CAR_PERSON_FOLLOWERS}    Get All Followers    ${SHARD_CAR_PERSON_NAME}
    Set Suite Variable    ${CAR_PERSON_FOLLOWERS}

Delete Cars From Follower1
    Delete All Cars And Verify    @{CAR_FOLLOWERS}[0]

Delete People From Follower1
    Delete All People And Verify    @{PEOPLE_FOLLOWERS}[0]

Delete Car-Persons from Follower1
    Delete All Cars-Persons And Verify    @{CAR_PERSON_FOLLOWERS}[0]

Add Cars And Get Cars From Follower1
    [Documentation]    Add cars and get added cars from Follower1
    Add Cars And Verify    @{CAR_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Added Cars From Follower2
    [Documentation]    Get added cars from Follower2
    Get Cars And Verify    @{CAR_FOLLOWERS}[1]    ${NUM_ENTRIES}

Add People And Get People From Follower1
    [Documentation]    Add people and get people from Follower1
    Add People And Verify    @{PEOPLE_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Added People From Follower2
    [Documentation]    Get added people from Follower2
    Get People And Verify    @{PEOPLE_FOLLOWERS}[1]    ${NUM_ENTRIES}

Add Car-Person Mapping And Get Car-Person Mapping From Follower1
    Add Car Person And Verify    @{CAR_PERSON_FOLLOWERS}[0]

Purchase Cars On Follower1
    [Documentation]    Purchase cars using Follower1
    Buy Cars And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Car-Person Mappings From Follower1
    [Documentation]    Get car-person mappings from Follower1 to see all entries
    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[0]    ${NUM_ENTRIES}

Get Car-Person Mappings From Leader
    [Documentation]    Get car-person mappings from the Leader to see all entries
    ${CURRENT_CAR_LEADER}    Get Leader And Verify    ${SHARD_CAR_PERSON_NAME}
    Get Car-Person Mappings And Verify    ${CURRENT_CAR_LEADER}    ${NUM_ENTRIES}

Get Car-Person Mappings From Follower2
    [Documentation]    Get car-person mappings from Follower2 to see all entries
    Get Car-Person Mappings And Verify    @{CAR_PERSON_FOLLOWERS}[1]    ${NUM_ENTRIES}
