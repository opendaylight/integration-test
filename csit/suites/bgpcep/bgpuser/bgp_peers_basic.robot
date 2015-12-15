*** Settings ***
Documentation     Basic tests for BGP application peer.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic BGP functional test cases for
...               BGP peers configured as route reflector rlients (rr-client role).
...
...               Covered bugs:
...               Bug 4791 - BGPSessionImpl: Failed to send message Update logged even all UPDATE mesages received by iBGP peer
...               Bug xxxx - No routes advertised to one of newly connected iBGP RR-client peer
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
deleteLibrary           RequestsLibrary
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
${BGP_PEER1_PREFIX_LEN}    28
${BGP_PEER2_PREFIX_LEN}    28
${BGP_PEER1_PREFIX_COUNT}    3
${BGP_PEER2_PREFIX_COUNT}    3
${BGP_PEER1_LOG_FILE}    bgp_peer1.log
${BGP_PEER2_LOG_FILE}    bgp_peer2.log
${BGP_PEER1_COMMAND}    python play.py --firstprefix ${BGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER1_PREFIX_LEN} --amount ${BGP_PEER1_PREFIX_COUNT} --myip=${BGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER1_LOG_FILE}
${BGP_PEER1_OPTIONS}    &>${BGP_PEER1_LOG_FILE}
${BGP_PEER2_COMMAND}    python play.py --firstprefix ${BGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER2_PREFIX_LEN} --amount ${BGP_PEER2_PREFIX_COUNT} --myip=${BGP_PEER2_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER2_LOG_FILE}
${BGP_PEER2_OPTIONS}    &>${BGP_PEER2_LOG_FILE}

*** Test Cases ***
TC1
    [Documentation]    Two iBGP RR-client peers
    No_Operation

TC1_Configure_Two_iBGP_Route_Reflector_Client_Peers
    [Documentation]    Configure two BGP peers as routing reflector clients.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1', 'IP': '${BGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'rr-client', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2', 'IP': '${BGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'rr-client', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}

TC1_Connect_BGP_Peer1
    [Documentation]     Connect BGP peer
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Log_Example_IPv4_Topology

TC1_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Log_Example_IPv4_Topology

TC1_BGP_Peer1_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER2_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received: ${BGP_PEER2_FIRST_PREFIX_IP}/${BGP_PEER2_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    xxxx

TC1_BGP_Peer2_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    xxxx

TC1_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc1_${BGP_PEER1_LOG_FILE}
    Log_Example_IPv4_Topology

TC1_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Log_Example_IPv4_Topology
    [Teardown]    Report_Failure_Due_To_Bug    xxxx

TC1_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc1_${BGP_PEER2_LOG_FILE}
    Log_Example_IPv4_Topology

TC1_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}

TC2
    [Documentation]    Two iBGP peers: one RR client and one non-client
    BuiltIn.Sleep    3s

TC2_Configure_One_iBGP_Route_Reflector_Client_And_One_iBGP_Non_Client
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1', 'IP': '${BGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'rr-client', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2', 'IP': '${BGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}

TC2_Connect_BGP_Peer1
    [Documentation]     Connect BGP peer
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Log_Example_IPv4_Topology

TC2_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Log_Example_IPv4_Topology

TC2_BGP_Peer1_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER2_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received: ${BGP_PEER2_FIRST_PREFIX_IP}/${BGP_PEER2_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    0

TC2_BGP_Peer2_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    4791

TC2_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc2_${BGP_PEER1_LOG_FILE}
    Log_Example_IPv4_Topology

TC2_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    Log_Example_IPv4_Topology

TC2_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc2_${BGP_PEER2_LOG_FILE}
    Log_Example_IPv4_Topology

TC2_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}

TC3
    [Documentation]    Two iBGP RR non-client peers
    BuiltIn.Sleep    3s

TC3_Configure_Two_iBGP_Non_Client_Peers
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1', 'IP': '${BGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2', 'IP': '${BGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}

TC3_Connect_BGP_Peer1
    [Documentation]     Connect BGP peer
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Log_Example_IPv4_Topology

TC3_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Log_Example_IPv4_Topology

TC3_BGP_Peer1_Check_Log_For_No_Updates
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    total_received_update_message_counter: 0    2

TC3_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    Switch_To_BGP_Peer1_Console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc3_${BGP_PEER1_LOG_FILE}
    Log_Example_IPv4_Topology

TC3_BGP_Peer2_Check_Log_For_No_Updates
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    total_received_update_message_counter: 0    4
    Log_Example_IPv4_Topology

TC3_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    Switch_To_BGP_Peer2_Console
    Stop_Console_Tool
    Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc3_${BGP_PEER2_LOG_FILE}
    Log_Example_IPv4_Topology

TC3_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peers    ${template_as_string}

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

Switch_To_BGP_Peer1_Console
    SSHLibrary.Switch Connection    bgp_peer1_console

Switch_To_BGP_Peer2_Console
    SSHLibrary.Switch Connection    bgp_peer2_console

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

Log_Example_IPv4_Topology
    [Documentation]    Log the example-ipv4-topology actual content
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}

Wait_For_Topology_To_Change_To
    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Normalize the expected json topology and save it to ${EXPECTED_RESPONSES_FOLDER}.
    ...    Wait until Compare_Topology matches. ${ACTUAL_RESPONSES_FOLDER} will hold its last result.
    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${EXPECTED_RESPONSES_FOLDER}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}

Verify_That_Topology_Does_Not_Change_From
    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Normalize the expected json topology and save it to ${EXPECTED_RESPONSES_FOLDER}.
    ...    Verify that Compare_Topology keeps passing. ${ACTUAL_RESPONSES_FOLDER} will hold its last result.
    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${EXPECTED_RESPONSES_FOLDER}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}

Compare_Topology
    [Arguments]    ${expected_normalized}    ${filename}
    [Documentation]    Get current example-ipv4-topology as json, normalize it, save to ${ACTUAL_RESPONSES_FOLDER}.
    ...    Check that status code is 200, check that normalized jsons match exactly.
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    ${actual_normalized}=    Normalize_And_Save_Expected_Json    ${response.text}    ${filename}    ${ACTUAL_RESPONSES_FOLDER}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
    BuiltIn.Should_Be_Equal    ${actual_normalized}    ${expected_normalized}

Normalize_And_Save_Expected_Json
    [Arguments]    ${json_text}    ${filename}    ${directory}
    [Documentation]    Normalize given json using hsf_json library. Log and save the result to given filename under given directory.
    ${json_normalized}=    hsf_json.Hsf_Json    ${json_text}
    BuiltIn.Log    ${json_normalized}
    OperatingSystem.Create_File    ${directory}${/}${filename}    ${json_normalized}
    # TODO: Should we prepend .json to the filename? When we detect it is not already prepended?
    [Return]    ${json_normalized}

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
