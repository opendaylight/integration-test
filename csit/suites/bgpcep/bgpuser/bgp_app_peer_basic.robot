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
...               BGP application peer operations and checks for IP4 topology updates
...               and updates towards BGP peer as follows:
...
...               Test case 1: Initial BGP peer connection with pre-filled topology (Bug 4714),
...               POST and simple DELETE requests used.
...               BGP_Application_Peer_Post_3_Initial_Routes,
...               Check_Example-IPv4-Topology_Is_Filled_With_3_Routes,
...               Connect_BGP_Peer,
...               BGP_Peer_Check_Incomming_Updates_For_3_Introduced_Prefixes,
...               BGP_Application_Peer_Delete_3_Initial_Routes,
...               Check_Example-IPv4-Topology_Is_Empty,
...               Peer_Check_Incomming_Updates_For_3_Withdrawn_Prefixes,
...               Stop_BGP_Peer.
...
...               Test case 2: PUT and DELETE all routes requests while BGP peer is connected.
...               Reconnect_BGP_Peer,
...               BGP_Application_Peer_Put_3_Routes,
...               Check_Example-IPv4-Topology_Is_Filled_With_3_Routes,
...               BGP_Peer_Check_Incomming_Updates_For_3_Introduced_Prefixes,
...               BGP_Application_Peer_Delete_All_Routes,
...               Check_Example-IPv4-Topology_Is_Empty,
...               BGP_Peer_Check_Incomming_Updates_For_3_Withdrawn_Prefixes,
...               Stop_BGP_Peer.
...
...               Test case 3: Repeated BGP peer re-connection with pre-filled topology.
...               BGP_Application_Peer_Put_3_Routes,
...               Check_Example-IPv4-Topology_Is_Filled_With_3_Routes,
...               Reconnect_BGP_Peer_And_Check_Incomming_Updates_For_3_Introduced_Prefixes,
...               BGP_Application_Peer_Delete_All_Routes,
...               Check_Example-IPv4-Topology_Is_Empty,
...               BGP_Peer_Check_Incomming_Updates_For_3_Withdrawn_Prefixes,
...               Stop_BGP_Peer.
...
...               Brief description how to configure BGP application peer and
...               how to use restconf application peer interface:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:User_Guide#BGP_Application_Peer
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:Programmer_Guide#BGP
...               Covered bugs:
...               Bug 4714 - No routes from loc-rib are advertised to newly connected peer
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
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
${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       180
${BGP_PEER_LOG_LEVEL}    debug
${BGP_APP_PEER_LOG_LEVEL}    debug
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT
${BGP_PEER_COMMAND}    python play.py --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL}
${BGP_PEER_OPTIONS}    ${EMPTY}
${BGP_APP_PEER_ID}    10.0.0.10
${BGP_APP_PEER_POST_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command post --count 3 --prefix 8.0.1.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_PUT_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command put --count 3 --prefix 8.0.1.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_DELETE_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command delete --count 3 --prefix 8.0.1.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_DELETE_ALL_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command delete-all --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_GET_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command get --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_OPTIONS}    &>/dev/null
${BGP_APP_PEER_TIMEOUT}    30s

*** Test Cases ***
Reconfigure_ODL_To_Accept_BGP_Peer_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Reconfigure_ODL_To_Accept_BGP_Application_Peer
    [Documentation]    Configure BGP application peer module.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-app', 'IP': '${BGP_APP_PEER_ID}'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    ${template_as_string}

Check_For_Empty_Example-IPv4-Topology
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    000_Empty.json    timeout=120s

TC1_BGP_Application_Peer_Post_3_Initial_Routes
    [Documentation]    Start BGP application peer tool and give it ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_POST_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_initial_post_tc1.log

TC1_Check_Example-IPv4-Topology_Is_Filled_With_3_Routes
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    010_Filled.json

TC1_Connect_BGP_Peer
    [Documentation]    Start BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen

TC1_BGP_Peer_Check_Incomming_Updates_For_3_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.0/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.16/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.32/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    0
    [Teardown]    Report_Failure_Due_To_Bug    4714

TC1_BGP_Application_Peer_Delete_3_Initial_Routes
    [Documentation]    Start BGP application peer tool and give him ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_tc1.log

TC1_Check_Example-IPv4-Topology_Is_Empty
    [Documentation]    See new routes are deleted.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    011_Empty.json

TC1_Peer_Check_Incomming_Updates_For_3_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.0/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.16/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.32/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3
    [Teardown]    Report_Failure_Due_To_Bug    4714

TC1_Stop_BGP_Peer
    [Documentation]    Stop BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_peer.log    bgp_peer_tc1.log

TC2_Reconnect_BGP_Peer
    [Documentation]    Start BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    0
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    0

TC2_BGP_Application_Peer_Put_3_Routes
    [Documentation]    Start BGP application peer tool and give him ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_PUT_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_put_tc2.log

TC2_Check_Example-IPv4-Topology_Is_Filled_With_3_Routes
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    020_Filled.json

TC2_BGP_Peer_Check_Incomming_Updates_For_3_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.0/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.16/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.32/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    0

TC2_BGP_Application_Peer_Delete_All_Routes
    [Documentation]    Start BGP application peer tool and give him ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_ALL_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_all_tc2.log

TC2_Check_Example-IPv4-Topology_Is_Empty
    [Documentation]    See new routes are deleted.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    021_Empty.json

TC2_BGP_Peer_Check_Incomming_Updates_For_3_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.0/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.16/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.32/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3

TC2_Stop_BGP_Peer
    [Documentation]    Stop BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_peer.log    bgp_peer_tc2.log

TC3_BGP_Application_Peer_Put_3_Routes
    [Documentation]    Start BGP application peer tool and give him ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_PUT_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_put_tc3.log

TC3_Check_Example-IPv4-Topology_Is_Filled_With_3_Routes
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    030_Filled.json

TC3_Reconnect_BGP_Peer_And_Check_Incomming_Updates_For_3_Introduced_Prefixes
    [Documentation]    Start BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.0/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.16/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received: 8.0.1.32/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    0

TC3_BGP_Application_Peer_Delete_All_Routes
    [Documentation]    Start BGP application peer tool and give him ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_ALL_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_all_tc3.log

TC3_Check_Example-IPv4-Topology_Is_Empty
    [Documentation]    See new routes are deleted.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    031_Empty.json

TC3_BGP_Peer_Check_Incomming_Updates_For_3_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received:    3
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.0/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.16/28    1
    Check_File_For_Word_Count    bgp_peer.log    withdrawn_prefix_received: 8.0.1.32/28    1
    Check_File_For_Word_Count    bgp_peer.log    nlri_prefix_received:    3

TC3_Stop_BGP_Peer
    [Documentation]    Stop BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_peer.log    bgp_peer_tc3.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Delete_Bgp_Application_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-app'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    ${template_as_string}

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    Open_BGP_Peer_Console
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    Open_BGP_Aplicationp_Peer_Console
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/bgp_app_peer.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/ipv4-routes-template.xml
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
    KillPythonTool.Search_And_Kill_Remote_Python    'bgp_app_peer\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Open_BGP_Peer_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_peer_console
    Utils.Flexible_Mininet_Login

Open_BGP_Aplicationp_Peer_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_app_peer_console
    Utils.Flexible_Mininet_Login

Switch_To_BGP_Peer_Console
    SSHLibrary.Switch Connection    bgp_peer_console

Switch_To_BGP_Application_Peer_Console
    SSHLibrary.Switch Connection    bgp_app_peer_console

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
