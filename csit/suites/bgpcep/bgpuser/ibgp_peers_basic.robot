*** Settings ***
Documentation     Basic tests for BGP application peer.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
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
${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
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
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Content

TC1_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Content

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
    Check_Example_IPv4_Topology_Content

TC1_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Check_Example_IPv4_Topology_Content
    [Teardown]    Report_Failure_Due_To_Bug    4819

TC1_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc1_${BGP_PEER2_LOG_FILE}
    Check_Example_IPv4_Topology_Content

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
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Content

TC2_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Content

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
    Check_Example_IPv4_Topology_Content

TC2_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Check_Example_IPv4_Topology_Content

TC2_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc2_${BGP_PEER2_LOG_FILE}
    Check_Example_IPv4_Topology_Content

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
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC3_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

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
    Check_Example_IPv4_Topology_Content

TC3_BGP_Peer2_Check_Log_For_No_Updates
    [Documentation]    Consequent check for no updates received by iBGP peer No. 2
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    ${log_check_timeout}=    DateTime.Convert_Time    ${DEFAULT_LOG_CHECK_TIMEOUT}    result_format=number
    BuiltIn.Wait_Until_Keyword_Succeeds    ${log_check_timeout*2}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    total_received_update_message_counter: 0    4
    Check_Example_IPv4_Topology_Content

TC3_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc3_${BGP_PEER2_LOG_FILE}
    Check_Example_IPv4_Topology_Content

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
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    Open_BGP_Peer1_Console
    Open_BGP_Peer2_Console
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    OperatingSystem.Remove_Directory    ${EXPECTED_RESPONSES_FOLDER}    recursive=True
    OperatingSystem.Remove_Directory    ${ACTUAL_RESPONSES_FOLDER}    recursive=True
    # The previous suite may have been using the same directories.
    OperatingSystem.Create_Directory    ${EXPECTED_RESPONSES_FOLDER}
    OperatingSystem.Create_Directory    ${ACTUAL_RESPONSES_FOLDER}
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
    ConfigViaRestconf.Setup_Config_Via_Restconf
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.protocol

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    ${diff}=    OperatingSystem.Run    diff -dur ${EXPECTED_RESPONSES_FOLDER} ${ACTUAL_RESPONSES_FOLDER}
    BuiltIn.Log    ${diff}
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Open_BGP_Peer1_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer1_console
    Utils.Flexible_Controller_Login

Open_BGP_Peer2_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer2_console
    Utils.Flexible_Controller_Login

Start_Console_Tool
    [Arguments]    ${command}    ${tool_opt}
    [Documentation]    Start the tool ${command} ${tool_opt}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt}
    BuiltIn.Log    ${output}

Wait_Until_Console_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt

Stop_Console_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    SSHLibrary.Read Until Prompt

Check_Example_IPv4_Topology_Content
    [Documentation]    Check the example-ipv4-topology content for string
    [Arguments]    ${string_to_check}=${EMPTY}
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    BuiltIn.Should_Contain    ${response.text}    ${string_to_check}

Read_And_Fail_If_Prompt_Is_Seen
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    ${passed}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Run_Keyword_And_Expect_Error    No match found for '${ODL_SYSTEM_PROMPT}' in *.    Read_Text_Before_Prompt
    BuiltIn.Return_From_Keyword_If    ${passed}
    BGPSpeaker.Dump_BGP_Speaker_Logs
    Builtin.Fail    The prompt was seen but it was not expected yet

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}

Check_File_For_Word_Count
    [Arguments]    ${file_name}    ${word}    ${expected_count}
    [Documentation]    Count ${word} in ${file_name}. Expect ${expected_count} occurence(s)
    ${output_log}=    SSHLibrary.Execute_Command    grep -o '${word}' ${file_name} | wc -l
    BuiltIn.Log    ${output_log}
    BuiltIn.Should_Be_Equal_As_Strings    ${output_log}    ${expected_count}

Check_File_For_Occurence
    [Arguments]    ${file_name}    ${keyword}    ${value}=''
    [Documentation]    Check file for ${keyword} or ${keyword} ${value} pair and returns number of occurences
    ${output_log}=    SSHLibrary.Execute_Command    grep '${keyword}' ${file_name} | grep -c ${value}
    ${count}=    Convert To Integer    ${output_log}
    [Return]    ${count}
