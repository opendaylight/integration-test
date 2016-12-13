*** Settings ***
Documentation     Functional test suite for bgp - l3vpn-ipv4
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests advertising and receiveing routes with l3vpn content.
...               It uses odl and exabgp as bgp peers. Routes advertized from odl
...               are configured via application peer. Routes advertised from exabgp is
...               statically configured in exabgp config file.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ExaBgpLib.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
#Library           ${CURDIR}/../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${DEFAUTL_EXA_CFG}    exa.cfg
${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py
${CONFIG_SESSION}    session
${APP_PEER_ID}      192.182.0.2

*** Test Cases ***
Do_Something_1
    [Documentation]    This is just an empty testcase which has configured and connected 2 bgp peers.
    [Setup]    Two_Peers_Setup
    BuiltIn.Pass_Execution     We do not want to do anythong here
    [Teardown]    Two_Peers_Teardown

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${exa_conn_1}=     Setup_Exabgp_Env    ${TOOLS_SYSTEM_IP}    tool
    ${exa_conn_2}=     Setup_Exabgp_Env    ${ODL_SYSTEM_IP}    odl
    BuiltIn.Set_Suite_Variable    ${exa_conn_1}
    BuiltIn.Set_Suite_Variable    ${exa_conn_2}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Setup_Exabgp_Env
    [Documentation]    Installs virtenv for exabgp and uploads needed config files
    [Arguments]      ${exa_ip}     ${node_type}
    ${conn_id}=    SSHLibrary.Open_Connection    ${exa_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    BuiltIn.Run_Keyword_If    "${node_type}"=="odl"    Utils.Flexible_Controller_Login    ${ODL_SYSTEM_USER}
    BuiltIn.Run_Keyword_If    "${node_type}"=="tool"    Utils.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    Upload_Config_Files    ${exa_ip}
    BuiltIn.Return_From_Keyword    ${conn_id}


Upload_Config_Files
    [Arguments]     ${exa_ip}
    [Documentation]    Uploads exabgp config files and needed scripts
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${DEFAUTL_EXA_CFG}    .
    SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${exa_ip}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}

Configure_App_Peer
    [Documentation]    Configures bgp application peer.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${APP_PEER_ID}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary     BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${APP_PEER_ID}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Two_Peers_Setup_With_App_Peer
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    SSHLibrary.Switch_Connection    ${exa_conn_1}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${DEFAUTL_EXA_CFG}    ${CONFIG_SESSION}     ${TOOLS_SYSTEM_IP}
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${ODL_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    SSHLibrary.Switch_Connection    ${exa_conn_2}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${DEFAUTL_EXA_CFG}    ${CONFIG_SESSION}     ${ODL_SYSTEM_IP}
    Configure_App_Peer

Two_Peers_Teardown_With_App_Peer
    SSHLibrary.Switch_Connection    ${exa_conn_1}
    ExaBgpLib.Stop_ExaBgp
    SSHLibrary.Switch_Connection    ${exa_conn_2}
    ExaBgpLib.Stop_ExaBgp
    Deconfigure_App_Peer
