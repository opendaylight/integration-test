*** Settings ***
Documentation     Cluster Singleton testing: Common Keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Cluster Singleton service is designed to ensure that only one instance of an
...               application is registered globally in the cluster.
...
...               Creates and uses the following suite variables:
...               Created by Cluster_Singleton_Init:
...                 ${all_indices}
...                 ${exp_candidates} 
...               Created by Get_And_Save_Present_CsOwner_And_CsCandidates:
...                 ${cs_owner}
...                 ${cs_candidates}
...               Created by Isolate_Owner_And_Verify_Isolated
...                 ${cs_isolated_index}
Library           Collections
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${CS_DEVICE_NAME}    get-singleton-constant-service']
${CS_DEVICE_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${CS_CONSTANT_PREFIX}    constant-
@{CS_STATUS_ISOLATED}    ${501}


*** Keywords ***
Cluster_Singleton_Init
    ${exp_candidates} =    BuiltIn.Create_List
    BuiltIn.Set_Suite_Variable    ${exp_candidates}
    ${all_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${all_indices}

Register_Singleton_And_Update_Expected_Candidates
    [Arguments]    ${member_index}    ${constant}
    MdsalLowlevel.Register_Singleton_Constant    ${member_index}    ${constant}
    Collections.Append_To_List    ${exp_candidates}    ${member_index}
    Collections.Sort_List    ${exp_candidates}
    
Unregister_Singleton_And_Update_Expected_Candidates
    [Arguments]    ${member_index}
    MdsalLowlevel.Unregister_Singleton_Constant    ${member_index}
    Collections.Remove_Values_From_List    ${exp_candidates}    ${member_index}
 
Verify_Owner_And_Candidates_Stable
    [Arguments]    ${owner_index}
    [Documentation]    Verify the owner and candidates stability. Owner stability compares given ${owner_index} with the actual one inside
    ...    ClusterManagement.Verify_Owner_Elected_For_Device. Received {actual_candidates} are then compated with ${exp_candidates} suite
    ...    variable.
    ${actual_owner}    ${actual_candidates}    ClusterManagement.Verify_Owner_Elected_For_Device    ${CS_DEVICE_NAME}    ${CS_DEVICE_TYPE}    ${False}
    ...    ${owner_index}    ${owner_index}
    Collections.Lists_Should_Be_Equal    ${exp_candidates}    ${actual_candidates}

Monitor_Owner_And_Candidates_Stability
    [Arguments]      ${monitoring_duration}      ${owner_index}
    [Documentation]    Verify that the owner remains on the same node after non-owner candidate is unregistered.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${monitoring_duration}    3s    Verify_Owner_And_Candidates_Stable    ${owner_index}

Register_Singleton_Constant_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Register a candidate application on given nodes.
    : FOR    ${index}    IN    @{index_list}
    \    Register_Singleton_And_Update_Expected_Candidates    ${index}    ${CS_CONSTANT_PREFIX}${index}

Unregister_Singleton_Constant_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Unregister the application from given nodes.
    : FOR    ${index}    IN    @{index_list}
    \    Unregister_Singleton_And_Update_Expected_Candidates    ${index}

Get_And_Save_Present_CsOwner_And_CsCandidates
    [Arguments]    ${node_to_ask}
    [Documentation]    Store owner index into suite variables.
    ${cs_owner}    ${cs_candidates}    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${CS_DEVICE_NAME}    ${CS_DEVICE_TYPE}    ${node_to_ask}
    BuiltIn.Set_Suite_Variable    ${cs_owner}
    BuiltIn.Set_Suite_Variable    ${cs_candidates}
    BuiltIn.Return_From_Keyword    ${cs_owner}    ${cs_candidates}

Verify_Singleton_Constant_On_Node
    [Arguments]    ${node_to_ask}    ${exp_constant}
    ${constant} =    MdsalLowlevel.Get_Singleton_Constant    ${node_to_ask}
    BuiltIn.Should_Be_Equal    ${exp_constant}    ${constant}

Verify_Singleton_Constant_On_Nodes
    [Arguments]    ${index_list}    ${exp_constant}
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Singleton_Constant_On_Node    ${index}    ${exp_constant}

Verify_Singleton_Constant_During_Isolation
    : FOR    ${index}    IN    @{all_indices}
    \    BuiltIn.Run_Keyword_If    "${index}" == "${cs_isolated_index}"    MdsalLowlevel.Get_Singleton_Constant    ${index}    explicit_status_codes=${CS_STATUS_ISOLATED}
    \    BuiltIn.Run_Keyword_Unless    "${index}" == "${cs_isolated_index}"    Verify_Singleton_Constant_On_Node    ${index}    ${CONSTANT_PREFIX}${cs_owner}

Isolate_Owner_And_Verify_Isolated
    [Documentation]    Isolate the owner cluster node. Wait until the new owner is elected and store new values of owner and candidates. Then wait
    ...    for isolated node to respond correctly if isolated.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${cs_owner}
    BuiltIn.Set_Suite_Variable    ${cs_isolated_index}    ${cs_owner}
    ${non_isolated_list} =    ClusterManagement.List_Indices_Minus_Member     ${cs_isolated_index}    member_index_list=${all_indices}
    ${node_to_ask} =    Collections.Get_From_list    ${non_isolated_list}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Verify_Owner_Elected_For_Device    ${CS_DEVICE_NAME}    ${CS_DEVICE_TYPE}    ${True}
    ...    ${cs_isolated_index}    ${node_to_ask}
    Get_And_Save_Present_CsOwner_And_CsCandidates    ${node_to_ask}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    MdsalLowlevel.Get_Singleton_Constant    ${cs_isolated_index}    explicit_status_codes=${CS_STATUS_ISOLATED}
    
Rejoin_Node_And_Verify_Rejoined
    [Documentation]    Rejoin isolated node.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${cs_isolated_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Singleton_Constant_On_Node    ${cs_isolated_index}    ${CONSTANT_PREFIX}${cs_owner}

