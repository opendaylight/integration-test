*** Settings ***
Documentation     Functional test for bgp - long-lived graceful-restart
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
${HOLDTIME}       180
${RIB_NAME}       example-bgp-rib
${CONFIG_SESSION}    config-session
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${GR_FOLDER}      ${CURDIR}/../../../variables/bgpfunctional/graceful_restart
${LL_GR_FOLDER}    ${GR_FOLDER}/ll_gr
${PEER1_AS}       65000
${PEER2_AS}       65001
${PEER1_IP}       127.0.0.2
${PEER2_IP}       127.0.0.3
${PEER1_PORT}     8001
${PEER2_PORT}     8002
${FIRST_PREFIX}    8.1.0.0
${SECOND_PREFIX}    8.2.0.0
${NEXT_HOP}       1.1.1.1
${PREFIX_LEN}     28

*** Test Cases ***
Verify_Presence_Of_Long_Lived_Community
    [Documentation]    Prerequistes: One peer with one route running.
    ...    Verify peer route is present in odl's loc-rib.
    ...    Kill bgp speaker. After graceful-restart restart-time runs out,
    ...    route has to have additional community in rib.
    [Setup]    Setup_TC0
    Verify_Routes    dir=ipv4_1
    Kill_Talking_BGP_Speakers    log_name=ll_gr_tc0.out
    Verify_Routes    dir=ipv4_1
    Verify_Routes    dir=ll_gr/ipv4_1
    [Teardown]    Teardown_TC    ll_gr_tc0.out

Verify_Removal_Of_Community_After_Peer_Restart
    [Documentation]    Prerequistes: One peer with one route was just killed.
    ...    Restart killed peer with the same route.
    ...    Verify that ll-graceful-restart community was removed from the route in rib.
    [Setup]    Setup_TC_LL_GR_Route
    Start_Bgp_Peer    grace=7    log_name=ll_gr_tc1.out
    Verify_Routes    dir=ipv4_1
    [Teardown]    Teardown_TC    ll_gr_tc1.out

Verify_Odl_Advertisement_To_Peer_With_LL_GR_Enabled
    [Documentation]    Prerequistes: One peer with one route was just killed.
    ...    Start another peer with ll-graceful-restart capability enabled.
    ...    Verify odl advertizes route to second peer.
    [Setup]    Setup_TC_LL_GR_Route
    Start_Bgp_Peer    prefix=${SECOND_PREFIX}    myip=${PEER2_IP}    port=${PEER2_PORT}    as_number=${PEER2_AS}    log_name=ll_gr_tc2.out    amount=0
    ...    grace=4
    Verify_Routes    dir=ll_gr/ipv4_1
    Verify_Hex_Message    tc2    peer=${PEER2_IP}
    [Teardown]    Teardown_TC    ll_gr_tc2.out

Verify_Route_With_No_LL_GR_Community_Removal
    [Documentation]    Prerequistes: One peer with one route running.
    ...    Peer and odl have long-lived graceful-restart enabled.
    ...    Route has no-long-lived-graceful-restart community configured.
    ...    Kill peer, and verify that route was removed after normal
    ...    graceful-timer of 5 seconds.
    [Setup]    Setup_TC3
    Kill_Talking_BGP_Speakers    log_name=ll_gr_tc3.out
    BuiltIn.Sleep    5s
    Verify_Routes    retry=8x    interval=1s
    [Teardown]    Teardown_TC    ll_gr_tc3.out    0s

Verify_Odl_Advertize_Empty_Message_To_Peer_Without_LL_GR_Enabled
    [Documentation]    Prerequistes: One peer with one route was just killed.
    ...    Start another peer with ll-graceful-restart capability disabled.
    ...    Verify peer doesn't recieve route.
    [Setup]    Setup_TC_LL_GR_Route
    Start_Bgp_Peer    prefix=${SECOND_PREFIX}    myip=${PEER2_IP}    port=${PEER2_PORT}    as_number=${PEER2_AS}    log_name=ll_gr_tc4.out    amount=0
    ...    grace=0
    Verify_Routes    dir=ll_gr/ipv4_1
    Verify_Hex_Message    tc3    peer=${PEER2_IP}
    [Teardown]    Teardown_TC    ll_gr_tc4.out


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

