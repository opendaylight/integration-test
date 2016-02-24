*** Settings ***
Documentation     This test focuses on testing buy-car RPC over 3 Leader reboots.
...               All purchases are against the same node, which is the first one to get rebooted.
Suite Setup       Setup
Default Tags      3-node-cluster    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${CARPEOPLE_ITEMS}    ${100}
${MEMBER_START_TIMEOUT}    300s
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Test Cases ***
Add_Cars_To_Leader_And_Verify
    [Documentation]    Add all needed cars to car_leader_session, verify on each member.
    ${car_items} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} * 4
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/cars    session=${car_leader_session}    iterations=${car_items}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/cars    session=${session}    verify=True    iterations=${car_items}

Add_People_To_Leader_And_Verify
    [Documentation]    Add all needed people to people_leader_session, verify on each member.
    ${people_items} =    BuiltIn.Evaluate    ${CARPEOPLE_ITEMS} * 4
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/people    session=${people_leader_session}    iterations=${people_items}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/people    session=${session}    verify=True    iterations=${people_items}

Purchase_Cars_After_0_Reboots_And_Verify
    [Documentation]    Purchase some cars on the test member.
    ${iter_start} =    BuiltIn.Evaluate    0 * ${CARPEOPLE_ITEMS} + 1
    Purchase_Several_Cars    session=${car-people_leader_session}    amount=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_amount} =    BuiltIn.Evaluate    1 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_amount}

Reboot_1
    [Documentation]    Previous car-people Leader is rebooted (without persistence cleanup).
    ${index_to_reboot} =    Collections.Remove_From_List    ${list_to_reboot}    0
    ${index_list} =    BuiltIn.Create_List    ${index_to_reboot}
    ClusterManagement.Kill_Members_From_List_Or_All    member_index_list=${index_list}    confirm=True
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${index_list}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

Purchase_Cars_After_1_Reboots_And_Verify
    [Documentation]    Purchase some cars on the test member.
    ${iter_start} =    BuiltIn.Evaluate    1 * ${CARPEOPLE_ITEMS} + 1
    Purchase_Several_Cars    session=${car-people_leader_session}    amount=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_amount} =    BuiltIn.Evaluate    2 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_amount}

Reboot_2
    [Documentation]    Previous car-people Leader is rebooted (without persistence cleanup).
    ${index_to_reboot} =    Collections.Remove_From_List    ${list_to_reboot}    0
    ${index_list} =    BuiltIn.Create_List    ${index_to_reboot}
    ClusterManagement.Kill_Members_From_List_Or_All    member_index_list=${index_list}    confirm=True
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${index_list}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

Purchase_Cars_After_2_Reboots_And_Verify
    [Documentation]    Purchase some cars on the test member.
    ${iter_start} =    BuiltIn.Evaluate    2 * ${CARPEOPLE_ITEMS} + 1
    Purchase_Several_Cars    session=${car-people_leader_session}    amount=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_amount} =    BuiltIn.Evaluate    3 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_amount}

Reboot_3
    [Documentation]    Previous car-people Leader is rebooted (without persistence cleanup).
    ${index_to_reboot} =    Collections.Remove_From_List    ${list_to_reboot}    0
    ${index_list} =    BuiltIn.Create_List    ${index_to_reboot}
    ClusterManagement.Kill_Members_From_List_Or_All    member_index_list=${index_list}    confirm=True
    ClusterManagement.Start_Members_From_List_Or_All    member_index_list=${index_list}    wait_for_sync=True    timeout=${MEMBER_START_TIMEOUT}

Purchase_Cars_After_1_Reboots_And_Verify
    [Documentation]    Purchase some cars on the test member.
    ${iter_start} =    BuiltIn.Evaluate    3 * ${CARPEOPLE_ITEMS} + 1
    Purchase_Several_Cars    session=${car-people_leader_session}    amount=${CARPEOPLE_ITEMS}    iter_start=${iter_start}
    ${total_amount} =    BuiltIn.Evaluate    4 * ${CARPEOPLE_ITEMS}
    : FOR    ${session}    IN    @{ClusterManagement__session_list}
    \    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/car-people    session=${session}    verify=True    iterations=${total_amount}

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
    # TODO: Avoid dash in variable names.
    ${leader}    ${follower_list} =    Set_Variables_For_Shard    shard_name=car-people
    ${leader_list} =    BuiltIn.Create_List    ${leader}
    ${reboot_list} =    Collections.Combine_Lists    ${leader_list}    ${follower_list}
    BuiltIn.Set_Suite_Variable    \${list_to_reboot}    ${reboot_list}

Set_Variables_For_Shard
    [Arguments]    ${shard_name}
    [Documentation]    Get leader and followers, set suite variables.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=config
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_sessions}    ${sessions}
    [Return]    ${leader}    ${follower_list}

Purchase_Several_Cars
    [Arguments]    ${session}    ${amount}    ${iter_start}=1
    [Documentation]    Simple loop for purchasing one by one.
    ...    Needs to be a separate keyword, as Robot does not support nested FORs.
    : FOR    ${i}    IN RANGE    ${iter_start}    ${iter_start}+${amount}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/purchase-car    mapping={"i": "${i}"}    session=${session}
