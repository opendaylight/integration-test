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
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library     Collections
Library     SSHLibrary
Resource    ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource    ${CURDIR}/../../../libraries/SetupUtils.robot
Resource    ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${NODE1_CONSTANT}    constant1
${NODE2_CONSTANT}    constant2
${NODE3_CONSTANT}    constant3


*** Test Cases ***
Register_Rpc_On_Each_Node
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Register_Constant    ${index}    ${NODE${index}_CONSTANT}

Invoke_Rpc_On_Each_Node
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal    "${NODE${index}_CONSTANT}"    ${constant}

Unregister_Rpc_On_Node1
    MdsalLowlevel.Unregister_Constant    1

Invoke_Rpc_On_Node1
    ${allowed_values} =    BuiltIn.Create_List    ${NODE2_CONSTANT}    ${NODE3_CONSTANT}
    ${constant} =    MdsalLowlevel.Get_Constant   1
    Collections.List_Should_Contain_Value    ${allowed_values}    ${constant}

Invoke_Rpc_On_Remaining_Nodes
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    Continue For Loop If    "${index}" == "1"
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal    "${NODE${index}_CONSTANT}"    ${constant}

Reregister_Rpc_On_Node1
    MdsalLowlevel.Register_Constant    1    ${NODE1_CONSTANT}

Invoke_Rpc_On_Each_Node_Again
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List
    : FOR    ${index}    IN    @{index_list}
    \    ${constant} =    MdsalLowlevel.Get_Constant    ${index}
    \    BuiltIn.Should_Be_Equal    "${NODE${index}_CONSTANT}"    ${constant}


