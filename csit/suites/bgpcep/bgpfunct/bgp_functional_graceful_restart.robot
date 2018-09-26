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
${CONFIG_SESSION}    config-session
${RT_CONSTRAIN_DIR}    ${CURDIR}/../../../variables/bgpfunctional/rt_constrain
${L3VPN_RIB_URI}    ${CURDIR}/../../../variables/bgpfunctional/rt_constrain/ext_l3vpn_rt_arg/rib
${L3VPN_IPV4_DIR}    ${CURDIR}/../../../variables/bgpfunctional/l3vpn_ipv4
${L3VPN_RSPEMPTY}    ${L3VPN_IPV4_DIR}/bgp-l3vpn-ipv4-empty.json
${EBGP_DIR}       ${CURDIR}/../../../variables/bgpfunctional/ebgp_peer
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_NAME}       example-bgp-rib
${ODL_2_IP}       127.0.0.2
${ODL_3_IP}       127.0.0.3
${ODL_4_IP}       127.0.0.4
@{ODL_IP_INDICES_ALL}    2    3    4
&{LOC_RIB}        PATH=loc-rib    BGP_RIB=${RIB_NAME}
&{RT_CONSTRAIN_APP_PEER}    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
&{ADJ_RIB_OUT}    PATH=peer/bgp:%2F%2F${ODL_3_IP}/adj-rib-out    BGP_RIB=${RIB_NAME}
&{RT_CONSTRAIN_APP_PEER}    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${RT_CONSTRAIN_APP_PEER}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${i}    ${type}    IN ZIP    ${ODL_IP_INDICES_ALL}    ${BGP_PEER_TYPES}
    \    &{ODL_CONFIG}=    BuiltIn.Create Dictionary    IP=${ODL_${i}_IP}    TYPE=${type}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false
    \    ...    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    \    TemplatedRequests.Put_As_Xml_Templated    ${EBGP_DIR}    mapping=${ODL_CONFIG}    session=${CONFIG_SESSION}

Start_Bgp_Peers
    [Documentation]    Start Python speaker to connect to ODL. We give each speaker time until odl really starts to accept incomming
    ...    bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer.
    [Tags]    local_run
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${i}    ${as_number}    IN ZIP    ${ODL_IP_INDICES_ALL}    ${BGP_PEER_AS_NUMBERS}
    \    BuiltIn.Log Many    IP: ${ODL_${i}_IP}    as_number: ${as_number}
    \    BuiltIn.Sleep    5s
    \    Start_Bgp_Peer    ${ODL_${i}_IP}    ${as_number}    800${i}    play.py.090.${i}


