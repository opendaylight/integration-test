*** Settings ***
Documentation     Basic tests for eBGP application peers.
...
...               Copyright (c) 2015-2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic eBGP functional tests:
...               Two eBGP peers advertise the same group of prefixes (aka BGP HA)
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:BGP
...               Reported bugs:
...               Bug 4834 - ODL controller announces the same route twice (two eBGP scenario aka HA)
...               Bug 4835 - Routes not withdrawn when eBGP peers are disconnected (the same prefixes announced)
...
...               TODO: Extend testsuite by tests dedicated to path selection algorithm
...               TODO: Choose keywords used by more than one test suite to be placed in a common place.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           RequestsLibrary
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
${iBGP_PEER1_IP}    127.0.0.1
${eBGP_PEER1_IP}    127.0.0.3
${eBGP_PEER2_IP}    127.0.0.4
${iBGP_PEER1_FIRST_PREFIX_IP}    8.1.0.0
${eBGP_PEERS_FIRST_PREFIX_IP}    8.0.0.0
${eBGP_PEER1_FIRST_PREFIX_IP}    ${eBGP_PEERS_FIRST_PREFIX_IP}
${eBGP_PEER2_FIRST_PREFIX_IP}    ${eBGP_PEERS_FIRST_PREFIX_IP}
${eBGP_PEER1_NEXT_HOP}    1.1.1.1
${eBGP_PEER2_NEXT_HOP}    2.2.2.2
${PREFIX_LEN}     28
${iBGP_PEER1_PREFIX_LEN}    ${PREFIX_LEN}
${eBGP_PEER1_PREFIX_LEN}    ${PREFIX_LEN}
${eBGP_PEER2_PREFIX_LEN}    ${PREFIX_LEN}
${PREFIX_COUNT}    2
${iBGP_PEER1_PREFIX_COUNT}    0
${eBGP_PEER1_PREFIX_COUNT}    ${PREFIX_COUNT}
${eBGP_PEER2_PREFIX_COUNT}    ${PREFIX_COUNT}
${eBGP_PEERS_AS}    32768
${eBGP_PEER1_AS}    ${eBGP_PEERS_AS}
${eBGP_PEER2_AS}    ${eBGP_PEERS_AS}
${iBGP_PEER1_LOG_FILE}    bgp_peer1.log
${eBGP_PEER1_LOG_FILE}    ebgp_peer1.log
${eBGP_PEER2_LOG_FILE}    ebgp_peer2.log
${iBGP_PEER1_COMMAND}    python play.py --firstprefix ${iBGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${iBGP_PEER1_PREFIX_LEN} --amount ${iBGP_PEER1_PREFIX_COUNT} --myip=${iBGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${iBGP_PEER1_LOG_FILE}
${eBGP_PEER1_COMMAND}    python play.py --firstprefix ${eBGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${eBGP_PEER1_PREFIX_LEN} --amount ${eBGP_PEER1_PREFIX_COUNT} --myip=${eBGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --nexthop ${eBGP_PEER1_NEXT_HOP} --asnumber ${eBGP_PEER1_AS} --${BGP_PEER_LOG_LEVEL} --logfile ${eBGP_PEER1_LOG_FILE}
${eBGP_PEER2_COMMAND}    python play.py --firstprefix ${eBGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${eBGP_PEER2_PREFIX_LEN} --amount ${eBGP_PEER2_PREFIX_COUNT} --myip=${eBGP_PEER2_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --nexthop ${eBGP_PEER2_NEXT_HOP} --asnumber ${eBGP_PEER2_AS} --${BGP_PEER_LOG_LEVEL} --logfile ${eBGP_PEER2_LOG_FILE}
${iBGP_PEER1_OPTIONS}    &>${iBGP_PEER1_LOG_FILE}
${eBGP_PEER1_OPTIONS}    &>${eBGP_PEER1_LOG_FILE}
${eBGP_PEER2_OPTIONS}    &>${eBGP_PEER2_LOG_FILE}
${DEFAULT_LOG_CHECK_TIMEOUT}    20s
${DEFAULT_LOG_CHECK_PERIOD}    1s
${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    10s
${DEFAULT_TOPOLOGY_CHECK_PERIOD}    1s

*** Test Cases ***
Configure_BGP_Peers
    [Documentation]    Configure an iBGP and two eBGP peers
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ibgp-peer1', 'IP': '${iBGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ibgp', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ebgp-peer1', 'IP': '${eBGP_PEER1_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'PEER_ROLE': 'ebgp', 'AS_NUMBER': '${eBGP_PEER1_AS}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ebgp-peer2', 'IP': '${eBGP_PEER2_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}','PEER_ROLE': 'ebgp', 'AS_NUMBER': '${eBGP_PEER2_AS}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ibgp-peer1'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ebgp-peer1'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ebgp-peer2'}
    ${result}=    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
    BuiltIn.Log    ${result}

Connect_iBGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    ibgp_peer1_console
    Start_Console_Tool    ${iBGP_PEER1_COMMAND}    ${iBGP_PEER1_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen
    Check_Example_IPv4_Topology_Does_Not_Contain    prefix

Connect_eBGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    ebgp_peer1_console
    Start_Console_Tool    ${eBGP_PEER1_COMMAND}    ${eBGP_PEER1_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen

Check_IPv4_Topology_For_First_Path
    [Documentation]    The IPv4 topology shall contain the route announced by the first eBGP
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    "node-id":"${eBGP_PEER1_NEXT_HOP}"
    Check_Example_IPv4_Topology_Content    "prefix":"${eBGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"

iBGP_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for introduced routes
    [Tags]    critical
    SSHLibrary.Switch Connection    ibgp_peer1_console
    ${total_prefix_count}=    BuiltIn.Evaluate    ${eBGP_PEER1_PREFIX_COUNT}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${iBGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${total_prefix_count}
    ${count}=    Count_Key_Value_Pairs    ${iBGP_PEER1_LOG_FILE}    Network Address of Next Hop    ${eBGP_PEER1_NEXT_HOP}
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    ${eBGP_PEER1_PREFIX_COUNT}
    ${count}=    Count_Key_Value_Pairs    ${iBGP_PEER1_LOG_FILE}    Network Address of Next Hop    ${eBGP_PEER2_NEXT_HOP}
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    0

Connect_eBGP_Peer2
    [Documentation]    Connect BGP peer and check empty topology
    [Tags]    critical
    SSHLibrary.Switch Connection    ebgp_peer2_console
    Start_Console_Tool    ${eBGP_PEER2_COMMAND}    ${eBGP_PEER2_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen

Disconnect_eBGP_Peer1
    [Documentation]    Stop BGP peer, log topology and store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    ebgp_peer1_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${eBGP_PEER1_LOG_FILE}    ${eBGP_PEER1_LOG_FILE}

Check_IPv4_Topology_For_Second_Path
    [Documentation]    The IPv4 topology shall contain the route announced by the second eBGP now
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Content    "node-id":"${eBGP_PEER2_NEXT_HOP}"
    Check_Example_IPv4_Topology_Content    "prefix":"${eBGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"

iBGP_Check_Log_For_Updated_Prefixes
    [Documentation]    Check incomming updates for updated routes
    [Tags]    critical
    SSHLibrary.Switch Connection    ibgp_peer1_console
    ${total_prefix_count}=    BuiltIn.Evaluate    ${eBGP_PEER1_PREFIX_COUNT} + ${eBGP_PEER2_PREFIX_COUNT}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${iBGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${total_prefix_count}
    ${count}=    Count_Key_Value_Pairs    ${iBGP_PEER1_LOG_FILE}    Network Address of Next Hop    ${eBGP_PEER1_NEXT_HOP}
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    ${eBGP_PEER1_PREFIX_COUNT}
    ${count}=    Count_Key_Value_Pairs    ${iBGP_PEER1_LOG_FILE}    Network Address of Next Hop    ${eBGP_PEER2_NEXT_HOP}
    BuiltIn.Should_Be_Equal_As_Integers    ${count}    ${eBGP_PEER2_PREFIX_COUNT}
    [Teardown]    Report_Failure_Due_To_Bug    4834

Disconnect_eBGP_Peer2
    [Documentation]    Stop BGP peer, store logs and wait for empty topology
    [Tags]    critical
    SSHLibrary.Switch Connection    ebgp_peer2_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${eBGP_PEER2_LOG_FILE}    ${eBGP_PEER2_LOG_FILE}

Check_For_Empty_IPv4_Topology
    [Documentation]    The IPv4 topology shall be empty
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    Check_Example_IPv4_Topology_Does_Not_Contain    prefix
    [Teardown]    Report_Failure_Due_To_Bug    4835

iBGP_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    ibgp_peer1_console
    ${prefixes_to_be_removed}=    BuiltIn.Evaluate    max(${eBGP_PEER1_PREFIX_COUNT}, ${eBGP_PEER2_PREFIX_COUNT})
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    Check_File_For_Word_Count    ${iBGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    ${prefixes_to_be_removed}
    [Teardown]    Report_Failure_Due_To_Bug    4835

Disconnect_iBGP_Peer1
    [Documentation]    Stop BGP peer, log topology and store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    ibgp_peer1_console
    Stop_Console_Tool
    Store_File_To_Workspace    ${iBGP_PEER1_LOG_FILE}    ${iBGP_PEER1_LOG_FILE}

Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ibgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ebgp-peer1'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-ebgp-peer2'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}ebgp_peers    ${template_as_string}

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ibgp_peer1_console
    Utils.Flexible_Controller_Login
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ebgp_peer1_console
    Utils.Flexible_Controller_Login
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=ebgp_peer2_console
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

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

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

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}
