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
...               There are 3 peers: ebgp and two ibgps. First peer sends l3vpn route with specific RT to odl, second peer
...               sends RT route and third peer only establishes connection. Then it is checked that odl advertizes l3vpn route
...               to second peer. Third peer sends wildcard RT route and it is checked that odl doesn't advertize l3vpn route
...               to it. Then second peer removes RT and it is checked that second peer withdrew RT route and that odl withdrew
...               l3vpn route from it.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8002    WITH NAME    BgpRpcClient2
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8003    WITH NAME    BgpRpcClient3
Library           ../../../libraries/BgpRpcClient.py    ${ODL_SYSTEM_IP}    8004    WITH NAME    BgpRpcClient4
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
${CONFIG_SESSION}    config-session
${RT_CONSTRAIN_DIR}    ${CURDIR}/../../../variables/bgpfunctional/rt_constrain
${EBGP_DIR}       ${CURDIR}/../../../variables/bgpfunctional/ebgp_peer
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_NAME}       example-bgp-rib
${ODL_2_IP}       127.0.0.2
${ODL_3_IP}       127.0.0.3
${ODL_4_IP}       127.0.0.4
${OLD_AS_PATH}    \n"as-path": {},
${NEW_AS_PATH}    ${EMPTY}
@{BGP_PEER_TYPES}    external    internal    internal
@{BGP_PEER_AS_NUMBERS}    65000    64496    64496
@{ODL_IP_INDICES_ALL}    2    3    4
@{L3VPN_RT_CHECK}    false    true    false
&{RT_CONSTRAIN_APP_PEER}    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
&{ADJ_RIB_OUT}    PATH=peer/bgp:%2F%2F${ODL_3_IP}/adj-rib-out    BGP_RIB=${RIB_NAME}

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${i}    ${type}    IN ZIP    ${ODL_IP_INDICES_ALL}    ${BGP_PEER_TYPES}
    \    &{ODL_CONFIG}=    BuiltIn.Create_Dictionary    IP=${ODL_${i}_IP}    TYPE=${type}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    \    ...    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    \    TemplatedRequests.Put_As_Xml_Templated    ${EBGP_DIR}    mapping=${ODL_CONFIG}    session=${CONFIG_SESSION}

Start_Bgp_Peers
    [Documentation]    Start Python speaker to connect to ODL. We give each speaker time until odl really starts to accept incoming
    ...    bgp connection. The failure happens if the incoming connection comes too quickly after configuring the peer.
    [Tags]    local_run
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${i}    ${as_number}    IN ZIP    ${ODL_IP_INDICES_ALL}    ${BGP_PEER_AS_NUMBERS}
    \    BuiltIn.Log_Many    IP: ${ODL_${i}_IP}    as_number: ${as_number}
    \    Start_Bgp_Peer    ${ODL_${i}_IP}    ${as_number}    800${i}    play.py.090.${i}

Play_To_Odl_ext_l3vpn_rt_arg
    [Documentation]    This TC sends route-target route containing route-target argument from node 1 to odl
    ...    so odl can identify this peer as appropriate for advertizement when it recieves such route.
    Play_To_Odl_Non_Removal_BgpRpcClient2    ext_l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}
    &{effective_rib_in}    BuiltIn.Create_Dictionary    PATH=peer/bgp:%2F%2F${ODL_2_IP}/effective-rib-in    BGP_RIB=${RIB_NAME}    AS_PATH=${AS_PATH}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    ${RT_CONSTRAIN_DIR}/ext_l3vpn_rt_arg/rib    mapping=${effective_rib_in}    session=${CONFIG_SESSION}
    ...    verify=True

Play_To_Odl_rt_constrain_type_0
    [Documentation]    Sends RT route from node 2 to odl and then checks that odl advertizes l3vpn route from previous TC.
    Play_To_Odl_Non_Removal_BgpRpcClient3    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}
    &{loc_rib}    BuiltIn.Create_Dictionary    PATH=loc-rib    BGP_RIB=${RIB_NAME}    AS_PATH=${AS_PATH}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    ${RT_CONSTRAIN_DIR}/rt_constrain_type_0/rib    mapping=${loc_rib}    session=${CONFIG_SESSION}
    ...    verify=True

Check_Presence_Of_l3vpn_Route_In_Node_2_Effective_Rib_In_Table
    [Documentation]    Checks l3vpn route is present in node 2 effective-rib-in table.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    ${RT_CONSTRAIN_DIR}/ext_l3vpn_rt_arg/rib    mapping=${ADJ_RIB_OUT}    session=${CONFIG_SESSION}
    ...    verify=True

