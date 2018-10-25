*** Settings ***
Documentation     Functional test for bgp - route-target-constrain safi
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
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8002    WITH NAME    BgpRpcClient1
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8003    WITH NAME    BgpRpcClient2
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8004    WITH NAME    BgpRpcClient3
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
${GRACEFUL_RESTART_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/graceful_restart
${iBGP_PEER1_IP}    127.0.0.2
${eBGP_PEER1_IP}    127.0.0.3
${eBGP_PEER2_IP}    127.0.0.4
@{BGP_PEERS_IPS}    ${iBGP_PEER1_IP}    ${eBGP_PEER1_IP}    ${eBGP_PEER2_IP}
${iBGP_PEER1_AS}    64496
${eBGP_PEER1_AS}    65000
${eBGP_PEER2_AS}    65001
${iBGP_PEER1_FIRST_PREFIX_IP}    8.0.0.0
${eBGP_PEER1_FIRST_PREFIX_IP}    8.1.0.0
${eBGP_PEER2_FIRST_PREFIX_IP}    8.2.0.0
${eBGP_PEER1_NEXT_HOP}    2.2.2.2
${eBGP_PEER2_NEXT_HOP}    3.3.3.3
${PREFIX_LEN}     28
${iBGP_PEER1_COMMAND}      python play.py --firstprefix ${iBGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${PREFIX_LEN} --amount 1 --myip ${iBGP_PEER1_IP} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port 8002 --usepeerip --debug --allf --wfr 1 &> play.py.iBGP_PEER1 &
${eBGP_PEER1_COMMAND}    python play.py --firstprefix ${eBGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${PREFIX_LEN} --amount 1 --myip ${eBGP_PEER1_IP} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port 8003 --usepeerip --nexthop ${eBGP_PEER1_NEXT_HOP} --asnumber ${eBGP_PEER1_AS} --debug --allf --wfr 1 &> play.py.eBGP_PEER1 &
${eBGP_PEER2_COMMAND}    python play.py --firstprefix ${eBGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${PREFIX_LEN} --amount 1 --myip ${eBGP_PEER2_IP} --myport ${BGP_TOOL_PORT} --peerip ${ODL_SYSTEM_IP} --peerport ${ODL_BGP_PORT} --port 8004 --usepeerip --nexthop ${eBGP_PEER2_NEXT_HOP} --asnumber ${eBGP_PEER2_AS} --debug --allf --wfr 1 &> play.py.eBGP_PEER2 &
@{BGP_PEERS}    iBGP_PEER1    eBGP_PEER1    eBGP_PEER2
&{LOC_RIB}        PATH=loc-rib    BGP_RIB=${RIB_NAME}

*** Test Cases ***
Configure_BGP_Peers
    [Documentation]    Configure an iBGP and two eBGP peers
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    IP=${iBGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${iBGP_PEER1_AS}
    ...    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true    PEER_TYPE=INTERNAL
    TemplatedRequests.Put_As_Xml_Templated    ${GRACEFUL_RESTART_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${eBGP_PEER1_AS}
    ...    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true    PEER_TYPE=EXTERNAL
    TemplatedRequests.Put_As_Xml_Templated    ${GRACEFUL_RESTART_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    AS_NUMBER=${eBGP_PEER2_AS}
    ...    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true    PEER_TYPE=EXTERNAL
    TemplatedRequests.Put_As_Xml_Templated    ${GRACEFUL_RESTART_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Bgp_Peers
    [Documentation]    Start Python speaker to connect to ODL. We give each speaker time until odl really starts to accept incomming
    ...    bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer.
    [Tags]    local_run
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${peer}    IN    @{BGP_PEERS}
    \    BuiltIn.Log    peer: ${peer}
    \    Start_Bgp_Peer    ${${peer}_COMMAND}

Verify_ODL_Contains_All_Routes_01
    TemplatedRequests.Get_As_Json_Templated    ${GRACEFUL_RESTART_FOLDER}${/}ipv4_routes    session=${CONFIG_SESSION}    verify=True

Post_Graceful_Restart_To_Internal_Peer
    &{mapping}    BuiltIn.Create_Dictionary    IP=${iBGP_PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Post_As_Xml_Templated    ${GRACEFUL_RESTART_FOLDER}${/}restart    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Sleep    2s    # TODO: wuks with keyword
    ${update} =    BgpRpcClient1.play_get
    BuiltIn.Log    ${update}

Verify_ODL_Contains_All_Routes_02
    TemplatedRequests.Get_As_Json_Templated    ${GRACEFUL_RESTART_FOLDER}${/}ipv4_routes    session=${CONFIG_SESSION}    verify=True

Post_Graceful_Restart_To_All_Peers
    : FOR    ${peer}    IN    @{BGP_PEERS_IPS}
    \    &{mapping}    BuiltIn.Create_Dictionary    IP=${peer}    BGP_RIB=${RIB_NAME}
    \    TemplatedRequests.Post_As_Xml_Templated    ${GRACEFUL_RESTART_FOLDER}${/}restart    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Sleep    2s    # TODO: wuks with keyword
    ${update} =    BgpRpcClient1.play_get
    BuiltIn.Log    ${update}
    ${update} =    BgpRpcClient2.play_get
    BuiltIn.Log    ${update}
    ${update} =    BgpRpcClient3.play_get
    BuiltIn.Log    ${update}

Verify_ODL_Contains_All_Routes_03
    TemplatedRequests.Get_As_Json_Templated    ${GRACEFUL_RESTART_FOLDER}${/}ipv4_routes    session=${CONFIG_SESSION}    verify=True

Post_Graceful_From_Internal_Peer
    BuiltIn.No_Operation
    #    TODO: send hex via BgpRpcClient.play_send

Verify_ODL_Contains_All_Routes_04
    TemplatedRequests.Get_As_Json_Templated    ${GRACEFUL_RESTART_FOLDER}${/}ipv4_routes    session=${CONFIG_SESSION}    verify=True

Kill_Talking_BGP_Speakers
    [Documentation]    Abort all Python speakers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${peer}    IN    @{BGP_PEERS}
    \    BGPcliKeywords.Store_File_To_Workspace    play.py.${peer}    graceful_restart_play_${peer}.log
    BGPSpeaker.Kill_All_BGP_Speakers

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    IP=${iBGP_PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GRACEFUL_RESTART_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER1_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GRACEFUL_RESTART_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${eBGP_PEER2_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${GRACEFUL_RESTART_FOLDER}${/}peers    mapping=${mapping}    session=${CONFIG_SESSION}

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

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Start_Bgp_Peer
    [Arguments]    ${command}
    [Documentation]    Starts bgp peer.
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Resolve_Text_From_File
    [Arguments]    ${folder}    ${file_name}    ${mapping}={}
    [Documentation]    Read and Log contents of file ${folder}/${file_name}, remove endline,
    ...    perform safe substitution, return result.
    ${file_path}=    BuiltIn.Set_Variable    ${folder}${/}${file_name}
    ${template} =    OperatingSystem.Get_File    ${file_path}
    BuiltIn.Log    ${template}
    ${final_text} =    BuiltIn.Evaluate    string.Template('''${template}'''.rstrip()).safe_substitute(${mapping})    modules=string
    [Return]    ${final_text}
