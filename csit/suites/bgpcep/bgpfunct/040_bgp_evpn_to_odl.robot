*** Settings ***
Documentation     Functional test for bgp.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Library           ${CURDIR}/../../../libraries/norm_json.py
Library           ${CURDIR}/../../../libraries/BgpRpcClient.py        ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Test Setup        Verify Test Preconditions


*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${CMD}            source ~/osctestenv/bin/activate; env exabgp.tcp.port=1790 exabgp --debug
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${DEFAUTL_RPC_CFG}     exa.cfg
${L3VPN_CFG}           bgp-l3vpn-ipv4.cfg
${L3VPN_RSPEMPTY}      l3vpn_ipv4/bgp-l3vpn-ipv4-empty.json
${L3VPN_RSP}           l3vpn_ipv4/bgp-l3vpn-ipv4.json
${L3VPN_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-types:mpls-labeled-vpn-subsequent-address-family/bgp-vpn-ipv4:vpn-ipv4-routes
${CONFIG_SESSION}      config-session
${JOLOKURL}    /jolokia/read/org.opendaylight.controller:instanceName=${BGP_PEER_NAME},type=RuntimeBean,moduleFactoryName=bgp-peer
${EVPN_VARIABLES_DIR}    ${CURDIR}/../../../variables/bgpfunctional/l2vpn_evpn
${BGP_TOOL_LOG_LEVEL}      debug
${PLAY_SCRIPT}           ${CURDIR}/../../../../tools/fastbgp/play.py
${EVPN_CONF_URL}      /restconf/config/bgp-rib:application-rib/example-app-rib/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes/
${LOC_RIB_URL}        /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/odl-bgp-evpn:l2vpn-address-family/odl-bgp-evpn:evpn-subsequent-address-family/odl-bgp-evpn:evpn-routes

*** Test Cases ***
#Reconfigure_ODL_To_Accept_Connection
#    [Documentation]    Configure BGP peer module with initiate-connection set to false.
#    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
#    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
#    TemplatedRequests.Put_As_Json_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start Bgp Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer


Play To Odl route_es_arb
    [Template]    Play To Odl Template
    route_es_arb

Play To Odl route_es_as
    [Template]    Play To Odl Template
    route_es_as

Play To Odl route_es_lacp
    [Template]    Play To Odl Template
    route_es_lacp

Play To Odl route_es_lan
    [Template]    Play To Odl Template
    route_es_lan

Play To Odl route_es_mac
    [Template]    Play To Odl Template
    route_es_mac

Play To Odl route_es_rou
    [Template]    Play To Odl Template
    route_es_rou

Play To Odl route_eth_lacp_extesr
    [Template]    Play To Odl Template
    route_eth_lacp_extesr

Play To Odl route_eth_arb
    [Template]    Play To Odl Template
    route_eth_arb

Play To Odl route_eth_as
    [Template]    Play To Odl Template
    route_eth_as

Play To Odl route_eth_lacp
    [Template]    Play To Odl Template
    route_eth_lacp

Play To Odl route_eth_lacp_extdef
    [Template]    Play To Odl Template
    route_eth_lacp_extdef

Play To Odl route_eth_lacp_extesilab
    [Template]    Play To Odl Template
    route_eth_lacp_extesilab

Play To Odl route_eth_lacp_extesr
    [Template]    Play To Odl Template
    route_eth_lacp_extesr

Play To Odl route_eth_lacp_extl2
    [Template]    Play To Odl Template
    route_eth_lacp_extl2

Play To Odl route_eth_lacp_extmac
    [Template]    Play To Odl Template
    route_eth_lacp_extmac

Play To Odl route_eth_lan
    [Template]    Play To Odl Template
    route_eth_lan

Play To Odl route_eth_mac
    [Template]    Play To Odl Template
    route_eth_mac

Play To Odl route_eth_rou
    [Template]    Play To Odl Template
    route_eth_rou

Play To Odl route_inc_arb
    [Template]    Play To Odl Template
    route_inc_arb

Play To Odl route_inc_as
    [Template]    Play To Odl Template
    route_inc_as

Play To Odl route_inc_lacp
    [Template]    Play To Odl Template
    route_inc_lacp

Play To Odl route_inc_lan
    [Template]    Play To Odl Template
    route_inc_lan

Play To Odl route_inc_mac
    [Template]    Play To Odl Template
    route_inc_mac

Play To Odl route_inc_rou
    [Template]    Play To Odl Template
    route_inc_rou

Play To Odl route_mac_arb
    [Template]    Play To Odl Template
    route_mac_arb

Play To Odl route_mac_as
    [Template]    Play To Odl Template
    route_mac_as

Play To Odl route_mac_lacp
    [Template]    Play To Odl Template
    route_mac_lacp

Play To Odl route_mac_lan
    [Template]    Play To Odl Template
    route_mac_lan

Play To Odl route_mac_mac
    [Template]    Play To Odl Template
    route_mac_mac

Play To Odl route_mac_rou
    [Template]    Play To Odl Template
    route_mac_rou

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    BGPSpeaker.Kill_BGP_Speaker


#Delete_Bgp_Peer_Configuration
#    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
#    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
#    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
#    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
#    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    RequestsLibrary.Create Session   ${CONFIG_SESSION}     http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Put File    ${PLAY_SCRIPT}    .

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Start Bgp Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_TOOL_LOG_LEVEL} --evpn --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Odl To Play Template
    [Arguments]      ${totest}
    ${data_xml}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/${totest}.xml
    ${data_json}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/${totest}.json
    ${announce_hex}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/announce_${totest}.hex
    ${withdraw_hex}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/withdraw_${totest}.hex
    BuiltIn.Log    ${data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BgpRpcClient.play_clean
    ${resp}=     RequestsLibrary.Post Request    ${CONFIG_SESSION}     ${EVPN_CONF_URL}      data=${data_xml}    headers=${HEADERS_XML}
    BuiltIn.Should Be Equal As Numbers    ${resp.status_code}    204
    ${aupdate}=       BuiltIn.Wait Until Keyword Succeeds   4x   2s   Get Update Content
    BuiltIn.Log     ${aupdate};
    BuiltIn.Should Be Equal As Strings   ${aupdate}    ${announce_hex}
    BgpRpcClient.play_clean
    Remove Configured Routes
    ${wupdate}=       BuiltIn.Wait Until Keyword Succeeds   4x   2s   Get Update Content
    BuiltIn.Log     ${wupdate}
    BuiltIn.Should Be Equal As Strings    ${wupdate}   ${withdraw_hex}
    [Teardown]      Remove Configured Routes

Play To Odl Template
    [Arguments]      ${totest}
    ${data_xml}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/${totest}.xml
    ${data_json}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/${totest}.json
    ${announce_hex}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/announce_${totest}.hex
    ${withdraw_hex}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/withdraw_${totest}.hex
    ${empty_routes}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/empty_routes.json
    BuiltIn.Set Suite Variable    ${withdraw_hex}
    BuiltIn.Set Suite Variable    ${empty_routes}
    BuiltIn.Log    ${data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BuiltIn.Log    ${empty_routes}
    BgpRpcClient.play_clean
    BgpRpcClient.play_send     ${announce_hex}
    BuiltIn.Wait Until Keyword Succeeds   4x   2s     Loc Rib Presnece     ${data_json}
    BgpRpcClient.play_send     ${withdraw_hex}
    BuiltIn.Wait Until Keyword Succeeds   4x   2s     Loc Rib Presnece     ${empty_routes}
    [Teardown]      Withdraw Route And Verify    ${withdraw_hex}


Verify Test Preconditions
    [Arguments]
    ${resp}=     RequestsLibrary.Get Request    ${CONFIG_SESSION}     ${EVPN_CONF_URL}
    BuiltIn.Should Be Equal As Numbers    ${resp.status_code}    404
    ${empty_routes}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/empty_routes.json
    Loc Rib Presnece     ${empty_routes}

Remove Configured Routes
    ${rsp}=     RequestsLibrary.Get Request    ${CONFIG_SESSION}     ${LOC_RIB_URL}     headers=${HEADERS}
    Log     ${rsp.content}
    ${resp}=     RequestsLibrary.Delete Request   ${CONFIG_SESSION}    ${EVPN_CONF_URL}
    BuiltIn.Should Be Equal As Numbers    ${resp.status_code}    200

Withdraw Route And Verify
    [Arguments]     ${withdraw_hex}
    BgpRpcClient.play_send     ${withdraw_hex}
    BuiltIn.Wait Until Keyword Succeeds   3x   2s    Loc Rib Presnece     ${empty_routes}

Get Update Content
    ${update}=       BgpRpcClient.play_get
    BuiltIn.Should Not Be Equal    ${update}     ${Empty}
    [Return]    ${update}

Loc Rib Presnece
    [Arguments]   ${exp_content}
    ${rsp}=     RequestsLibrary.Get Request    ${CONFIG_SESSION}     ${LOC_RIB_URL}     headers=${HEADERS}
    Log     ${rsp.content}
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${received_json}=    norm_json.Normalize Json Text    ${rsp.content}     keys_with_bits=${keys_with_bits}
    BuiltIn.Log     ${received_json}
    ${expected_json}=    norm_json.Normalize Json Text    ${exp_content}     keys_with_bits=${keys_with_bits}
    BuiltIn.Should Be Equal    ${received_json}    ${expected_json}
