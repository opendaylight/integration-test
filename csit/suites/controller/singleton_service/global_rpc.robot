*** Settings ***
Documentation     Controller functional HA testing of singleton service.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${RPC_URL}    /restconf/operations/basic-rpc-test:basic-global
&{EMPTY_DICT}

*** Test Cases ***
Get_Basic_Rpc_Test_Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${brt_owner}    ${brt_successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    Basic-rpc-test']    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set_Suite_Variable    ${brt_owner}    ${brt_owner}
    BuiltIn.Set_Suite_Variable    ${brt_successors}    ${brt_successors}

Global Rpc Before Isolation On Owner
    [Documentation]    Run rpc on every cluster node
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${brt_owner}
    Run_Rpc    ${session}

Global Rpc Before Isolation On Successors
    [Documentation]    Run rpc on every cluster node
    : FOR    ${idx}    IN    @{brt_successors}
    \    ${session} =    Resolve_Http_Session_For_Member    member_index=${idx}
    \    Run_Rpc    ${session}

Isolate_Current_Owner_Member
    [Documentation]    Isolating cluster node which is the owner.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${brt_owner}
    BuiltIn.Set Suite variable    ${old_brt_owner}    ${brt_owner}
    BuiltIn.Set Suite variable    ${old_brt_successors}    ${brt_successors}

Verify_New_Basic_Rpc_Test_Owner_Elected
    [Documentation]    Verifies if new owner of example-bgp-rib is elected.
    ${idx}=    Collections.Get From List    ${old_brt_candidates}    0
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_New_Owner_Elected    ${old_rib_owner}    ${idx}

Global Rpc On Isolated Node
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${old_brt_owner}
    Run_Rpc    ${session}

Global Rpc On Remained Cluster Node
    [Documentation]    Run rpc on every cluster node
    : FOR    ${idx}    IN    @{old_brt_successors}
    \    ${session} =    Resolve_Http_Session_For_Member    member_index=${idx}
    \    Run_Rpc    ${session}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_brt_owner}

Get_Basic_Rpc_Test_New_Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${brt_owner}    ${brt_successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    Basic-rpc-test']    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set_Suite_Variable    ${brt_owner}    ${brt_owner}
    BuiltIn.Set_Suite_Variable    ${brt_successors}    ${brt_successors}

Global Rpc After Rejoinn On New Owner
    [Documentation]    Run rpc on every cluster node
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${brt_owner}
    Run_Rpc    ${session}

Global Rpc After Rejoinn On Old Owner
    [Documentation]    Run rpc on every cluster node
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${old_brt_owner}
    Run_Rpc    ${session}

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHLibrary.Close_All_Connections

Run_Rpc
    [Arguments]    ${session}
    [Documentation]    Run rpc
    TemplatedRequests.Post_To_Uri    ${RPC_URL}    ${Empty}    ${EMPTY_DICT}    ${EMPTY_DICT}    session=${session}

Verify_New_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${successors}=    ClusterManagement.Get_Owner_And_Successors_For_Device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}

