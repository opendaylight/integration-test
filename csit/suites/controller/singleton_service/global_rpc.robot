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
#Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot

*** Variables ***
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpclustering
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_openconf
${DEFAUTL_EXA_CFG}    exa.cfg
${EXA_CMD}        env exabgp.tcp.port=1790 exabgp
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib

*** Test Cases ***
Global Rpc Before Isolation
    BuiltIn.Pass_Execution

#Isolate_Current_Owner_Member
#    [Documentation]    Isolating cluster node which is connected with exabgp.
#    ClusterManagement.Isolate_Member_From_List_Or_All    ${rib_owner}
#    BuiltIn.Set Suite variable    ${old_rib_owner}    ${rib_owner}
#    BuiltIn.Set Suite variable    ${old_rib_candidates}    ${rib_candidates}
#    ${idx}=    Collections.Get From List    ${old_rib_candidates}    0
#    ${session}=    Resolve_Http_Session_For_Member    member_index=${idx}
#    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
#    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Global Rpc On Isolated Node
    BuiltIn.Pass_Execution

Global Rpc On Remained Cluster Node

#Rejoin_Isolated_Member
#    [Documentation]    Rejoin isolated node
#    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_rib_owner}

Global Rpc On Rejoined Node

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHLibrary.Close_All_Connections
