*** Settings ***
Documentation     Functional test for bgp - graceful-restart
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               TC0:
...
...
...
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Teardown_TC
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8001    WITH NAME    BgpRpcClient1
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8002    WITH NAME    BgpRpcClient2
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
    [Documentation]    One peer with one route running.
    ...    Verify peer route is present in odl's loc-rib.
    ...    Kill bgp speaker. After graceful-restart restart-time runs out, route must not be
    ...    present in odl's loc-rib.
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc0.out
    BuiltIn.Sleep    5s
    Verify_No_Routes

TC_1
    [Setup]    Setup_TC1
    [Documentation]    One peer with one route was just killed.
    ...    Restart that peer with the same route.
    ...    Wait for graceful-restart restart-timer to run out, and verify that route is still present in loc-rib.
    ...    Verify odl advertised end-of-rib message with appropriate flags.
    Start_Bgp_Peer    grace=3    log_name=gr_tc1.out
    BuiltIn.Sleep    5s
    Verify_One_Route
    ${update} =    BgpRpcClient1.play_get
    BuiltIn.Log    ${update}    #TODO: verify update message
    Kill_Talking_BGP_Speakers    log_name=gr_tc1.out

TC_2
    [Setup]    Setup_TC2
    Start_Bgp_Peer    grace=2    log_name=gr_tc2.out
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc2.out

TC_3
    [Setup]    Setup_TC3
    Start_Bgp_Peer    ammount=2    grace=2
    BuiltIn.Sleep    5s
    ${update} =    BgpRpcClient2.play_get
    BuiltIn.Log    ${update}    #TODO: verify update message
    Verify_Two_And_One_Routes
    Kill_Talking_BGP_Speakers    log_name=gr_tc3.out

TC_4
    [Setup]    Setup_TC_PG
    Post_Graceful_Restart
    Kill_Talking_BGP_Speakers
    Start_Bgp_Peer    grace=1    log_name=gr_tc4.out
    BuiltIn.Sleep    5s    #wuks here
    ${update} =    BgpRpcClient1.play_get
    BuiltIn.Log    ${update}    #TODO: verify update message
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc4.out

TC_5
    [Setup]    Setup_TC_PG
    Post_Graceful_Restart
    Kill_Talking_BGP_Speakers
    Start_Bgp_Peer    amount=2    grace=2    log_name=gr_tc5.out
    BuiltIn.Sleep    5s    #wuks here
    ${update} =    BgpRpcClient2.play_get
    BuiltIn.Log    ${update}    #TODO: verify update message
    Verify_Two_Routes
    Kill_Talking_BGP_Speakers    log_name=gr_tc5.out

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

Teardown_TC
    [Documentation]    In case Test Case failed to close Python Speakers, we close them.
    ...    Wait until there are no routes present in loc-rib.
    Kill_Talking_BGP_Speakers
    Verify_No_Routes

Verify_No_Routes
    [Documentation]    Verify loc-rib is empty, and no routes are present from either peer.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}empty_route    session=${CONFIG_SESSION}    verify=True

Verify_One_Route
    [Documentation]    Verify one route present from peer 1.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_1    session=${CONFIG_SESSION}    verify=True

Verify_One_And_One_Routes
    [Documentation]    Verify one route present from peer 1, and one route from peer 2.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_1_1    session=${CONFIG_SESSION}    verify=True

Verify_Two_Routes
    [Documentation]    Verify two routes present from peer 1.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_2    session=${CONFIG_SESSION}    verify=True

Verify_Two_And_One_Routes
    [Documentation]    Verify two routes present from peer 1, and one route from peer 2.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_2_1    session=${CONFIG_SESSION}    verify=True

Start_Bgp_Peer
    [Arguments]    ${prefix}=${FIRST_PREFIX}    ${amount}=1    ${myip}=${PEER1_IP}    ${port}=${PEER1_PORT}    ${as_number}=${PEER1_AS}    ${grace}=0
    ...    ${log_name}=play.py.out    ${multiple}=&
    [Documentation]    Starts bgp peer.
    ${command} =    BuiltIn.Set_Variable    python play.py --firstprefix ${prefix} --prefixlen ${PREFIX_LEN} --amount ${amount} --myip ${myip} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port ${port} --usepeerip --nexthop ${NEXT_HOP} --asnumber ${as_number} --debug --grace ${grace} --wfr 1 &> ${log_name} ${multiple}
    BuiltIn.Log    ${command}
    ${output} =    SSHLibrary.Write    ${command}

Kill_Talking_BGP_Speakers
    [Arguments]    ${log_name}=play.py.out
    [Documentation]    Save play.py log into workspace, attempt to dump speaker logs into robot log.
    ...    Abort all Python speakers.
    BGPcliKeywords.Store_File_To_Workspace    ${log_name}    ${log_name}.log
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

