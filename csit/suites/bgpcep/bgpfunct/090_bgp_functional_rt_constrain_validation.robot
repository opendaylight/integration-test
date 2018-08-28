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
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_2_IP}    WITH NAME    BgpRpcClient2
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_3_IP}    WITH NAME    BgpRpcClient3
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_4_IP}    WITH NAME    BgpRpcClient4
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
${ODL_2_IP}       127.0.0.2
${ODL_3_IP}       127.0.0.3
${ODL_4_IP}       127.0.0.4
@{ODL_IP_INDICES}    2    3    4
@{L3VPN_RT_CHECK}    false    true    false
&{RT_CONSTRAIN_APP_PEER}    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${RT_CONSTRAIN_APP_PEER}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    :FOR    ${i}    IN    ${ODL_IP_INDICES}
    \    &{RT_CONSTRAIN_ODL_CONFIG}=    BuiltIn.Create Dictionary    IP=${ODL_${i}_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    \    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${RT_CONSTRAIN_ODL_CONFIG}    session=${CONFIG_SESSION}
    \    BuiltIn.Log    ${RT_CONSTRAIN_ODL_CONFIG}

Start_Bgp_Peers
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Tags]    local_run
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    :FOR    ${i}    IN    ${ODL_IP_INDICES}
    \    BuiltIn.Log    ${ODL_${i}_IP}
    \    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start_Bgp_Peer    ${ODL_${i}_IP}

Play_To_Odl_l3vpn_rt_arg
    BgpOperations.Play_To_Odl_Non_Removal_Template    BgpRpcClient2    l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}

Play_To_Odl_rt_constrain_type_0
    BgpOperations.Play_To_Odl_Non_Removal_Template    BgpRpcClient3    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}
    ${announce}=    OperatingSystem.Get_File    ${RT_CONSTRAIN_DIR}/l3vpn_rt_arg/announce_l3vpn_rt_arg.hex
    ${announce_hex}=    BuiltIn.Remove_String    ${announce}    \n
    : FOR    ${i}    ${option}    IN ZIP    ${ODL_IP_INDICES}    ${L3VPN_RT_CHECK}
    \    BgpOperations.Get_Update_Message_And_Compare_With_Hex    BgpRpcClient${i}    ${announce_hex}    ${option}

Play_To_Odl_rt_constrain_type_1
    BgpOperations.Play_To_Odl_No_Routes_Removal_Template    BgpRpcClient4    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}
    ${announce}=    OperatingSystem.Get_File    ${RT_CONSTRAIN_DIR}/l3vpn_rt_arg/announce_l3vpn_rt_arg.hex
    ${announce_hex}=    BuiltIn.Remove_String    ${announce}    \n
    BgpOperations.Get_Update_Message_And_Compare_With_Hex    BgpRpcClient4    ${announce_hex}    true

Play_To_Odl_remove_rt
    BgpOperations.Play_To_Odl_Routes_Removal_Template    BgpRpcClient3    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}
    ${withdraw}=    OperatingSystem.Get_File    ${RT_CONSTRAIN_DIR}/l3vpn_rt_arg/withdraw_l3vpn_rt_arg.hex
    ${withdraw_hex}=    BuiltIn.Remove_String    ${withdraw}    \n
    BgpOperations.Get_Update_Message_And_Compare_With_Hex    BgpRpcClient3    ${withdraw_hex}    true
    ${update}=    BgpRpcClient4.play_get
    BuiltIn.Should_Not_Be_Equal    ${update}    ${Empty}

Play_To_Odl_remove_routes
    [Template]    Play_To_Odl_Routes_Removal_Template
    BgpRpcClient2    l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}
    BgpRpcClient4    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}

Kill_Talking_BGP_Speakers
    [Documentation]    Abort all Python speakers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_All_BGP_Speakers

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${i}    IN    ${ODL_IP_INDICES}
    \    &{RT_CONSTRAIN_ODL_CONFIG}=    BuiltIn.Create Dictionary    IP=${ODL_${i}_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
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
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${ip} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --debug --allf --wfr 1 &
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen
