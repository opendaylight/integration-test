*** Settings ***
Documentation       Cluster suite for testing minimal and sum-minimal member population behavior.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This test stops majority of the followers and verifies car addition is not possible,
...                 then resumes single follower (first from original list) and checks that addition works.
...                 Then remaining members are brought up.
...                 Leader member is always up and assumed to remain Leading during the whole suite run.
...
...                 TODO: Use initial data to check more operations.
...                 TODO: Perhaps merge with car_failover_crud suite.
...
...                 Other modules and Shards (people, car-people) are not accessed by this suite.
...
...                 All data is deleted at the end of the suite.
...                 This suite expects car module to have a separate Shard.

Library             Collections
Resource            ${CURDIR}/../../../libraries/CarPeople.robot
Resource            ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables           ${CURDIR}/../../../variables/Variables.py

Suite Setup         Setup
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing

Default Tags        clustering    carpeople    critical


*** Variables ***
${CAR_ITEMS}                50
${MINORITY_START_I}         300
${MAJORITY_START_I}         200
${MEMBER_START_TIMEOUT}     300s
@{SHARD_NAME_LIST}          car
${VAR_DIR}                  ${CURDIR}/../../../variables/carpeople/crud
${CLUSTER_DIR}              ${CURDIR}/../../../variables/clustering


*** Test Cases ***
Stop_Majority_Of_The_Followers
    [Documentation]    Stop half plus one car Follower members and set reviving followers down (otherwsise tipping followers cannot join cluster).
    ...    Mark most of stopped members as explicitly down, to allow the surviving leader make progress.
    ClusterManagement.Stop_Members_From_List_Or_All    member_index_list=${list_of_stopping}    confirm=True
    FOR    ${index}    IN    @{list_of_reviving}

        ${data} =    CompareStream.Set_Variable_If_At_Least_Scandium
        ...    OperatingSystem.Get File    ${CLUSTER_DIR}/member_down_pekko.json
        ...    OperatingSystem.Get File    ${CLUSTER_DIR}/member_down_akka.json
        ${member_ip} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
        ${data} =    String.Replace String    ${data}    {member_ip}    ${member_ip}
        TemplatedRequests.Post_To_Uri
        ...    uri=jolokia
        ...    data=${data}
        ...    content_type=${HEADERS}
        ...    accept=${ACCEPT_EMPTY}
        ...    session=${car_leader_session}
    END

Attempt_To_Add_Cars_To_Leader
    [Documentation]    Adding cars should fail, as majority of Followers are down.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    TemplatedRequests.Put_As_Json_Templated
    ...    folder=${VAR_DIR}/cars
    ...    session=${car_leader_session}
    ...    iterations=${CAR_ITEMS}
    ...    iter_start=${MINORITY_START_I}
    # TODO: Is there a specific status and mesage to require in this scenario?
    # Previously it was 500, now the restconf call simply times out.
    BuiltIn.Log    ${message}
    BuiltIn.Should_Be_Equal    ${status}    FAIL

Start_Tipping_Follower
    [Documentation]    Start one Follower member without persisted data.
    ClusterManagement.Start_Members_From_List_Or_All
    ...    member_index_list=${list_of_tipping}
    ...    wait_for_sync=True
    ...    timeout=${MEMBER_START_TIMEOUT}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    30s
    ...    2s
    ...    ClusterManagement.Verify_Leader_Exists_For_Each_Shard
    ...    shard_name_list=${SHARD_NAME_LIST}
    ...    shard_type=config
    ...    member_index_list=${list_of_majority}

Add_Cars_On_Tipping_Follower
    [Documentation]    Add cars on the tipping Follower.
    TemplatedRequests.Put_As_Json_Templated
    ...    folder=${VAR_DIR}/cars
    ...    session=${car_first_follower_session}
    ...    iterations=${CAR_ITEMS}
    ...    iter_start=${MAJORITY_START_I}

See_Cars_On_Existing_Members
    [Documentation]    On each up member: GET cars, should match the ones added on tipping Follower.
    FOR    ${session}    IN    @{list_of_majority}
        TemplatedRequests.Get_As_Json_Templated
        ...    folder=${VAR_DIR}/cars
        ...    session=${session}
        ...    verify=True
        ...    iterations=${CAR_ITEMS}
        ...    iter_start=${MAJORITY_START_I}
    END

Start_Other_Followers
    [Documentation]    Start other followers without persisted data.
    ClusterManagement.Start_Members_From_List_Or_All
    ...    member_index_list=${list_of_reviving}
    ...    wait_for_sync=True
    ...    timeout=${MEMBER_START_TIMEOUT}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    30s
    ...    2s
    ...    ClusterManagement.Verify_Leader_Exists_For_Each_Shard
    ...    shard_name_list=${SHARD_NAME_LIST}
    ...    shard_type=config

See_Cars_On_New_Follower_Leader
    [Documentation]    GET cars from a new follower to see that the current state was replicated.
    TemplatedRequests.Get_As_Json_Templated
    ...    folder=${VAR_DIR}/cars
    ...    session=${car_last_follower_session}
    ...    verify=True
    ...    iterations=${CAR_ITEMS}
    ...    iter_start=${MAJORITY_START_I}

Delete_Cars_On_Leader
    [Documentation]    Delete cars on Leader.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}


*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, pre-compute member lists.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=5
    CarPeople.Set_Variables_For_Shard    shard_name=car
    Set_Additional_Variables

Set_Additional_Variables
    [Documentation]    Compute various lists useful for test cases in this suite.
    # TODO: Migrate this Keyword to CarPeople Resource if more suites want that.
    ${last_follower_session} =    Collections.Get_From_List    ${car_follower_sessions}    -1
    BuiltIn.Set_Suite_Variable    \${car_last_follower_session}    ${last_follower_session}
    ${number_followers} =    BuiltIn.Get_Length    ${car_follower_indices}
    ${half_followers} =    BuiltIn.Evaluate    ${number_followers} / 2
    ${majority_follower_list} =    Collections.Get_Slice_From_List    ${car_follower_indices}    0    ${half_followers}
    ${leader_list} =    BuiltIn.Create_List    ${car_leader_index}
    ${majority_list} =    Collections.Combine_Lists    ${leader_list}    ${majority_follower_list}
    BuiltIn.Set_Suite_Variable    \${list_of_majority}    ${majority_list}
    ${tipping_list} =    Collections.Get_Slice_From_List    ${majority_follower_list}    0    1
    BuiltIn.Set_Suite_Variable    \${list_of_tipping}    ${tipping_list}
    ${revive_list} =    Collections.Get_Slice_From_List
    ...    ${car_follower_indices}
    ...    ${half_followers}
    ...    ${number_followers}
    BuiltIn.Set_Suite_Variable    \${list_of_reviving}    ${revive_list}
    ${stop_list} =    Collections.Combine_Lists    ${tipping_list}    ${revive_list}
    BuiltIn.Set_Suite_Variable    \${list_of_stopping}    ${stop_list}
