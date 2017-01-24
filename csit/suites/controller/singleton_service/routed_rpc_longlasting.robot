*** Settings ***
Documentation     Controller functional HA testing of routed rpcs.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
${RPC_URL}        /restconf/operations/basic-rpc-test:basic-global
&{EMPTY_DICT}
${SERVICE}        Basic-rpc-test']
${TEST_DURATION}    10m
${TEST_DELAY}     1s
${TEST_LOG_LEVEL}    info

*** Test Cases ***
Longlasting_Rpc_Tests
    [Documentation]    Run rpc on the service owner.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${TEST_LOG_LEVEL}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${TEST_DURATION}    ${TEST_DELAY}    Tested_Scenario

*** Keywords ***
Tested_Scenario
    [Documentation]    Testing scenario
    Isolation_Scenario
    Kill_Scenario

Isolation_Scenario
    [Documentation]    Isolation scenario
    Get_Owner_And_Successors
    Rpc_On_All_Nodes
    ClusterManagement.Isolate_Member_From_List_Or_All    ${brt_owner}
    Verify_New_Basic_Rpc_Test_Owner_Elected
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_brt_owner}
    Rpc_On_All_Nodes

Kill_Scenario
    [Documentation]    Kill scenario
    Get_Owner_And_Successors
    Rpc_On_All_Nodes
    ClusterManagement.Kill_Single_Member    ${brt_owner}
    Verify_New_Basic_Rpc_Test_Owner_Elected
    ClusterManagement.Start_Single_Member    ${old_brt_owner}
    Rpc_On_All_Nodes

Get_Owner_And_Successors
    [Documentation]    Find a service owner and successors.
    ${brt_owner}    ${brt_successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    ${SERVICE}    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set_Suite_Variable    ${brt_owner}    ${brt_owner}
    BuiltIn.Set_Suite_Variable    ${brt_successors}    ${brt_successors}

Rpc_On_All_Nodes
    [Documentation]    Run rpc on the service owner.
    Rpc_On_Single_Node    ${brt_owner}
    Rpc_On_Nodes_List    ${brt_successors}

Rpc_On_Single_Node
    [Arguments]    ${node_idx}
    Run_Rpc    ${node_idx}

Rpc_On_Nodes_List
    [Arguments]    ${nodes_list}
    : FOR    ${node_idx}    IN    @{nodes_list}
    \    Run_Rpc    ${node_idx}

Verify_New_Basic_Rpc_Test_Owner_Elected
    [Documentation]    Verify new owner of the service is elected.
    ${idx}=    Collections.Get_From_List    ${brt_successors}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_New_Owner_Elected    ${brt_owner}    ${idx}

Verify_New_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    ${SERVICE}    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}
