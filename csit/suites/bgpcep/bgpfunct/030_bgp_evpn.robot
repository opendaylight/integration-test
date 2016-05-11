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
Test Setup        Verify No Route In Operational


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

*** Test Cases ***
#Reconfigure_ODL_To_Accept_Connection
#    [Documentation]    Configure BGP peer module with initiate-connection set to false.
#    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
#    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
#    TemplatedRequests.Put_As_Json_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start Bgp Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer


Odl To Play route_eth_arb
    [Template]     Odl To Play Template
    route_eth_arb

Play To Odl route_eth_arb
    [Template]    Play To Odl Template
    route_eth_arb

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

Setup Testcase
    [Arguments]    ${cfg_file}    ${url}    ${empty_response}
    Verify Reported Data     ${url}    ${empty_response}
    Start Tool    ${cfg_file}

Start_Tool
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Start_Tool_And_Verify
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    Start_Tool    ${cfg_file}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Stop_Tool_And_Verify
    [Arguments]    ${url}    ${emptyrspfile}
    [Documentation]    Stop the tool if still running.
    Stop_Tool
    Verify Reported Data    ${url}    ${emptyrspfile}

Stop_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}

Verify Reported Data
    [Arguments]    ${url}    ${exprspfile}
    [Documentation]    Verify expected response
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${expected_rsp}=    Get Expected Response From File    ${exprspfile}
    ${expected_json}=    norm_json.Normalize Json Text    ${expected_rsp}    keys_with_bits=${keys_with_bits}
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${url}
    BuiltIn.Log    ${rsp.content}
    ${received_json}=    norm_json.Normalize Json Text    ${rsp.content}    keys_with_bits=${keys_with_bits}
    BuiltIn.Log    ${received_json}
    BuiltIn.Log    ${expected_json}
    BuiltIn.Should Be Equal    ${received_json}    ${expected_json}

Get Expected Response From File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpfunctional/${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${BGP_VARIABLES_FOLDER}/${exprspfile}
    [Return]    ${expresponse}

Verify Odl Sent Route Request
    [Arguments]    ${expcount}
    ${count}=    ExaClient.get_received_route_refresh_count
    BuiltIn.Should Be Equal As Numbers     ${count}    ${expcount}

Verify Odl Received Route Request
    [Arguments]    ${expcount}
    ${rsp}=      RequestsLibrary.Get Request      ${CONFIG_SESSION}    ${JOLOKURL}
    BuiltIn.Log     ${rsp.content}
    BuiltIn.Should Be Equal As Numbers     ${rsp.status_code}     200
    BuiltIn.Should Be Equal As Numbers     ${rsp.json()['status']}     200
    #${count}=    BuiltIn.Set Variable    ${rsp.json()}['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']
    BuiltIn.Should Be Equal As Numbers     ${rsp.json()['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']}    ${expcount}

Start Bgp Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_TOOL_LOG_LEVEL} --evpn
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Odl To Play Template
    [Arguments]      ${totest}
    ${data}=     OperatingSystem.Get File      ${EVPN_VARIABLES_DIR}/${totest}.xml
    ${resp}=     RequestsLibrary.Post Request    ${CONFIG_SESSION}     ${EVPN_CONF_URL}      data=${data}    headers=${HEADERS_XML}
    BuiltIn.Should Be Equal As Numbers    ${resp.status_code}    204
    ${update}=       BgpRpcClient.play_get
    BgpRpcClient.play_clean
    ${resp}=     RequestsLibrary.Delete Request   ${CONFIG_SESSION}    ${EVPN_CONF_URL}
    BuiltIn.Should Be Equal As Numbers    ${resp.status_code}    200

Play To Odl Template
    No Operation

Verify No Route In Operational
    Sleep     1s
