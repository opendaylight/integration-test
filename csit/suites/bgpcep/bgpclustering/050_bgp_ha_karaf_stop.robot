*** Settings ***
Documentation     BGP functional HA testing with one exabgp peer.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses exabgp. It is configured to have 3 peers (all 3 nodes of odl).
...               Bgp implemented with singleton accepts only one incomming conection. Exabgp
...               logs will show that one peer will be connected and two will fail.
...               After stopping karaf which owned connection new owner should be elected and
...               this new owner should accept incomming bgp connection.
...               TODO: Add similar keywords from all bgpclustering-ha tests into same libraries
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpclustering
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_openconf
${DEFAULT_EXA_CFG}    exa.cfg
${EXA_CMD}        env exabgp.tcp.port=1790 exabgp
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib

*** Test Cases ***
Get_Example_Bgp_Rib_Owner
    [Documentation]    Find an odl node which is able to accept incomming connection.
    ${rib_owner}    ${rib_candidates}=    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Get_Owner_And_Successors_For_Device    example-bgp-rib
    ...    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${rib_owner}
    BuiltIn.Log    ${ODL_SYSTEM_${rib_owner}_IP}
    BuiltIn.Set Suite variable    ${rib_candidates}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${rib_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${rib_owner}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}    http_timeout=5
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_ExaBgp_Peer
    [Documentation]    Starts exabgp
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    BGPcliKeywords.Start_Console_Tool    ${EXA_CMD}    ${DEFAULT_EXA_CFG}

Verify_ExaBgp_Connected
    [Documentation]    Verifies exabgp's presence in operational ds.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ExaBgpLib.Verify_ExaBgps_Connection    ${living_session}

Stop_Current_Owner_Member
    [Documentation]    Stopping karaf which is connected with exabgp.
    Kill_Single_Member    ${rib_owner}
    BuiltIn.Set Suite variable    ${old_rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${old_rib_candidates}    ${rib_candidates}
    ${idx}=    Collections.Get From List    ${old_rib_candidates}    0
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Verify_New_Rib_Owner
    [Documentation]    Verifies if new owner of example-bgp-rib is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_New_Rib_Owner_Elected    ${old_rib_owner}    ${living_node}

Verify_ExaBgp_Reconnected
    [Documentation]    Verifies exabgp's presence in operational ds.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ExaBgpLib.Verify_ExaBgps_Connection    ${living_session}

Start_Stopped_Member
    [Documentation]    Starting stopped node
    Start_Single_Member    ${old_rib_owner}

Verify_New_Candidate
    [Documentation]    Verifies started node become candidate for example-bgp-rib
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Rib_Candidate_Present    ${old_rib_owner}    ${living_node}

Verify_ExaBgp_Still_Connected
    [Documentation]    Verifies exabgp's presence in operational ds
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    ExaBgpLib.Verify_ExaBgps_Connection    ${living_session}

Stop_ExaBgp_Peer
    [Documentation]    Stops exabgp tool by sending ctrl+c
    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers
    &{mapping}    Create Dictionary    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Delete_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}    http_timeout=5

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    ExaBgpLib.Upload_ExaBgp_Cluster_Config_Files    ${BGP_VAR_FOLDER}    ${DEFAULT_EXA_CFG}

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHKeywords.Virtual_Env_Delete
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Verify_New_Rib_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}

Verify_New_Rib_Candidate_Present
    [Arguments]    ${candidate}    ${node_to_ask}
    [Documentation]    Verifies candidate's presence.
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Contain    ${candidates}    ${candidate}
