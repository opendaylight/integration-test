*** Settings ***
Documentation     DOMRpcBroker testing: RPC Provider Partition And Heal
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This tests establishes that the RPC service operates correctly when faced
...               with node failures.
...               This suite will work in more than three node cluster too.
Suite Setup       Setup_Kw
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           Collections
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
@{INSTALLED_RPC_MEMEBER_IDX_LIST}    ${1}    ${2}
${TESTED_MEMBER_WITHOUT_RPC_IDX}    ${3}
${CONSTANT_PREFIX}    member-
@{NON_WORKING_RPC_STATUS_CODE}    ${501}

*** Test Cases ***
Register_Rpc_On_Two_Nodes
    [Documentation]    Register rpc on two nodes of the odl cluster.
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX_LIST}
    \    MdsalLowlevel.Register_Constant    ${index}    ${CONSTANT_PREFIX}${index}

Invoke_Rpc_On_Each_Node
    [Documentation]    Invoke get-constant rpc on every node of the cluster. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected. From the constant returned from the last node (with no rpc instance) an index of
    ...    the node to be isolated is derived. And in the tc Invoke_Rpc_On_Remaining_Nodes a different constant
    ...    is expected.
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX_LIST}
    \    Verify_Local_Rpc_Invoked    ${index}
    : FOR    ${index}    IN    @{non_installed_rpc_member_idx_list}
    \    ${constant} =    Verify_Any_Remote_Rpc_Invoked    ${index}
    \    BuiltIn.Run_Keyword_If    "${index}" == "${TESTED_MEMBER_WITHOUT_RPC_IDX}"    BuiltIn.Set_Suite_Variable    ${initial_const_on_tested_non_rpc_member}    ${constant}
    ${isolated_idx} =    String.Replace_String    ${initial_const_on_tested_non_rpc_member}    ${CONSTANT_PREFIX}    ${EMPTY}
    BuiltIn.Set_Suite_Variable    ${isolated_idx}    ${${isolated_idx}}

Isolate_One_Node
    [Documentation]    Isolate one node with registered rpc.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${isolated_idx}

Invoke_Rpc_On_Isolated_Node
    [Documentation]    Invoke rpc on isolated node. Because rpc is registered on this node, local constant
    ...    is expected.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Verify_Local_Rpc_Invoked    ${isolated_idx}

Invoke_Rpc_On_Remaining_Nodes
    [Documentation]    Invoke rpc on non-islolated nodes. As the only instance of rpc remained in the non-isolated
    ...    cluster nodes, only this value is expected.
    ${index_list} =    ClusterManagement.List_Indices_Minus_Member    ${isolated_idx}    ${all_indices}
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    Verify_Any_Remote_Rpc_Invoked    ${index}
    \    BuiltIn.Should_Not_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${isolated_idx}    ${constant}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${isolated_idx}

Invoke_Rpc_On_Each_Node_Again
    [Documentation]    Invoke rpc get-constant on every node. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected.
    : FOR    ${index}    IN    @{all_indices}
    \    BuiltIn.Run_Keyword_If    ${index} in ${INSTALLED_RPC_MEMEBER_IDX_LIST}    Verify_Local_Rpc_Invoked    ${index}
    \    BuiltIn.Run_Keyword_Unless    ${index} in ${INSTALLED_RPC_MEMEBER_IDX_LIST}    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    20s    3s    Verify_Any_Remote_Rpc_Invoked
    \    ...    ${index}

Isolate_Member_Without_Registered_Rpc
    [Documentation]    Isolate one node with unregistered rpc.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${TESTED_MEMBER_WITHOUT_RPC_IDX}

Verify_Rpc_Fails_On_Isolated_Member_Without_Rpc
    [Documentation]    Rpc should fail as it is requested on isolated node without rpc instance.
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    2s    MdsalLowlevel.Get_Constant    ${TESTED_MEMBER_WITHOUT_RPC_IDX}    use_explicit_status_codes=${NON_WORKING_RPC_STATUS_CODE}

Rejoin_Isolated_Member_Without_Registered_Rpc
    [Documentation]    Rejoin isolated node.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${TESTED_MEMBER_WITHOUT_RPC_IDX}

Verify_Rpc_Again_Passes_On_Member_Without_Rpc
    [Documentation]    Verify rpc works after the node rejoin.
    ${constant} =    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    MdsalLowlevel.Get_Constant    ${TESTED_MEMBER_WITHOUT_RPC_IDX}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}

Unregister_Rpc_On_Each_Node
    [Documentation]    Inregister rpc on both nodes.
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX_LIST}
    \    MdsalLowlevel.Unregister_Constant    ${index}

*** Keywords ***
Setup_Kw
    [Documentation]    Setup keyword. Create ${possible_constants} list with possible variables of remote constants.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${all_indices} =     ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${all_indices}
    ${non_installed_rpc_member_idx_list} =    ClusterManagement.List_All_Indices
    ${possible_constants} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX_LIST}
    \    Collections.Append_To_List    ${possible_constants}    ${CONSTANT_PREFIX}${index}
    \    ${non_installed_rpc_member_idx_list} =    ClusterManagement.List_Indices_Minus_Member    ${index}    ${non_installed_rpc_member_idx_list}
    BuiltIn.Set_Suite_Variable    ${possible_constants}
    BuiltIn.Set_Suite_Variable    ${non_installed_rpc_member_idx_list}

Verify_Local_Rpc_Invoked
    [Arguments]    ${member_index}
    [Documentation]    Verify that local constant is received.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Any_Remote_Rpc_Invoked
    [Arguments]    ${member_index}
    [Documentation]    Verify that any valid constant is received.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}
