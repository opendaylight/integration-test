*** Settings ***
Documentation     This test kills majority of the followers and verifies CRUD is not possible,
...               then resumes a follower, CRUD works.
...               TODO: Use initial data to check more operations.
...               TODO: Improve Test Case Documentation.
Suite Setup       Setup
Default Tags      3-node-cluster    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CAR_ITEMS}      50
${MINORITY_START_I}    300
${MAJORITY_START_I}    200
${MEMBER_START_TIMEOUT}    300s
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Kill_Majority_Of_The_Followers
    [Documentation]    Stop half plus one car followers.
    ClusterManagement.Kill_Members_From_List_Or_All    member_index_list=${list_of_killing}    confirm=True

Attempt_To_Add_Cars_To_Leader
    [Documentation]    Add car should fail as majority of followers are down.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CAR_ITEMS}    iter_start=${MINORITY_START_I}
    BuiltIn.Should_Contain    ${message}    '50

Clean_And_Start_Tipping_Follower
    [Documentation]    Start one follower.
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All    member_index_list=${list_of_tipping}
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${list_of_tipping}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

Add_Cars_On_Leader
    [Documentation]    Add cars on Leader.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${CAR_ITEMS}    iter_start=${MAJORITY_START_I}

See_Cars_On_Leader
    [Documentation]    Get cars from Leader.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${MAJORITY_START_I}

See_Cars_On_Existing_Followers
    [Documentation]    The same check on other existing members.
    : FOR    ${session}    IN    @{list_of_majority}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${MAJORITY_START_I}

Clean_And_Start_Other_Followers
    [Documentation]    Start other followers.
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${list_of_reviving}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

See_Cars_On_New_Follower_Leader
    [Documentation]    Get cars in new follower.
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_first_follower_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${MAJORITY_START_I}

Delete_Cars_On_Leader
    [Documentation]    Delete cars in Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}

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
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${${shard_name}_first_follower_session}    ${first_follower_session}
    ${number_followers} =    BuiltIn.Get_Length    ${follower_list}
    ${half_followers} =    BuiltIn.Evaluate    ${number_followers} / 2
    ${majority_list} =    Collections.Get_Slice_From_List    ${original_follower_indices}    0    ${half_followers}
    ${tipping_list} =    Collections.Get_Slice_From_List    ${majority_list}    0    1
    ${revive_list} =    Collections.Get_Slice_From_List    ${original_follower_indices}    ${half_followers}    ${half_followers}
    ${kill_list} =    Collections.Combine_Lists    ${tipping_list}   ${revive_list}
    BuiltIn.Set_Suite_Variable    \${list_of_killing}    ${kill_list}
    BuiltIn.Set_Suite_Variable    \${list_of_reviving}    ${revive_list}
    BuiltIn.Set_Suite_Variable    \${list_of_tipping}    ${tipping_list}
    BuiltIn.Set_Suite_Variable    \${list_of_majority}    ${majority_list}
