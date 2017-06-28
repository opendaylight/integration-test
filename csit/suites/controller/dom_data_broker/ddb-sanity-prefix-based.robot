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
Suite Setup       BuiltIn.Run_Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
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
${DURATION}       ${30}
${SIMPLE_TX}      ${False}
${CHAINED_TX}     ${True}
${ID_PREFIX}      prefix-

*** Test Cases ***
Become_Prefix_Leader_0
    [Documentation]    Make the member-1 leader.
    MdsalLowlevel.Become_Prefix_Leader    ${1}    ${PREF_BASED_SHARD}
    ${leader}    ${followers}=    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Get_Leader_And_Followers_For_Shard    shard_name=${PREF_BASED_SHARD}!!    shard_type=${SHARD_TYPE}

Remove_Leader_Prefix_Shard_Replica_And_Add_It_Back
    [Documentation]    Remove and add shard replica adn verify it.
    ${shard_name} =    BuiltIn.Set_Variable    ${PREF_BASED_SHARD}
    ${shard_type} =    BuiltIn.Set_Variable    ${SHARD_TYPE}
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${old_leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}    verify_restconf=False
    ClusterAdmin.Remove_Prefix_Shard_Replica    ${old_leader}    ${shard_name}    member-${old_leader}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Verify_Shard_Replica_Not_Present    ${old_leader}    ${shard_name}!!    ${shard_type}
    ${actual_leader}    ${actual_follower_list} =    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!
    ...    verify_restconf=False    shard_type=${shard_type}    member_index_list=${follower_list}
    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_leader}    ${actual_leader}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterAdmin.Add_Prefix_Shard_Replica    ${old_leader}    ${shard_name}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}!!    shard_type=${shard_type}    member_index_list=${all_indices}
    ...    verify_restconf=False

Become_Prefix_Leader_1
    [Documentation]    Make the member-1 leader again.
    MdsalLowlevel.Become_Prefix_Leader    ${1}    ${PREF_BASED_SHARD}
    ${leader}    ${followers}=    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Get_Leader_And_Followers_For_Shard    shard_name=${PREF_BASED_SHARD}!!    shard_type=${SHARD_TYPE}

Produce_Transactions_One_Node_Leader
    [Documentation]    Produce transactions.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}    member_index_list=${all_indices}    verify_restconf=False
    ${leader_idx_as_list} =    BuiltIn.Create_List    ${leader}
    ${leader_ip_as_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${leader_idx_as_list}
    MdsalLowlevelPy.Start_Produce_Transactions_On_Nodes    ${leader_ip_as_list}    ${leader_idx_as_list}    ${ID_PREFIX}    ${DURATION}    ${TRANSACTION_RATE_1K}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Transactions
    : FOR    ${resp}    IN    @{resp_list}
    \    TemplatedRequests.Check_Status_Code    @{resp}[2]
