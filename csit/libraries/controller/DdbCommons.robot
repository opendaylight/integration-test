*** Settings ***
Documentation     DOMDataBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/../MdsalLowlevelPy.py
Resource          ${CURDIR}/../ClusterAdmin.robot
Resource          ${CURDIR}/../ClusterManagement.robot
Resource          ${CURDIR}/../MdsalLowlevel.robot
Resource          ${CURDIR}/../TemplatedRequests.robot
Resource          ${CURDIR}/../WaitForFailure.robot

*** Variables ***
${SHARD_NAME}     default
${SHARD_TYPE}     config
${TRANSACTION_RATE_1K}    ${1000}
${DURATION_30S}    ${30}
${DURATION_10S}    ${10}
${ID_PREFIX}      prefix-
${TRANSACTION_TIMEOUT}    ${30}
${TRANSACTION_TIMEOUT_2X}    ${2*${TRANSACTION_TIMEOUT}}
${SIMPLE_TX}      ${False}
${CHAINED_TX}     ${True}
${HARD_TIMEOUT}    ${60}
@{TRANSACTION_FAILED}    ${500}
${PREF_BASED_SHARD}     tested-shard

*** Keywords ***
Explicit_Leader_Movement_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements explicit leader movement test scenario.
    ${idx_from}    ${idx_to}    ${idx_trans} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}    ${shard_name}    ${shard_type}
    ${ip_trans_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${idx_trans}_IP}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${ip_trans_as_list}    ${ID_PREFIX}    ${DURATION_30S}    ${TRANSACTION_RATE_1K}    chained_flag=${False}
    ClusterAdmin.Make_Leader_Local    ${idx_to}    ${shard_name}    ${shard_type}
    ${new_leader}    ${new_followers} =    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}
    ...    ${shard_type}    ${True}    ${idx_from}
    BuiltIn.Should_Be_Equal    ${idx_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    TemplatedRequests.Check_Status_Code    @{resp_list}[0]

Explicit_Leader_Movement_PrefBasedShard_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements explicit leader movement test scenario.
    ${idx_from}    ${idx_to}    ${idx_trans} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}
    ${ip_trans_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${idx_trans}_IP}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${ip_trans_as_list}    ${ID_PREFIX}    ${DURATION_30S}    ${TRANSACTION_RATE_1K}    chained_flag=${False}
    ClusterAdmin.Make_Leader_Local    ${idx_to}    ${shard_name}    ${shard_type}
    ${new_leader}    ${new_followers} =    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}
    ...    ${shard_type}    ${True}    ${idx_from}
    BuiltIn.Should_Be_Equal    ${idx_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    TemplatedRequests.Check_Status_Code    @{resp_list}[0]

Get_Node_Indexes_For_The_ELM_Test
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}    ${shard_type}
    [Documentation]    Return indexes for explicit leader movement test case, indexes of present to next leader node and index where transaction
    ...    producer should be deployed.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}
    ${idx_from} =    BuiltIn.Set_Variable    ${leader}
    ${idx_to} =    BuiltIn.Set_Variable    @{follower_list}[0]
    ${idx_trans} =    BuiltIn.Set_Variable_If    "${leader_from}" == "remote" and "${leader_to}" == "remote"    @{follower_list}[1]    "${leader_from}" == "local"    ${leader}    "${leader_to}" == "local"
    ...    @{follower_list}[0]
    BuiltIn.Return_From_Keyword    ${idx_from}    ${idx_to}    ${idx_trans}

Clean_Leader_Shutdown_Test_Templ
    [Arguments]    ${leader_location}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements clean leader shutdown test scenario.
    ${removed} =    BuiltIn.Set_Variable    ${False}
    ${producer_idx}    ${actual_leader} =    Get_Node_Indexes_For_Clean_Leader_Shutdown_Test    ${leader_location}    ${shard_name}    ${shard_type}
    ${producer_ip_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${producer_idx}_IP}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${producer_ip_as_list}    ${ID_PREFIX}    ${DURATION_30S}    ${TRANSACTION_RATE_1K}    chained_flag=${False}
    ClusterAdmin.Remove_Shard_Replica    ${actual_leader}    ${shard_name}    member-${actual_leader}    ${shard_type}
    ${removed} =    BuiltIn.Set_Variable    ${True}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    TemplatedRequests.Check_Status_Code    @{resp_list}[0]
    [Teardown]    ClusterAdmin.Add_Shard_Replica    ${actual_leader}    ${shard_name}    ${shard_type}

Clean_Leader_Shutdown_PrefBasedShard_Test_Templ
    [Arguments]    ${leader_location}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements clean leader shutdown test scenario.
    ${removed} =    BuiltIn.Set_Variable    ${False}
    ${producer_idx}    ${actual_leader} =    Get_Node_Indexes_For_Clean_Leader_Shutdown_Test    ${leader_location}    ${shard_name}    ${shard_type}
    ${producer_ip_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${producer_idx}_IP}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${producer_ip_as_list}    ${ID_PREFIX}    ${DURATION_30S}    ${TRANSACTION_RATE_1K}    chained_flag=${False}
    ClusterAdmin.Remove_Shard_Replica    ${actual_leader}    ${shard_name}    member-${actual_leader}    ${shard_type}
    ${removed} =    BuiltIn.Set_Variable    ${True}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    TemplatedRequests.Check_Status_Code    @{resp_list}[0]
    [Teardown]    ClusterAdmin.Add_Shard_Replica    ${actual_leader}    ${shard_name}    ${shard_type}

Get_Node_Indexes_For_Clean_Leader_Shutdown_Test
    [Arguments]    ${leader_location}    ${shard_name}    ${shard_type}
    [Documentation]    Return indexes for clean leader shudown test case, index where transaction producer shoudl be deployed and a shard leader index.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}
    ${follower_list_leangth} =    BuiltIn.Evaluate    ${NUM_ODL_SYSTEM}-1
    BuiltIn.Length_Should_Be    ${follower_list}    ${follower_list_leangth}
    ${producer_idx} =    BuiltIn.Set_Variable_If    "${leader_location}" == "local"    ${leader}    @{follower_list}[0]
    BuiltIn.Return_From_Keyword    ${producer_idx}    ${leader}

Leader_Isolation_Test_Templ
    [Arguments]    ${heal_timeout}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements leader isolation test scenario.
    ${producing_transactions_time} =    BuiltIn.Set_Variable    ${${heal_timeout}+60}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${all_ip_list}    ${ID_PREFIX}    ${producing_transactions_time}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ${date_start} =    DateTime.Get_Current_Date
    ${date_end} =    DateTime.Add_Time_To_Date    ${date_start}    ${producing_transactions_time}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${leader}
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    2s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}    ${shard_type}    ${True}
    ...    ${leader}    member_index_list=${follower_list}
    BuiltIn.Sleep    ${heal_timeout}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${leader}
    BuiltIn.Wait_Until_Keyword_Succeeds    20s    2s    ClusterManagement.Get_Leader_And_Followers_For_Shard    ${shard_name}    ${shard_type}
    ${time_to_finish} =    Get_Seconds_To_Time    ${date_end}
    BuiltIn.Run_Keyword_If    ${heal_timeout} < ${TRANSACTION_TIMEOUT}    Leader_Isolation_Heal_Within_Tt
    ...    ELSE    Module_Leader_Isolation_Heal_Default    ${time_to_finish}

