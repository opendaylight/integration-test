*** Settings ***
Documentation     DOMRpcBroker longevity testing: RPC Provider Precedence
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The aim is to establish that remote RPC implementations have lower priority
...               than local ones, which is to say that any movement of RPCs on remote nodes
...               does not affect routing as long as a local implementation is available.
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

*** Variables ***
${CONSTANT_PREFIX}    constant-
${TEST_DURATION}     10m

*** Test Cases ***
Rpc_Provider_Precedence_Longevity
    Verify_Keyword_Does_Not_Fail_Within_Timeout    ${TEST_DURATION}    1s    Test_Scenario

*** Keywords ***
Setup_Test_Variables
    [Documentation]    Create a list of possible constant responses on the node with unregistered rpc.
    ${full_cluster_index_list} =    ClusterManagement.List_All_Indices
    BuiltIn.Set_Suite_Variable    ${full_cluster_index_list}
    ${UNREGISTERED_RPC_NODE}
    ${allowed_values} =    BuiltIn.Create_List
    ${allowed_index_list} =    ClusterManagement.List_Indices_Minus_Member    ${UNREGISTERED_RPC_NODE}    ${full_cluster_index_list}
    : FOR    ${index}    IN    @{allowed_index_list}
    \    Collections.Append_To_List    ${allowed_values}    ${CONSTANT_PREFIX}${index}
    BuiltIn.Set_Suite_Variable    ${allowed_index_list}
    BuiltIn.Set_Suite_Variable    ${allowed_values}

Register_Rpc_On_Each_Node
    [Documentation]    Register global rpc on each node of the cluster.
    : FOR    ${index}    IN    @{full_cluster_index_list}
    \    MdsalLowlevel.Register_Constant    ${index}    ${CONSTANT_PREFIX}${index}

Invoke_Rpc_On_Each_Node
    [Documentation]    Verify that the rpc response comes from the local node.
    : FOR    ${index}    IN    @{full_cluster_index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${index}    ${constant}

Unregister_Rpc_On_Node
    [Documentation]    Unregister the rpc on one of the cluster nodes.
    MdsalLowlevel.Unregister_Constant    ${UNREGISTERED_RPC_NODE}

Invoke_Rpc_On_Node_With_Unregistered_Rpc
    [Documentation]    Invoke rcp on the node with unregistered rpc. The response is expected
    ...    to come from other nodes where the rpc remained registered.
    ${constant} =    MdsalLowlevel.Get_Constant    ${UNREGISTERED_RPC_NODE}
    Collections.List_Should_Contain_Value    ${allowed_values}    ${constant}

Invoke_Rpc_On_Remaining_Nodes
    [Documentation]    Verify that the rpc response comes from the local node.
    : FOR    ${index}    IN    @{allowed_index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${index}    ${constant}

Reregister_Rpc_On_Node
    [Documentation]    Reregister the rpc.
    MdsalLowlevel.Register_Constant    ${UNREGISTERED_RPC_NODE}    ${CONSTANT_PREFIX}${UNREGISTERED_RPC_NODE}

Invoke_Rpc_On_Each_Node_Again
    [Documentation]    Verify that the rpc response comes from the local node.
    : FOR    ${index}    IN    @{full_cluster_index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal_As_Strings    ${CONSTANT_PREFIX}${index}    ${constant}

Unregister_Rpc_On_Each_Node
    [Documentation]    Unregister rpc on every node.
    : FOR    ${index}    IN    @{full_cluster_index_list}
    \    MdsalLowlevel.Unregister_Constant    ${index}

Test_Scenario
    Setup_Test_Variables
    Register_Rpc_On_Each_Node
    Invoke_Rpc_On_Each_Node
    Unregister_Rpc_On_Node
    Invoke_Rpc_On_Node_With_Unregistered_Rpc
    Invoke_Rpc_On_Remaining_Nodes
    Reregister_Rpc_On_Node
    Invoke_Rpc_On_Each_Node_Again
    Unregister_Rpc_On_Each_Node
