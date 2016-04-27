*** Settings ***
Documentation     This test focuses on testing buy-car RPC over 3 Leader reboots.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               All purchases are against the same node, which is the first one to get rebooted.
...
...               All data is deleted at the end of the suite.
...               This suite expects car, people and car-people modules to have separate Shards.
Suite Setup       Setup
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CARPEOPLE_ITEMS}    ${100}
${MEMBER_START_TIMEOUT}    300s
@{SHARD_NAME_LIST}    car    people    car-people
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Cars_To_Leader_And_Verify
    [Documentation]    Add all needed cars to car Leader, verify on each member.
    ${car_items} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} * 4
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${car_items}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${car_items}

Add_People_To_First_Follower_And_Verify
    [Documentation]    Add all needed people to people first Follower, verify on each member.
    ${people_items} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} * 4
    CarPeople.Add_Several_People    session=${people_first_follower_session}    iterations=${people_items}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/people    session=${session}    verify=True    iterations=${people_items}

Buy_Cars_On_Leader_And_Verify
    [Documentation]    Buy some cars on the leader member.
    ${iter_start} =    BuiltIn.Evaluate    0 * ${CARPEOPLE_ITEMS} + 1
    CarPeople.Buy_Several_Cars    session=${car-people_leader_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_iterations} =    BuiltIn.Evaluate    1 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_iterations}

Buy_Cars_On_Follower_And_Verify
    [Documentation]    Buy some cars on the first follower member.
    ${iter_start} =    BuiltIn.Evaluate    1 * ${CARPEOPLE_ITEMS} + 1
    CarPeople.Buy_Several_Cars    session=${car-people_first_follower_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_iterations} =    BuiltIn.Evaluate    2 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_iterations}

Reboot_People_Leader
    [Documentation]    Previous people Leader is rebooted. We should never stop the people first follower, this is where people are registered.
    ClusterManagement.Kill_Single_Member    ${people_leader_index}    confirm=True
    ClusterManagement.Start_Single_Member    ${people_leader_index}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_NAME_LIST}    shard_type=config

Buy_Cars_On_Leader_After_Reboot_And_Verify
    [Documentation]    Buy some cars on the leader member.
    ${iter_start} =    BuiltIn.Evaluate    2 * ${CARPEOPLE_ITEMS} + 1
    CarPeople.Buy_Several_Cars    session=${car-people_leader_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_iterations} =    BuiltIn.Evaluate    3 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_iterations}

Buy_Cars_On_Follower_After_Reboot_And_Verify
    [Documentation]    Buy some cars on the first follower member.
    ${iter_start} =    BuiltIn.Evaluate    3 * ${CARPEOPLE_ITEMS} + 1
    CarPeople.Buy_Several_Cars    session=${car-people_first_follower_session}    iterations=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_iterations} =    BuiltIn.Evaluate    4 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_iterations}

Delete_All_CarPeople
    [Documentation]    DELETE car-people container. No verification beyond http status.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/car-people    session=${car-people_leader_session}

Delete_All_People
    [Documentation]    DELETE people container. No verification beyond http status.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/people    session=${people_leader_session}

Delete_All_Cars
    [Documentation]    DELETE cars container. No verification beyond http status.
    TemplatedRequests.Delete_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize shard leaders, compute item distribution.
    ClusterManagement.ClusterManagement_Setup
    Set_Variables_For_Shard    shard_name=car
    Set_Variables_For_Shard    shard_name=people
    Set_Variables_For_Shard    shard_name=car-people
    ${leader_list} =    BuiltIn.Create_List    ${car-people_leader_index}
    ${reboot_list} =    Collections.Combine_Lists    ${leader_list}    ${car-people_follower_indices}
    BuiltIn.Set_Suite_Variable    \${list_to_reboot}    ${reboot_list}