Leader_Isolation_PrefBasedShard_Test_Templ
    [Arguments]    ${heal_timeout}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements leader isolation test scenario.    
    ${producing_transactions_time} =    BuiltIn.Set_Variable    ${${heal_timeout}+60}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${all_ip_list}    ${ID_PREFIX}    ${producing_transactions_time}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ${date_start} =    DateTime.Get_Current_Date
    ${date_end} =    DateTime.Add_Time_To_Date    ${date_start}    ${producing_transactions_time}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${leader}
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    2s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}    ${shard_type}    ${True}
    ...    ${leader}    member_index_list=${follower_list}
    BuiltIn.Sleep    ${heal_timeout}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${leader}
    BuiltIn.Wait_Until_Keyword_Succeeds    20s    2s    ClusterManagement.Get_Leader_And_Followers_For_Shard    ${shard_name}    ${shard_type}
    ${time_to_finish} =    Get_Seconds_To_Time    ${date_end}
    BuiltIn.Run_Keyword_If    ${heal_timeout} < ${TRANSACTION_TIMEOUT}    Leader_Isolation_Heal_Within_Tt
    ...    ELSE    Prefix_Leader_Isolation_Heal_Default    ${time_to_finish}

Leader_Isolation_Heal_Within_Tt
    [Documentation]    The leader isolation test case end if the heal happens within transaction timeout. All write transaction
    ...    producers shoudl finish without error.
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    ${resp}

Module_Leader_Isolation_Heal_Default
    [Arguments]    ${isolated_node}    ${time_to_finish}
    [Documentation]    The leader isolation test case end. The transaction producer on isolated node shoudl fail and should be restarted.
    Then all write transaction producers shoudl finish without error.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Log    ${resp}
    ${restart_producer_node}    BuiltIn.Create_List    ${isolated_node}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${restart_producer_node}    ${ID_PREFIX}    ${time_to_finish}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    ${resp}

Prefix_Leader_Isolation_Heal_Default
    [Arguments]    ${isolated_node}    ${time_to_finish}
    [Documentation]    The leader isolation test case end. The transaction producer on isolated node shoudl fail and should be restarted.
    Then all write transaction producers shoudl finish without error.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Log    ${resp}
    ${restart_producer_node}    BuiltIn.Create_List    ${isolated_node}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${restart_producer_node}    ${ID_PREFIX}    ${time_to_finish}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    ${resp}

