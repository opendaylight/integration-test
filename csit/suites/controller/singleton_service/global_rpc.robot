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

*** Test Cases ***
Get Basic Rpc Test Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${brt_owner}    ${brt_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_Device    Basic-rpc-test']    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${brt_owner}    ${brt_owner}
    BuiltIn.Set Suite variable    ${brt_owner_node_id}    ${ODL_SYSTEM_${brt_owner}_IP}
    BuiltIn.Set Suite variable    ${brt_candidates}    ${brt_candidates}
    ${session}=    Resolve_Http_Session_For_Member    member_index=${brt_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${brt_owner}


Global Rpc Before Isolation On Owner
    [Documentation]    Run rpc on every cluster node
    : FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
    # \    ${idxl}=    BuiltIn.Create_List    ${idx}
    \    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    \    Run_Rpc    ${session}


#Isolate_Current_Owner_Member
#    [Documentation]    Isolating cluster node which is connected with exabgp.
#    ClusterManagement.Isolate_Member_From_List_Or_All    ${brt_owner}
#    BuiltIn.Set Suite variable    ${old_brt_owner}    ${brt_owner}
#    BuiltIn.Set Suite variable    ${old_brt_candidates}    ${brt_candidates}
#    ${idx}=    Collections.Get From List    ${old_brt_candidates}    0
#    ${session}=    Resolve_Http_Session_For_Member    member_index=${idx}
#    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
#    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Global Rpc On Isolated Node
    BuiltIn.Pass_Execution    OK

Global Rpc On Remained Cluster Node
    BuiltIn.Pass_Execution    OK

#Rejoin_Isolated_Member
#    [Documentation]    Rejoin isolated node
#    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_brt_owner}

Global Rpc On Rejoined Node
    BuiltIn.Pass_Execution    OK


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
    TemplatedRequests.Post_To_Uri    ${RPC_URL}    ${Empty}    ${Empty}    ${Empty}    session=${session}

