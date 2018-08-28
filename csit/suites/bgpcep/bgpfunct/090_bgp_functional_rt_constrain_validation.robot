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
#Suite Setup       Start_Suite
#Suite Teardown    Stop_Suite
#Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Library           ../../../libraries/BgpRpcMultiplePlay.py
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

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${RT_CONSTRAIN_APP_PEER}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    :FOR    ${i}    IN RANGE   2   5
    \    &{RT_CONSTRAIN_ODL_CONFIG}=    BuiltIn.Create Dictionary    IP=${ODL_SYSTEM_${i}_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    \    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${RT_CONSTRAIN_ODL_CONFIG}    session=${CONFIG_SESSION}
    \    BuiltIn.Log    ${RT_CONSTRAIN_ODL_CONFIG}

Start_Bgp_Peers
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Tags]    local_run
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    :FOR    ${i}    IN RANGE   2   5
    \    BuiltIn.Log    ${ODL_SYSTEM_${i}_IP}
    \    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start_Bgp_Peer    ${ODL_SYSTEM_${i}_IP}

Play_To_Odl_rt_constrain_default
    BgpOperations.Play_To_Odl_Non_Removal_Template    ${ODL_SYSTEM_2_IP}    l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_type_0
    BgpOperations.Play_To_Odl_Non_Removal_Template    ${ODL_SYSTEM_3_IP}    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_type_1
    Play_To_Odl_No_Routes_Removal_Template    ${ODL_SYSTEM_4_IP}    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}

Play_To_Odl_remove_rt
    Play_To_Odl_Routes_Removal_Template    ${ODL_SYSTEM_3_IP}    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}    ${ipv}=ipv4

Play_To_Odl_remove_routes
    [Template]    Play_To_Odl_Routes_Removal_Template
    ${ODL_SYSTEM_2_IP}    l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}    ${ipv}=ipv4
    ${ODL_SYSTEM_4_IP}    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}    ${ipv}=ipv4

Kill_Talking_BGP_Speakers
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    BGPcliKeywords.Store_File_To_Workspace    play.py.out    rt_constrain_play.log

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    :FOR    ${i}    IN RANGE   2   5
    \    &{RT_CONSTRAIN_ODL_CONFIG}=    BuiltIn.Create Dictionary    IP=${ODL_SYSTEM_${i}_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    \    TemplatedRequests.Delete_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${RT_CONSTRAIN_ODL_CONFIG}    session=${CONFIG_SESSION}

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
    [Arguments]    ${ip}
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${ip} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --debug --rt_constrain --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Play_To_Odl_Remove_Route
    [Arguments]    ${ip}    ${totest}    ${dir}    ${ipv}=ipv4
    ${withdraw_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/withdraw_${totest}.hex
    ${proxy}=    BgpRpcClientFunctions.proxy_return    ${ip}
    BgpRpcClientFunctions.play_send    ${proxy}    ${withdraw_hex}
