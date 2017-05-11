*** Settings ***
Documentation     DOMDataBroker testing: Module based shards sanity suite
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The goal is to call several basic rpc form ClusterAdmin.robot and
...               MdsalLowlevel.robot to ensute that those rpcs can be safely used in
...               other suites.
...               It also verify the ability of the odl-controller-test-app to perform
...               several activities.
Suite Setup       BuiltIn.Run_Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=30
...               AND    DdbCommons.Create_Prefix_Based_Shard_And_Verify
Suite Teardown    BuiltIn.Run_Keywords    DdbCommons.Remove_Prefix_Based_Shard_And_Verify
...               AND    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Library           ${CURDIR}/../../../libraries/MdsalLowlevelPy.py
Resource          ${CURDIR}/../../../libraries/ClusterAdmin.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${PREF_BASED_SHARD}    id-ints
${SHARD_TYPE}     config
${TRANSACTION_RATE_1K}    ${1000}
${DURATION_10S}    ${10}
${SIMPLE_TX}      ${False}
${CHAINED_TX}     ${True}
${SHARD_PREFIX}    member-
${ID_PREFIX}      prefix-

*** Test Cases ***
Produce_Transactions
    [Documentation]    Write transactions.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${all_ip_list}    ${all_indices}    ${ID_PREFIX}    ${DURATION_10S}    ${TRANSACTION_RATE_1K}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    ${resp}

Become_Prefix_Leader
    [Documentation]    Make the loeader local and verify.
    ${shard_name} =    BuiltIn.Set_Variable    ${PREF_BASED_SHARD}
    ${shard_type} =    BuiltIn.Set_Variable    ${SHARD_TYPE}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${old_leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    MdsalLowlevel.Become_Prefix_Leader    ${follower1}    ${shard_name}    ${ID_PREFIX}
    ${leader}    ${follower_list} =    BuiltIn.Wait_Until_Keyword_Succeeds    30s    3s    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}!!
    ...    ${shard_type}    ${True}    ${old_leader}    member_index_list=${EMPTY}
    BuiltIn.Should_Be_Equal_As_Numbers    ${follower1}    ${leader}

Remove_Leader_Prefix_Shard_Replica_And_Add_It_Back
    [Documentation]    Remove and add shard replica adn verify it.
    ${shard_name} =    BuiltIn.Set_Variable    ${PREF_BASED_SHARD}
    ${shard_type} =    BuiltIn.Set_Variable    ${SHARD_TYPE}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${old_leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ClusterAdmin.Remove_Prefix_Shard_Replica    ${old_leader}    ${shard_name}    member-${old_leader}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    Verify_Shard_Replica_Removed    ${old_leader}    ${shard_name}!!    ${shard_type}
    ${actual_leader}    ${actual_follower_list} =    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!
    ...    verify_restconf=False    shard_type=${shard_type}    member_index_list=${follower_list}
    ClusterAdmin.Add_Prefix_Shard_Replica    ${old_leader}    ${shard_name}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}
    ...    verify_restconf=False

Remove_Follower_Prefix_Shard_Replica_And_Add_It_Back
    [Documentation]    Remove and add shard replica adn verify it.
    ${shard_name} =    BuiltIn.Set_Variable    ${PREF_BASED_SHARD}
    ${shard_type} =    BuiltIn.Set_Variable    ${SHARD_TYPE}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ClusterAdmin.Remove_Prefix_Shard_Replica    ${follower1}    ${shard_name}    member-${follower1}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    DdbCommons.Verify_Shard_Replica_Removed    ${follower1}    ${shard_name}!!    ${shard_type}
    ${new_indices_list} =    ClusterManagement.List_Indices_Minus_Member    ${follower1}
    ClusterManagement.Verify_Shard_Leader_Elected    ${shard_name}!!    ${shard_type}    ${False}    ${leader}    member_index_list=${new_indices_list}
    ClusterAdmin.Add_Prefix_Shard_Replica    ${follower1}    ${shard_name}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}
    ...    verify_restconf=False
