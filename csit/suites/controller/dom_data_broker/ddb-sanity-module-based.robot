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
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${SHARD_NAME}     default
${SHARD_TYPE}     config
${TRANSACTION_RATE_1K}    ${1000}
${DURATION_10S}    ${10}
${SIMPLE_TX}      ${False}
${CHAINED_TX}     ${True}

*** Test Cases ***
Remove_Leader_Shard_Replica_And_Add_It_Back
    [Arguments]    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}
    [Documentation]    Remove and add shard replica adn verify it.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${old_leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${all_indices}
    ClusterAdmin.Remove_Shard_Replica    ${old_leader}    ${shard_name}    member-${old_leader}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    3s    Verify_Shard_Removed    ${old_leader}    ${shard_name}    ${shard_type}
    ${actual_leader}    ${actual_follower_list} =    BuiltIn.Wait_Until_Keyword_Succeeds    15s    3s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_tyep}    member_index_list=${follower_list}
    ClusterAdmin.Add_Shard_Replica    ${old_leader}    ${shard_name}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    3s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_tyep}    member_index_list=${all_indices}

Remove_Follower_Shard_Replica_And_Add_It_Back
    [Arguments]    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}
    [Documentation]    Remove and add shard replica adn verify it.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_name}    member_index_list=${all_indices}
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ClusterAdmin.Remove_Shard_Replica    ${follower1}    ${shard_name}    member-${follower1}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    3s    Verify_Shard_Removed    ${follower1}    ${shard_name}    ${shard_type}
    ${new_indices_list} =    ClusterManagement.List_Indices_Minus_Member    ${follower1}
    Verify_Shard_Leader_Elected     ${shard_name}    ${shard_type}    ${False}    ${leader}    member_index_list=${new_indices_list}
    ClusterAdmin.Add_Shard_Replica    ${follower1}    ${shard_name}    ${shard_type}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    3s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_tyep}    member_index_list=${all_indices}

Make_Leader_Local
    [Arguments]    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}
    [Documentation]    Make the loeader local and verify.
    ${old_leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}
    ${follower1} =    Collections.Get_From_List    ${follower_list}    ${0}
    ClusterAdmin.Make_Leader_Local    ${follower1}    ${shard_name}    ${shard_type}
    ${leader}    ${follower_list} =    BuiltIn.Wait_Until_Keyword_Succeeds    30s    3s    Verify_Shard_Leader_Elected    ${shard_name}    ${shard_type}    ${True}    ${old_leader}    ${member_index_list}=${EMPTY}
    BuiltIn.Should_Be_Equal_As_Numbers    ${follower1}    ${leader}

Write_Transactions
    [Documentation]    Write transactions.
    ${all_indices} =    ClusterManagement.List_All_Indices
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Start_Write_Transactions_On_Nodes    ${all_ip_list}    ${MODULE_SHARD_PREFIX}    ${DURATION_10S}    ${TRANSACTION_RATE_1K}    chained_flag=${SIMPLE_TX}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Write_Transactions
    TemplatedRequests.Check_Status_Code    @{resp_list}[0]

*** Keywords ***
Verify_Shard_Removed
    [Arguments]    ${member_index}    ${shard_name}    ${shard_type}
    [Documentation]    Verify that shard is removed. Jolokia return 404 for shard memeber.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${type_class} =    Resolve_Shard_Type_Class    shard_type=${shard_type}
    ${uri} =    BuiltIn.Set_Variable    /jolokia/read/org.opendaylight.controller:Category=Shards,name=member-${member_index}-shard-${shard_name}-${shard_type},type=${type_class}
    BuiltIn.Run_Keyword_And_Return    TemplatedRequests.Get_From_Uri    uri=${uri}    session=${session}    explicit_status_codes=${DELETED_STATUS_CODE}
