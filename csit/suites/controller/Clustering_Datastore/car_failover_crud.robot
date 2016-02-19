*** Settings ***
Documentation     This test brings down the current leader of the "car" shard and then executes CRUD
...               operations on the new leader.
...               This suite uses 3 different car sets, same size but different starting Id.
...               TODO: Improve Test Case Documentation.
Suite Setup       Setup
Default Tags      3-node-cluster    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CARPEOPLE_ITEMS}    ${30}
${FOLLOWER_2NODE_START_I}    300
${LEADER_2NODE_START_I}    200
${MEMBER_START_TIMEOUT}    300s
#${MEMBER_KILL_TIMEOUT}    1s
${ORIGINAL_START_I}    100
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Original_Cars_On_Old_Leader
    [Documentation]    Add new cars in Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${ORIGINAL_START_I}

Kill_Original_Car_Leader
    [Documentation]    Kill the leader to cause a new leader to be elected.
    ${kill_list} =    BuiltIn.Create_List    ${original_leader_index}
    ClusterManagement.Kill_Members_From_List_Or_All    member_index_list=${kill_list}    confirm=True
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All    member_index_list=${kill_list}

Locate_New_Leader
    [Documentation]    Wait until lew car leader gets elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    Set_Variables_For_2nodes    shard_name=car    member_index_list=${original_follower_indices}

See_Original_Cars_On_New_Leader
    [Documentation]    Get cars in new Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${ORIGINAL_START_I}

See_Original_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${ORIGINAL_START_I}

Delete_Original_Cars_On_New_Leader
    [Documentation]    Delete cars in new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}

Add_Leader_Cars_On_New_Leader
    [Documentation]    Add cars on the new Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${LEADER_2NODE_START_I}

See_Leader_Cars_On_New_Leader
    [Documentation]    Get cars in new Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${LEADER_2NODE_START_I}

See_Leader_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${LEADER_2NODE_START_I}

Delete_Leader_Cars_On_New_First_Follower
    [Documentation]    Delete cars in new first Follower.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_first_follower_session}

Add_Follower_Cars_On_New_First_Follower
    [Documentation]    Add cars on the new first Follower.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_first_follower_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

See_Folower_Cars_On_New_Leader
    [Documentation]    Get cars in new Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

See_Follower_Cars_On_New_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{new_follower_sessions}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

Clean_And_Start_Old_Car_Leader
    [Documentation]    Start old car Leader.
    ${revive_list} =    BuiltIn.Create_List    ${original_leader_index}
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All    member_index_list=${revive_list}
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${revive_list}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

See_Folower_Cars_On_Old_Leader
    [Documentation]    Get cars in old Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CARPEOPLE_ITEMS}    iter_start=${FOLLOWER_2NODE_START_I}

Delete_Follower_Cars_On_New_Leader
    [Documentation]    Delete cars in new Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${new_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    Set_Variables_For_Shard    shard_name=car

Set_Variables_For_Shard
    [Arguments]    ${shard_name}
    [Documentation]    Get leader and followers, set suite variables.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=config
    BuiltIn.Set_Suite_Variable    ${original_leader_index}    ${leader}
    BuiltIn.Set_Suite_Variable    ${original_follower_indices}    ${follower_list}
    ${leader_session} =    ClusterManagement.Find_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Find_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${${shard_name}_first_follower_session}    ${first_follower_session}

Set_Variables_For_2nodes
    [Arguments]    ${shard_name}    ${member_index_list}
    [Documentation]    Get leader and follower, set additional suite variables.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=config    member_index_list=${member_index_list}
    ${leader_session} =    ClusterManagement.Find_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${new_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Find_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${new_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${new_first_follower_session}    ${first_follower_session}

Purchase_Several_Cars
    [Arguments]    ${session}    ${amount}    ${iter_start}=1
    [Documentation]    Simple loop for purchasing one by one.
    ...    Needs to be a separate keyword, as Robot does not support nested FORs.
    : FOR    ${i}    IN RANGE    ${iter_start}    ${iter_start}+${amount}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/purchase-car    mapping={"i": "${i}"}    session=${session}
