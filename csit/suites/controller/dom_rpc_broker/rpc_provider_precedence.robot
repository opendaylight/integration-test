*** Settings ***
Documentation     DOMRpcBroker testing: RPC Provider Precedence
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
Suite Setup       Setup_Keyword
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DrbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${UNREGISTERED_RPC_NODE}    ${1}

*** Test Cases ***
Register_Rpc_On_Each_Node
    [Documentation]    Register global rpc on each node of the cluster.
    DrbCommons.Register_Rpc_On_Nodes    ${all_indices}

Invoke_Rpc_On_Each_Node
    [Documentation]    Verify that the rpc response comes from the local node.
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${all_indices}

Unregister_Rpc_On_Node
    [Documentation]    Unregister the rpc on one of the cluster nodes.
    DrbCommons.Unregister_Rpc_And_Update_Possible_Constants    ${UNREGISTERED_RPC_NODE}

Invoke_Rpc_On_Node_With_Unregistered_Rpc
    [Documentation]    Invoke rcp on the node with unregistered rpc. The response is expected
    ...    to come from other nodes where the rpc remained registered.
    DrbCommons.Verify_Constant_On_Unregistered_Node    ${UNREGISTERED_RPC_NODE}

Invoke_Rpc_On_Remaining_Nodes
    [Documentation]    Verify that the rpc response comes from the local node.
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${registered_indices}

Reregister_Rpc_On_Node
    [Documentation]    Reregister the rpc.
    DrbCommons.Register_Rpc_And_Update_Possible_Constants    ${UNREGISTERED_RPC_NODE}

Invoke_Rpc_On_Each_Node_Again
    [Documentation]    Verify that the rpc response comes from the local node.
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${all_indices}

Unregister_Rpc_On_Each_Node
    [Documentation]    Unregister rpc on every node.
    DrbCommons.Unregister_Rpc_On_Nodes    ${all_indices}

*** Keywords ***
Setup_Keyword
    [Documentation]    Create a list of possible constant responses on the node with unregistered rpc.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DrbCommons.DrbCommons_Init
