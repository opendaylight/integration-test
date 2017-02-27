*** Settings ***
Documentation     Cluster Singleton testing: Master Stability
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
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
${CONSTANT}    test-constant
${DEVICE_NAME}    get-singleton-constant-service']
${DEVICE_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${STABILITY_TIMEOUT}     1m

*** Test Cases ***
Register_Singleton_Constant_On_Each_Node
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Register_Singleton_Constant    ${index}    ${CONSTANT}

Get_And_Store_Master_And_Candidates
    ${master}    ${candidates}    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${DEVICE_NAME}     ${DEVICE_TYPE}    1
    BuiltIn.Set_Suite_Variable    ${master}
    BuiltIn.Set_Suite_Variable    ${candidates}

Unregister_Singleton_Constant_On_Non_Master_Node
    ${unregistered_node} =     Collections.Get_From_List    ${candidates}    0
    MdsalLowlevel.Unregister_Singleton_Constant    ${unregistered_node}
    BuiltIn.Set_Suite_Variable    ${unregistered_node}

Monitor_Stability_While_Unregistered
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT}    3s    Verify_Master_And_Candidates_Stable

Reregister_Singleton_Constant
    MdsalLowlevel.Register_Singleton_Constant    ${unregistered_node}

Verify_Stability_After_Reregistration
    Verify_Master_And_Candidates_Stable

Unregister_Singleton_Constant_On_Each_Node
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Unregister_Singleton_Constant    ${index}

*** Keywords ***
Verify_Master_And_Candidates_Stable
    ${master2}    ${candidates2}    ClusterManagement.Get_Owner_And_Candidates_For_Device    ${DEVICE_NAME}     ${DEVICE_TYPE}    ${master}
    BuiltIn.Should_Be_Equal    ${master}     ${master2}
    BuiltIn.Should_Be_Equal    ${candidates}    ${candidates2}

