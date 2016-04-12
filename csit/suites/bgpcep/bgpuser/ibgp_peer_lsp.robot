*** Settings ***
Documentation     Basic tests for iBGP peers.
...
...               Copyright (c) 2015-2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic iBGP functional test case for
...               carrying LSP State Information in BGP as described in
...               http://tools.ietf.org/html/draft-ietf-idr-te-lsp-distribution-03
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           OperatingSystem
Library           RequestsLibrary
Library           DateTime
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${ODL_SYSTEM_PROMPT}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${COUNT}          1
${HOLDTIME}       180
${BGP_PEER_LOG_FILE}    bgp_peer.log
${BGP_PEER_COMMAND}    python play.py --amount ${COUNT} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER_LOG_FILE} --bgpls True
${BGP_PEER_OPTIONS}    &>${BGP_PEER_LOG_FILE}
${DEFAULT_RIB_CHECK_PERIOD}    1s
${DEFAULT_RIB_CHECK_TIMEOUT}    10s
${BGP_PEER_LOG_LEVEL}    debug
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT
${JSONKEYSTR}     "linkstate-route"

*** Test Cases ***
TC1_Configure_iBGP_Peer
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

TC1_Check_Example_Bgp_Rib_Is_Empty
    [Documentation]    Check RIB for none linkstate-routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    Check_Example_Bgp_Rib_Does_Not_Contain    ${JSONKEYSTR}

TC1_Connect_BGP_Peer
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BGPcliKeywords.Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

TC1_Check_Example_Bgp_Rib
    [Documentation]    Check RIB for linkstate-route(s)
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_RIB_CHECK_TIMEOUT}    ${DEFAULT_RIB_CHECK_PERIOD}    Check_Example_Bgp_Rib_Content    ${JSONKEYSTR}

TC1_Disconnect_BGP_Peer
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BGPcliKeywords.Stop_Console_Tool
    BGPcliKeywords.Store_File_To_Workspace    ${BGP_PEER_LOG_FILE}    tc1_${BGP_PEER_LOG_FILE}

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_peer_console
    Utils.Flexible_Mininet_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    ConfigViaRestconf.Setup_Config_Via_Restconf
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.protocol

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Check_Example_Bgp_Rib_Content
    [Arguments]    ${substr}    ${error_message}=${JSONKEYSTR} not found, but expected.
    [Documentation]    Check the example-bgp-rib content for string
    ${response}=    RequestsLibrary.Get Request    operational    bgp-rib:bgp-rib/rib/example-bgp-rib
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${substr}    ${error_message}    values=False

Check_Example_Bgp_Rib_Does_Not_Contain
    [Arguments]    ${substr}    ${error_message}=${JSONKEYSTR} found, but not expected.
    [Documentation]    Check the example-bgp-rib does not contain the string
    ${response}=    RequestsLibrary.Get Request    operational    bgp-rib:bgp-rib/rib/example-bgp-rib
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Not_Contain    ${response.text}    ${substr}    ${error_message}    values=False
