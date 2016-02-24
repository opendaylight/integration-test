*** Settings ***
Documentation     This test kills the current leader of the "car" shard and then executes CRUD
...               operations on the new leader and a new follower. The killed member is brought back.
...               This suite uses 3 different car sets, same size but different starting Id.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               TODO: Improve Test Case Documentation.
Suite Setup       Setup
Default Tags      3-node-cluster    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CAR_ITEMS}      30
${FOLLOWER_2NODE_START_I}    300
${LEADER_2NODE_START_I}    200
${MEMBER_START_TIMEOUT}    300s
${ORIGINAL_START_I}    100
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Original_Cars_On_Old_Leader
    [Documentation]    Add new cars in Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}

Kill_Original_Car_Leader
    [Documentation]    Kill the leader to cause a new leader to be elected.
    ${kill_list} =    BuiltIn.Create_List    ${original_leader_index}
    ClusterManagement.Kill_Members_From_List_Or_All    member_index_list=${kill_list}    confirm=True

Locate_New_Leader
    [Documentation]    Wait until lew car leader gets elected.
    # BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    
    Set_Variables_For_2nodes    shard_name=car    member_index_list=${original_follower_indices}

See_Original_Cars_On_New_Leader
    [Documentation]    Get cars in new Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}

See_Original_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${ORIGINAL_START_I}

Delete_Original_Cars_On_New_Leader
    [Documentation]    Delete cars in new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}

Add_Leader_Cars_On_New_Leader
    [Documentation]    Add cars on the new Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    iterations=${CAR_ITEMS}    iter_start=${LEADER_2NODE_START_I}

See_Leader_Cars_On_New_Leader
    [Documentation]    Get cars in new Leader.
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
    [Documentation]    Get cars in new Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

See_Follower_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

Start_Old_Car_Leader
    [Documentation]    Start old car Leader without deleting persisted data.
    ${revive_list} =    BuiltIn.Create_List    ${original_leader_index}
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${revive_list}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

See_Folower_Cars_On_Old_Leader
    [Documentation]    Get cars in old Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

Delete_Follower_Cars_On_New_Leader
    [Documentation]    Delete cars in new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    CarPeople.Set_Variables_For_Shard    shard_name=car

Set_Variables_For_2nodes
    [Arguments]    ${shard_name}    ${member_index_list}
    [Documentation]    Get leader and follower, set additional suite variables.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=config    member_index_list=${member_index_list}
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${new_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${new_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${new_first_follower_session}    ${first_follower_session}
