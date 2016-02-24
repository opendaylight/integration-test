*** Settings ***
Documentation     This test kills majority of the followers and verifies car addition is not possible,
...               then resumes a follower (first from original list), addition works.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               TODO: Use initial data to check more operations.
...               TODO: Improve Test Case Documentation.
Suite Setup       Setup
Default Tags      3-node-cluster    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
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

Add_Cars_On_Tipping_Follower
    [Documentation]    Add cars on the tipping Follower.
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_first_follower_session}    iterations=${CAR_ITEMS}    iter_start=${MAJORITY_START_I}

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
    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_last_follower_session}    verify=True    iterations=${CAR_ITEMS}    iter_start=${MAJORITY_START_I}

Delete_Cars_On_Leader
    [Documentation]    Delete cars in Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    Set_Variables

Set_Variables
    [Documentation]    Get leader and followers, set suite variables.
    CarPeople.Set_Variables_For_Shard    shard_name=car
    # TODO: Move two following lines to CarPeople if more suites want that.
    ${last_follower_session} =    Collections.Get_From_List    ${car_follower_sessions}    -1
    BuiltIn.Set_Suite_Variable    \${car_last_follower_session}    ${last_follower_session}
    ${number_followers} =    BuiltIn.Get_Length    ${car_follower_indices}
    ${half_followers} =    BuiltIn.Evaluate    ${number_followers} / 2
    ${majority_list} =    Collections.Get_Slice_From_List    ${car_follower_indices}    0    ${half_followers}
    ${tipping_list} =    Collections.Get_Slice_From_List    ${majority_list}    0    1
    ${revive_list} =    Collections.Get_Slice_From_List    ${ca_follower_indices}    ${half_followers}    ${number_followers}
    ${kill_list} =    Collections.Combine_Lists    ${tipping_list}   ${revive_list}
    BuiltIn.Set_Suite_Variable    \${list_of_killing}    ${kill_list}
    BuiltIn.Set_Suite_Variable    \${list_of_reviving}    ${revive_list}
    BuiltIn.Set_Suite_Variable    \${list_of_tipping}    ${tipping_list}
    BuiltIn.Set_Suite_Variable    \${list_of_majority}    ${majority_list}
