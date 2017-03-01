*** Settings ***
Documentation     Suite mixing basic operations with isolation of car Leader.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This test isolates the current leader of the "car" shard and then executes CRD
...               operations on the new leader and a new follower. The isolated member is brought back.
...               This suite uses 3 different car sets, same size but different starting ID.
...
...               Other models and shards (people, car-people) are not accessed by this suite.
...
...               All data is deleted at the end of the suite.
...               This suite expects car module to have a separate Shard.
Suite Setup       Setup
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CAR_ITEMS}      30
${FOLLOWER_2NODE_START_I}    300
${LEADER_2NODE_START_I}    200
${MEMBER_START_TIMEOUT}    300s
${ORIGINAL_START_I}    100
${SHARD_TYPE}     config
${SHARD_NAME}     car
@{SHARD_NAME_LIST}    ${SHARD_NAME}
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Original_Cars_On_Old_Leader_And_Verify
    [Documentation]    Add initial cars on car Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}

Isolate_Original_Car_Leader
    [Documentation]    Isolate the car Leader to cause a new leader to get elected.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${car_leader_index}

Wait_For_New_Leader
    [Documentation]    Wait until new car Leader is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Shard_Leader_Elected    ${SHARD_NAME}    ${SHARD_TYPE}    ${True}
    ...    ${car_leader_index}    member_index_list=${car_follower_indices}
    CarPeople.Set_Tmp_Variables_For_Shard_For_Nodes    member_index_list=${car_follower_indices}    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}

See_Original_Cars_On_New_Leader
    [Documentation]    GET cars from new Leader, should be the initial ones.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}

See_Original_Cars_On_New_Followers
    [Documentation]    The same check on other existing member(s).
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}

Delete_Original_Cars_On_New_Leader
    [Documentation]    Delete cars on the new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}

Add_Leader_Cars_On_New_Leader
    [Documentation]    Add cars on the new Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    iterations=${CAR_ITEMS}    iter_start=${LEADER_2NODE_START_I}

See_Leader_Cars_On_New_Leader
    [Documentation]    GET cars from new Leader, should be the new ones.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${LEADER_2NODE_START_I}

See_Leader_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${LEADER_2NODE_START_I}

Delete_Leader_Cars_On_New_First_Follower
    [Documentation]    Delete cars in new first Follower.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_first_follower_session}

Add_Follower_Cars_On_New_First_Follower
    [Documentation]    Add cars on the new first Follower.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_first_follower_session}    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

See_Folower_Cars_On_New_Leader
    [Documentation]    Get cars from the new Leader, should be the ones added on follower.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

See_Follower_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

Rejoin_Old_Car_Leader
    [Documentation]    Rejoin the isolated member without deleting the persisted data.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${car_leader_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_NAME_LIST}    shard_type=config

See_Folower_Cars_On_Old_Leader
    [Documentation]    GET cars from the restarted member, should be the ones added on follower.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

Delete_Follower_Cars_On_New_Leader
    [Documentation]    Delete cars on the last Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize car shard leader and followers.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    CarPeople.Set_Variables_For_Shard    shard_name=car
