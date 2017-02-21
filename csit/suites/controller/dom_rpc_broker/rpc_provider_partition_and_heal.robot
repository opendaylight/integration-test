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
@{INSTALLED_RPC_MEMEBER_IDX}    ${1}    ${2}
${CONSTANT_PREFIX}    member-

*** Test Cases ***
Register_Rpc_On_Two_Nodes
    [Documentation]    Register rpc on two nodes of the odl cluster.
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX}
    \    MdsalLowlevel.Register_Constant    ${index}    ${CONSTANT_PREFIX}${index}

Invoke_Rpc_On_Each_Node
    [Documentation]    Invoke get-constant rpc on every node of the cluster. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected. From the constant returned from the last node (with no rpc instance) an index of
    ...    the node to be isolated is derived. And in the tc Invoke_Rpc_On_Remaining_Nodes a different constant
    ...    is expected.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    BuiltIn.Run_Keyword_If    ${index} in ${INSTALLED_RPC_MEMEBER_IDX}    Verify_Local_Rpc_Invoked    ${index}
    \    ...    ELSE    Verify_Any_Remote_Rpc_Invoked    ${index}
    BuiltIn.Set_Suite_Variable    ${non_rpc_member_index}    ${index}
    ${isolated_idx} =    String.Replace_String    ${constant}    ${CONSTANT_PREFIX}    ${EMPTY}
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
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    Collections.Remove_Values_From_List    ${index_list}    ${isolated_idx}
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
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    BuiltIn.Run_Keyword_If    ${index} in ${INSTALLED_RPC_MEMEBER_IDX}    Verify_Local_Rpc_Invoked    ${index}
    \    BuiltIn.Run_Keyword_Unless    ${index} in ${INSTALLED_RPC_MEMEBER_IDX}    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    20s    3s    Verify_Any_Remote_Rpc_Invoked
    \    ...    ${index}

Isolate_Member_Without_Registered_Rpc
    [Documentation]    Isolate one node with unregistered rpc.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${non_rpc_member_index}

Verify_Rpc_Fails_On_Isolated_Member_Without_Rpc
    [Documentation]    Rpc should fail as it is requested on isolated node without rpc instance.
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    2s    Verify_Expected_Status_Code_For_Rpc    ${non_rpc_member_index}    501

Rejoin_Isolated_Member_Without_Registered_Rpc
    [Documentation]    Rejoin isolated node.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${non_rpc_member_index}

Verify_Rpc_Again_Passes_On_Member_Without_Rpc
    [Documentation]    Verify rpc works after the node rejoin.
    ${constant} =    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    MdsalLowlevel.Get_Constant    ${non_rpc_member_index}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}

Unregister_Rpc_On_Each_Node
    [Documentation]    Inregister rpc on both nodes.
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX}
    \    MdsalLowlevel.Unregister_Constant    ${index}

*** Keywords ***
Setup_Kw
    [Documentation]    Setup keyword. Create ${possible_constants} list with possible variables of remote constants.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${possible_constants} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX}
    \    Collections.Append_To_List    ${possible_constants}    ${CONSTANT_PREFIX}${index}
    BuiltIn.Set_Suite_Variable    ${possible_constants}

Verify_Local_Rpc_Invoked
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Any_Remote_Rpc_Invoked
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Expected_Status_Code_For_Rpc
    [Arguments]    ${member_index}    ${exp_status_code}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response} =    RequestsLibrary.Post_Request    ${session}    uri=/restconf/operations/odl-mdsal-lowlevel-target:get-constant
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${response.status_code}
