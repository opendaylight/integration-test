*** Settings ***
Documentation     Functional test for bgp - graceful-restart
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
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
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${RIB_NAME}    example-bgp-rib
${CONFIG_SESSION}    config-session
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${GR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/graceful_restart
${PEER1_AS}    65000
${PEER2_AS}    65001
${PEER1_IP}    127.0.0.2
${PEER2_IP}    127.0.0.3
${PEER1_PORT}    8001
${PEER2_PORT}    8002
${FIRST_PREFIX}    8.1.0.0
${SECOND_PREFIX}    8.2.0.0
${NEXT_HOP}    1.1.1.1
${PREFIX_LEN}     28

*** Test Cases ***
TC_0
    [Setup]    Setup_TC0
    [Documentation]    Prerequistes: One peer with one route running.
    ...    Verify peer route is present in odl's loc-rib.
    ...    Kill bgp speaker. After graceful-restart restart-time runs out, route must not be
    ...    present in odl's loc-rib.
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc0.out
    BuiltIn.Sleep    5s
    Verify_No_Routes
    [Teardown]    Teardown_TC    gr_tc0.out

TC_1
    [Setup]    Setup_TC1
    [Documentation]    Prerequistes: One peer with one route was just killed.
    ...    Restart killed peer with the same route.
    ...    Wait for graceful-restart restart-timer to run out, and verify that route is still present in loc-rib.
    ...    Verify odl advertised end-of-rib message with appropriate flags.
    Start_Bgp_Peer    grace=3    log_name=gr_tc1.out
    Verify_One_Route
    Verify_Hex_Message    tc1
    [Teardown]    Teardown_TC    gr_tc1.out

TC_2
    [Setup]    Setup_TC2
    [Documentation]    Prerequistes: One peer with two routes was just killed.
    ...    Restart killed peer with just one route. Verify only one route is present in loc-rib.
    Start_Bgp_Peer    grace=2    log_name=gr_tc2.out
    Verify_One_Route
    [Teardown]    Teardown_TC    gr_tc2.out

TC_3
    [Setup]    Setup_TC3
    [Documentation]    Prerequistes: One peer with one route, was just killed. Second is still running.
    ...    Restart killed peer with two routes. Verify that two routes from restarted peer and one route
    ...    from second peer is in loc-rib. Verify odl advertised update message to second peer with new route
    ...    and appropriate end-of-rib message.
    Start_Bgp_Peer    amount=2    grace=2
    Verify_Hex_Message    tc3
    Verify_Two_And_One_Routes
    [Teardown]    Teardown_TC    gr_tc3.out

TC_4
    [Setup]    Setup_TC_PG
    [Documentation]    Prerequistes: One peer with one route running.
    ...    Graceful-restart odl. Close tcp connection from peer side and reopen it.
    ...    Send end-of-rib with all 0 flags, and expect the route still in loc-rib.
    ...    Verify end-of-rib message from odl with all flags set to 1.
    Post_Graceful_Restart
    Kill_Talking_BGP_Speakers
    Start_Bgp_Peer    grace=0    log_name=gr_tc4.out
    Verify_Hex_Message    tc4
    Verify_One_Route
    [Teardown]    Teardown_TC    gr_tc4.out

TC_5
    [Setup]    Setup_TC_PG
    [Documentation]    Prerequistes: One peer with one route running.
    ...    Graceful-restart odl. Close tcp connection from peer side and reopen it.
    ...    Start bgp peer with two routes, and send end-of-rib message with ipv4 flag
    ...    set to 1. Verify loc-rib and end-of-rib message from odl.
    Post_Graceful_Restart
    Kill_Talking_BGP_Speakers
    Start_Bgp_Peer    amount=2    grace=2    log_name=gr_tc5.out
    Verify_Hex_Message    tc5
    Verify_Two_Routes
    [Teardown]    Teardown_TC    gr_tc5.out

TC_6
    [Setup]    Setup_TC6
    [Documentation]    [Documentation]    Prerequistes: One peer with one ipv4 route and one ipv6 route running.
    ...    Kill the speaker. And Verify that there is ipv4 route still present, but ipv6 rib should be empty
    ...    because it had no graceful-restart ability configured.
    Kill_Talking_BGP_Speakers
    Verify_One_Route
    Verify_No_Ipv6_Routes
    [Teardown]    Teardown_TC    gr_tc6.out

*** Keywords ***
Start_Suite
    [Documentation]    Initialize SetupUtils. Suite setup keyword.
    ...    Copies play.py script for peer simulation onto ODL VM.
    ...    Configures peers on odl with graceful-restart enabled.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    SSHKeywords.Flexible_Controller_Login
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Put_File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    Configure_BGP_Peers

Stop_Suite
    [Documentation]    Delete peer configuration, close all remaining ssh and http sessions.
    Delete_Bgp_Peers_Configuration
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Setup_TC0
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with one routes.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    log_name=gr_tc0.out

Setup_TC1
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with one routes, and verify routes is present in loc-rib.
    ...    Kill bgp speaker  (effectively simulating graceful-restart)
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer
    Verify_One_Route
    Kill_Talking_BGP_Speakers

Setup_TC2
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with two routes, and verify routes are present in loc-rib.
    ...    Kill bgp speaker  (effectively simulating graceful-restart)
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    amount=2
    Verify_Two_Routes
    Kill_Talking_BGP_Speakers

Setup_TC3
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start two bgp peers, each with their default values, and verify their respective routes
    ...    are present in loc-rib, than kill the first bgp speaker (effectively simulating graceful-restart)
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    prefix=${SECOND_PREFIX}    myip=${PEER2_IP}    port=${PEER2_PORT}    as_number=${PEER2_AS}    log_name=gr_tc3.out
    Start_Bgp_Peer    multiple=${EMPTY}
    Verify_One_And_One_Routes
    BGPSpeaker.Kill_BGP_Speaker

Setup_TC_PG
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer, and verify it's route is present in loc-rib.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer
    Verify_One_Route

Setup_TC6
    [Documentation]    Log Test Case name into karaf log, and make sure it wont fail other TC's.
    ...    Start one bgp peer with one routes, and send ipv6 route without gr configured.
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    log_name=gr_tc6.out    ipv6=${SPACE}--ipv6
    ${announce_hex} =    OperatingSystem.Get_File    ${GR_FOLDER}${/}ipv6.hex
    ${announce_hex} =    String.Remove_String    ${announce_hex}    \n
    BgpRpcClient1.play_send    ${announce_hex}
    Verify_One_Route
    Verify_Ipv6_Route

Teardown_TC
    [Arguments]    ${log_name}=play.py.out
    [Documentation]    In case Test Case failed to close Python Speakers, we close them.
    ...    Wait until there are no routes present in loc-rib.
    Kill_Talking_BGP_Speakers    ${log_name}
    Verify_No_Routes
    Verify_No_Ipv6_Routes

Verify_No_Routes
    [Documentation]    Verify loc-rib is empty, and no routes are present from either peer.
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}empty_route    session=${CONFIG_SESSION}    verify=True