Client_Isolation_Test_Templ
    [Arguments]    ${listener_node_role}    ${trans_chain_flag}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements client isolation test scenario.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ${client_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    ${client_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${client_node_dst}
    ${client_node_ip_as_list}    BuiltIn.Create_List    ${client_node_ip}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${client_node_ip_as_list}    ${ID_PREFIX}    ${DURATION_30S}    ${TRANSACTION_RATE_1K}    chained_flag=${trans_chain_flag}
    ${start_date}    DateTime.Get_Current_Date
    ${timeout_date} =    DateTime.Add_Time_To_Date    ${start_date}    ${TRANSACTION_TIMEOUT}
    ${abort_date} =    DateTime.Add_Time_To_Date    ${start_date}    ${HARD_TIMEOUT}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${client_node_dst}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${TRANSACTION_TIMEOUT}    1s    Ongoing_Transactions_Not_Failed_Yet
    WaitForFailure.Confirm_Keyword_Fails_Within_Timeout    3s    1s    Ongoing_Transactions_Failed
    ${abort_time}    Get_Seconds_To_Time    ${abort_date}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${abort_time}    1s    Verify_Client_Aborted    ${False}
    WaitForFailure.Confirm_Keyword_Fails_Within_Timeout    3s    1s    Verify_Client_Aborted    ${True}
    [Teardown]    BuiltIn.Run Keywords    ClusterManagement.Rejoin_Member_From_List_Or_All    ${client_node_dst}
    ...    AND    MdsalLowlevelPy.Wait_For_Transactions

Client_Isolation_PrefBasedShard_Test_Templ
    [Arguments]    ${listener_node_role}    ${trans_chain_flag}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements client isolation test scenario.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ${client_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    ${client_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${client_node_dst}
    ${client_node_ip_as_list}    BuiltIn.Create_List    ${client_node_ip}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${client_node_ip_as_list}    ${ID_PREFIX}    ${DURATION_30S}    ${TRANSACTION_RATE_1K}    chained_flag=${trans_chain_flag}
    ${start_date}    DateTime.Get_Current_Date
    ${timeout_date} =    DateTime.Add_Time_To_Date    ${start_date}    ${TRANSACTION_TIMEOUT}
    ${abort_date} =    DateTime.Add_Time_To_Date    ${start_date}    ${HARD_TIMEOUT}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${client_node_dst}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${TRANSACTION_TIMEOUT}    1s    Ongoing_Transactions_Not_Failed_Yet
    WaitForFailure.Confirm_Keyword_Fails_Within_Timeout    3s    1s    Ongoing_Transactions_Failed
    ${abort_time}    Get_Seconds_To_Time    ${abort_date}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${abort_time}    1s    Verify_Client_Aborted    ${False}
    WaitForFailure.Confirm_Keyword_Fails_Within_Timeout    3s    1s    Verify_Client_Aborted    ${True}
    [Teardown]    BuiltIn.Run Keywords    ClusterManagement.Rejoin_Member_From_List_Or_All    ${client_node_dst}
    ...    AND    MdsalLowlevelPy.Wait_For_Transactions

Ongoing_Transactions_Not_Failed_Yet
    [Documentation]    Verify that no write-transaction rpc finished, means they are still running.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Should_Be_Equal    ${None}    ${resp}    ${resp} not expected.

Ongoing_Transactions_Failed
    [Documentation]    Verify if write-transaction failed.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    Check_Status_Code    ${resp}    explicit_status_codes=${TRANSACTION_FAILED}

Verify_Client_Aborted
    [Arguments]    ${exp_aborted}
    [Documentation]    To be reworked
    BuiltIn.Fail    TODO: Logic to be reworked

Get_Seconds_To_Time
    [Arguments]    ${date_in_future}
    [Documentation]    Return number of seconds remaining to ${date_in_future}.
    ${date_now} =    DateTime.Get_Current_Date
    ${duration} =    DateTime.Subtract_Date_From_Date    ${date_in_future}    ${date_now}
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Convert_To_Integer    ${duration}

Remote_Listener_Test_Templ
    [Arguments]    ${listener_node_role}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements listener isolation test scenario.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ${follower2} =    Collections.Get_From_List    ${follower_list}    ${1}
    ${listener_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    MdsalLowlevel.Subscribe_Dtcl    ${listener_node_dst}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${all_ip_list}    ${ID_PREFIX}    ${DURATION_10S}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ClusterAdmin.Make_Leader_Local    ${follower1}    ${shard_name}    ${shard_type}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    ${resp}
    [Teardown]    MdsalLowlevel.Unsubscribe_Dtcl    ${listener_node_dst}

Remote_Listener_PrefBasedShard_Test_Templ
    [Arguments]    ${listener_node_role}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements listener isolation test scenario.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ${follower2} =    Collections.Get_From_List    ${follower_list}    ${1}
    ${listener_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    MdsalLowlevel.Subscribe_Dtcl    ${listener_node_dst}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${all_ip_list}    ${ID_PREFIX}    ${DURATION_10S}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ClusterAdmin.Make_Leader_Local    ${follower1}    ${shard_name}    ${shard_type}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    ${resp}
    [Teardown]    MdsalLowlevel.Unsubscribe_Dtcl    ${listener_node_dst}

Create_Prefix_Based_Shard
    [Arguments]    ${prefix}=${PREF_BASED_SHARD}
    [Documentation]    Create prefix based shard with replicas on all nodes
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${node_to_trigger} =    Collections.Get_From_List    ${all_indices}    ${0}
    MdsalLowlevel.Create_Prefix_Shard      ${node_to_trigger}    ${prefix}    ${all_indices}

Remove_Prefix_Based_Shard
    [Arguments]    ${prefix}=${PREF_BASED_SHARD}
    [Documentation]    Remove prefix based shard with all replicas
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${node_to_trigger} =    Collections.Get_From_List    ${all_indices}    ${0}
    MdsalLowlevel.Remove_Prefix_Shard    ${node_to_trigger}    ${prefix}
