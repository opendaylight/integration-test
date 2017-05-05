*** Settings ***
Documentation     DOMRpcBroker testing: RPC Provider Partition And Heal
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This tests establishes that the RPC service operates correctly when faced
...               with node failures.
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
@{NON_WORKING_RPC_STATUS_CODE}    ${501}

*** Test Cases ***
Register_Rpc_On_Two_Nodes
    [Documentation]    Register rpc on two nodes of the odl cluster.
    DrbCommons.Register_Rpc_On_Nodes    ${INSTALLED_RPC_MEMEBER_IDX_LIST}

Invoke_Rpc_On_Each_Node
    [Documentation]    Invoke get-constant rpc on every node of the cluster. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected.
    DrbCommons.Verify_Constant_On_Active_Nodes

Isolate_One_Node
    [Documentation]    Isolate one node with registered rpc.
    ...    From the constant returned from the ${TESTED_MEMBER_WITHOUT_RPC_IDX} node (with no rpc instance) an index of
    ...    the node to be isolated is derived. And in the tc Invoke_Rpc_On_Remaining_Nodes a different constant
    ...    is expected.
    ${isolated_idx} =    DrbCommons.Get_Constant_Index_From_Node    ${TESTED_MEMBER_WITHOUT_RPC_IDX}
    BuiltIn.Set_Suite_Variable    ${isolated_idx}
    DrbCommons.Isolate_Node    ${isolated_idx}

Invoke_Rpc_On_Isolated_Node
    [Documentation]    Invoke rpc on isolated node. Because rpc is registered on this node, local constant
    ...    is expected.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    DrbCommons.Verify_Constant_On_Registered_Node    ${isolated_idx}

Invoke_Rpc_On_Remaining_Nodes
    [Documentation]    Invoke rpc on non-islolated nodes.
    DrbCommons.Verify_Constant_On_Active_Nodes

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    DrbCommons.Rejoin_Node    ${isolated_idx}

Invoke_Rpc_On_Each_Node_Again
    [Documentation]    Invoke rpc get-constant on every node. When requested on the node with
    ...    local instance the local value is expected. If invoked on the node with no local instance, any remote
    ...    value is expected.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    20s    3s    DrbCommons.Verify_Constant_On_Active_Nodes

Isolate_Member_Without_Registered_Rpc
    [Documentation]    Isolate one node with unregistered rpc.
    DrbCommons.Isolate_Node    ${TESTED_MEMBER_WITHOUT_RPC_IDX}

Verify_Rpc_Fails_On_Isolated_Member_Without_Rpc
    [Documentation]    Rpc should fail as it is requested on isolated node without rpc instance.
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    2s    MdsalLowlevel.Get_Constant    ${TESTED_MEMBER_WITHOUT_RPC_IDX}    explicit_status_codes=${NON_WORKING_RPC_STATUS_CODE}

Rejoin_Isolated_Member_Without_Registered_Rpc
    [Documentation]    Rejoin isolated node.
    DrbCommons.Rejoin_Node    ${TESTED_MEMBER_WITHOUT_RPC_IDX}

Verify_Rpc_Again_Passes_On_Member_Without_Rpc
    [Documentation]    Verify rpc works after the node rejoin.
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    DrbCommons.Verify_Constant_On_Unregistered_Node    ${TESTED_MEMBER_WITHOUT_RPC_IDX}

Unregister_Rpc_On_Each_Node
    [Documentation]    Inregister rpc on both nodes.
    DrbCommons.Unregister_Rpc_On_Nodes    ${INSTALLED_RPC_MEMEBER_IDX_LIST}

*** Keywords ***
Setup_Kw
    [Documentation]    Setup keyword. Create ${possible_constants} list with possible variables of remote constants.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=30
    DrbCommons.DrbCommons_Init
