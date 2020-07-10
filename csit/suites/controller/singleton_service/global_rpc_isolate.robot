*** Settings ***
Documentation     Controller functional HA testing of global singleton rpcs.
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
Default Tags      critical
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ShardStability.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${RPC_URL}        /restconf/operations/basic-rpc-test:basic-global
&{EMPTY_DICT}
${SERVICE}        Basic-rpc-test']
${TEST_LOG_LEVEL}    info
@{TEST_LOG_COMPONENTS}    org.opendaylight.controller.remote.rpc
${EOS_URL}        /restconf/operational/entity-owners:entity-owners
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
    FOR    ${idx}    IN    @{brt_successors}
        Run_Rpc    ${idx}
    END

Isolate_Current_Owner_Member
    [Documentation]    Isolating cluster node which is the owner.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${brt_owner}
    BuiltIn.Set Suite variable    ${old_brt_owner}    ${brt_owner}
    BuiltIn.Set Suite variable    ${old_brt_successors}    ${brt_successors}

Verify_New_Basic_Rpc_Test_Owner_Elected
    [Documentation]    Verify new owner of the service is elected.
    ${idx}=    Collections.Get_From_List    ${old_brt_successors}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}    member_index_list=${old_brt_successors}
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Verify_Owner_Elected    ${True}    ${old_brt_owner}    ${idx}
    Get_Present_Brt_Owner_And_Successors    ${idx}    store=${True}

Rpc_On_Isolated_Node
    [Documentation]    Run rpc on isolated cluster node.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${old_brt_owner}
    BuiltIn.Run_Keyword_And_Ignore_Error    Get_And_Log_EOS_Output_To_Karaf_Log    ${session}
    BuiltIn.Pass_Execution    Rpc on isolated node may work for some time(bug 8207), then will fail (bug 8214)
    ${resp} =    RequestsLibrary.Post Request    ${session}    ${RPC_URL}    data=${EMPTY}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    ${RPC_STATUS_ISOLATED}

Rpc_On_Non_Isolated_Cluster_Nodes
    [Documentation]    Run rpc on remained cluster nodes.
    FOR    ${idx}    IN    @{old_brt_successors}
        BuiltIn.Wait_Until_Keyword_Succeeds    60s    5s    Run_Rpc    ${idx}
    END

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_brt_owner}
    BuiltIn.Wait_Until_Keyword_Succeeds    70s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}

Rpc_After_Rejoin_On_New_Owner
    [Documentation]    Run rpc on the new service owner node.
    Run_Rpc    ${brt_owner}

Rpc_After_Rejoin_On_Old_Owner
    [Documentation]    Run rpc on rejoined cluster node.
    Run_Rpc    ${old_brt_owner}

Rpc_After_Rejoin_On_All
    [Documentation]    Run rpc again on all nodes.
    Run_Rpc    ${brt_owner}
    FOR    ${idx}    IN    @{brt_successors}
        Run_Rpc    ${idx}
    END

*** Keywords ***
Setup_Suite
    [Documentation]    FIXME: Add a documentation.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=30
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}    ${TEST_LOG_COMPONENTS}

Run_Rpc
    [Arguments]    ${node_idx}
    [Documentation]    Run rpc and log the entity ownership service details to karaf log.
    ...    Logging the details was a developer's request during the implementation to improve debugging.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${node_idx}
    Get_And_Log_EOS_Output_To_Karaf_Log    ${session}
    TemplatedRequests.Post_To_Uri    ${RPC_URL}    ${EMPTY}    ${HEADERS_XML}    ${ACCEPT_XML}    session=${session}

Verify_Owner_Elected
    [Arguments]    ${new_elected}    ${old_owner}    ${node_to_ask}
    [Documentation]    Verify new owner was elected or remained the same.
    ${owner}    ${successors}=    Get_Present_Brt_Owner_And_Successors    ${node_to_ask}
    BuiltIn.Run_Keyword_If    ${new_elected}    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_owner}    ${owner}
    BuiltIn.Run_Keyword_Unless    ${new_elected}    BuiltIn.Should_Be_Equal_As_numbers    ${old_owner}    ${owner}

Get_Present_Brt_Owner_And_Successors
    [Arguments]    ${node_to_ask}    ${store}=${False}
    [Documentation]    Find a basic rpc test service owner and successors and store them if indicated.
    ${brt_owner}    ${brt_successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    ${SERVICE}    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${brt_owner}    ${brt_owner}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${brt_successors}    ${brt_successors}
    BuiltIn.Return_From_Keyword    ${brt_owner}    ${brt_successors}

Get_And_Log_EOS_Output_To_Karaf_Log
    [Arguments]    ${session}
    [Documentation]    Log the entity ownership service details to karaf.log
    ${out} =    TemplatedRequests.Get_From_Uri    ${EOS_URL}    session=${session}
    KarafKeywords.Log_Message_To_Controller_Karaf    EOS rest resp: ${out}
