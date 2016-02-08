*** Settings ***
Documentation     Basic tests for iBGP peers.
...
...               Copyright (c) 2015-2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic iBGP functional test cases for
...               BGP peers in different roles (iBGP, iBGP RR-client):
...
...               Test Case 1: Two iBGP RR-client peers introduce prefixes
...               Expected result: controller forwards updates towards both peers
...
...               Test Case 2: Two iBGP peers: one RR client and one non-client introduces prefixes
...               Expected result: controller forwards updates towards both peers
...
...               Test Case 3: Two iBGP RR non-client peers introduce prefixes
...               Expected result: controller does not forward any update towards peers
...
...               For polices see: https://wiki.opendaylight.org/view/BGP_LS_PCEP:BGP
...
...               Covered bugs:
...               Bug 4791 - BGPSessionImpl: Failed to send message Update logged even all UPDATE mesages received by iBGP peer
...               Bug 4819 - No routes advertised to one of newly configured iBGP RR-client peer
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           RequestsLibrary
Library           DateTime
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
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
${HOLDTIME}       180
${BGP_PEER_LOG_LEVEL}    debug
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT
${BGP_PEER1_IP}    127.0.0.1
${BGP_PEER2_IP}    127.0.0.2
${BGP_PEER1_FIRST_PREFIX_IP}    8.1.0.0
${BGP_PEER2_FIRST_PREFIX_IP}    8.2.0.0
${PREFIX_LEN}     28
${BGP_PEER1_PREFIX_LEN}    ${PREFIX_LEN}
${BGP_PEER2_PREFIX_LEN}    ${PREFIX_LEN}
${PREFIX_COUNT}    3
${BGP_PEER1_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER2_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER1_LOG_FILE}    bgp_peer1.log
${BGP_PEER2_LOG_FILE}    bgp_peer2.log
${BGP_PEER1_COMMAND}    python play.py --firstprefix ${BGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER1_PREFIX_LEN} --amount ${BGP_PEER1_PREFIX_COUNT} --myip=${BGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER1_LOG_FILE}
${BGP_PEER2_COMMAND}    python play.py --firstprefix ${BGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER2_PREFIX_LEN} --amount ${BGP_PEER2_PREFIX_COUNT} --myip=${BGP_PEER2_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER2_LOG_FILE}
${BGP_PEER1_OPTIONS}    &>${BGP_PEER1_LOG_FILE}
${BGP_PEER2_OPTIONS}    &>${BGP_PEER2_LOG_FILE}
${DEFAULT_LOG_CHECK_TIMEOUT}    20s
${DEFAULT_LOG_CHECK_PERIOD}    1s
${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    10s
${DEFAULT_TOPOLOGY_CHECK_PERIOD}    1s

*** Test Cases ***
TC1_Configure_Two_iBGP_Route_Reflector_Client_Peers
    [Documentation]    Configure two iBGP peers as routing reflector clients.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1', 'IP': '${BGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'rr-client', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2', 'IP': '${BGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'rr-client', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}

TC1_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC1_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC1_BGP_Peer1_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER2_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received: ${BGP_PEER2_FIRST_PREFIX_IP}/${BGP_PEER2_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    4819

TC1_BGP_Peer2_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    4819

TC1_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc1_${BGP_PEER1_LOG_FILE}

TC1_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    [Teardown]    Report_Failure_Due_To_Bug    4819

TC1_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc1_${BGP_PEER2_LOG_FILE}

TC_1_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC1_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}

TC2_Configure_One_iBGP_Route_Reflector_Client_And_One_iBGP_Non_Client
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1', 'IP': '${BGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'rr-client', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2', 'IP': '${BGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}

TC2_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC2_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC2_BGP_Peer1_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER2_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received: ${BGP_PEER2_FIRST_PREFIX_IP}/${BGP_PEER2_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    0

TC2_BGP_Peer2_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    4791

TC2_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc2_${BGP_PEER1_LOG_FILE}

TC2_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1

TC2_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc2_${BGP_PEER2_LOG_FILE}

TC_2_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC2_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}

TC3_Configure_Two_iBGP_Non_Client_Peers
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1', 'IP': '${BGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2', 'IP': '${BGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}

TC3_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC3_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC3_BGP_Peer1_Check_Log_For_No_Updates
    [Documentation]    Check for no updates received by iBGP peer No. 1
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    total_received_update_message_counter: 0    2

TC3_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc3_${BGP_PEER1_LOG_FILE}

TC3_BGP_Peer2_Check_Log_For_No_Updates
    [Documentation]    Consequent check for no updates received by iBGP peer No. 2
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    ${log_check_timeout}=    DateTime.Convert_Time    ${DEFAULT_LOG_CHECK_TIMEOUT}    result_format=number
    BuiltIn.Wait_Until_Keyword_Succeeds    ${log_check_timeout*2}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    total_received_update_message_counter: 0    4

TC3_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc3_${BGP_PEER2_LOG_FILE}

TC_3_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC3_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    # TODO: Choose keywords used by more than one test suite to be placed in a common place.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer1_console
    Utils.Flexible_Controller_Login
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer2_console
    Utils.Flexible_Controller_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
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

Check_Example_IPv4_Topology_Content
    [Arguments]    ${string_to_check}=${EMPTY}
    [Documentation]    Check the example-ipv4-topology content for string
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${string_to_check}

Check_Example_IPv4_Topology_Does_Not_Contain
    [Arguments]    ${string_to_check}
    [Documentation]    Check the example-ipv4-topology does not contain the string
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Not_Contain    ${response.text}    ${string_to_check}
