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
#${DURATION_24_HOURS_IN_SECONDS}    86400
${DURATION_24_HOURS_IN_SECONDS}    180

*** Test Cases ***
Rpc_Provider_Precedence_Longevity
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${DURATION_24_HOURS_IN_SECONDS}    1s    Test_Scenario

*** Keywords ***
Setup_Keyword
    [Documentation]    Create a list of possible constant responses on the node with unregistered rpc.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DrbCommons.DrbCommons_Init

Test_Scenario
    DrbCommons.Register_Rpc_On_Nodes    ${all_indices}
    ${unregistered_rpc_node} =    BuiltIn.Evaluate    random.choice(${all_indices})    modules=random
    ${unregistered_rpc_node} =    BuiltIn.Convert_To_Integer    ${unregistered_rpc_node}
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${all_indices}
    DrbCommons.Unregister_Rpc_And_Update_Possible_Constants    ${unregistered_rpc_node}
    DrbCommons.Verify_Constant_On_Unregistered_Node    ${unregistered_rpc_node}
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${registered_indices}
    DrbCommons.Register_Rpc_And_Update_Possible_Constants    ${unregistered_rpc_node}
    DrbCommons.Verify_Constant_On_Registered_Nodes    ${all_indices}
    DrbCommons.Unregister_Rpc_On_Nodes    ${all_indices}
