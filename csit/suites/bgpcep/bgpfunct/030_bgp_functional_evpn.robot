*** Settings ***
Documentation     Functional test for bgp - evpn
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests advertising and receiveing routes with evpn content.
...               It uses play.py and odl as bgp peers. Routes advertized from odl
...               are configured via application peer. Routes advertised from play.py are
...               stored in *.hex files. These files are used also as expected data which
...               is recevied from odl.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
...               AND    Verify Test Preconditions
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Library           ${CURDIR}/../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot

*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${DEFAUTL_RPC_CFG}    exa.cfg
${CONFIG_SESSION}    config-session
${EVPN_VARIABLES_DIR}    ${CURDIR}/../../../variables/bgpfunctional/l2vpn_evpn
${BGP_TOOL_LOG_LEVEL}    debug
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${PATH_ID_JSON}    "path-id": 0,${\n}${SPACE}${SPACE}${SPACE}${SPACE}"route-key"
${PATH_ID_XML}    </route-key>${\n}${SPACE}${SPACE}${SPACE}${SPACE}<path-id>0</path-id>

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Bgp_Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer

Odl_To_Play_route_es_arb
    [Template]    Odl_To_Play_Template
    route_es_arb

Play_To_Odl_route_es_arb
    [Template]    Play_To_Odl_Template
    route_es_arb

Odl_To_Play_route_es_as
    [Template]    Odl_To_Play_Template
    route_es_as

Play_To_Odl_route_es_as
    [Template]    Play_To_Odl_Template
    route_es_as

Odl_To_Play_route_es_lacp
    [Template]    Odl_To_Play_Template
    route_es_lacp

Play_To_Odl_route_es_lacp
    [Template]    Play_To_Odl_Template
    route_es_lacp

Odl_To_Play_route_es_lan
    [Template]    Odl_To_Play_Template
    route_es_lan

Play_To_Odl_route_es_lan
    [Template]    Play_To_Odl_Template
    route_es_lan

Odl_To_Play_route_es_mac
    [Template]    Odl_To_Play_Template
    route_es_mac

Play_To_Odl_route_es_mac
    [Template]    Play_To_Odl_Template
    route_es_mac

Odl_To_Play_route_es_rou
    [Template]    Odl_To_Play_Template
    route_es_rou

Play_To_Odl_route_es_rou
    [Template]    Play_To_Odl_Template
    route_es_rou

Odl_To_Play_route_eth_arb
    [Template]    Odl_To_Play_Template
    route_eth_arb

Play_To_Odl_route_eth_arb
    [Template]    Play_To_Odl_Template
    route_eth_arb

Odl_To_Play_route_eth_as
    [Template]    Odl_To_Play_Template
    route_eth_as

Play_To_Odl_route_eth_as
    [Template]    Play_To_Odl_Template
    route_eth_as

Odl_To_Play_route_eth_lacp
    [Template]    Odl_To_Play_Template
    route_eth_lacp

Play_To_Odl_route_eth_lacp
    [Template]    Play_To_Odl_Template
    route_eth_lacp

Odl_To_Play_route_eth_lacp_extdef
    [Template]    Odl_To_Play_Template
    route_eth_lacp_extdef

Play_To_Odl_route_eth_lacp_extdef
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extdef

Odl_To_Play_route_eth_lacp_extesilab
    [Template]    Odl_To_Play_Template
    route_eth_lacp_extesilab

Play_To_Odl_route_eth_lacp_extesilab
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extesilab

Odl_To_Play_route_eth_lacp_extesr
    [Template]    Odl_To_Play_Template
    route_eth_lacp_extesr

Play_To_Odl_route_eth_lacp_extesr
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extesr

Odl_To_Play_route_eth_lacp_extl2
    [Template]    Odl_To_Play_Template
    route_eth_lacp_extl2

Play_To_Odl_route_eth_lacp_extl2
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extl2

Odl_To_Play_route_eth_lacp_extmac
    [Template]    Odl_To_Play_Template
    route_eth_lacp_extmac

Play_To_Odl_route_eth_lacp_extmac
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extmac

Odl_To_Play_route_eth_lan
    [Template]    Odl_To_Play_Template
    route_eth_lan

Play_To_Odl_route_eth_lan
    [Template]    Play_To_Odl_Template
    route_eth_lan

Odl_To_Play_route_eth_mac
    [Template]    Odl_To_Play_Template
    route_eth_mac

Play_To_Odl_route_eth_mac
    [Template]    Play_To_Odl_Template
    route_eth_mac

Odl_To_Play_route_eth_rou
    [Template]    Odl_To_Play_Template
    route_eth_rou

Play_To_Odl_route_eth_rou
    [Template]    Play_To_Odl_Template
    route_eth_rou

Odl_To_Play_route_inc_arb
    [Template]    Odl_To_Play_Template
    route_inc_arb

Play_To_Odl_route_inc_arb
    [Template]    Play_To_Odl_Template
    route_inc_arb

Odl_To_Play_route_inc_as
    [Template]    Odl_To_Play_Template
    route_inc_as

Play_To_Odl_route_inc_as
    [Template]    Play_To_Odl_Template
    route_inc_as

Odl_To_Play_route_inc_lacp
    [Template]    Odl_To_Play_Template
    route_inc_lacp

Play_To_Odl_route_inc_lacp
    [Template]    Play_To_Odl_Template
    route_inc_lacp

Odl_To_Play_route_inc_lan
    [Template]    Odl_To_Play_Template
    route_inc_lan

Play_To_Odl_route_inc_lan
    [Template]    Play_To_Odl_Template
    route_inc_lan

Odl_To_Play_route_inc_mac
    [Template]    Odl_To_Play_Template
    route_inc_mac

Play_To_Odl_route_inc_mac
    [Template]    Play_To_Odl_Template
    route_inc_mac

