*** Settings ***
Documentation     DOMRpcBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The aim is to establish that remote RPC implementations have lower priority
...               than local ones, which is to say that any movement of RPCs on remote nodes
...               does not affect routing as long as a local implementation is available.
...
...               This resource file should be initiated by DrbCommons_Init. It creates
...               ${all_indices}, ${registered_indices} and ${possible_constants} suite
...               variables.
Library           Collections
Resource          ${CURDIR}/../ClusterManagement.robot
Resource          ${CURDIR}/../MdsalLowlevel.robot

*** Variables ***
${CONSTANT_PREFIX}    constant-

*** Keywords ***
DrbCommons_Init
    [Documentation]    Resouce initial keyword. Creates several suite variables which are
    ...    used in other keywords and should be used im the test suites.
    ${all_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${all_indices}
    ${possible_constants} =    BuiltIn.Create_List
    BuiltIn.Set_Suite_Variable    ${possible_constants}
    ${registered_indices} =    BuiltIn.Create_List
    BuiltIn.Set_Suite_Variable    ${registered_indices}
    BuiltIn.Set_Suite_Variable    ${isolated_constant}    ${registered_indices}

Register_Rpc_And_Update_Possible_Constants
    [Arguments]    ${member_index}
    [Documentation]    Register global rpc on given node of the cluster.
    MdsalLowlevel.Register_Constant    ${member_index}    ${CONSTANT_PREFIX}${member_index}
    Collections.Append_To_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
    Collections.Sort_List    ${possible_constants}

Unregister_Rpc_And_Update_Possible_Constants
    [Arguments]    ${member_index}
    [Documentation]    Unregister global rpc on given node of the cluster.
    MdsalLowlevel.Unregister_Constant    ${member_index}
    Collections.Remove_Values_From_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}

Register_Rpc_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Register global rpc on given nodes of the cluster.
    : FOR    ${index}    IN    @{index_list}
    \    Register_Rpc_And_Update_Possible_Responses    ${index}

Unregister_Rpc_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Unregister global rpc on given nodes of the cluster.
    : FOR    ${index}    IN    @{index_list}
    \    Unregister_Rpc_And_Update_Possible_Responses    ${index}

Verify_Constant_On_Registered_Node
    [Arguments]    ${member_index}
    [Documentation]     Verify that the rpc response comes from the local node.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Constant_On_Unregistered_Node
    [Arguments]    ${member_index}
    [Documentation]     Verify that the response comes from other nodes with rpc registered.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Constant_On_Registered_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Constant_On_Registered_Node    ${index}

Verify_Constant_On_Unregistered_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Constant_On_Unregistered_Node    ${index}

Verify_Expected_Constant_On_Nodes
    [Arguments]    ${index_list}    ${exp_constant}
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    ${constant}    ${cindex} =    Get_Constant_And_Member_Index_From_Node    ${index}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${exp_constant}    ${constant}

Get_Constant_And_Member_Index_From_Node
    [Arguments]    ${member_index}
    [Documentation]    Ivoke get-constant rpc on given member index. Returns the constant and the index of
    ...    the node where the constant came from.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    ${index} =    String.Replace_String    ${constant}    ${CONSTANT_PREFIX}    ${EMPTY}
    BuiltIn.Return_From_Keyword     ${constant}    ${index}

Isolate_Node
    [Arguments]    ${member_index}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${member_index}
    BuiltIn.Return_From_Keyword_If     ${member_index} not in ${registered_indices}
    Collections.Remove_Values_From_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
    BuiltIn.Set_Suite_Variable    ${isolated_constant}    ${CONSTANT_PREFIX}${member_index}

Rejoin_Node
    [Arguments]    ${member_index}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${isolated_idx}
    BuiltIn.Return_From_Keyword_If     ${member_index} not in ${registered_indices}
    Collections.Append_To_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
    Collections.Sort_List    ${possible_constants}
    BuiltIn.Set_Suite_Variable    ${isolated_constant}    ${EMPTY}
