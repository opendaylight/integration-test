*** Settings ***
Documentation     Cluster Singleton testing: Master Stability
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Cluster Singleton service is designed to ensure that only one instance of an
...               application is registered globally in the cluster.
...               The goal is to establish the service operates correctly in face of application
...               registration changing without moving the active instance.
Suite Setup       Setup_Keyword
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           Collections
Library           SSHLibrary
Resource          ${CURDIR}/CsCommon.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${STABILITY_TIMEOUT}    1m

*** Test Cases ***
Register_Singleton_Constant_On_Each_Node_And_Verify
    [Documentation]    Register a candidate application on each node.
    CsCommon.Register_Singleton_Constant_On_Nodes    ${all_indices}
    ${owner}    ${candidates}=     CsCommon.Get_And_Save_Present_CsOwner_And_CsCandidates    1
    CsCommon.Verify_Singleton_Constant_On_Nodes    ${all_indices}    ${CS_CONSTANT_PREFIX}${owner}

Unregister_Singleton_Constant_On_Non_Master_Node
    [Documentation]    Unregister the application on a non master node.
    ${unregistered_node} =    Get_Node_Idx_To_Unregister
    CsCommon.Unregister_Singleton_And_Update_Expected_Candidates    ${unregistered_node}
    BuiltIn.Set_Suite_Variable    ${unregistered_node}

Monitor_Stability_While_Unregistered
    [Documentation]    Verify that the owner remains on the same node after non-owner candidate is unregistered.
    CsCommon.Monitor_Owner_And_Candidates_Stability    ${STABILITY_TIMEOUT}    ${cs_owner}

Reregister_Singleton_Constant
    [Documentation]    Re-registere the unregistered candidate.
    CsCommon.Register_Singleton_And_Update_Expected_Candidates     ${unregistered_node}    ${CS_CONSTANT_PREFIX}${unregistered_node}

Verify_Stability_After_Reregistration
    [Documentation]    Verify that the owner remains on the same node after the unregistered candidate re-registration.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    5x    3s    CsCommon.Verify_Owner_And_Candidates_Stable    ${cs_owner}

Unregister_Singleton_Constant_On_Each_Node
    [Documentation]    Unregister the application from each node.
    CsCommon.Unregister_Singleton_Constant_On_Nodes    ${all_indices}

*** Keywords ***
Setup_Keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    CsCommon.Cluster_Singleton_Init

Get_Node_Idx_To_Unregister
    [Documentation]    Return the first non owner node from the stored candidate list.
    : FOR    ${index}    IN    @{cs_candidates}
    \    BuiltIn.Return_From_Keyword_If    "${index}" != "${cs_owner}"    ${index}
