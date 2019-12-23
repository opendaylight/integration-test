*** Settings ***
Documentation     DOMDataBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This resource file implements various test cases templates.
...               FIXME: add a link to a document (when published) where the scenarios are defined
...
...               TODO: When checking first response in isolation scenarior, make sure it comes from the expected member.
Library           ${CURDIR}/../MdsalLowlevelPy.py
Resource          ${CURDIR}/../ClusterAdmin.robot
Resource          ${CURDIR}/../ClusterManagement.robot
Resource          ${CURDIR}/../KarafKeywords.robot
Resource          ${CURDIR}/../MdsalLowlevel.robot
Resource          ${CURDIR}/../TemplatedRequests.robot
Resource          ${CURDIR}/../ShardStability.robot
Resource          ${CURDIR}/../WaitForFailure.robot

*** Variables ***
${SHARD_NAME}     default
${SHARD_TYPE}     config
${TRANSACTION_RATE_1K}    ${1000}
${TRANSACTION_PRODUCTION_TIME_2X_REQ_TIMEOUT}    ${2*${REQUEST_TIMEOUT}}
${TRANSACTION_PRODUCTION_TIME}    ${40}
${SLEEP_AFTER_TRANSACTIONS_INIT}    5s
${ID_PREFIX}      prefix-
${ID_PREFIX2}     prefix-    # different-prefix- has been used before, but currently is neither needed nor supported
${SIMPLE_TX}      ${False}
${CHAINED_TX}     ${True}
${ISOLATED_TRANS_TRUE}    ${True}
${ISOLATED_TRANS_FALSE}    ${False}
${JAVA_INTERNAL_RECONNECT_TIMEOUT}    ${30}
${REQUEST_TIMEOUT}    ${120}
${HEAL_WITHIN_REQUEST_TIMEOUT}    ${${JAVA_INTERNAL_RECONNECT_TIMEOUT}+10}
${HEAL_AFTER_REQUEST_TIMEOUT}    ${${REQUEST_TIMEOUT}+10}
@{TRANSACTION_FAILED}    ${500}
${PREF_BASED_SHARD}    id-ints
${TEST_LOG_LEVEL}    info
@{TEST_LOG_COMPONENTS}    org.opendaylight.controller.cluster.sharding    org.opendaylight.controller.cluster.datastore
${HEAL_WITHIN_TRANS_TIMEOUT}    ${0}

*** Keywords ***
Explicit_Leader_Movement_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements explicit leader movement test scenario.
    ${idx_from}    ${idx_to}    ${idx_trans} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}    ${shard_name}
    ...    ${shard_type}
    KarafKeywords.Log_Message_To_Controller_Karaf    Starting leader movement from node${idx_from} to node${idx_to}, transaction producer at node${idx_trans}.
    ${ip_trans_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${idx_trans}_IP}
    ${idx_trans_as_list} =    BuiltIn.Create_List    ${idx_trans}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${ip_trans_as_list}    ${idx_trans_as_list}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME}    ${TRANSACTION_RATE_1K}    chained_flag=${CHAINED_TX}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    ClusterAdmin.Make_Leader_Local    ${idx_to}    ${shard_name}    ${shard_type}
    ${new_leader}    ${new_followers} =    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}
    ...    ${shard_type}    ${True}    ${idx_from}    verify_restconf=False
    BuiltIn.Should_Be_Equal    ${idx_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    Check_Status_Of_First_Response    ${resp_list}

Explicit_Leader_Movement_PrefBasedShard_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements explicit leader movement test scenario.
    ${idx_from}    ${idx_to}    ${idx_trans} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}    ${shard_name}!!
    ...    ${shard_type}
    ${ip_trans_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${idx_trans}_IP}
    ${idx_trans_as_list} =    BuiltIn.Create_List    ${idx_trans}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${ip_trans_as_list}    ${idx_trans_as_list}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME}    ${TRANSACTION_RATE_1K}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    MdsalLowlevel.Become_Prefix_Leader    ${idx_to}    ${shard_name}
    ${new_leader}    ${new_followers} =    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}!!
    ...    ${shard_type}    ${True}    ${idx_from}    verify_restconf=False
    BuiltIn.Should_Be_Equal    ${idx_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    Check_Status_Of_First_Response    ${resp_list}

Get_Node_Indexes_For_The_ELM_Test
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}    ${shard_type}
    [Documentation]    Return indexes for explicit leader movement test case, indexes of present to next leader node and index where transaction
    ...    producer should be deployed.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    verify_restconf=False
    ${idx_from} =    BuiltIn.Set_Variable    ${leader}
    ${idx_to} =    BuiltIn.Set_Variable    @{follower_list}[0]
    ${idx_trans} =    BuiltIn.Set_Variable_If    "${leader_from}" == "remote" and "${leader_to}" == "remote"    @{follower_list}[1]    "${leader_from}" == "local"    ${leader}    "${leader_to}" == "local"
    ...    @{follower_list}[0]
    BuiltIn.Return_From_Keyword    ${idx_from}    ${idx_to}    ${idx_trans}

