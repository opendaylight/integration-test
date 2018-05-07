*** Settings ***
Documentation     Functional test for bgp flowspec.
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
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpflowspec
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${EXP0}           empty-flowspec.json
${CFG1}           bgp-flowspec.cfg
${EXP1}           bgp-flowspec.json
${CFG2}           bgp-flowspec-redirect.cfg
${EXP2}           bgp-flowspec-redirect.json
${FLOWSPEC_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-flowspec:flowspec-subsequent-address-family/bgp-flowspec:flowspec-routes
${CONFIG_SESSION}    session
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check bgp-flowspec:flowspec-routes is up but empty.
    [Tags]    critical
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Verify Empty Flowspec Data

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

FlowSpec Test 1
    [Documentation]    Testing flowspec values for ${CFG1}
    [Setup]    Setup Testcase    ${CFG1}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${EXP1}
    [Teardown]    ExaBgpLib.Stop_ExaBgp

FlowSpec Test 2
    [Documentation]    Testing flowspec values for ${CFG2}
    [Setup]    Setup Testcase    ${CFG2}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${EXP2}
    [Teardown]    ExaBgpLib.Stop_ExaBgp

Deconfigure_ODL_To_Accept_Connection
    [Documentation]    Deconfigure BGP peer.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    RequestsLibrary.Create Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload Config Files    ${CURDIR}/../../../variables/bgpflowspec/

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Upload Config Files
    [Arguments]    ${dir_name}
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put Directory    ${CURDIR}/../../../variables/bgpflowspec/    .
    @{cfgfiles}=    SSHLibrary.List Files In Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute Command    cat ${cfgfile}
    \    Log    ${stdout}

Setup Testcase
    [Arguments]    ${cfg_file}
    Verify Empty Flowspec Data
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cfg_file}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}    connection_retries=${3}

Verify Empty Flowspec Data
    [Documentation]    Verify expected response.
    Verify Flowspec Data    ${EXP0}

Verify Flowspec Data
    [Arguments]    ${exprspfile}
    [Documentation]    Verify expected response
    ${keys_with_bits}=    BuiltIn.Create_List
    ${expected_rsp}=    Get Expected Response From File    ${exprspfile}
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${FLOWSPEC_URL}
    TemplatedRequests.Normalize_Jsons_With_Bits_And_Compare    ${expected_rsp}    ${rsp.content}    keys_with_bits=${keys_with_bits}

Get Expected Response From File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpflowspec/${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpflowspec/${exprspfile}
    [Return]    ${expresponse}
