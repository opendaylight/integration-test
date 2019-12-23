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
...               ${cs_all_indices}
...               ${cs_exp_candidates}
...               Created by Get_And_Save_Present_CsOwner_And_CsCandidates:
...               ${cs_owner}
...               ${cs_candidates}
...               Created by Isolate_Owner_And_Verify_Isolated
...               ${cs_isolated_index}
Library           Collections
Resource          ${CURDIR}/../ClusterManagement.robot
Resource          ${CURDIR}/../MdsalLowlevel.robot
Resource          ${CURDIR}/../ShardStability.robot
Resource          ${CURDIR}/../WaitForFailure.robot

*** Variables ***
${CS_DEVICE_NAME}    get-singleton-constant-service']
${CS_DEVICE_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${CS_CONSTANT_PREFIX}    constant-

*** Keywords ***
Cluster_Singleton_Init
    [Documentation]    Resouce initial keyword. Creates {cs_exp_candidates} and {cs_all_indices} suite variables which are
    ...    used in other keywords.
    ${cs_exp_candidates} =    BuiltIn.Create_List
    BuiltIn.Set_Suite_Variable    ${cs_exp_candidates}
    ${cs_all_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${cs_all_indices}

Register_Singleton_And_Update_Expected_Candidates
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    Register the singleton candidate and add it to the list of ${cs_exp_candidates}.
    MdsalLowlevel.Register_Singleton_Constant    ${member_index}    ${constant}
    Collections.Append_To_List    ${cs_exp_candidates}    ${member_index}
    Collections.Sort_List    ${cs_exp_candidates}

Unregister_Singleton_And_Update_Expected_Candidates
    [Arguments]    ${member_index}
    [Documentation]    Unregister the singleton candidate. Also remove it from the list of ${cs_exp_candidates}.
    MdsalLowlevel.Unregister_Singleton_Constant    ${member_index}
    Collections.Remove_Values_From_List    ${cs_exp_candidates}    ${member_index}

Verify_Owner_And_Candidates_Stable
    [Arguments]    ${owner_index}
    [Documentation]    Fail if the actual owner is different from ${owner_index} or if the actual candidate list is different from ${cs_exp_candidates}.
    ${actual_owner}    ${actual_candidates}    ClusterManagement.Check_Old_Owner_Stays_Elected_For_Device    ${CS_DEVICE_NAME}    ${CS_DEVICE_TYPE}    ${owner_index}    ${owner_index}
    Collections.Lists_Should_Be_Equal    ${cs_exp_candidates}    ${actual_candidates}

Monitor_Owner_And_Candidates_Stability
    [Arguments]    ${monitoring_duration}    ${owner_index}
    [Documentation]    Verify that the owner remains on the same node after non-owner candidate is unregistered.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${monitoring_duration}    3s    Verify_Owner_And_Candidates_Stable    ${owner_index}

Register_Singleton_Constant_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Register a candidate application on given nodes.
    FOR    ${index}    IN    @{index_list}
        Register_Singleton_And_Update_Expected_Candidates    ${index}    ${CS_CONSTANT_PREFIX}${index}
    END

Unregister_Singleton_Constant_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Unregister the application from given nodes.
    FOR    ${index}    IN    @{index_list}
        Unregister_Singleton_And_Update_Expected_Candidates    ${index}
    END

Get_And_Save_Present_CsOwner_And_CsCandidates
    [Arguments]    ${node_to_ask}
    [Documentation]    Store owner index into suite variables.
    ${cs_owner}    ${cs_candidates}    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${CS_DEVICE_NAME}    ${CS_DEVICE_TYPE}    ${node_to_ask}
    BuiltIn.Set_Suite_Variable    ${cs_owner}
    BuiltIn.Set_Suite_Variable    ${cs_candidates}
    BuiltIn.Return_From_Keyword    ${cs_owner}    ${cs_candidates}

Verify_Singleton_Constant_On_Node
    [Arguments]    ${node_to_ask}    ${cs_exp_constant}
    [Documentation]    Verify that the expected constant is return from the given node.
    ${constant} =    MdsalLowlevel.Get_Singleton_Constant    ${node_to_ask}
    BuiltIn.Should_Be_Equal    ${cs_exp_constant}    ${constant}

Verify_Singleton_Constant_On_Nodes
    [Arguments]    ${index_list}    ${cs_exp_constant}
    [Documentation]    Iterate over all cluster nodes and all should return expected constant.
    FOR    ${index}    IN    @{index_list}
        Verify_Singleton_Constant_On_Node    ${index}    ${cs_exp_constant}
    END

Verify_Singleton_Constant_During_Isolation
    [Documentation]    Iterate over all non-isolated cluster nodes. They should return the correct constant.
    FOR    ${index}    IN    @{cs_all_indices}
        BuiltIn.Run_Keyword_If    "${index}" == "${cs_isolated_index}"    BuiltIn.Log    Node not triggered, behavior not well described, see bugs 8207, 8214.
        BuiltIn.Run_Keyword_Unless    "${index}" == "${cs_isolated_index}"    Verify_Singleton_Constant_On_Node    ${index}    ${CS_CONSTANT_PREFIX}${cs_owner}
    END

Isolate_Owner_And_Verify_Isolated
    [Documentation]    Isolate the owner cluster node. Wait until the new owner is elected and store new values of owner and candidates.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${cs_owner}
    BuiltIn.Set_Suite_Variable    ${cs_isolated_index}    ${cs_owner}
    ${non_isolated_list} =    ClusterManagement.List_Indices_Minus_Member    ${cs_isolated_index}    member_index_list=${cs_all_indices}
    ${node_to_ask} =    Collections.Get_From_list    ${non_isolated_list}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}    member_index_list=${non_isolated_list}
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    2s    ClusterManagement.Check_New_Owner_Got_Elected_For_Device    ${CS_DEVICE_NAME}    ${CS_DEVICE_TYPE}    ${cs_isolated_index}
    ...    ${node_to_ask}    http_timeout=125
    Get_And_Save_Present_CsOwner_And_CsCandidates    ${node_to_ask}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    3s    Verify_Singleton_Constant_During_Isolation

Rejoin_Node_And_Verify_Rejoined
    [Documentation]    Rejoin isolated node.
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${cs_isolated_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}

Register_Flapping_Singleton_On_Nodes
    [Arguments]    ${index_list}
    [Documentation]    Register a candidate application on each node which starts the test.
    FOR    ${index}    IN    @{index_list}
        MdsalLowlevel.Register_Flapping_Singleton    ${index}
    END

Unregister_Flapping_Singleton_On_Nodes_And_Validate_Results
    [Arguments]    ${index_list}    ${rate_limit_to_pass}    ${test_duration}
    [Documentation]    Unregister the testing service and check recevied statistics.
    ${movements_count} =    BuiltIn.Set_Variable    ${0}
    FOR    ${index}    IN    @{index_list}
        ${count} =    MdsalLowlevel.Unregister_Flapping_Singleton    ${index}
        BuiltIn.Run_Keyword_If    ${count} < 0    BuiltIn.Fail    No failure should have occured during the ${test_duration} timeout.
        ${movements_count} =    BuiltIn.Evaluate    ${movements_count}+${count}
    END
    ${seconds} =    DateTime.Convert_Time    ${test_duration}
    ${rate} =    BuiltIn.Evaluate    ${movements_count}/${seconds}
    BuiltIn.Run_Keyword_If    ${rate} < ${rate_limit_to_pass}    BuiltIn.Fail    Acceptance rate ${rate_limit_to_pass} not reached, actual rate is ${rate}.