Clean_Leader_Shutdown_Test_Templ
    [Arguments]    ${leader_location}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements clean leader shutdown test scenario.
    ${producer_idx}    ${actual_leader}    ${follower_list} =    Get_Node_Indexes_For_Clean_Leader_Shutdown_Test    ${leader_location}    ${shard_name}    ${shard_type}
    ${producer_ip_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${producer_idx}_IP}
    ${producer_idx_as_list} =    BuiltIn.Create_List    ${producer_idx}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${producer_ip_as_list}    ${producer_idx_as_list}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME}    ${TRANSACTION_RATE_1K}    chained_flag=${CHAINED_TX}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    BuiltIn.Comment    Bug 8794 workaround: Use remove-shard-replica until shutdown starts behaving properly.
    ClusterAdmin.Remove_Shard_Replica    ${actual_leader}    ${shard_name}    member-${actual_leader}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Verify_Shard_Replica_Not_Present    ${actual_leader}    ${shard_name}    ${shard_type}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    Check_Status_Of_First_Response    ${resp_list}
    [Teardown]    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    120s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}
    ...    shard_type=${shard_type}    member_index_list=${follower_list}    verify_restconf=False

Clean_Leader_Shutdown_PrefBasedShard_Test_Templ
    [Arguments]    ${leader_location}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements clean leader shutdown test scenario.
    ${producer_idx}    ${actual_leader}    ${follower_list} =    Get_Node_Indexes_For_Clean_Leader_Shutdown_Test    ${leader_location}    ${shard_name}!!    ${shard_type}
    ${producer_ip_as_list} =    BuiltIn.Create_List    ${ODL_SYSTEM_${producer_idx}_IP}
    ${producer_idx_as_list} =    BuiltIn.Create_List    ${producer_idx}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${producer_ip_as_list}    ${producer_idx_as_list}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME}    ${TRANSACTION_RATE_1K}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    BuiltIn.Comment    Bug 8794 workaround: Use remove-shard-replica until shutdown starts behaving properly.
    ClusterAdmin.Remove_Prefix_Shard_Replica    ${actual_leader}    ${shard_name}    member-${actual_leader}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Verify_Shard_Replica_Not_Present    ${actual_leader}    ${shard_name}!!    ${shard_type}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    Check_Status_Of_First_Response    ${resp_list}
    [Teardown]    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    120s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!
    ...    shard_type=${shard_type}    member_index_list=${follower_list}    verify_restconf=False

Get_Node_Indexes_For_Clean_Leader_Shutdown_Test
    [Arguments]    ${leader_location}    ${shard_name}    ${shard_type}
    [Documentation]    Return indexes for clean leader shudown test case, index where transaction producer shoudl be deployed and a shard leader index.
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    verify_restconf=False
    ${follower_list_leangth} =    BuiltIn.Evaluate    ${NUM_ODL_SYSTEM}-1
    BuiltIn.Length_Should_Be    ${follower_list}    ${follower_list_leangth}
    ${producer_idx} =    BuiltIn.Set_Variable_If    "${leader_location}" == "local"    ${leader}    @{follower_list}[0]
    BuiltIn.Return_From_Keyword    ${producer_idx}    ${leader}    ${follower_list}

