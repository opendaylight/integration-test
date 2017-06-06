*** Settings ***
Documentation     DOMRpcBroker testing: RPC Action Provider Partition And Heal
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This tests establishes that the RPC service for actions operates correctly
...               when faced with node failures.
...               This suite supports more than three node cluster setup too.
Suite Setup       Setup_Kw
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DrbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
@{INSTALLED_RPC_MEMEBER_IDX_LIST}    ${1}    ${2}
${TESTED_MEMBER_WITHOUT_RPC_IDX}    ${3}

*** Test Cases ***
Register_Rpc_On_Two_Nodes
    [Documentation]    Register rpc on two nodes of the odl cluster.
    DrbCommons.Register_Action_On_Nodes    ${INSTALLED_RPC_MEMEBER_IDX_LIST}

Invoke_Rpc_On_Each_Node
    [Documentation]    Invoke get-contexted-constant rpc on every node of the cluster. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected. From the constant returned from the ${TESTED_MEMBER_WITHOUT_RPC_IDX} node (with no rpc instance) an index of
    ...    the node to be isolated is derived. And in the tc Invoke_Rpc_On_Remaining_Nodes a different constant
    ...    is expected. The second for loop makes the suite suitable for more that 3 nodes cluster.
    DrbCommons.Verify_Contexted_Constant_On_Active_Nodes

Isolate_One_Node
    [Documentation]    Isolate one node with registered rpc.
    ${isolated_idx} =    DrbCommons.Get_Contexted_Constant_Index_From_Node    ${TESTED_MEMBER_WITHOUT_RPC_IDX}
    BuiltIn.Set_Suite_Variable    ${isolated_idx}
    DrbCommons.Isolate_Node    ${isolated_idx}

Invoke_Rpc_On_Remaining_Nodes
    [Documentation]    Invoke rpc on non-islolated nodes. As the only instance of rpc remained in the non-isolated
    ...    cluster nodes, only this value is expected.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    DrbCommons.Verify_Contexted_Constant_On_Active_Nodes

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    DrbCommons.Rejoin_Node    ${isolated_idx}

Invoke_Rpc_On_Each_Node_Again
    [Documentation]    Invoke rpc get-contexted-constant on every node. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    20s    3s    DrbCommons.Verify_Contexted_Constant_On_Active_Nodes

Unregister_Rpc_On_Each_Node
    [Documentation]    Inregister rpc on both nodes.
    DrbCommons.Unregister_Action_On_Nodes    ${INSTALLED_RPC_MEMEBER_IDX_LIST}

*** Keywords ***
Setup_Kw
    [Documentation]    Setup keyword. Create ${possible_constants} list with possible variables of remote constants.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
    DrbCommons.DrbCommons_Init
