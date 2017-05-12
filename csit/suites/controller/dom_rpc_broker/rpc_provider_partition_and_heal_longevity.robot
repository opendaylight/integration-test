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
# TODO: Consider unregistering one at random for each iteration, as in the precedence longevity suite.
${TESTED_MEMBER_WITHOUT_RPC_IDX}    ${3}
${DURATION_24_HOURS_IN_SECONDS}    86400

*** Test Cases ***
Rpc_Provider_Precedence_Longevity
    [Documentation]    Test register rpc on two of three nodes and repeat the tested scenario for 24h.
    DrbCommons.Register_Rpc_On_Nodes    ${INSTALLED_RPC_MEMEBER_IDX_LIST}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${DURATION_24_HOURS_IN_SECONDS}    1s    Test_Scenario
    DrbCommons.Unregister_Rpc_On_Nodes    ${INSTALLED_RPC_MEMEBER_IDX_LIST}

*** Keywords ***
Setup_Kw
    [Documentation]    Setup keyword. Create ${possible_constants} list with possible variables of remote constants.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=30
    DrbCommons.DrbCommons_Init

Test_Scenario
    [Documentation]    Isolate and rejoin one of the registrated nodes while testing expected constants.
    DrbCommons.Verify_Constant_On_Active_Nodes
    ${isolated_idx} =    DrbCommons.Get_Constant_Index_From_Node    ${TESTED_MEMBER_WITHOUT_RPC_IDX}
    DrbCommons.Isolate_Node    ${isolated_idx}
    BuiltIn.Wait_Until_Keyword_Succeeds    45s    1s    DrbCommons.Verify_Constant_On_Active_Nodes
    DrbCommons.Rejoin_Node    ${isolated_idx}
    # Shards are settled, but that does not mean RPC registrations have been synchronized between members yet.
    BuiltIn.Wait_Until_Keyword_Succeeds    5s    1s    DrbCommons.Verify_Constant_On_Active_Nodes