Leader_Isolation_Test_Templ
    [Arguments]    ${heal_timeout}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements leader isolation test scenario.
    ${li_isolated}    BuiltIn.Set_Variable    ${False}
    ${producing_transactions_time} =    BuiltIn.Set_Variable_If    ${heal_timeout}<${REQUEST_TIMEOUT}    ${${REQUEST_TIMEOUT}+60}    ${2*${REQUEST_TIMEOUT}}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${all_ip_list}    ${all_indices}    ${ID_PREFIX}    ${producing_transactions_time}    ${TRANSACTION_RATE_1K}    chained_flag=${CHAINED_TX}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    ${date_start} =    DateTime.Get_Current_Date
    ${date_end} =    DateTime.Add_Time_To_Date    ${date_start}    ${producing_transactions_time}
    KarafKeywords.Log_Message_To_Controller_Karaf    Isolating node ${leader}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${leader}
    ${li_isolated}    BuiltIn.Set_Variable    ${True}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}    ${shard_type}    ${True}
    ...    ${leader}    member_index_list=${follower_list}    verify_restconf=False
    ${heal_date} =    DateTime.Add_Time_To_Date    ${date_start}    ${heal_timeout}
    ${sleep_to_heal} =    Get_Seconds_To_Time    ${heal_date}
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Should_Be_Equal    ${resp}    ${NONE}    No response expected, received ${resp}
    BuiltIn.Sleep    ${sleep_to_heal}
    KarafKeywords.Log_Message_To_Controller_Karaf    Rejoining node ${leader}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${leader}
    ${li_isolated}    BuiltIn.Set_Variable    ${False}
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    ${shard_name}    ${shard_type}    verify_restconf=False
    ${time_to_finish} =    Get_Seconds_To_Time    ${date_end}
    BuiltIn.Run_Keyword_If    ${heal_timeout} < ${REQUEST_TIMEOUT}    Leader_Isolation_Heal_Within_Rt
    ...    ELSE    Module_Leader_Isolation_Heal_Default    ${leader}    ${time_to_finish}
    [Teardown]    BuiltIn.Run_Keyword_If    ${li_isolated}    BuiltIn.Run_Keywords    ClusterManagement.Rejoin_Member_From_List_Or_All    ${leader}
    ...    AND    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}

Leader_Isolation_PrefBasedShard_Test_Templ
    [Arguments]    ${heal_timeout}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements leader isolation test scenario.
    ${li_isolated}    BuiltIn.Set_Variable    ${False}
    ${producing_transactions_time} =    BuiltIn.Set_Variable_If    ${heal_timeout}<${REQUEST_TIMEOUT}    ${${REQUEST_TIMEOUT}+60}    ${2*${REQUEST_TIMEOUT}}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${all_ip_list}    ${all_indices}    ${ID_PREFIX}    ${producing_transactions_time}    ${TRANSACTION_RATE_1K}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    ${date_start} =    DateTime.Get_Current_Date
    ${date_end} =    DateTime.Add_Time_To_Date    ${date_start}    ${producing_transactions_time}
    KarafKeywords.Log_Message_To_Controller_Karaf    Isolating node ${leader}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${leader}
    ${li_isolated}    BuiltIn.Set_Variable    ${True}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}!!    ${shard_type}    ${True}
    ...    ${leader}    member_index_list=${follower_list}    verify_restconf=False
    ${heal_date} =    DateTime.Add_Time_To_Date    ${date_start}    ${heal_timeout}
    ${sleep_to_heal} =    Get_Seconds_To_Time    ${heal_date}
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Should_Be_Equal    ${resp}    ${NONE}    No response expected, received ${resp}
    BuiltIn.Sleep    ${sleep_to_heal}
    KarafKeywords.Log_Message_To_Controller_Karaf    Rejoining node ${leader}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${leader}
    ${li_isolated}    BuiltIn.Set_Variable    ${False}
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    ${shard_name}!!    ${shard_type}    verify_restconf=False
    ${time_to_finish} =    Get_Seconds_To_Time    ${date_end}
    BuiltIn.Run_Keyword_If    ${heal_timeout} < ${REQUEST_TIMEOUT}    Leader_Isolation_Heal_Within_Rt
    ...    ELSE    Prefix_Leader_Isolation_Heal_Default    ${leader}    ${time_to_finish}
    [Teardown]    BuiltIn.Run_Keyword_If    ${li_isolated}    BuiltIn.Run_Keywords    ClusterManagement.Rejoin_Member_From_List_Or_All    ${leader}
    ...    AND    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}

Leader_Isolation_Heal_Within_Rt
    [Documentation]    The leader isolation test case end if the heal happens within transaction timeout. All write transaction
    ...    producers shoudl finish without error.
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    FOR    ${resp}    IN    @{resp_list}
        TemplatedRequests.Check_Status_Code    @{resp}[2]
    END

