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
Suite Teardown    BgpOperations.Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           OperatingSystem
Library           RequestsLibrary
Library           DateTime
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../variables/Variables.robot

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
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${JSONKEYSTR}     "linkstate-route"
${BGP_PEER_NAME}    example-bgp-peer
${DEVICE_NAME}    controller-config
${CONFIG_SESSION}    config-session
${SKIP_PARAMS}    --skipattr
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}

*** Test Cases ***
TC1_Configure_iBGP_Peer
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Tags]    critical
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

TC1_Check_Example_Bgp_Rib_Is_Empty
    [Documentation]    Check RIB for none linkstate-routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BgpOperations.Check_Example_Bgp_Rib_Does_Not_Contain    ${CONFIG_SESSION}    ${JSONKEYSTR}

TC1_Connect_BGP_Peer
    [Documentation]    Connect BGP peer with advertising the routes without mandatory params like LOC_PREF.
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BuiltIn.Run_Keyword_And_Ignore_Error    KarafKeywords.Log_Message_To_Controller_Karaf    Error = WELL_KNOWN_ATTR_MISSING is EXPECTED in this test case, and should be thrown when missing mandatory attributes.
    BGPcliKeywords.Start_Console_Tool    ${BGP_PEER_COMMAND} ${SKIP_PARAMS}    ${BGP_PEER_OPTIONS}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

TC1_Check_Example_Bgp_Rib
    [Documentation]    Check RIB for not containig linkstate-route(s), because update messages were not good.
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${DEFAULT_RIB_CHECK_TIMEOUT}    ${DEFAULT_RIB_CHECK_PERIOD}    BgpOperations.Check_Example_Bgp_Rib_Does_Not_Contain    ${CONFIG_SESSION}    ${JSONKEYSTR}

TC1_Disconnect_BGP_Peer
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BGPcliKeywords.Stop_Console_Tool
    BGPcliKeywords.Store_File_To_Workspace    ${BGP_PEER_LOG_FILE}    tc1_${BGP_PEER_LOG_FILE}

TC1_Deconfigure_iBGP_Peer
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

TC2_Configure_iBGP_Peer
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

TC2_Check_Example_Bgp_Rib_Is_Empty
    [Documentation]    Check RIB for none linkstate-routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BgpOperations.Check_Example_Bgp_Rib_Does_Not_Contain    ${CONFIG_SESSION}    ${JSONKEYSTR}

TC2_Connect_BGP_Peer
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BGPcliKeywords.Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

TC2_Check_Example_Bgp_Rib
    [Documentation]    Check RIB for linkstate-route(s)
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_RIB_CHECK_TIMEOUT}    ${DEFAULT_RIB_CHECK_PERIOD}    BgpOperations.Check_Example_Bgp_Rib_Content    ${CONFIG_SESSION}    ${JSONKEYSTR}

TC2_Disconnect_BGP_Peer
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer_console
    BGPcliKeywords.Stop_Console_Tool
    BGPcliKeywords.Store_File_To_Workspace    ${BGP_PEER_LOG_FILE}    tc2_${BGP_PEER_LOG_FILE}

TC2_Deconfigure_iBGP_Peer
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_peer_console
    SSHKeywords.Flexible_Mininet_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    KarafKeywords.Setup_Karaf_Keywords
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.protocol