Setup_TC0
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with one route.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    log_name=ll_gr_tc0.out    grace=4

Setup_TC_LL_GR_Route
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with one route, and verify route is present in loc-rib.
    ...    Kill bgp speaker (effectively simulating graceful-restart)
    ...    Verify route has additional community present in rib.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    grace=4
    Verify_Routes    dir=ipv4_1
    Kill_Talking_BGP_Speakers
    Verify_Routes    dir=ll_gr/ipv4_1    retry=10x

Setup_TC3
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer without any routes. Get hex string which represents normal route,
    ...    but it also has no-long-lived-graceful-restart configured.
    ...    Verify that this route is present in rib.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    grace=4    amount=0    log_name=ll_gr_tc4.out
    ${announce_hex} =    OperatingSystem.Get_File    ${LL_GR_FOLDER}${/}no_ll_gr${/}message.hex
    ${announce_hex} =    String.Remove_String    ${announce_hex}    \n
    BgpRpcClient1.play_send    ${announce_hex}
    Verify_Routes    dir=ll_gr/ipv4_1_no_ll_gr

Teardown_TC
    [Arguments]    ${log_name}=play.py.out    ${stale_time}=10s
    [Documentation]    In case Test Case failed to close Python Speakers, we close them.
    ...    Wait until there are no routes present in loc-rib. Stale_time represents
    ...    long-lived graceful-restart timer, which is the time in which the routes get removed from rib.
    Kill_Talking_BGP_Speakers    ${log_name}
    BuiltIn.Sleep    ${stale_time}
    Verify_Routes    dir=empty_route    retry=10x
    Verify_Routes    dir=empty_ipv6_route    interval=1s

Verify_Routes
    [Arguments]    ${dir}=empty_route    ${retry}=5x    ${interval}=3s
    [Documentation]    Verify route based on how many routes are present in rib.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${retry}    ${interval}    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}${dir}    session=${CONFIG_SESSION}    verify=True

Verify_Hex_Message
    [Arguments]    ${file_dir}    ${peer}=${PEER1_IP}
    [Documentation]    Verify hex message advertised from odl.
    ${expected} =    TemplatedRequests.Resolve_Text_From_Template_File    ${LL_GR_FOLDER}${/}${file_dir}    message.hex
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
    [Arguments]    ${prefix}=${FIRST_PREFIX}    ${amount}=1    ${myip}=${PEER1_IP}    ${port}=${PEER1_PORT}    ${as_number}=${PEER1_AS}    ${grace}=0
    ...    ${log_name}=play.py.out    ${multiple}=&    ${ipv6}=${EMPTY}
    [Documentation]    Starts bgp peer.
    ${command} =    BuiltIn.Set_Variable    python play.py${ipv6} --firstprefix ${prefix} --prefixlen ${PREFIX_LEN} --amount ${amount} --myip ${myip} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port ${port} --usepeerip --nexthop ${NEXT_HOP} --asnumber ${as_number} --debug --grace ${grace} --wfr 1 &> ${log_name} ${multiple}
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
    [Arguments]    ${folder}=${EMPTY}
    [Documentation]    Configure two eBGP peers with graceful-restart enabled, and long-lived graceful-restart enabled
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${PEER1_AS}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${LL_GR_FOLDER}${/}${folder}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${PEER2_AS}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${LL_GR_FOLDER}${/}${folder}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${LL_GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER2_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${LL_GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Post_Graceful_Restart
    [Arguments]    ${ip}=${PEER1_IP}
    [Documentation]    Post rpc to odl, effectively restarting it.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ip}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Post_As_Xml_Templated    ${GR_FOLDER}${/}restart    mapping=${mapping}    session=${CONFIG_SESSION}