Module_Leader_Isolation_Heal_Default
    [Arguments]    ${isolated_node}    ${time_to_finish}
    [Documentation]    The leader isolation test case end. The transaction producer on isolated node should fail and should be restarted.
    ...    Then all write transaction producers should finish without error.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Log    ${resp}
    BuiltIn.Should_Not_Be_Equal    ${NONE}    ${resp}    Write-transaction should have returned error from isolated leader node.
    # TODO: check on response status code
    ${restart_producer_node_idx_as_list}    BuiltIn.Create_List    ${isolated_node}
    ${restart_producer_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${isolated_node}
    ${restart_producer_node_ip_as_list}    BuiltIn.Create_List    ${restart_producer_node_ip}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${restart_producer_node_ip_as_list}    ${restart_producer_node_idx_as_list}    ${ID_PREFIX2}    ${time_to_finish}    ${TRANSACTION_RATE_1K}    chained_flag=${CHAINED_TX}
    ...    reset_globals=${False}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    FOR    ${resp}    IN    @{resp_list}
        TemplatedRequests.Check_Status_Code    @{resp}[2]
    END

Prefix_Leader_Isolation_Heal_Default
    [Arguments]    ${isolated_node}    ${time_to_finish}
    [Documentation]    The leader isolation test case end. The transaction producer on isolated node shoudl fail and should be restarted.
    ...    Then all write transaction producers shoudl finish without error.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Log    ${resp}
    BuiltIn.Should_Not_Be_Equal    ${NONE}    ${resp}    Produce-transaction should have returned error from isolated leader node.
    # TODO: check on response status code
    ${restart_producer_node_idx_as_list}    BuiltIn.Create_List    ${isolated_node}
    ${restart_producer_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${isolated_node}
    ${restart_producer_node_ip_as_list}    BuiltIn.Create_List    ${restart_producer_node_ip}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${restart_producer_node_ip_as_list}    ${restart_producer_node_idx_as_list}    ${ID_PREFIX2}    ${time_to_finish}    ${TRANSACTION_RATE_1K}    reset_globals=${False}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    FOR    ${resp}    IN    @{resp_list}
        TemplatedRequests.Check_Status_Code    @{resp}[2]
    END

Client_Isolation_Test_Templ
    [Arguments]    ${listener_node_role}    ${trans_chain_flag}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements client isolation test scenario.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ${client_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    ${client_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${client_node_dst}
    ${client_node_ip_as_list}    BuiltIn.Create_List    ${client_node_ip}
    ${client_node_idx_as_list}    BuiltIn.Create_List    ${client_node_dst}
    ${start_date}    DateTime.Get_Current_Date
    ${abort_date} =    DateTime.Add_Time_To_Date    ${start_date}    ${REQUEST_TIMEOUT}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${client_node_ip_as_list}    ${client_node_idx_as_list}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME_2X_REQ_TIMEOUT}    ${TRANSACTION_RATE_1K}    chained_flag=${trans_chain_flag}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    KarafKeywords.Log_Message_To_Controller_Karaf    Isolating node ${client_node_dst}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${client_node_dst}
    ${rpc_timeout} =    Get_Seconds_To_Time    ${abort_date}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${rpc_timeout}    1s    Ongoing_Transactions_Not_Failed_Yet
    BuiltIn.Wait_Until_Keyword_Succeeds    20s    2s    Ongoing_Transactions_Failed
    [Teardown]    BuiltIn.Run Keywords    KarafKeywords.Log_Message_To_Controller_Karaf    Rejoining node ${client_node_dst}
    ...    AND    ClusterManagement.Rejoin_Member_From_List_Or_All    ${client_node_dst}
    ...    AND    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}
    ...    AND    MdsalLowlevelPy.Wait_For_Transactions

Client_Isolation_PrefBasedShard_Test_Templ
    [Arguments]    ${listener_node_role}    ${isolated_transactions_flag}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements client isolation test scenario.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ${client_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    ${client_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${client_node_dst}
    ${client_node_ip_as_list}    BuiltIn.Create_List    ${client_node_ip}
    ${client_node_idx_as_list}    BuiltIn.Create_List    ${client_node_dst}
    ${start_date}    DateTime.Get_Current_Date
    ${abort_date} =    DateTime.Add_Time_To_Date    ${start_date}    ${REQUEST_TIMEOUT}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${client_node_ip_as_list}    ${client_node_idx_as_list}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME_2X_REQ_TIMEOUT}    ${TRANSACTION_RATE_1K}    isolated_transactions_flag=${isolated_transactions_flag}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    KarafKeywords.Log_Message_To_Controller_Karaf    Isolating node ${client_node_dst}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${client_node_dst}
    ${rpc_timeout} =    Get_Seconds_To_Time    ${abort_date}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${rpc_timeout}    1s    Ongoing_Transactions_Not_Failed_Yet
    BuiltIn.Wait_Until_Keyword_Succeeds    20s    2s    Ongoing_Transactions_Failed
    [Teardown]    BuiltIn.Run Keywords    KarafKeywords.Log_Message_To_Controller_Karaf    Rejoining node ${client_node_dst}
    ...    AND    ClusterManagement.Rejoin_Member_From_List_Or_All    ${client_node_dst}
    ...    AND    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}
    ...    AND    MdsalLowlevelPy.Wait_For_Transactions

Ongoing_Transactions_Not_Failed_Yet
    [Documentation]    Verify that no write-transaction rpc finished, means they are still running.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    BuiltIn.Should_Be_Equal    ${None}    ${resp}    ${resp} not expected.

Ongoing_Transactions_Failed
    [Documentation]    Verify if write-transaction failed.
    ${resp} =    MdsalLowlevelPy.Get_Next_Transactions_Response
    Check_Status_Code    @{resp}[2]    explicit_status_codes=${TRANSACTION_FAILED}

Get_Seconds_To_Time
    [Arguments]    ${date_in_future}
    [Documentation]    Return number of seconds remaining to ${date_in_future}.
    ${date_now} =    DateTime.Get_Current_Date
    ${duration} =    DateTime.Subtract_Date_From_Date    ${date_in_future}    ${date_now}
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Convert_To_Integer    ${duration}

Listener_Stability_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}=${SHARD_NAME}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements listener stability test scenario for module-based shards.
    ${subscribed} =    BuiltIn.Set_Variable    ${False}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${idx_from}    ${idx_to}    ${idx_listen} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}    ${shard_name}
    ...    ${shard_type}
    MdsalLowlevel.Subscribe_Dtcl    ${idx_listen}
    ${subscribed} =    BuiltIn.Set_Variable    ${True}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${all_ip_list}    ${all_indices}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME}    ${TRANSACTION_RATE_1K}    chained_flag=${CHAINED_TX}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    ClusterAdmin.Make_Leader_Local    ${idx_to}    ${shard_name}    ${shard_type}
    ${new_leader}    ${new_followers} =    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}
    ...    ${shard_type}    ${True}    ${idx_from}    verify_restconf=False
    BuiltIn.Should_Be_Equal    ${idx_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    FOR    ${resp}    IN    @{resp_list}
        TemplatedRequests.Check_Status_Code    @{resp}[2]
    END
    ${copy_matches} =    MdsalLowlevel.Unsubscribe_Dtcl    ${idx_listen}
    ${subscribed} =    BuiltIn.Set_Variable    ${False}
    BuiltIn.Should_Be_True    ${copy_matches}
    [Teardown]    BuiltIn.Run_Keyword_If    ${subscribed}    MdsalLowlevel.Unsubscribe_Dtcl    ${idx_listen}

Listener_Stability_PrefBasedShard_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}    ${shard_name}=${PREF_BASED_SHARD}    ${shard_type}=${SHARD_TYPE}
    [Documentation]    Implements listener stability test scenario for prefix-based shards.
    ${subscribed} =    BuiltIn.Set_Variable    ${False}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${idx_from}    ${idx_to}    ${idx_listen} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}    ${shard_name}!!
    ...    ${shard_type}
    MdsalLowlevel.Subscribe_Ddtl    ${idx_listen}
    ${subscribed} =    BuiltIn.Set_Variable    ${True}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${all_ip_list}    ${all_indices}    ${ID_PREFIX}    ${TRANSACTION_PRODUCTION_TIME}    ${TRANSACTION_RATE_1K}
    BuiltIn.Sleep    ${SLEEP_AFTER_TRANSACTIONS_INIT}
    MdsalLowlevel.Become_Prefix_Leader    ${idx_to}    ${shard_name}
    ${new_leader}    ${new_followers} =    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}!!
    ...    ${shard_type}    ${True}    ${idx_from}    verify_restconf=False
    BuiltIn.Should_Be_Equal    ${idx_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    FOR    ${resp}    IN    @{resp_list}
        TemplatedRequests.Check_Status_Code    @{resp}[2]
    END
    ${copy_matches} =    MdsalLowlevel.Unsubscribe_Ddtl    ${idx_listen}
    ${subscribed} =    BuiltIn.Set_Variable    ${False}
    BuiltIn.Should_Be_True    ${copy_matches}
    [Teardown]    BuiltIn.Run_Keyword_If    ${subscribed}    MdsalLowlevel.Unsubscribe_Ddtl    ${idx_listen}

Create_Prefix_Based_Shard_And_Verify
    [Arguments]    ${prefix}=${PREF_BASED_SHARD}
    [Documentation]    Create prefix based shard with replicas on all nodes
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${node_to_trigger} =    Collections.Get_From_List    ${all_indices}    ${0}
    MdsalLowlevel.Create_Prefix_Shard    ${node_to_trigger}    ${prefix}    ${all_indices}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${prefix}!!    shard_type=${SHARD_TYPE}    member_index_list=${all_indices}
    ...    verify_restconf=False

Remove_Prefix_Based_Shard_And_Verify
    [Arguments]    ${prefix}=${PREF_BASED_SHARD}
    [Documentation]    Remove prefix based shard with all replicas
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${node_to_trigger} =    Collections.Get_From_List    ${all_indices}    ${0}
    MdsalLowlevel.Remove_Prefix_Shard    ${node_to_trigger}    ${prefix}
    FOR    ${idx}    IN    @{all_indices}
        BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Verify_Shard_Replica_Not_Present    ${idx}    ${prefix}!!
        ...    ${SHARD_TYPE}
    END

Verify_Shard_Replica_Not_Present
    [Arguments]    ${member_index}    ${shard_name}    ${shard_type}
    [Documentation]    Verify that shard is removed. Jolokia return 404 for shard memeber.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${type_class} =    Resolve_Shard_Type_Class    shard_type=${shard_type}
    ${uri} =    BuiltIn.Set_Variable    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-${member_index}-shard-${shard_name}-${shard_type},type=${type_class}
    ${text}    TemplatedRequests.Get_From_Uri    uri=${uri}    session=${session}
    BuiltIn.Should_Contain    ${text}    "status":404    javax.management.InstanceNotFoundException

Restart_Test_Templ
    [Documentation]    Stop every odl node and start again.
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Clean_Directories_On_List_Or_All    tmp_dir=/tmp
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds    300s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}    verify_restconf=True
    ClusterManagement.Run_Bash_Command_On_List_Or_All    ps -ef | grep java

