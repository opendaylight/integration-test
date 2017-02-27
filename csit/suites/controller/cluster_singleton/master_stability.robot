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
${CONSTANT}       test-constant
${DEVICE_NAME}    get-singleton-constant-service']
${DEVICE_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${STABILITY_TIMEOUT}    1m

*** Test Cases ***
Register_Singleton_Constant_On_Each_Node
    [Documentation]    Register a candidate application on each node.
    ${index_list} =    ClusterManagement.List_All_Indices
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Register_Singleton_Constant    ${index}    ${CONSTANT}

Get_And_Store_Owner_And_Candidates
    [Documentation]    Store owner and candidates for the tested service into suite variables.
    ${owner}    ${candidates}    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${DEVICE_NAME}    ${DEVICE_TYPE}    1
    BuiltIn.Set_Suite_Variable    ${owner}
    Collections.Sort_List    ${candidates}
    BuiltIn.Set_Suite_Variable    ${candidates}

Unregister_Singleton_Constant_On_Non_Master_Node
    [Documentation]    Unregister the application on a non master node.
    ${unregistered_node} =    Get_Node_Idx_To_Unregister
    MdsalLowlevel.Unregister_Singleton_Constant    ${unregistered_node}
    BuiltIn.Set_Suite_Variable    ${unregistered_node}
    Collections.Remove_Values_From_List    ${candidates}    ${unregistered_node}

Monitor_Stability_While_Unregistered
    [Documentation]    Verify that the owner remains on the same node after non-owner candidate is unregistered.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT}    3s    Verify_Owner_And_Candidates_Stable

Reregister_Singleton_Constant
    [Documentation]    Re-registere the unregistered candidate.
    MdsalLowlevel.Register_Singleton_Constant    ${unregistered_node}    ${CONSTANT}
    Collections.Append_To_List    ${candidates}    ${unregistered_node}
    Collections.Sort_List    ${candidates}

Verify_Stability_After_Reregistration
    [Documentation]    Verify that the owner remains on the same node after the unregistered candidate re-registration.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    5x    3s    Verify_Owner_And_Candidates_Stable

Unregister_Singleton_Constant_On_Each_Node
    [Documentation]    Unregister the application from each node.
    ${index_list} =    ClusterManagement.List_All_Indices
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Unregister_Singleton_Constant    ${index}

*** Keywords ***
Verify_Owner_And_Candidates_Stable
    [Documentation]    Varify the owner stability by checking the presnet owner and candidate values with the one stored in suite
    ...    variables at the beginning (Get_And_Store_Owner_And_Candidates tc) os the suite.
    ${owner2}    ${candidates2}    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${DEVICE_NAME}    ${DEVICE_TYPE}    ${owner}
    BuiltIn.Should_Be_Equal    ${owner}    ${owner2}
    Collections.Sort_List    ${candidates2}
    BuiltIn.Should_Be_Equal    ${candidates}    ${candidates2}

Get_Node_Idx_To_Unregister
    [Documentation]    Return the first non owner node from the candidate list.
    : FOR    ${cindex}    IN    @{candidates}
    \    BuiltIn.Return_From_Keyword_If    "${cindex}" != "${owner}"    ${cindex}
