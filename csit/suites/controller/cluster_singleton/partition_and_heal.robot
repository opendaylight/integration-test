*** Settings ***
Documentation     Cluster Singleton testing: Partition And Heal
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Cluster Singleton service is designed to ensure that only one instance of
...               an application is registered globally in the cluster.
...               The goal is to establish the service operates correctly in face of node
...               failures.
Suite Setup       Setup_Keyword
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Resource          ${CURDIR}/CsCommon.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${CONSTANT_PREFIX}    constant-
${STABILITY_TIMEOUT_ISOLATED}    30s
${STABILITY_TIMEOUT_REJOINED}    15s
@{STATUS_ISOLATED}    ${501}

*** Test Cases ***
Register_Singleton_Constant_On_Each_Node
    [Documentation]    Register a candidate application on each node.
    CsCommon.Register_Singleton_Constant_On_Nodes    ${all_indices}    ${CONSTANT_PREFIX}

Verify_Singleton_Constant_On_Each_Node
    [Documentation]    Store the owner and candidates of the application and initially verify that all
    ...    odl nodes are used.
    ${owner}    ${candidates}=     CsCommon.Get_And_Save_Present_CsOwner_And_CsCandidates    1
    CsCommon.Verify_Singleton_Constant_On_Nodes    ${all_indices}    ${CONSTANT_PREFIX}${owner}

Isolate_Owner_Node
    [Documentation]    Isolate the cluster node which is the owner. Wait until the new owner is elected and store
    ...    new values of owner and candidates.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${sowner}
    Collections.Remove_Values_From_List    ${scandidates}    ${sowner}
    ${node_to_ask} =    Collections.Get_From_list    ${scandidates}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Verify_Owner_Elected_For_Device    ${DEVICE_NAME}    ${DEVICE_TYPE}    ${True}
    ...    ${sowner}    ${node_to_ask}
    BuiltIn.Set_Suite_Variable    ${isolated_node}    ${sowner}
    Get_Present_Singleton_Owner_And_Candidates    ${node_to_ask}    store=${True}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    MdsalLowlevel.Get_Singleton_Constant    ${isolated_node}    explicit_status_codes=${STATUS_ISOLATED}

Monitor_Stability_While_Isolated
    [Documentation]    Monitor the stability of the singleton application and fail the the owner is changed during the monitoring.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_ISOLATED}    3s    Verify_Stability_During_Isolation

Rejoin_Isolated_node
    [Documentation]    Rejoin isolated node.
    [Tags]    @{NO_TAGS}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${isolated_node}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    MdsalLowlevel.Get_Singleton_Constant    ${isolated_node}

Verify_Stability_After_Reregistration
    [Documentation]    Verify that the rejoining of the isolated node does not change the singleton owner.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_REJOINED}    3s    CsCommon.Verify_Singleton_Constant_On_Nodes    ${all_indices}    ${CONSTANT_PREFIX}${sowner}

Unregister_Singleton_Constant_On_Each_Node
    [Documentation]    Unregister the application on every node.
    CsCommon.Unregister_Singleton_Constant_On_Nodes    ${all_indices}

*** Keywords ***
Setup_Keyword
    [Documentation]    Suite setup.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    CsCommon.Cluster_Singleton_Init

Verify_Stability_During_Isolation
    : FOR    ${index}    IN    @{all_indices}
    \    BuiltIn.Run_Keyword_If    "${index}" == "${isolated_node}"    MdsalLowlevel.Get_Singleton_Constant    ${index}    explicit_status_codes=${STATUS_ISOLATED}
    \    BuiltIn.Run_Keyword_Unless    "${index}" == "${isolated_node}"    Verify_Expected_Constant    ${index}    ${CONSTANT_PREFIX}${sowner}