Check_l3vpn_Route_Advertisement_On_Each_Node
    [Documentation]    Checks that each node received or did not receive update message containing given hex message.
    ${announce} =    OperatingSystem.Get_File    ${RT_CONSTRAIN_DIR}/ext_l3vpn_rt_arg/announce_ext_l3vpn_rt_arg.hex
    ${announce_hex} =    String.Remove_String    ${announce}    \n
    Check_For_L3VPN_Odl_Avertisement    ${announce_hex}

Play_To_Odl_rt_constrain_type_1
    [Documentation]    Sends RT route from node 3 to odl and then checks that odl does not advertize l3vpn route from previous TC,
    ...    that is that update message is empty.
    Play_To_Odl_Non_Removal_BgpRpcClient4    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}
    &{effective_rib_in} =    BuiltIn.Create_Dictionary    PATH=peer/bgp:%2F%2F${ODL_4_IP}/effective-rib-in    BGP_RIB=${RIB_NAME}    AS_PATH=${AS_PATH}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    ${RT_CONSTRAIN_DIR}/rt_constrain_type_1/rib    mapping=${effective_rib_in}    session=${CONFIG_SESSION}
    ...    verify=True
    ${update} =    BgpRpcClient4.play_get
    Comment    From neon onwards there is extra BGP End-Of-RIB message
    CompareStream.Run_Keyword_If_At_Most_Fluorine    BuiltIn.Should_Be_Equal    ${update}    ${Empty}

Play_To_Odl_remove_rt
    [Documentation]    Removes RT from odl and then checks that second node withdrew l3vpn route and third node did not receive any message.
    BgpRpcClient3.play_clean
    Play_To_Odl_Routes_Removal_Template_BgpRpcClient3    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Verify_Empty_Reported_Data
    ${update} =    BgpRpcClient4.play_get
    BuiltIn.Should_Be_Equal    ${update}    ${Empty}
    Comment    From neon onwards there is extra BGP End-Of-RIB message
    CompareStream.Run_Keyword_If_At_Most_Fluorine    BuiltIn.Should_Be_Equal    ${update}    ${Empty}

Play_To_Odl_remove_routes
    [Documentation]    Removes rt arguments from odl.
    Play_To_Odl_Routes_Removal_Template_BgpRpcClient2    ext_l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}
    Play_To_Odl_Routes_Removal_Template_BgpRpcClient4    rt_constrain_type_1    ${RT_CONSTRAIN_DIR}

Kill_Talking_BGP_Speakers
    [Documentation]    Abort all Python speakers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPcliKeywords.Store_File_To_Workspace    play.py.090.2    090_rt_constrain_play_1.log
    BGPcliKeywords.Store_File_To_Workspace    play.py.090.3    090_rt_constrain_play_2.log
    BGPcliKeywords.Store_File_To_Workspace    play.py.090.4    090_rt_constrain_play_3.log
    BGPSpeaker.Kill_All_BGP_Speakers

Delete_Bgp_Peers_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${i}    ${type}    IN ZIP    ${ODL_IP_INDICES_ALL}    ${BGP_PEER_TYPES}
    \    &{ODL_CONFIG} =    BuiltIn.Create_Dictionary    IP=${ODL_${i}_IP}    TYPE=${type}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    \    ...    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    \    TemplatedRequests.Delete_Templated    ${EBGP_DIR}    mapping=${ODL_CONFIG}    session=${CONFIG_SESSION}

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
    ${AS_PATH} =    CompareStream.Set_Variable_If_At_Least_Neon    ${NEW_AS_PATH}    ${OLD_AS_PATH}
    BuiltIn.Set_Suite_Variable    ${AS_PATH}

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Start_Bgp_Peer
    [Arguments]    ${ip}    ${as_number}    ${port}    ${filename}
    [Documentation]    Starts bgp peer.
    ${command} =    BuiltIn.Set_Variable    python play.py --amount 0 --myip=${ip} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --asnumber=${as_number} --peerport=${ODL_BGP_PORT} --port=${port} --usepeerip --debug --allf --wfr 1 &> ${filename} &
    BuiltIn.Log    ${command}
    ${output} =    SSHLibrary.Write    ${command}

