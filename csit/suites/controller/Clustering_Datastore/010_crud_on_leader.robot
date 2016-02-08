*** Settings ***
Documentation     This test finds the leader for shards in a 3-Node cluster and executes CRUD operations on them
Default Tags      3-node-cluster    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CARPEOPLE_ITEMS}    ${30}
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople

*** Test Cases ***
Add_Cars_To_Leader
    [Documentation]    Add ${CARPEOPLE_ITEMS} cars to ${car_leader_session}.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CARPEOPLE_ITEMS}

See_Added_Cars_On_Leader
    [Documentation]    GET response should match the PUT data on Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}

See_Added_Cars_On_Followers
    [Documentation]    The same check on other peers.
    : FOR    ${session}    IN    @{car_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}

Add_People_To_Leader
    [Documentation]    Add ${CARPEOPLE_ITEMS} people to ${people_leader_session}.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/people    session=${people_leader_session}    iterations=${CARPEOPLE_ITEMS}

See_Added_People_On_Leader
    [Documentation]    GET response should match the PUT data on Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/people    session=${people_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}

See_Added_People_On_Followers
    [Documentation]    The same check on other peers.
    : FOR    ${session}    IN    @{people_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/people    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}

Purchase_Cars_On_Leader
    [Documentation]    Purchase some cars on the Leader.
    # Cars are numbered, leader gets chunk at the end, as that is few keyspresses shorter.
    ${start_id} =    BuiltIn.Evaluate    (${NUM_ODL_SYSTEM} - 1) * ${items_per_follower} + 1
    Purchase_Several_Cars    session=${car-people_leader_session}    amount=${items_per_leader}

Purchase_Cars_On_Followers
    [Documentation]    Purchase some cars on Followers.
    : FOR    ${session}    IN    @{car-people_follower_sessions}
    \    Purchase_Several_Cars    session=${session}    amount=${items_per_follower}

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

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    Set_Variables_For_Shard    shard_name=car
    Set_Variables_For_Shard    shard_name=people
    Set_Variables_For_Shard    shard_name=car-people
    # TODO: Avoid dash in variable names.
    ${follower_number} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} / ${NUM_ODL_SYSTEM}
    BuiltIn.Set_Suite_Variable    ${items_per_follower}    ${follower_number}
    ${leader_number} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} - (${NUM_ODL_SYSTEM} - 1) * ${folloer_number}
    BuiltIn.Set_Suite_Variable    ${items_per_leader}    ${leader_number}

Set_Variables_For_Shard
    [Arguments]    ${shard_name}
    [Documentation]    Get leader and followers, set suite variables.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=config
    # BuiltIn.Set_Suite_Variable    \${${shard_name}_leader}    ${leader}
    # BuiltIn.Set_Suite_Variable    \${${shard_name}_followers}    ${follower_list}
    ${leader_session} =    ClusterManagement.Get_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list
    \    ${follower_session} =    ClusterManagement.Get_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${session}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_sessions}    ${sessions}

Purchase_Several_Cars
    [Arguments]    ${session}    ${amount}
    [Documentation]    Simple loop for purchasing one by one.
    ...    Needs to be a separate keyword, as Robot does not support nested FORs.
    : FOR    ${i}    IN RANGE    ${amount}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/purchase-car    session=${session}
