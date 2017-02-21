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

*** Variables ***
${ISOLATED_MEMBER_IDX}    ${1}
${NON_ISOLATED_MEMBER_IDX}    ${2}
@{INSTALLED_RPC_MEMEBER_IDX}    ${ISOLATED_MEMBER_IDX}    ${NON_ISOLATED_MEMBER_IDX}
${CONSTANT_PREFIX}    member-

*** Test Cases ***
Register_Rpc_On_Two_Nodes
    [Documentation]    Register rpc on two nodes of the odl cluster.
    : FOR    ${index}    IN    @{INSTALLED_RPC_MEMEBER_IDX}
    \    MdsalLowlevel.Register_Constant    ${index}    ${CONSTANT_PREFIX}${index}

Invoke_Rpc_On_Each_Node
    [Documentation]    Invoke get-constant rpc on every node of the cluster. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Run_Keyword_If    ${index} in ${INSTALLED_RPC_MEMEBER_IDX}    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${index}    ${constant}
    \    ...    ELSE    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}

Isolate_One_Node
    [Documentation]    Isolate one node with registered rpc.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${ISOLATED_MEMBER_IDX}

Invoke_Rpc_On_Isolated_Node
    [Documentation]    Invoke rpc on isolated node. Because rpc is registered on this node, local constant
    ...    is expected.
    ${constant} =    MdsalLowlevel.Get_Constant    ${ISOLATED_MEMBER_IDX}
    Collections.List_Should_Contain_Value    ${CONSTANT_PREFIX}${ISOLATED_MEMBER_IDX}    ${constant}

Invoke_Rpc_On_Remaining_Nodes
    [Documentation]    Invoke rpc on non-islolated nodes. Because the only instance of rpc remained in the non-isolated
    ...    cluster nodes
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    Collections.Remove_Values_From_List    ${index_list}    ${ISOLATED_MEMBER_IDX}
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${NON_ISOLATED_MEMBER_IDX}    ${constant}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${ISOLATED_MEMBER_IDX}

Invoke_Rpc_On_Each_Node_Again
    [Documentation]    Invoke rpc get-constant on every node. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Run_Keyword_If    ${index} in ${INSTALLED_RPC_MEMEBER_IDX}    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${index}    ${constant}
    \    ...    ELSE    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}

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
