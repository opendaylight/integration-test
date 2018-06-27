*** Settings ***
Documentation     Functional test for bgp - mvpn
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests advertising mvpn routes to odl. For advertising play.py is used,
...               and particular files are stored as *.hex files. There are 7 different
...               types of routes used for auto-discovery of multicast network. Also 4 more routes
...               with new attributes specific for mvpn.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${CONFIG_SESSION}    config-session
${MVPN_DIR}       ${CURDIR}/../../../variables/bgpfunctional/mvpn
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_NAME}       example-bgp-rib
&{MVPN_APP_PEER}    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
&{MVPN_ODL_CONFIG}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${MVPN_DIR}/app_peer    mapping=${MVPN_APP_PEER}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${MVPN_DIR}/bgp_peer    mapping=${MVPN_ODL_CONFIG}    session=${CONFIG_SESSION}

Start_Bgp_Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer

Odl_To_Play_intra_as_ipmsi_ad
    [Template]    Odl_To_Play_Template
    intra_as_ipmsi_ad    ${MVPN_DIR}

Play_To_Odl_intra_as_ipmsi_ad
    [Template]    Play_To_Odl_Template
    intra_as_ipmsi_ad    ${MVPN_DIR}

Odl_To_Play_inter_as_ipmsi_ad
    [Template]    Odl_To_Play_Template
    inter_as_ipmsi_ad    ${MVPN_DIR}

Play_To_Odl_inter_as_ipmsi_ad
    [Template]    Play_To_Odl_Template
    inter_as_ipmsi_ad    ${MVPN_DIR}

Odl_To_Play_spmsi_ad
    [Template]    Odl_To_Play_Template
    spmsi_ad    ${MVPN_DIR}

Play_To_Odl_spmsi_ad
    [Template]    Play_To_Odl_Template
    spmsi_ad    ${MVPN_DIR}

Odl_To_Play_leaf_ad
    [Template]    Odl_To_Play_Template
    leaf_ad    ${MVPN_DIR}

Play_To_Odl_leaf_ad
    [Template]    Play_To_Odl_Template
    leaf_ad    ${MVPN_DIR}

Odl_To_Play_source_active_ad
    [Template]    Odl_To_Play_Template
    source_active_ad    ${MVPN_DIR}

Play_To_Odl_source_active_ad
    [Template]    Play_To_Odl_Template
    source_active_ad    ${MVPN_DIR}

Odl_To_Play_shared_tree_join
    [Template]    Odl_To_Play_Template
    shared_tree_join    ${MVPN_DIR}

Play_To_Odl_shared_tree_join
    [Template]    Play_To_Odl_Template
    shared_tree_join    ${MVPN_DIR}

Odl_To_Play_source_tree_join
    [Template]    Odl_To_Play_Template
    source_tree_join    ${MVPN_DIR}

Play_To_Odl_source_tree_join
    [Template]    Play_To_Odl_Template
    source_tree_join    ${MVPN_DIR}

Odl_To_Play_intra_pe_distinguisher
    [Template]    Odl_To_Play_Template
    intra_pe_distinguisher    ${MVPN_DIR}

Play_To_Odl_intra_pe_distinguisher
    [Template]    Play_To_Odl_Template
    intra_pe_distinguisher    ${MVPN_DIR}

Odl_To_Play_intra_vrf
    [Template]    Odl_To_Play_Template
    intra_vrf    ${MVPN_DIR}

Play_To_Odl_intra_vrf
    [Template]    Play_To_Odl_Template
    intra_vrf    ${MVPN_DIR}

Odl_To_Play_intra_source_as
    [Template]    Odl_To_Play_Template
    intra_source_as    ${MVPN_DIR}

Play_To_Odl_intra_source_as
    [Template]    Play_To_Odl_Template
    intra_source_as    ${MVPN_DIR}

Odl_To_Play_intra_source_as_4
    [Template]    Odl_To_Play_Template
    intra_source_as_4    ${MVPN_DIR}

Play_To_Odl_intra_source_as_4
    [Template]    Play_To_Odl_Template
    intra_source_as_4    ${MVPN_DIR}

Play_To_Odl_intra_ipv6
    [Template]    Play_To_Odl_Template
    intra_ipv6    ${MVPN_DIR}    ipv6

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    BGPcliKeywords.Store_File_To_Workspace    play.py.out    mvpn_play.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Delete_Templated    ${MVPN_DIR}/bgp_peer    mapping=${MVPN_ODL_CONFIG}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Delete_Templated    ${MVPN_DIR}/app_peer    mapping=${MVPN_APP_PEER}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Initialize SetupUtils. Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id} =    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    RequestsLibrary.Create Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Put File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Start_Bgp_Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --debug --mvpn --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen
