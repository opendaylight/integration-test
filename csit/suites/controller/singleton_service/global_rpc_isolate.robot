*** Settings ***
Documentation     Controller functional HA testing of global sibgleton rpcs.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup_Suite
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${RPC_URL}        /restconf/operations/basic-rpc-test:basic-global
&{EMPTY_DICT}
${SERVICE}        Basic-rpc-test']
${TEST_LOG_LEVEL}    info
@{TEST_LOG_COMPONENTS}    org.opendaylight.controller.remote.rpc
${EOS_URL}    /restconf/operational/entity-owners:entity-owners
${RPC_STATUS_ISOLATED}    501

*** Test Cases ***
Get_Basic_Rpc_Test_Owner
    [Documentation]    Find a service owner and successors.
    Get_Present_Brt_Owner_And_Successors    1    store=${True}

Rpc_Before_Isolation_On_Owner
    [Documentation]    Run rpc on the service owner.
    Run_Rpc    ${brt_owner}

Rpc_Before_Isolation_On_Successors
    [Documentation]    Run rpc on non owher cluster nodes.
    : FOR    ${idx}    IN    @{brt_successors}
    \    Run_Rpc    ${idx}

Isolate_Current_Owner_Member
    [Documentation]    Isolating cluster node which is the owner.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${brt_owner}
    BuiltIn.Set Suite variable    ${old_brt_owner}    ${brt_owner}
    BuiltIn.Set Suite variable    ${old_brt_successors}    ${brt_successors}

Verify_New_Basic_Rpc_Test_Owner_Elected
    [Documentation]    Verify new owner of the service is elected.
    ${idx}=    Collections.Get_From_List    ${old_brt_successors}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Owner_Elected    ${old_brt_owner}    ${idx}    new_elected=${True}
    Get_Brt_Owner_And_Successors    ${idx}    store=${True}

Rpc_On_Isolated_Node
    [Documentation]    Run rpc on isolated cluster node.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${old_brt_owner}
    ${out} =    TemplatedRequests.Get_From_Uri    ${EOS_URL}    session=${session}
    KarafKeywords.Execute Controller Karaf Command With Retry On Background    log:log ${out}    member_index=${node_idx}
    ${resp} =    RequestsLibrary.Post Request    ${session}    ${RPC_URL}    data=${EMPTY}
    BuiltIn.Should_Be_Equal_As_Numbers     ${resp.status_code}    ${RPC_STATUS_ISOLATED}

Rpc_On_Non_Isolated_Cluster_Nodes
    [Documentation]    Run rpc on remained cluster nodes.
    : FOR    ${idx}    IN    @{old_brt_successors}
    \    Run_Rpc    ${idx}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_brt_owner}

Verify_New_Owner_Remained_After_Rejoin
    [Documentation]    Verify now owner shich happened after rejoin.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    15s    2s     Verify_Owner_Elected     ${brt_owner}    ${brt_owner}      new_elected=${False}

Rpc_After_Rejoin_On_New_Owner
    [Documentation]    Run rpc on the new service owner node.
    Run_Rpc    ${brt_owner}

Rpc_After_Rejoin_On_Old_Owner
    [Documentation]    Run rpc on rejoined cluster node.
    Run_Rpc    ${old_brt_owner}

Rpc_After_Rejoin_On_All
    [Documentation]    Run rpc on the service owner.
    Run_Rpc    ${brt_owner}
    : FOR    ${idx}    IN    @{brt_successors}
    \    Run_Rpc    ${idx}

*** Keywords ***
Setup_Suite
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}     ${TEST_LOG_COMPONENTS}

Run_Rpc
    [Arguments]    ${node_idx}
    [Documentation]    Run rpc and log the entity ownership service details to karaf log
    ${session} =    Resolve_Http_Session_For_Member    member_index=${node_idx}
    ${out} =    TemplatedRequests.Get_From_Uri    ${EOS_URL}    session=${session}
    KarafKeywords.Execute Controller Karaf Command With Retry On Background    log:log ${out}    member_index=${node_idx}
    TemplatedRequests.Post_To_Uri    ${RPC_URL}    ${EMPTY}    ${EMPTY_DICT}    ${EMPTY_DICT}    session=${session}

Verify_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}    ${new_elected}=${True}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${successors}=    Get_Brt_Owner_And_Successors    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}

Get_Brt_Owner_And_Successors
    [Arguments]    ${node_to_ask}    ${store}=${False}
    [Documentation]    Find a basic rpc test service owner and successors and store them if indicated
    ${brt_owner}    ${brt_successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    ${SERVICE}    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${brt_owner}    ${brt_owner}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${brt_successors}    ${brt_successors}
    BuiltIn.Return_From_Keyword    ${brt_owner}    ${brt_successors}
