*** Settings ***
Documentation     DOMRpcBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The aim of this resource is to groups reusable blocks of commands into
...               keywords. It should be initiated by DrbCommons_Init. It creates
...               ${all_indices}, ${registered_indices}, ${nonregistered_indices} and
...               ${possible_constants} suite variables.
...               ${registered_indices} - list of indexes where rpc is registered; including
...               isolated mebers; exluding killed/stopped members
...               ${nonregistered_indices} - list of indexes where rpc is not registrated;
...               including isolated mebers; exluding killed/stopped
...               members
...               ${possible_constants} - list of valid constants responded from the cluster;
...               constant from isolated node with regirered rpc is
...               invalid
...               ${active_indices} - list of indexes of non-isolated, non-stopped/killed nodes
Library           Collections
Resource          ${CURDIR}/../ClusterManagement.robot
Resource          ${CURDIR}/../MdsalLowlevel.robot
Resource          ${CURDIR}/../ShardStability.robot

*** Variables ***
${CONSTANT_PREFIX}    constant-
${CONTEXT}        context

*** Keywords ***
DrbCommons_Init
    [Documentation]    Resouce initial keyword. Creates several suite variables which are
    ...    used in other keywords and should be used im the test suites.
    ${all_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${all_indices}
    ${nonregistered_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${nonregistered_indices}
    ${active_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${active_indices}
    ${possible_constants} =    BuiltIn.Create_List
    BuiltIn.Set_Suite_Variable    ${possible_constants}
    ${registered_indices} =    BuiltIn.Create_List
    BuiltIn.Set_Suite_Variable    ${registered_indices}

Register_Rpc_And_Update_Possible_Constants
    [Arguments]    ${member_index}
    [Documentation]    Register global rpc on given node of the cluster.
    MdsalLowlevel.Register_Constant    ${member_index}    ${CONSTANT_PREFIX}${member_index}
    DrbCommons__Add_Possible_Constant    ${member_index}
    DrbCommons__Register_Index    ${member_index}

Unregister_Rpc_And_Update_Possible_Constants
    [Arguments]    ${member_index}
    [Documentation]    Unregister global rpc on given node of the cluster.
    MdsalLowlevel.Unregister_Constant    ${member_index}
    DrbCommons__Rem_Possible_Constant    ${member_index}
    DrbCommons__Deregister_Index    ${member_index}

Register_Action_And_Update_Possible_Constants
    [Arguments]    ${member_index}
    [Documentation]    Register routed rpc on given node of the cluster.
    MdsalLowlevel.Register_Bound_Constant    ${member_index}    ${CONTEXT}    ${CONSTANT_PREFIX}${member_index}
    DrbCommons__Add_Possible_Constant    ${member_index}
    DrbCommons__Register_Index    ${member_index}

Unregister_Action_And_Update_Possible_Constants
    [Arguments]    ${member_index}
    [Documentation]    Unregister routed rpc on given node of the cluster.
    MdsalLowlevel.Unregister_Bound_Constant    ${member_index}    ${CONTEXT}
    DrbCommons__Rem_Possible_Constant    ${member_index}
    DrbCommons__Deregister_Index    ${member_index}

Register_Rpc_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Register global rpc on given nodes of the cluster.
    : FOR    ${index}    IN    @{index_list}
    \    Register_Rpc_And_Update_Possible_Constants    ${index}

Unregister_Rpc_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Unregister global rpc on given nodes of the cluster.
    : FOR    ${index}    IN    @{index_list}
    \    Unregister_Rpc_And_Update_Possible_Constants    ${index}

Register_Action_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Register global rpc on given nodes of the cluster.
    : FOR    ${index}    IN    @{index_list}
    \    Register_Action_And_Update_Possible_Constants    ${index}

Unregister_Action_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Unregister global rpc on given nodes of the cluster.
    : FOR    ${index}    IN    @{index_list}
    \    Unregister_Action_And_Update_Possible_Constants    ${index}

Verify_Constant_On_Registered_Node
    [Arguments]    ${member_index}
    [Documentation]    Verify that the rpc response comes from the local node.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Constant_On_Unregistered_Node
    [Arguments]    ${member_index}
    [Documentation]    Verify that the response comes from other nodes with rpc registered. Verification
    ...    passes for registered nodes too.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Contexted_Constant_On_Registered_Node
    [Arguments]    ${member_index}
    [Documentation]    Verify that the rpc response comes from the local node.
    ${constant} =    MdsalLowlevel.Get_Contexted_Constant    ${member_index}    ${CONTEXT}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Contexted_Constant_On_Unregistered_Node
    [Arguments]    ${member_index}
    [Documentation]    Verify that the response comes from other nodes with rpc registered. Verification
    ...    passes for registered nodes too.
    ${constant} =    MdsalLowlevel.Get_Contexted_Constant    ${member_index}    ${CONTEXT}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    BuiltIn.Return_From_Keyword    ${constant}

Verify_Constant_On_Registered_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Constant_On_Registered_Node    ${index}

Verify_Contexted_Constant_On_Registered_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Contexted_Constant_On_Registered_Node    ${index}

Verify_Constant_On_Unregistered_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Verify that the rpc response comes from the remote node for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Constant_On_Unregistered_Node    ${index}

Verify_Constant_On_Active_Nodes
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{active_indices}
    \    BuiltIn.Run_Keyword_If    ${index} in ${registered_indices}    Verify_Constant_On_Registered_Node    ${index}
    \    ...    ELSE    Verify_Constant_On_Unregistered_Node    ${index}

Verify_Contexted_Constant_On_Active_Nodes
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    : FOR    ${index}    IN    @{active_indices}
    \    BuiltIn.Run_Keyword_If    ${index} in ${registered_indices}    Verify_Contexted_Constant_On_Registered_Node    ${index}
    \    ...    ELSE    Verify_Contexted_Constant_On_Unregistered_Node    ${index}

Verify_Expected_Constant_On_Nodes
    [Arguments]    ${index_list}    ${exp_constant}
    [Documentation]    Verify that the rpc response comes only from one node only for every node in the list.
    : FOR    ${index}    IN    @{index_list}
    \    ${const_index} =    Get_Constant_Index_From_Node    ${index}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${exp_constant}    ${CONSTANT_PREFIX}${const_index}

Get_Constant_Index_From_Node
    [Arguments]    ${member_index}
    [Documentation]    Ivoke get-constant rpc on given member index. Returns the index of
    ...    the node where the constant came from.
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    ${index} =    String.Replace_String    ${constant}    ${CONSTANT_PREFIX}    ${EMPTY}
    ${index} =    BuiltIn.Convert_To_Integer    ${index}
    BuiltIn.Return_From_Keyword    ${index}

Get_Contexted_Constant_Index_From_Node
    [Arguments]    ${member_index}
    [Documentation]    Ivoke get-contexted-constant rpc on given member index. Returns the index of
    ...    the node where the constant came from.
    ${constant} =    MdsalLowlevel.Get_Contexted_Constant    ${member_index}    ${CONTEXT}
    ${index} =    String.Replace_String    ${constant}    ${CONSTANT_PREFIX}    ${EMPTY}
    ${index} =    BuiltIn.Convert_To_Integer    ${index}
    BuiltIn.Return_From_Keyword    ${index}

Isolate_Node
    [Arguments]    ${member_index}
    [Documentation]    Isolate a member and update appropriate suite variables.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${member_index}
    DrbCommons__Upadte_Active_Nodes_List    deactivate_idx=${member_index}
    BuiltIn.Return_From_Keyword_If    ${member_index} not in ${registered_indices}
    DrbCommons__Rem_Possible_Constant    ${member_index}

Rejoin_Node
    [Arguments]    ${member_index}
    [Documentation]    Rejoin a member and update appropriate suite variables.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${member_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}
    DrbCommons__Upadte_Active_Nodes_List    activate_idx=${member_index}
    BuiltIn.Return_From_Keyword_If    ${member_index} not in ${registered_indices}
    DrbCommons__Add_Possible_Constant    ${member_index}

DrbCommons__Upadte_Active_Nodes_List
    [Arguments]    ${activate_idx}=${EMPTY}    ${deactivate_idx}=${EMPTY}
    [Documentation]    Add or remove member index to/from the list of active nodes.
    BuiltIn.Run_Keyword_If    "${activate_idx}" != "${EMPTY}"    Collections.Append_To_List    ${active_indices}    ${activate_idx}
    BuiltIn.Run_Keyword_If    "${deactivate_idx}" != "${EMPTY}"    Collections.Remove_Values_From_List    ${active_indices}    ${deactivate_idx}
    Collections.Sort_List    ${active_indices}

DrbCommons__Register_Index
    [Arguments]    ${member_index}
    [Documentation]    Add member index to the list of indices with registered rpc.
    ...    Isolated nodes are included in the list.
    Collections.Append_To_List    ${registered_indices}    ${member_index}
    Collections.Remove_Values_From_List    ${nonregistered_indices}    ${member_index}
    Collections.Sort_List    ${registered_indices}
    Collections.Sort_List    ${nonregistered_indices}

DrbCommons__Deregister_Index
    [Arguments]    ${member_index}
    [Documentation]    Remove member index from the list of indices with registered rpc.
    ...    Isolated nodes are included in the list.
    Collections.Remove_Values_From_List    ${registered_indices}    ${member_index}
    Collections.Append_To_List    ${nonregistered_indices}    ${member_index}
    Collections.Sort_List    ${registered_indices}
    Collections.Sort_List    ${nonregistered_indices}

DrbCommons__Add_Possible_Constant
    [Arguments]    ${member_index}
    [Documentation]    Add a constant to the ${possible_constants} list. The list is about to maintain
    ...    all valid constants possibly responded from the odl cluster (excluding isolated nodes).
    Collections.Append_To_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
    Collections.Sort_List    ${possible_constants}

DrbCommons__Rem_Possible_Constant
    [Arguments]    ${member_index}
    [Documentation]    Remove a constant from the ${possible_constants} list. The list is about to maintain
    ...    all valid constants possibly responded from the odl cluster (excluding isolated nodes).
    Collections.Remove_Values_From_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
