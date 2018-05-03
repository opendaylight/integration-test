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
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/KillPythonTool.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       180
${BGP_PEER_LOG_LEVEL}    debug
${BGP_APP_PEER_LOG_LEVEL}    debug
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${BGP_PEER_COMMAND}    python play.py --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL}
${BGP_PEER_OPTIONS}    ${EMPTY}
${BGP_APP_PEER_ID}    ${ODL_SYSTEM_IP}
${BGP_APP_PEER_POST_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command post --count 3 --prefix 8.0.1.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_PUT_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command put --count 3 --prefix 8.0.1.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_DELETE_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command delete --count 3 --prefix 8.0.1.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_DELETE_ALL_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command delete-all --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_GET_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command get --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_OPTIONS}    &>/dev/null
${BGP_APP_PEER_TIMEOUT}    30s
${BGP_PEER_APP_NAME}    example-bgp-peer-app
${CONFIG_SESSION}    session
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${SCRIPT_URI_OPT}    --uri config/bgp-rib:application-rib/${ODL_SYSTEM_IP}/tables/bgp-types:ipv4-address-family/bgp-types:unicast-subsequent-address-family/

*** Test Cases ***
Reconfigure_ODL_To_Accept_BGP_Peer_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Tags]    critical
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_BGP_Application_Peer
    [Documentation]    Configure BGP application peer module.
    [Tags]    critical
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=${BGP_PEER_APP_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    IP=${BGP_APP_PEER_ID}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Check_For_Empty_Example-IPv4-Topology
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    empty_topology    timeout=180s

TC1_BGP_Application_Peer_Post_3_Initial_Routes
    [Documentation]    Start BGP application peer tool and give it ${BGP_APP_PEER_TIMEOUT}
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_POST_COMMAND} ${SCRIPT_URI_OPT}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_initial_post_tc1.log

TC1_Check_Example-IPv4-Topology_Is_Filled_With_3_Routes
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    filled_topology

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
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_COMMAND} ${SCRIPT_URI_OPT}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_tc1.log

TC1_Check_Example-IPv4-Topology_Is_Empty
    [Documentation]    See new routes are deleted.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    empty_topology

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
    Start_Console_Tool    ${BGP_APP_PEER_PUT_COMMAND} ${SCRIPT_URI_OPT}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_put_tc2.log

TC2_Check_Example-IPv4-Topology_Is_Filled_With_3_Routes
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    filled_topology

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
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_ALL_COMMAND} ${SCRIPT_URI_OPT}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_all_tc2.log

TC2_Check_Example-IPv4-Topology_Is_Empty
    [Documentation]    See new routes are deleted.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    empty_topology

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
    Start_Console_Tool    ${BGP_APP_PEER_PUT_COMMAND} ${SCRIPT_URI_OPT}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_put_tc3.log

TC3_Check_Example-IPv4-Topology_Is_Filled_With_3_Routes
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    filled_topology

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
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_ALL_COMMAND} ${SCRIPT_URI_OPT}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${BGP_APP_PEER_TIMEOUT}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_all_tc3.log

TC3_Check_Example-IPv4-Topology_Is_Empty
    [Documentation]    See new routes are deleted.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    empty_topology

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
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Bgp_Application_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=${BGP_PEER_APP_NAME}    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. SSH-login to mininet machine, create HTTP session,
    ...    put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    Open_BGP_Peer_Console
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    Open_BGP_Aplication_Peer_Console
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/bgp_app_peer.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/ipv4-routes-template.xml*
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.protocol

Teardown_Everything
    [Documentation]    Make sure Python tool was killed.
    ...    Tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    KillPythonTool.Search_And_Kill_Remote_Python    'bgp_app_peer\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Open_BGP_Peer_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_peer_console
    SSHKeywords.Flexible_Mininet_Login

Open_BGP_Aplication_Peer_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_app_peer_console
    SSHKeywords.Flexible_Mininet_Login

Switch_To_BGP_Peer_Console
    SSHLibrary.Switch Connection    bgp_peer_console

Switch_To_BGP_Application_Peer_Console
    SSHLibrary.Switch Connection    bgp_app_peer_console

Wait_For_Topology_To_Change_To
    [Arguments]    ${folder_name}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Wait until Compare_Topology matches expected result.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Compare_Topology    ${folder_name}

Verify_That_Topology_Does_Not_Change_From
    [Arguments]    ${folder_name}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Verify that Compare_Topology keeps passing, it will hold its last result.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${timeout}    ${refresh}    Compare_Topology    ${folder_name}

Compare_Topology
    [Arguments]    ${folder_name}
    [Documentation]    Get current example-ipv4-topology as json, and compare it to expected result.
    TemplatedRequests.Get_As_Json_Templated    ${BGP_VARIABLES_FOLDER}${/}${folder_name}    session=${CONFIG_SESSION}    verify=True
