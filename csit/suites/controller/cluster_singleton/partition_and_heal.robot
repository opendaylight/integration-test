*** Settings ***
Documentation     Cluster Singleton testing: Partition And Heal
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The goal is to establish the service operates correctly in face of node
...               failures.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           Collections
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${CONSTANT_PREFIX}    constant-
${DEVICE_NAME}    get-singleton-constant-service']
${DEVICE_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${STABILITY_TIMEOUT_ISOLATED}     30s
${STABILITY_TIMEOUT_REJOINED}     15s

*** Test Cases ***
Register_Singleton_Constant_On_Each_Node
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Register_Singleton_Constant    ${index}    ${CONSTANT_PREFIX}${index}

Verify_Singleton_Constant_On_Each_Node
    Get_Present_Singleton_Master_And_Candidates    1    store=${True}
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    BuiltIn.Should_Be_Equal    ${index_list}    ${scandidates}
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    MdsalLowlevel.Get_Singleton_Constant    ${index}
    \    BuiltIn.Should_Be_Equal    ${CONSTANT_PREFIX}${smaster}    ${constant}

Isolate_Master_Node
    [Documentation]    Isolating cluster node which is the owner.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${smaster}
    Collections.Remove_Values_From_List    ${scandidates}    ${smaster}
    ${node_to_ask} =     Collections.Get_From_list    ${scandidates}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Master    ${True}    ${smaster}    ${node_to_ask}
    BuiltIn.Set_Suite_Variable    ${isolated_node}    ${smaster}
    Get_Present_Singleton_Master_And_Candidates    ${node_to_ask}    store=${True}

Monitor_Stability_While_Isolated
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_ISOLATED}    3s    Verify_Master_And_Candidates_Stable

Rejoin_Isolated_node
    [Documentation]    Rejoin isolated node
    [Tags]    @{NO_TAGS}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${isolated_node}

Verify_Stability_After_Reregistration
    Verify_Master_And_Candidates_Stable

Unregister_Singleton_Constant_On_Each_Node
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Unregister_Singleton_Constant    ${index}

*** Keywords ***
Verify_Master
    [Arguments]    ${new_elected}    ${old_master}    ${node_to_ask}
    ${master}    ${candidates}    Get_Present_Singleton_Master_And_Candidates    ${node_to_ask}
    BuiltIn.Run_Keyword_If    ${new_elected}    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_master}    ${master}
    BuiltIn.Run_Keyword_Unless    ${new_elected}    BuiltIn.Should_Be_Equal_As_numbers    ${old_master}    ${master}

Get_Present_Singleton_Master_And_Candidates
    [Arguments]    ${node_to_ask}    ${store}=${False}
    ${master}    ${candidates}=    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${DEVICE_NAME}     ${DEVICE_TYPE}    ${node_to_ask}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${smaster}    ${master}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${scandidates}    ${candidates}
    BuiltIn.Return_From_Keyword    ${master}    ${candidates}

Verify_Expected_Constant
    [Arguments]    ${node_to_ask}    ${exp_constant}    ${is_isolated}=${False}
    ${constant} =    MdsalLowlevel.Get_Singleton_Constant    ${node_to_ask}
    BuiltIn.Should_Be_Equal    ${CONSTANT_PREFIX}${smaster}    ${constant}

Verify_Master_And_Candidates_Stable
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    BuiltIn.Run_Keyword_If    "${index}" == "${isolated_node}"    
    \    BuiltIn.Run_Keyword_Unless    "${index}" == "${isolated_node}"

