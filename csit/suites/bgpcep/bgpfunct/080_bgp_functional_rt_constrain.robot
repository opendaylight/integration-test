*** Settings ***
Documentation     Functional test for bgp - route-target-constrain safi
...           
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...               This suite tests advertising rt-constrain routes to odl. For advertising from peer,
...               play.py is used, sending hex messages to odl.
...               For advertising to app-peer, we are sending post requests with routes in xml.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${CONFIG_SESSION}    config-session
${RT_CONSTRAIN_DIR}    ${CURDIR}/../../../variables/bgpfunctional/rt_constrain
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_NAME}       example-bgp-rib
&{RT_CONSTRAIN_APP_PEER}    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
&{RT_CONSTRAIN_ODL_CONFIG}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${RT_CONSTRAIN_APP_PEER}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${RT_CONSTRAIN_ODL_CONFIG}    session=${CONFIG_SESSION}

Start_Bgp_Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start_Bgp_Peer

Odl_To_Play_rt_constrain_default
    [Template]    Odl_To_Play_Template
    rt_constrain_default    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_default
    [Template]    Play_To_Odl_Template
    rt_constrain_default    ${RT_CONSTRAIN_DIR}

Odl_To_Play_rt_constrain_type_0
    [Template]    Odl_To_Play_Template
    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_type_0
    [Template]    Play_To_Odl_Template
    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}

Odl_To_Play_rt_constrain_type_1
    [Template]    Odl_To_Play_Template
    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_type_1
    [Template]    Play_To_Odl_Template
    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}

Odl_To_Play_rt_constrain_type_2
    [Template]    Odl_To_Play_Template
    rt_constrain_type_2    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_type_2
    [Template]    Play_To_Odl_Template
    rt_constrain_type_2    ${RT_CONSTRAIN_DIR}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    BGPcliKeywords.Store_File_To_Workspace    play.py.out    rt_constrain_play.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Delete_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${RT_CONSTRAIN_ODL_CONFIG}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Delete_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${RT_CONSTRAIN_APP_PEER}    session=${CONFIG_SESSION}

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
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --debug --rt_constrain --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen
