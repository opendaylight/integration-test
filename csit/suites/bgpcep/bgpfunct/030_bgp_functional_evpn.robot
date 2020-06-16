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
...               AND    Verify_Test_Preconditions
Test Template     Odl_To_Play_Template
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${RIB_NAME}       example-bgp-rib
${BGP_DIR}        ${CURDIR}/../../../variables/bgpfunctional
${DEFAUTL_RPC_CFG}    exa.cfg
${CONFIG_SESSION}    config-session
${EVPN_DIR}       ${CURDIR}/../../../variables/bgpfunctional/l2vpn_evpn
${BGP_TOOL_LOG_LEVEL}    debug
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${SS}             ${SPACE}${SPACE}${SPACE}${SPACE}
${PATH_ID_JSON}    ${SS}${SS}"path-id": 0,${\n}
${PATH_ID_XML}    ${SS}<path-id>0</path-id>${\n}
${OLD_EVPN_ROUTES_LINE}    \n"odl-bgp-evpn:evpn-routes": {},
${NEW_EVPN_ROUTES_LINE}    ${EMPTY}
${OLD_AS_PATH}    ,\n"as-path": {}
${NEW_AS_PATH}    ${EMPTY}

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    NONE
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${RIB_NAME}    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_DIR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    NONE
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB_OPENCONFIG=${RIB_NAME}
    ...    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_DIR}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Bgp_Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    NONE
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer

Odl_To_Play_route_es_arb
    route_es_arb

Play_To_Odl_route_es_arb
    [Template]    Play_To_Odl_Template
    route_es_arb

Odl_To_Play_route_es_as
    route_es_as

Play_To_Odl_route_es_as
    [Template]    Play_To_Odl_Template
    route_es_as

Odl_To_Play_route_es_lacp
    route_es_lacp

Play_To_Odl_route_es_lacp
    [Template]    Play_To_Odl_Template
    route_es_lacp

Odl_To_Play_route_es_lan
    route_es_lan

Play_To_Odl_route_es_lan
    [Template]    Play_To_Odl_Template
    route_es_lan

Odl_To_Play_route_es_mac
    route_es_mac

Play_To_Odl_route_es_mac
    [Template]    Play_To_Odl_Template
    route_es_mac

Odl_To_Play_route_es_rou
    route_es_rou

Play_To_Odl_route_es_rou
    [Template]    Play_To_Odl_Template
    route_es_rou

Odl_To_Play_route_eth_arb
    route_eth_arb

Play_To_Odl_route_eth_arb
    [Template]    Play_To_Odl_Template
    route_eth_arb

Odl_To_Play_route_eth_as
    route_eth_as

Play_To_Odl_route_eth_as
    [Template]    Play_To_Odl_Template
    route_eth_as

Odl_To_Play_route_eth_lacp
    route_eth_lacp

Play_To_Odl_route_eth_lacp
    [Template]    Play_To_Odl_Template
    route_eth_lacp

Odl_To_Play_route_eth_lacp_extdef
    route_eth_lacp_extdef

Play_To_Odl_route_eth_lacp_extdef
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extdef

Odl_To_Play_route_eth_lacp_extesilab
    route_eth_lacp_extesilab

Play_To_Odl_route_eth_lacp_extesilab
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extesilab

Odl_To_Play_route_eth_lacp_extesr
    route_eth_lacp_extesr

Play_To_Odl_route_eth_lacp_extesr
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extesr

Odl_To_Play_route_eth_lacp_extl2
    route_eth_lacp_extl2

Play_To_Odl_route_eth_lacp_extl2
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extl2

Odl_To_Play_route_eth_lacp_extmac
    route_eth_lacp_extmac

Play_To_Odl_route_eth_lacp_extmac
    [Template]    Play_To_Odl_Template
    route_eth_lacp_extmac

Odl_To_Play_route_eth_lan
    route_eth_lan

Play_To_Odl_route_eth_lan
    [Template]    Play_To_Odl_Template
    route_eth_lan

Odl_To_Play_route_eth_mac
    route_eth_mac

Play_To_Odl_route_eth_mac
    [Template]    Play_To_Odl_Template
    route_eth_mac

Odl_To_Play_route_eth_rou
    route_eth_rou

Play_To_Odl_route_eth_rou
    [Template]    Play_To_Odl_Template
    route_eth_rou

Odl_To_Play_route_inc_arb
    route_inc_arb

Play_To_Odl_route_inc_arb
    [Template]    Play_To_Odl_Template
    route_inc_arb

Odl_To_Play_route_inc_as
    route_inc_as

Play_To_Odl_route_inc_as
    [Template]    Play_To_Odl_Template
    route_inc_as

Odl_To_Play_route_inc_lacp
    route_inc_lacp

Play_To_Odl_route_inc_lacp
    [Template]    Play_To_Odl_Template
    route_inc_lacp

Odl_To_Play_route_inc_lan
    route_inc_lan

Play_To_Odl_route_inc_lan
    [Template]    Play_To_Odl_Template
    route_inc_lan

Odl_To_Play_route_inc_mac
    route_inc_mac

Play_To_Odl_route_inc_mac
    [Template]    Play_To_Odl_Template
    route_inc_mac

Odl_To_Play_route_inc_rou
    route_inc_rou

Play_To_Odl_route_inc_rou
    [Template]    Play_To_Odl_Template
    route_inc_rou

Odl_To_Play_route_mac_arb
    route_mac_arb

Play_To_Odl_route_mac_arb
    [Template]    Play_To_Odl_Template
    route_mac_arb

Odl_To_Play_route_mac_as
    route_mac_as

Play_To_Odl_route_mac_as
    [Template]    Play_To_Odl_Template
    route_mac_as

Odl_To_Play_route_mac_lacp
    route_mac_lacp

Play_To_Odl_route_mac_lacp
    [Template]    Play_To_Odl_Template
    route_mac_lacp

Odl_To_Play_route_mac_lan
    route_mac_lan

Play_To_Odl_route_mac_lan
    [Template]    Play_To_Odl_Template
    route_mac_lan

Odl_To_Play_route_mac_mac
    route_mac_mac

Play_To_Odl_route_mac_mac
    [Template]    Play_To_Odl_Template
    route_mac_mac

Odl_To_Play_route_mac_rou
    route_mac_rou

Play_To_Odl_route_mac_rou
    [Template]    Play_To_Odl_Template
    route_mac_rou

Odl_To_Play_pmsi_rsvp_te_p2mp_lsp
    [Template]    None
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Odl_To_Play_Template    pmsi_rsvp_te_p2mp_lsp

Play_To_Odl_pmsi_rsvp_te_p2mp_lsp
    [Template]    None
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Play_To_Odl_Template    pmsi_rsvp_te_p2mp_lsp

Odl_To_Play_pmsi_mldp_p2mp_lsp
    pmsi_mldp_p2mp_lsp

Play_To_Odl_pmsi_mldp_p2mp_lsp
    [Template]    Play_To_Odl_Template
    pmsi_mldp_p2mp_lsp

Odl_To_Play_pmsi_pim_ssm_tree
    pmsi_pim_ssm_tree

Play_To_Odl_pmsi_pim_ssm_tree
    [Template]    Play_To_Odl_Template
    pmsi_pim_ssm_tree

Odl_To_Play_pmsi_pim_sm_tree
    pmsi_pim_sm_tree

Play_To_Odl_pmsi_pim_sm_tree
    [Template]    Play_To_Odl_Template
    pmsi_pim_sm_tree

Odl_To_Play_pmsi_bidir_pim_tree
    pmsi_bidir_pim_tree

Play_To_Odl_pmsi_bidir_pim_tree
    [Template]    Play_To_Odl_Template
    pmsi_bidir_pim_tree

Odl_To_Play_pmsi_ingress_replication
    pmsi_ingress_replication

Play_To_Odl_pmsi_ingress_replication
    [Template]    Play_To_Odl_Template
    pmsi_ingress_replication

Odl_To_Play_pmsi_mldp_mp2mp_lsp
    pmsi_mldp_mp2mp_lsp

Play_To_Odl_pmsi_mldp_mp2mp_lsp
    [Template]    Play_To_Odl_Template
    pmsi_mldp_mp2mp_lsp

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    NONE
    BGPSpeaker.Kill_BGP_Speaker
    BGPcliKeywords.Store_File_To_Workspace    play.py.out    evpn_play.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    NONE
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_DIR}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    NONE
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_DIR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

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
    BuiltIn.Set_Suite_Variable    ${EVPN_CONF_URL}    /restconf/config/bgp-rib:application-rib/${ODL_SYSTEM_IP}/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes
    BuiltIn.Set_Suite_Variable    ${EVPN_LOC_RIB}    /restconf/operational/bgp-rib:bgp-rib/rib/${RIB_NAME}/loc-rib/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes
    BuiltIn.Set_Suite_Variable    ${EVPN_FAMILY_LOC_RIB}    /restconf/operational/bgp-rib:bgp-rib/rib/${RIB_NAME}/loc-rib/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/
    ${evpn_routes_line} =    CompareStream.Set_Variable_If_At_Least_Neon    ${NEW_EVPN_ROUTES_LINE}    ${OLD_EVPN_ROUTES_LINE}
    &{mapping}    BuiltIn.Create_Dictionary    EVPN_ROUTES=${evpn_routes_line}
    ${EMPTY_ROUTES} =    TemplatedRequests.Resolve_Text_From_Template_File    ${EVPN_DIR}/empty_routes    empty_routes.json    ${mapping}
    BuiltIn.Set_Suite_Variable    ${EMPTY_ROUTES}

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
    ${data_xml} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/${totest}.xml
    ${data_json} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/${totest}.json
    ${announce_hex} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/announce_${totest}.hex
    ${announce_hex} =    String.Remove_String    ${announce_hex}    \n
    ${withdraw_hex} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/withdraw_${totest}.hex
    ${withdraw_hex} =    String.Remove_String    ${withdraw_hex}    \n
    ${data_path_xml}    CompareStream.Run_Keyword_If_Less_Than_Fluorine    String.Replace_String    ${data_xml}    ${PATH_ID_XML}    ${EMPTY}
    ${post_data_xml}    CompareStream.Set_Variable_If_At_Least_Fluorine    ${data_xml}    ${data_path_xml}
    BuiltIn.Log    ${post_data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BgpRpcClient.play_clean
    ${resp} =    RequestsLibrary.Post_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}    data=${post_data_xml}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    204
    ${resp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    ${aupdate} =    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Get_Update_Content
    BuiltIn.Log    ${aupdate}
    BgpOperations.Verify_Two_Hex_Messages_Are_Equal    ${aupdate}    ${announce_hex}
    BgpRpcClient.play_clean
    Remove_Configured_Routes
    ${wupdate} =    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Get_Update_Content
    BuiltIn.Log    ${wupdate}
    BgpOperations.Verify_Two_Hex_Messages_Are_Equal    ${wupdate}    ${withdraw_hex}
    [Teardown]    Remove_Configured_Routes

Play_To_Odl_Template
    [Arguments]    ${totest}
    ${data_xml} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/${totest}.xml
    ${AS_PATH} =    CompareStream.Set_Variable_If_At_Least_Neon    ${NEW_AS_PATH}    ${OLD_AS_PATH}
    &{mapping}    BuiltIn.Create_Dictionary    AS_PATH=${AS_PATH}
    ${data_json} =    TemplatedRequests.Resolve_Text_From_Template_File    ${EVPN_DIR}/${totest}    ${totest}.json    ${mapping}
    ${announce_hex} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/announce_${totest}.hex
    ${withdraw_hex} =    OperatingSystem.Get_File    ${EVPN_DIR}/${totest}/withdraw_${totest}.hex
    ${data_path_json}    CompareStream.Run_Keyword_If_Less_Than_Fluorine    String.Replace_String    ${data_json}    ${PATH_ID_JSON}    ${EMPTY}
    ${data_json_exp}    CompareStream.Set_Variable_If_At_Least_Fluorine    ${data_json}    ${data_path_json}
    BuiltIn.Log    ${data_xml}
    BuiltIn.Log    ${data_json_exp}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BgpRpcClient.play_clean
    BgpRpcClient.play_send    ${announce_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Loc_Rib_Presence    ${data_json_exp}
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Verify_Test_Preconditions
    [Teardown]    Withdraw_Route_And_Verify    ${withdraw_hex}

Verify_Test_Preconditions
    ${resp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}
    BuiltIn.Should_Contain    ${DELETED_STATUS_CODES}    ${resp.status_code}
    ${rsp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_FAMILY_LOC_RIB}    headers=${HEADERS}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${EMPTY_ROUTES}    ${rsp.content}

Remove_Configured_Routes
    [Documentation]    Removes the route if present. First GET is for debug purposes.
    ${rsp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_LOC_RIB}    headers=${HEADERS}
    Log    ${rsp.content}
    ${rsp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}    headers=${HEADERS}
    Log    ${rsp.content}
    BuiltIn.Return_From_Keyword_If    ${rsp.status_code} in ${DELETED_STATUS_CODES}
    ${resp} =    RequestsLibrary.Delete_Request    ${CONFIG_SESSION}    ${EVPN_CONF_URL}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    200

Withdraw_Route_And_Verify
    [Arguments]    ${withdraw_hex}
    [Documentation]    Sends withdraw update message from exabgp and verifies route removal from odl's rib
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Verify_Test_Preconditions

Get_Update_Content
    [Documentation]    Gets received data from odl's peer
    ${resp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_LOC_RIB}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    ${update} =    BgpRpcClient.play_get
    BuiltIn.Should_Not_Be_Equal    ${update}    ${Empty}
    [Return]    ${update}

Loc_Rib_Presence
    [Arguments]    ${exp_content}
    [Documentation]    Verifies if loc-rib contains expected data
    ${rsp} =    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${EVPN_LOC_RIB}    headers=${HEADERS}
    BuiltIn.Log_Many    ${exp_content}    ${rsp.content}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp_content}    ${rsp.content}