Odl_To_Play_route_inc_rou
    [Template]    Odl_To_Play_Template
    route_inc_rou

Play_To_Odl_route_inc_rou
    [Template]    Play_To_Odl_Template
    route_inc_rou

Odl_To_Play_route_mac_arb
    [Template]    Odl_To_Play_Template
    route_mac_arb

Play_To_Odl_route_mac_arb
    [Template]    Play_To_Odl_Template
    route_mac_arb

Odl_To_Play_route_mac_as
    [Template]    Odl_To_Play_Template
    route_mac_as

Play_To_Odl_route_mac_as
    [Template]    Play_To_Odl_Template
    route_mac_as

Odl_To_Play_route_mac_lacp
    [Template]    Odl_To_Play_Template
    route_mac_lacp

Play_To_Odl_route_mac_lacp
    [Template]    Play_To_Odl_Template
    route_mac_lacp

Odl_To_Play_route_mac_lan
    [Template]    Odl_To_Play_Template
    route_mac_lan

Play_To_Odl_route_mac_lan
    [Template]    Play_To_Odl_Template
    route_mac_lan

Odl_To_Play_route_mac_mac
    [Template]    Odl_To_Play_Template
    route_mac_mac

Play_To_Odl_route_mac_mac
    [Template]    Play_To_Odl_Template
    route_mac_mac

Odl_To_Play_route_mac_rou
    [Template]    Odl_To_Play_Template
    route_mac_rou

Play_To_Odl_route_mac_rou
    [Template]    Play_To_Odl_Template
    route_mac_rou

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Initialize SetupUtils. Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    RequestsLibrary.Create Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Put File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    ${app_rib}=    Set Variable    ${ODL_SYSTEM_IP}
    ${bgp_rib}=    Set Variable    example-bgp-rib
    BuiltIn.Set_Suite_Variable    ${EVPN_CONF_URL}    /restconf/config/bgp-rib:application-rib/${app_rib}/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes/
    BuiltIn.Set_Suite_Variable    ${EVPN_LOC_RIB_OPER_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/${bgp_rib}/loc-rib/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Start_Bgp_Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_TOOL_LOG_LEVEL} --evpn --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Odl_To_Play_Template
    [Arguments]    ${totest}
    ${data_xml}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/${totest}.xml
    ${data_json}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/${totest}.json
    ${announce_hex}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/announce_${totest}.hex
    ${withdraw_hex}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/withdraw_${totest}.hex
    ${data_xml}    CompareStream.Run_Keyword_If_At_Least_Fluorine    String.Replace_String    ${data_xml}    </route-key>    ${PATH_ID_XML}
    BuiltIn.Log    ${data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BgpRpcClient.play_clean
    ${resp}=    RequestsLibrary.Post_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}    data=${data_xml}    headers=${HEADERS_XML}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    204
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    ${aupdate}=    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Get_Update_Content
    BuiltIn.Log    ${aupdate}
    BuiltIn.Should_Be_Equal_As_Strings    ${aupdate}    ${announce_hex}
    BgpRpcClient.play_clean
    Remove_Configured_Routes
    ${wupdate}=    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Get_Update_Content
    BuiltIn.Log    ${wupdate}
    BuiltIn.Should Be Equal As Strings    ${wupdate}    ${withdraw_hex}
    [Teardown]    Remove_Configured_Routes

Play_To_Odl_Template
    [Arguments]    ${totest}
    ${data_xml}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/${totest}.xml
    ${data_json}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/${totest}.json
    ${announce_hex}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/announce_${totest}.hex
    ${withdraw_hex}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/withdraw_${totest}.hex
    ${empty_routes}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/empty_routes.json
    ${data_json}    CompareStream.Run_Keyword_If_At_Least_Fluorine    String.Replace_String    ${data_json}    "route-key"    ${PATH_ID_JSON}
    BuiltIn.Set_Suite_Variable    ${withdraw_hex}
    BuiltIn.Set_Suite_Variable    ${empty_routes}
    BuiltIn.Log    ${data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BuiltIn.Log    ${empty_routes}
    BgpRpcClient.play_clean
    BgpRpcClient.play_send    ${announce_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Loc_Rib_Presnece    ${data_json}
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Loc_Rib_Presnece    ${empty_routes}
    [Teardown]    Withdraw_Route_And_Verify    ${withdraw_hex}

Verify_Test_Preconditions
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    404
    ${empty_routes}=    OperatingSystem.Get_File    ${EVPN_VARIABLES_DIR}/empty_routes.json
    Loc_Rib_Presnece    ${empty_routes}

Remove_Configured_Routes
    [Documentation]    Removes the route if present. First GET is for debug purposes.
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_LOC_RIB_OPER_URL}    headers=${HEADERS}
    Log    ${rsp.content}
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}    headers=${HEADERS}
    Log    ${rsp.content}
    BuiltIn.Return_From_Keyword_If    "${rsp.status_code}"=="404"
    ${resp}=    RequestsLibrary.Delete_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    200

Withdraw_Route_And_Verify
    [Arguments]    ${withdraw_hex}
    [Documentation]    Sends withdraw update message from exabgp and verifies route removal from odl's rib
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Loc Rib Presnece    ${empty_routes}

Get_Update_Content
    [Documentation]    Gets received data from odl's peer
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_LOC_RIB_OPER_URL}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    ${update}=    BgpRpcClient.play_get
    BuiltIn.Should_Not_Be_Equal    ${update}    ${Empty}
    [Return]    ${update}

Loc_Rib_Presnece
    [Arguments]    ${exp_content}
    [Documentation]    Verifies if loc-rib contains expected data
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_LOC_RIB_OPER_URL}    headers=${HEADERS}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp_content}    ${rsp.content}
