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
${DEVICE_NAME}    controller-config
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${GR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/graceful_restart
${eBGP_PEER1_IP}    127.0.0.2
${eBGP_PEER2_IP}    127.0.0.3
@{BGP_PEERS_IPS}    ${eBGP_PEER1_IP}    ${eBGP_PEER2_IP}
${eBGP_PEER1_AS}    65000
${eBGP_PEER2_AS}    65001
${FIRST_PREFIX}    8.1.0.0
${SECOND_PREFIX_IP}    8.2.0.0
${NEXT_HOP}    1.1.1.1
${PREFIX_LEN}     28
#${eBGP_PEER1_COMMAND}    python play.py --firstprefix ${eBGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${PREFIX_LEN} --amount 1 --myip ${eBGP_PEER1_IP} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port 8003 --usepeerip --nexthop ${eBGP_PEER1_NEXT_HOP} --asnumber ${eBGP_PEER1_AS} --debug --allf --wfr 1 &> play.py.1 &
#${eBGP_PEER2_COMMAND}    python play.py --firstprefix ${eBGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${PREFIX_LEN} --amount 1 --myip ${eBGP_PEER2_IP} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port 8004 --usepeerip --nexthop ${eBGP_PEER2_NEXT_HOP} --asnumber ${eBGP_PEER2_AS} --debug --allf --wfr 1 &> play.py.2 &
@{BGP_PEERS}    iBGP_PEER1    eBGP_PEER1    eBGP_PEER2
&{LOC_RIB}        PATH=loc-rib    BGP_RIB=${RIB_NAME}

*** Test Cases ***
TC_0
    [Setup]    Setup_TC0
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc0.out
    BuiltIn.Sleep    5s
    Verify_No_Routes

TC_1
    [Setup]    Setup_TC1
    Start_Bgp_Peer    grace=3    log_name=gr_tc1.out
    Verify_One_Route
    ${update} =    BgpRpcClient1.play_get
    BuiltIn.Log    ${update}    #TODO: verify update message
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc1.out

TC_2
    [Setup]    Setup_TC2
    Start_Bgp_Peer    grace=3    log_name=gr_tc2.out
    Verify_One_Route
    Kill_Talking_BGP_Speakers    log_name=gr_tc2.out

TC_3
    [Setup]    Setup_TC3
    Verify_Two_Routes
    Start_Bgp_Peer    ammount=2    grace=3
    ${update} =    BgpRpcClient2.play_get
    BuiltIn.Log    ${update}    #TODO: verify update message
    #TODO: Verify 3 routes
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
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id} =    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Put_File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    Configure_BGP_Peers

Stop_Suite
    [Documentation]    Suite teardown keyword
    Delete_Bgp_Peers_Configuration
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Setup_TC0
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    log_name=gr_tc0.out

Setup_TC1
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer
    Verify_One_Route
    Kill_Talking_BGP_Speakers

Setup_TC2
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    amount=2
    Verify_Two_Routes
    Kill_Talking_BGP_Speakers

Setup_TC3
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer    prefix=8.2.0.0    myip=127.0.0.3    port=8002    as_number=65001    log_name=gr_tc3.out
    Start_Bgp_Peer    multiple=${EMPTY}
    Verify_Two_Routes
    BGPSpeaker.Kill_BGP_Speaker

Setup_TC_PG
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Start_Bgp_Peer
    Verify_One_Route

Teardown_TC
    Kill_Talking_BGP_Speakers
    Verify_No_Routes

Verify_No_Routes
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}empty_route    session=${CONFIG_SESSION}    verify=True

Verify_One_Route
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_route    session=${CONFIG_SESSION}    verify=True

Verify_Two_Routes
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${GR_FOLDER}${/}ipv4_routes    session=${CONFIG_SESSION}    verify=True

Start_Bgp_Peer
    [Arguments]    ${prefix}=8.1.0.0    ${amount}=1    ${myip}=127.0.0.2    ${port}=8001    ${as_number}=65000    ${grace}=0
    ...    ${log_name}=play.py.out    ${multiple}=&
    [Documentation]    Starts bgp peer.
    ${command} =    BuiltIn.Set_Variable    python play.py --firstprefix ${prefix} --prefixlen 28 --amount ${amount} --myip ${myip} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port ${port} --usepeerip --nexthop 1.1.1.1 --asnumber ${as_number} --debug --grace ${grace} --wfr 1 &> ${log_name} ${multiple}
    BuiltIn.Log    ${command}
    ${output} =    SSHLibrary.Write    ${command}

Kill_Talking_BGP_Speakers
    [Arguments]    ${log_name}=play.py.out
    [Documentation]    Abort all Python speakers.
    BGPcliKeywords.Store_File_To_Workspace    ${log_name}    ${log_name}.log
    BGPSpeaker.Kill_All_BGP_Speakers

Configure_BGP_Peers
    [Documentation]    Configure an iBGP and two eBGP peers
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${eBGP_PEER1_AS}
    ...    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${eBGP_PEER2_AS}
    ...    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Put_As_Xml_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER2_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GR_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Post_Graceful_Restart
    [Arguments]    ${ip}=127.0.0.2
    TemplatedRequests.Post_As_Xml_Templated    ${GR_FOLDER}${/}restart    session=${CONFIG_SESSION}

