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
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${CONSTANT_PREFIX}    constant-
${DEVICE_NAME}    get-singleton-constant-service']
${DEVICE_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${GSC_URL}        /restconf/operations/odl-mdsal-lowlevel-target:get-singleton-constant
${STABILITY_TIMEOUT_ISOLATED}    30s
${STABILITY_TIMEOUT_REJOINED}    15s
@{STATUS_ISOLATED}    501

*** Test Cases ***
Register_Singleton_Constant_On_Each_Node
    [Documentation]    Register a candidate application on each node.
    : FOR    ${index}    IN    @{all_indices}
    \    MdsalLowlevel.Register_Singleton_Constant    ${index}    ${CONSTANT_PREFIX}${index}

Verify_Singleton_Constant_On_Each_Node
    [Documentation]    Store the owner and candidates of the application and initially verify that all
    ...    odl nodes are used.
    Get_Present_Singleton_Owner_And_Candidates    1    store=${True}
    BuiltIn.Should_Be_Equal    ${all_indices}    ${scandidates}
    Verify_Stability_While_Complete_Cluster

Isolate_Owner_Node
    [Documentation]    Isolate the cluster node which is the owner. Wait until the new owner is elected and store
    ...    new values of owner and candidates.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${sowner}
    Collections.Remove_Values_From_List    ${scandidates}    ${sowner}
    ${node_to_ask} =    Collections.Get_From_list    ${scandidates}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Verify_Singleton_Instance_Owner_Elected    ${DEVICE_NAME}    ${DEVICE_TYPE}    ${True}    ${sowner}    ${node_to_ask}
    BuiltIn.Set_Suite_Variable    ${isolated_node}    ${sowner}
    Get_Present_Singleton_Owner_And_Candidates    ${node_to_ask}    store=${True}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Expected_Response_On_Isolated_Node    ${isolated_node}

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
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_REJOINED}    3s    Verify_Stability_While_Complete_Cluster

Unregister_Singleton_Constant_On_Each_Node
    [Documentation]    Unregister the application on every node.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Unregister_Singleton_Constant    ${index}

*** Keywords ***
Setup_Keyword
    [Documentation]    Suite setup.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${all_indices} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${all_indices}

Get_Present_Singleton_Owner_And_Candidates
    [Arguments]    ${node_to_ask}    ${store}=${False}
    ${master}    ${candidates}=    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${DEVICE_NAME}    ${DEVICE_TYPE}    ${node_to_ask}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${sowner}    ${master}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${scandidates}    ${candidates}
    BuiltIn.Return_From_Keyword    ${master}    ${candidates}

Verify_Expected_Constant
    [Arguments]    ${node_to_ask}    ${exp_constant}
    ${constant} =    MdsalLowlevel.Get_Singleton_Constant    ${node_to_ask}
    BuiltIn.Should_Be_Equal    ${exp_constant}    ${constant}

Verify_Stability_During_Isolation
    : FOR    ${index}    IN    @{all_indices}
    \    BuiltIn.Run_Keyword_If    "${index}" == "${isolated_node}"    MdsalLowlevel.Get_Singleton_Constant    ${index}    explicit_status_codes=${STATUS_ISOLATED}
    \    BuiltIn.Run_Keyword_Unless    "${index}" == "${isolated_node}"    Verify_Expected_Constant    ${index}    ${CONSTANT_PREFIX}${sowner}

Verify_Stability_While_Complete_Cluster
    : FOR    ${index}    IN    @{all_indices}
    \    Verify_Expected_Constant    ${index}    ${CONSTANT_PREFIX}${sowner}