Verify_No_Ipv6_Routes
    [Documentation]    Verify loc-rib is empty, and no routes are present from either peer.
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}empty_route    session=${CONFIG_SESSION}    verify=True

Verify_One_Route
    [Documentation]    Verify one route present from peer 1.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_1    session=${CONFIG_SESSION}    verify=True

Verify_Ipv6_Route
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    1s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_1    session=${CONFIG_SESSION}    verify=True

Verify_One_And_One_Routes
    [Documentation]    Verify one route present from peer 1, and one route from peer 2.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_1_1    session=${CONFIG_SESSION}    verify=True

Verify_Two_Routes
    [Documentation]    Verify two routes present from peer 1.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_2    session=${CONFIG_SESSION}    verify=True

Verify_Two_And_One_Routes
    [Documentation]    Verify two routes present from peer 1, and one route from peer 2.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    3s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_2_1    session=${CONFIG_SESSION}    verify=True

Verify_Hex_Message
    [Arguments]    ${file_dir}    ${peer}=${PEER1_IP}    ${file_name}=${file_dir}.hex
    [Documentation]    Verify hex message advertised from odl.
    ${expected} =    TemplatedRequests.Resolve_Text_From_Template_File    ${GR_FOLDER}${/}${file_dir}    ${file_name}
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
    BuiltIn.Run_Keyword_And_Ignore_Error    BGPcliKeywords.Store_File_To_Workspace    ${log_name}    ${log_name}.log
    BuiltIn.Run_Keyword_And_Ignore_Error    BGPSpeaker.Dump_BGP_Speaker_Logs
    BGPSpeaker.Kill_All_BGP_Speakers

Configure_BGP_Peers
    [Documentation]    Configure two eBGP peers with graceful-restart enabled
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${PEER1_AS}
    ...    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${PEER2_AS}
    ...    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${PEER2_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Post_Graceful_Restart
    [Arguments]    ${ip}=${PEER1_IP}
    [Documentation]    Post rpc to odl, effectively restarting it.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ip}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Post_As_Xml_Templated    ${GR_FOLDER}${/}restart    mapping=${mapping}    session=${CONFIG_SESSION}

