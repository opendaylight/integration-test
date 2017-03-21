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
...               This suite supports more than three node cluster setup too.
Suite Setup       Setup_Kw
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DrbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
#${DURATION_24_HOURS_IN_SECONDS}    86400
${DURATION_24_HOURS_IN_SECONDS}    180
@{NON_WORKING_RPC_STATUS_CODE}    ${501}

*** Test Cases ***
Rpc_Provider_Precedence_Longevity
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${DURATION_24_HOURS_IN_SECONDS}    1s    Test_Scenario

*** Keywords ***
Setup_Kw
    [Documentation]    Setup keyword. Create ${possible_constants} list with possible variables of remote constants.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DrbCommons.DrbCommons_Init

Test_Scenario
    Setup_Test_Scenarion_Variables
    DrbCommons.Register_Rpc_On_Nodes    ${installed_rpc_member_idx_list}
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${installed_rpc_member_idx_list}
    DrbCommons.Verify_Constant_On_Unregistered_Nodes    ${non_installed_rpc_member_idx_list}
    ${constant}    ${isolated_idx} =    DrbCommons.Get_Constant_And_Member_Index_From_Node    ${tested_member_without_rpc_idx}
    BuiltIn.Set_Suite_Variable    ${isolated_idx}
    DrbCommons.Isolate_Node    ${isolated_idx}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    DrbCommons.Verify_Constant_On_Registered_Node    ${isolated_idx}
    ${index_list} =    ClusterManagement.List_Indices_Minus_Member    ${isolated_idx}    ${all_indices}
    DrbCommons.Verify_Constant_On_Unregistered_Nodes    ${index_list}
    DrbCommons.Rejoin_Node    ${isolated_idx}
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${installed_rpc_member_idx_list}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    20s    3s    DrbCommons.Verify_Constant_On_Unregistered_Nodes    ${non_installed_rpc_member_idx_list}
    DrbCommons.Isolate_Node    ${tested_member_without_rpc_idx}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    2s    MdsalLowlevel.Get_Constant    ${tested_member_without_rpc_idx}    explicit_status_codes=${NON_WORKING_RPC_STATUS_CODE}
    DrbCommons.Rejoin_Node    ${tested_member_without_rpc_idx}
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    DrbCommons.Verify_Constant_On_Unregistered_Node    ${tested_member_without_rpc_idx}
    DrbCommons.Unregister_Rpc_On_Nodes    ${installed_rpc_member_idx_list}

Setup_Test_Scenarion_Variables
    [Documentation]    Create ${possible_constants} list with possible variables of remote constants.
    ${idx1}   ${idx2}    ${idx3} =    BuiltIn.Evaluate    random.sample(${all_indices}, 3)    modules=random
    ${installed_rpc_member_idx_list}    BuiltIn.Create_list    ${idx1}    ${idx2}
    BuiltIn.Set_Suite_Variable    ${installed_rpc_member_idx_list}
    BuiltIn.Set_Suite_Variable    ${tested_member_without_rpc_idx}    ${idx3}
    ${non_installed_rpc_member_idx_list} =    ClusterManagement.List_All_Indices
    : FOR    ${index}    IN    @{installed_rpc_member_idx_list}
    \    ${non_installed_rpc_member_idx_list} =    ClusterManagement.List_Indices_Minus_Member    ${index}    ${non_installed_rpc_member_idx_list}
    BuiltIn.Set_Suite_Variable    ${non_installed_rpc_member_idx_list}