Play_To_Odl_Non_Removal_BgpRpcClient2
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    [Documentation]    Read contents of file ${dir}/${totest}/announce_${totest}.hex and send it to odl.
    ${announce_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/announce_${totest}.hex
    BgpRpcClient2.play_send    ${announce_hex}

Play_To_Odl_Non_Removal_BgpRpcClient3
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    [Documentation]    Read contents of file ${dir}/${totest}/announce_${totest}.hex and send it to odl.
    ${announce_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/announce_${totest}.hex
    BgpRpcClient3.play_send    ${announce_hex}

Play_To_Odl_Non_Removal_BgpRpcClient4
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    [Documentation]    Read contents of file ${dir}/${totest}/announce_${totest}.hex and send it to odl.
    ${announce_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/announce_${totest}.hex
    BgpRpcClient4.play_send    ${announce_hex}

Play_To_Odl_Routes_Removal_Template_BgpRpcClient2
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    [Documentation]    Read contents of file ${dir}/${totest}/withdraw_${totest}.hex and send it to odl to remove rt argument from odl.
    ${withdraw_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/withdraw_${totest}.hex
    BgpRpcClient2.play_clean
    BgpRpcClient2.play_send    ${withdraw_hex}

Play_To_Odl_Routes_Removal_Template_BgpRpcClient3
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    [Documentation]    Read contents of file ${dir}/${totest}/withdraw_${totest}.hex and send it to odl to remove rt argument from odl.
    ${withdraw_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/withdraw_${totest}.hex
    BgpRpcClient3.play_clean
    BgpRpcClient3.play_send    ${withdraw_hex}

Play_To_Odl_Routes_Removal_Template_BgpRpcClient4
    [Arguments]    ${totest}    ${dir}    ${ipv}=ipv4
    [Documentation]    Read contents of file ${dir}/${totest}/withdraw_${totest}.hex and send it to odl to remove rt argument from odl.
    ${withdraw_hex} =    OperatingSystem.Get_File    ${dir}/${totest}/withdraw_${totest}.hex
    BgpRpcClient4.play_clean
    BgpRpcClient4.play_send    ${withdraw_hex}

Get_Update_Message_And_Compare_With_Hex_BgpRpcClient2
    [Arguments]    ${hex}    ${option}
    [Documentation]    Returns hex update message and compares it to hex.
    ${update} =    BgpRpcClient2.play_get
    BuiltIn.Run_Keyword_If    "${option}" == "true"    BuiltIn.Should_Be_Equal_As_Strings    ${update}    ${hex}
    BuiltIn.Run_Keyword_If    "${option}" == "false"    BuiltIn.Should_Not_Be_Equal_As_Strings    ${update}    ${hex}

Get_Update_Message_And_Compare_With_Hex_BgpRpcClient3
    [Arguments]    ${hex}    ${option}
    [Documentation]    Returns hex update message and compares it to hex.
    ${update} =    BgpRpcClient3.play_get
    BuiltIn.Run_Keyword_If    "${option}" == "true"    BuiltIn.Should_Be_Equal_As_Strings    ${update}    ${hex}
    BuiltIn.Run_Keyword_If    "${option}" == "false"    BuiltIn.Should_Not_Be_Equal_As_Strings    ${update}    ${hex}

Get_Update_Message_And_Compare_With_Hex_BgpRpcClient4
    [Arguments]    ${hex}    ${option}
    [Documentation]    Returns hex update message and compares it to hex.
    ${update} =    BgpRpcClient4.play_get
    BuiltIn.Run_Keyword_If    "${option}" == "true"    BuiltIn.Should_Be_Equal_As_Strings    ${update}    ${hex}
    BuiltIn.Run_Keyword_If    "${option}" == "false"    BuiltIn.Should_Not_Be_Equal_As_Strings    ${update}    ${hex}

Check_For_L3VPN_Odl_Avertisement
    [Arguments]    ${announce_hex}
    [Documentation]    Checks that each node received or did not receive update message containing given hex message.
    : FOR    ${i}    ${option}    IN ZIP    ${ODL_IP_INDICES_ALL}    ${L3VPN_RT_CHECK}
    \    ${keyword_name}=    BuiltIn.Set_Variable    Get_Update_Message_And_Compare_With_Hex_BgpRpcClient${i}
    \    BuiltIn.Run_Keyword    ${keyword_name}    ${announce_hex}    ${option}

Verify_Reported_Data
    [Arguments]    ${url}    ${exprspfile}
    [Documentation]    Verifies expected response
    ${expresponse} =    OperatingSystem.Get File    ${exprspfile}
    BuiltIn.Log    expected_response: ${expresponse}
    ${rsp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${url}
    BuiltIn.Log    actual_response: ${rsp}
    BuiltIn.Log    actual_response_content: ${rsp.content}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${expresponse}    ${rsp.content}

Verify_Empty_Reported_Data
    [Documentation]    Verify empty data response
    CompareStream.Run_Keyword_If_At_Most_Fluorine    TemplatedRequests.Get_As_Json_Templated    ${RT_CONSTRAIN_DIR}${/}empty_l3vpn    session=${CONFIG_SESSION}    mapping=${ADJ_RIB_OUT}    verify=True
    CompareStream.Run_Keyword_If_At_Least_Neon    Verify_Empty_Data_Neon

Verify_Empty_Data_Neon
    [Documentation]    Verify empty data on neon
    TemplatedRequests.Get_As_Json_Templated    ${RT_CONSTRAIN_DIR}${/}empty_route    session=${CONFIG_SESSION}    mapping=${ADJ_RIB_OUT}    verify=True