Check_Status_Of_First_Response
    [Arguments]    ${resp_list}
    [Documentation]    Extract first item from the list, third item of the tuple and call TemplatedRequests to check the http status code.
    # @{resp_list}[0][2] does not work
    ${tuple} =    BuiltIn.Set_Variable    @{resp_list}[0]
    TemplatedRequests.Check_Status_Code    @{tuple}[2]

Change_Use_Tell_Based_Protocol
    [Arguments]    ${status}    ${DATASTORE_CFG}
    [Documentation]    Change status use-tell-based-protocol to True or False
    ClusterManagement.Check_Bash_Command_On_List_Or_All    sed -ie "s/^#use-tell-based-protocol=true/use-tell-based-protocol=true/g" ${DATASTORE_CFG}
    ClusterManagement.Check_Bash_Command_On_List_Or_All    sed -ie "s/^#use-tell-based-protocol=false/use-tell-based-protocol=false/g" ${DATASTORE_CFG}
    BuiltIn.Run_Keyword_And_Return_If    "${status}" == "True"    ClusterManagement.Check_Bash_Command_On_List_Or_All    sed -ie "s/^use-tell-based-protocol=false/use-tell-based-protocol=true/g" ${DATASTORE_CFG}
    BuiltIn.Run_Keyword_And_Return_If    "${status}" == "False"    ClusterManagement.Check_Bash_Command_On_List_Or_All    sed -ie "s/^use-tell-based-protocol=true/use-tell-based-protocol=false/g" ${DATASTORE_CFG}
    BuiltIn.Fail    Failure in status. Status can be True or False.
