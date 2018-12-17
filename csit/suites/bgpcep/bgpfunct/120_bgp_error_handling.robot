*** Settings ***
Documentation     Functional test for bgp - error-handling
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8001    WITH NAME    BgpRpcClient1
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8002    WITH NAME    BgpRpcClient2
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${CONFIG_SESSION}    config-session
${ERROR_HANDLING_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/error_handling
${HOLDTIME}       180
${PEER1_AS}       65000
${PEER2_AS}       65001
${PEER1_IP}       127.0.0.2
${PEER2_IP}       127.0.0.3
${PEER1_PORT}     8001
${PEER2_PORT}     8002
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_NAME}       example-bgp-rib

*** Test Cases ***
Verify_Withdrawal_After_Error
    [Documentation]    Prerequistes: Two peers connected without any routes.
    ...    Send mvpn route from first peer.
    [Setup]    Setup_TC
    ${announce_hex} =    OperatingSystem.Get_File    ${ERROR_HANDLING_FOLDER}${/}malformed_route/message.hex
    ${announce_hex} =    String.Remove_String    ${announce_hex}    \n
    BgpRpcClient1.play_send    ${announce_hex}
    Verify_Routes    dir=route
    Verify_Hex_Message    cease_message
    Verify_Hex_Message    withdraw_message    ${PEER2_IP}
    Kill_Talking_BGP_Speakers    log_name=error_handling_peer2.out
    [Teardown]    Teardown_TC    ll_gr_tc0.out

*** Keywords ***
Start_Suite
    [Documentation]    Initialize SetupUtils. Suite setup keyword.
    ...    Copies play.py script for peer simulation onto ODL VM.
    ...    Configures peers on odl with graceful-restart enabled,
    ...    and ll-graceful-restart enabled.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Put_File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Configure_BGP_Peers

Stop_Suite
    [Documentation]    Delete peer configuration, close all remaining ssh and http sessions.
    Delete_Bgp_Peers_Configuration
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Setup_TC
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with one route.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer
    Start_Bgp_Peer    log_name=error_handling_peer2.out    myip=${PEER2_IP}    port=${PEER2_PORT}    as_number=${PEER2_AS}
    Verify_Peer_Connected
    ${announce_hex} =    OperatingSystem.Get_File    ${ERROR_HANDLING_FOLDER}${/}inter_route/message.hex
    ${announce_hex} =    String.Remove_String    ${announce_hex}    \n
    BgpRpcClient1.play_send    ${announce_hex}
    Verify_Routes    dir=route

Verify_Peer_Connected
    [Arguments]    ${ip}=${PEER1_IP}
    [Documentation]    Verifies that peer connected by checking its ip's rib.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ip}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${ERROR_HANDLING_FOLDER}${/}empty_peer_rib    session=${CONFIG_SESSION}    mapping=${mapping}
    ...    verify=True

Teardown_TC
    [Arguments]    ${log_name}=play.py.out
    [Documentation]    In case Test Case failed to close Python Speakers, we close them.
    ...    Wait until there are no routes present in loc-rib. Stale_time represents
    ...    long-lived graceful-restart timer, which is the time in which the routes get removed from rib.
    Kill_Talking_BGP_Speakers    ${log_name}
    Verify_Routes    dir=empty_route    retry=10x

Verify_Routes
    [Arguments]    ${dir}=empty_route    ${retry}=5x    ${interval}=3s
    [Documentation]    Verify route based on how many routes are present in rib.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${retry}    ${interval}    TemplatedRequests.Get_As_Json_Templated    ${ERROR_HANDLING_FOLDER}${/}${dir}    session=${CONFIG_SESSION}    verify=True

Verify_Hex_Message
    [Arguments]    ${file_dir}    ${peer}=${PEER1_IP}
    [Documentation]    Verify hex message advertised from odl.
    ${expected} =    TemplatedRequests.Resolve_Text_From_Template_File    ${ERROR_HANDLING_FOLDER}${/}${file_dir}    message.hex
    ${actual} =    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    Get_Hex_Message    peer=${peer}
    BgpOperations.Verify_Two_Hex_Messages_Are_Equal    ${expected}    ${actual}

Get_Hex_Message
    [Arguments]    ${peer}=${PEER1_IP}
    [Documentation]    Gets open message in case of first peer, and update message in case of second peer.
    ${hex} =    BuiltIn.Run_Keyword_If    "${peer}" == "${PEER1_IP}"    BgpRpcClient1.play_get    what=open
    ...    ELSE    BgpRpcClient2.play_get
    BuiltIn.Should_Not_Be_Equal    ${hex}    ${EMPTY}
    [Return]    ${hex}

Start_Bgp_Peer
    [Arguments]    ${myip}=${PEER1_IP}    ${port}=${PEER1_PORT}    ${as_number}=${PEER1_AS}    ${log_name}=play.py.out
    [Documentation]    Starts bgp peer.
    ${command} =    BuiltIn.Set_Variable    python play.py --amount 0 --myip ${myip} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port ${port} --usepeerip --asnumber ${as_number} --mvpn --debug --wfr 1 &> ${log_name} &
    BuiltIn.Log    ${command}
    ${output} =    SSHLibrary.Write    ${command}

Kill_Talking_BGP_Speakers
    [Arguments]    ${log_name}=play.py.out
    [Documentation]    Save play.py log into workspace, attempt to dump speaker logs into robot log.
    ...    Abort all Python speakers.
    BGPSpeaker.Kill_All_BGP_Speakers
    BuiltIn.Run_Keyword_And_Ignore_Error    BGPcliKeywords.Store_File_To_Workspace    ${log_name}    ${log_name}.log
    BuiltIn.Run_Keyword_And_Ignore_Error    BGPSpeaker.Dump_BGP_Speaker_Logs

Configure_BGP_Peers
    [Documentation]    Configure two eBGP peers with error-handling enabled.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${PEER1_AS}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${ERROR_HANDLING_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${PEER2_AS}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${ERROR_HANDLING_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${ERROR_HANDLING_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER2_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${ERROR_HANDLING_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
