*** Settings ***
Documentation       DOMRpcBroker testing: Common keywords
...
...                 Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 The aim of this resource is to groups reusable blocks of commands into
...                 keywords. It should be initiated by DrbCommons_Init. It creates
...                 ${all_indices}, ${registered_indices}, ${nonregistered_indices} and
...                 ${possible_constants} suite variables.
...                 ${registered_indices} - list of indexes where rpc is registered; including
...                 isolated mebers; exluding killed/stopped members
...                 ${nonregistered_indices} - list of indexes where rpc is not registrated;
...                 including isolated mebers; exluding killed/stopped
...                 members
...                 ${possible_constants} - list of valid constants responded from the cluster;
...                 constant from isolated node with regirered rpc is
...                 invalid
...                 ${active_indices} - list of indexes of non-isolated, non-stopped/killed nodes
...
...                 Pekko can create spurious UnreachableMember events, see
...                 https://bugs.opendaylight.org/show_bug.cgi?id=8430
...                 so some keywords contain "tolerance" argument which applies BuiltIn.Wait_Until_Keyword_Succeeds.
...
...                 The delay before subsequent ReachableMember is significantly higher than
...                 RPC registration delay documented at
...                 http://docs.opendaylight.org/en/latest/developer-guide/controller.html#rpcs-and-cluster

Library             Collections
Resource            ${CURDIR}/../ClusterManagement.robot
Resource            ${CURDIR}/../MdsalLowlevel.robot
Resource            ${CURDIR}/../ShardStability.robot


*** Variables ***
${CONSTANT_PREFIX}          constant-
${CONTEXT}                  context
${BUG_8430_TOLERANCE}       10


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
    [Documentation]    Register global rpc on given node of the cluster.
    [Arguments]    ${member_index}
    MdsalLowlevel.Register_Constant    ${member_index}    ${CONSTANT_PREFIX}${member_index}
    DrbCommons__Add_Possible_Constant    ${member_index}
    DrbCommons__Register_Index    ${member_index}

Unregister_Rpc_And_Update_Possible_Constants
    [Documentation]    Unregister global rpc on given node of the cluster.
    [Arguments]    ${member_index}
    MdsalLowlevel.Unregister_Constant    ${member_index}
    DrbCommons__Rem_Possible_Constant    ${member_index}
    DrbCommons__Deregister_Index    ${member_index}

Register_Action_And_Update_Possible_Constants
    [Documentation]    Register routed rpc on given node of the cluster.
    [Arguments]    ${member_index}
    MdsalLowlevel.Register_Bound_Constant    ${member_index}    ${CONTEXT}    ${CONSTANT_PREFIX}${member_index}
    DrbCommons__Add_Possible_Constant    ${member_index}
    DrbCommons__Register_Index    ${member_index}

Unregister_Action_And_Update_Possible_Constants
    [Documentation]    Unregister routed rpc on given node of the cluster.
    [Arguments]    ${member_index}
    MdsalLowlevel.Unregister_Bound_Constant    ${member_index}    ${CONTEXT}
    DrbCommons__Rem_Possible_Constant    ${member_index}
    DrbCommons__Deregister_Index    ${member_index}

Register_Rpc_On_Nodes
    [Documentation]    Register global rpc on given nodes of the cluster.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Register_Rpc_And_Update_Possible_Constants    ${index}
    END

Unregister_Rpc_On_Nodes
    [Documentation]    Unregister global rpc on given nodes of the cluster.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Unregister_Rpc_And_Update_Possible_Constants    ${index}
    END

Register_Action_On_Nodes
    [Documentation]    Register global rpc on given nodes of the cluster.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Register_Action_And_Update_Possible_Constants    ${index}
    END

Unregister_Action_On_Nodes
    [Documentation]    Unregister global rpc on given nodes of the cluster.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Unregister_Action_And_Update_Possible_Constants    ${index}
    END

Verify_Constant_On_Registered_Node
    [Documentation]    Verify that the rpc response comes from the local node.
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    RETURN    ${constant}

Verify_Constant_On_Unregistered_Node
    [Documentation]    Verify that the response comes from other nodes with rpc registered. Verification
    ...    passes for registered nodes too.
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    RETURN    ${constant}

Verify_Contexted_Constant_On_Registered_Node
    [Documentation]    Verify that the rpc response comes from the local node.
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Contexted_Constant    ${member_index}    ${CONTEXT}
    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${member_index}    ${constant}
    RETURN    ${constant}

Verify_Contexted_Constant_On_Unregistered_Node
    [Documentation]    Verify that the response comes from other nodes with rpc registered. Verification
    ...    passes for registered nodes too.
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Contexted_Constant    ${member_index}    ${CONTEXT}
    Collections.List_Should_Contain_Value    ${possible_constants}    ${constant}
    RETURN    ${constant}

Verify_Constant_On_Registered_Nodes
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Verify_Constant_On_Registered_Node    ${index}
    END

Verify_Contexted_Constant_On_Registered_Nodes
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Verify_Contexted_Constant_On_Registered_Node    ${index}
    END

Verify_Constant_On_Unregistered_Nodes
    [Documentation]    Verify that the rpc response comes from the remote node for every node in the list.
    [Arguments]    ${index_list}
    FOR    ${index}    IN    @{index_list}
        Verify_Constant_On_Unregistered_Node    ${index}
    END

Verify_Constant_On_Active_Nodes
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    ...    As a workaround for Bug 8430, \${tolerance} can be set as duration (number of seconds) for WUKS.
    [Arguments]    ${tolerance}=${BUG_8430_TOLERANCE}
    # TODO: Rename most Verify_* keywords to Check_* and use the Verify prefix for the WUKS versions.
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${tolerance}
    ...    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    ${tolerance}
    ...    1s
    ...    Verify_Constant_On_Active_Nodes
    ...    tolerance=0
    FOR    ${index}    IN    @{active_indices}
        IF    ${index} in ${registered_indices}
            Verify_Constant_On_Registered_Node    ${index}
        ELSE
            Verify_Constant_On_Unregistered_Node    ${index}
        END
    END

Verify_Contexted_Constant_On_Active_Nodes
    [Documentation]    Verify that the rpc response comes from the local node for every node in the list.
    ...    As a workaround for Bug 8430, \${tolerance} can be set as duration (number of seconds) for WUKS.
    [Arguments]    ${tolerance}=${BUG_8430_TOLERANCE}
    # TODO: Rename most Verify_* keywords to Check_* and use the Verify prefix for the WUKS versions.
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${tolerance}
    ...    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    ${tolerance}
    ...    1s
    ...    Verify_Contexted_Constant_On_Active_Nodes
    ...    tolerance=0
    FOR    ${index}    IN    @{active_indices}
        IF    ${index} in ${registered_indices}
            Verify_Contexted_Constant_On_Registered_Node    ${index}
        ELSE
            Verify_Contexted_Constant_On_Unregistered_Node    ${index}
        END
    END

Verify_Expected_Constant_On_Nodes
    [Documentation]    Verify that the rpc response comes only from one node only for every node in the list.
    [Arguments]    ${index_list}    ${exp_constant}
    FOR    ${index}    IN    @{index_list}
        ${const_index} =    Get_Constant_Index_From_Node    ${index}
        BuiltIn.Should_Be_Equal_As_Strings    ${exp_constant}    ${CONSTANT_PREFIX}${const_index}
    END

Get_Constant_Index_From_Node
    [Documentation]    Ivoke get-constant rpc on given member index. Returns the index of
    ...    the node where the constant came from.
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Constant    ${member_index}
    ${index} =    String.Replace_String    ${constant}    ${CONSTANT_PREFIX}    ${EMPTY}
    ${index} =    BuiltIn.Convert_To_Integer    ${index}
    RETURN    ${index}

Get_Contexted_Constant_Index_From_Node
    [Documentation]    Ivoke get-contexted-constant rpc on given member index. Returns the index of
    ...    the node where the constant came from.
    [Arguments]    ${member_index}
    ${constant} =    MdsalLowlevel.Get_Contexted_Constant    ${member_index}    ${CONTEXT}
    ${index} =    String.Replace_String    ${constant}    ${CONSTANT_PREFIX}    ${EMPTY}
    ${index} =    BuiltIn.Convert_To_Integer    ${index}
    RETURN    ${index}

Isolate_Node
    [Documentation]    Isolate a member and update appropriate suite variables.
    [Arguments]    ${member_index}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${member_index}
    DrbCommons__Update_Active_Nodes_List    deactivate_idx=${member_index}
    IF    ${member_index} not in ${registered_indices}    RETURN
    DrbCommons__Rem_Possible_Constant    ${member_index}

Rejoin_Node
    [Documentation]    Rejoin a member and update appropriate suite variables.
    [Arguments]    ${member_index}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${member_index}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    70s
    ...    10s
    ...    ShardStability.Shards_Stability_Get_Details
    ...    ${DEFAULT_SHARD_LIST}
    DrbCommons__Update_Active_Nodes_List    activate_idx=${member_index}
    IF    ${member_index} not in ${registered_indices}    RETURN
    DrbCommons__Add_Possible_Constant    ${member_index}

DrbCommons__Update_Active_Nodes_List
    [Documentation]    Add or remove member index to/from the list of active nodes.
    [Arguments]    ${activate_idx}=${EMPTY}    ${deactivate_idx}=${EMPTY}
    IF    "${activate_idx}" != "${EMPTY}"
        Collections.Append_To_List    ${active_indices}    ${activate_idx}
    END
    IF    "${deactivate_idx}" != "${EMPTY}"
        Collections.Remove_Values_From_List    ${active_indices}    ${deactivate_idx}
    END
    Collections.Sort_List    ${active_indices}

DrbCommons__Register_Index
    [Documentation]    Add member index to the list of indices with registered rpc.
    ...    Isolated nodes are included in the list.
    [Arguments]    ${member_index}
    Collections.Append_To_List    ${registered_indices}    ${member_index}
    Collections.Remove_Values_From_List    ${nonregistered_indices}    ${member_index}
    Collections.Sort_List    ${registered_indices}
    Collections.Sort_List    ${nonregistered_indices}

DrbCommons__Deregister_Index
    [Documentation]    Remove member index from the list of indices with registered rpc.
    ...    Isolated nodes are included in the list.
    [Arguments]    ${member_index}
    Collections.Remove_Values_From_List    ${registered_indices}    ${member_index}
    Collections.Append_To_List    ${nonregistered_indices}    ${member_index}
    Collections.Sort_List    ${registered_indices}
    Collections.Sort_List    ${nonregistered_indices}

DrbCommons__Add_Possible_Constant
    [Documentation]    Add a constant to the ${possible_constants} list. The list is about to maintain
    ...    all valid constants possibly responded from the odl cluster (excluding isolated nodes).
    [Arguments]    ${member_index}
    Collections.Append_To_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
    Collections.Sort_List    ${possible_constants}

DrbCommons__Rem_Possible_Constant
    [Documentation]    Remove a constant from the ${possible_constants} list. The list is about to maintain
    ...    all valid constants possibly responded from the odl cluster (excluding isolated nodes).
    [Arguments]    ${member_index}
    Collections.Remove_Values_From_List    ${possible_constants}    ${CONSTANT_PREFIX}${member_index}
