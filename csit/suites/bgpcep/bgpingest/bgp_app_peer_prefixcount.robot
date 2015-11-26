*** Settings ***
Documentation     BGP performance of ingesting from 1 BGP application peer
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic BGP performance test cases for
...               BGP application peer. BGP application peer introduces routes
...               using restconf. Test suite checks that the prefixes are propagated to
...               Ipv4_Topology and announced to BGP peer via updates. Test cases
...               where the BGP peer is disconnected and reconnected and all routes
...               are deleted by BGP application peer are performed as well.
...               Brief description how to configure BGP application peer and
...               how to use restconf application peer interface:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:User_Guide#BGP_Application_Peer
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:Programmer_Guide#BGP
...
...               Reported bugs:
...               Bug 4689 - Not a reasonable duration of 1M prefix introduction from BGP application peer via restconf
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed    # TODO    DEBUG: Back To Fast Failing???
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${HOLDTIME_APP_PEER_PREFIX_COUNT}    ${HOLDTIME}
${COUNT}          1000000
${PREFILL}        0
${COUNT_APP_PEER_PREFIX_COUNT}    ${COUNT}
${CHECK_PERIOD}    1
${CHECK_PERIOD_APP_PEER_PREFIX_COUNT}    ${CHECK_PERIOD}
${REPETITIONS_APP_PEER_PREFIX_COUNT}    1
${BGP_PEER_LOG_LEVEL}    info
${BGP_APP_PEER_LOG_LEVEL}    info
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT
${BGP_PEER_COMMAND}    python play.py --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL}
${BGP_PEER_OPTIONS}    &>bgp_peer.log
${BGP_APP_PEER_ID}    10.0.0.10
${BGP_APP_PEER_INITIAL_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command post --count ${PREFILL} --prefix 8.0.0.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_PUT_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command put --count ${PREFILL} --prefix 8.0.0.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_DELETE_ALL_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command delete-all --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_GET_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command get --${BGP_APP_PEER_LOG_LEVEL}
${BGP_APP_PEER_OPTIONS}    &>bgp_app_peer.log
${TEST_DURATION_MULTIPLIER}    1
${last_prefix_count}    -1

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Starting
    [Documentation]    Wait for example-ipv4-topology to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_APP_PEER_PREFIX_COUNT}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer'}
    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Reconfigure_ODL_To_Accept_BGP_Application_Peer
    [Documentation]    Configure BGP application peer module.
    [Tags]    critical
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-app', 'IP': '${BGP_APP_PEER_ID}'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    ${template_as_string}
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-app'}
    ConfigViaRestconf.Get_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    ${template_as_string}

Start_BGP_Application_Peer_To_Prefill_Routes
    [Documentation]    Start BGP application peer tool and prefill routes.
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_INITIAL_COMMAND}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${bgp_filling_timeout}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_prefill_prefixes.log

Wait_For_Ipv4_Topology_Is_Prefilled
    [Documentation]    Wait until example-ipv4-topology reaches the target prfix count.
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    10s    PrefixCounting.Check_Ipv4_Topology_Count    ${PREFILL}
    [Teardown]    Report_Failure_Due_To_Bug    4689

Start_BGP_Application_Peer_To_Introduce_Individual_Routes
    [Documentation]    Start BGP application peer tool and introduce routes.
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command add --count ${remaining_prefixes} --prefix 10.0.0.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${bgp_filling_timeout*50}

Wait_For_Ipv4_Topology_Is_Filled
    [Documentation]    Wait until example-ipv4-topology reaches the target prfix count.
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    10s    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_APP_PEER_PREFIX_COUNT}
    [Teardown]    Report_Failure_Due_To_Bug    4689

Stop_BGP_Application_Peer
    [Documentation]    Stop BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_individual_prefixes.log

Connect_BGP_Peer
    [Documentation]    Start BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Bgp_Peer_Updates_For_New_Prefixes
    [Documentation]    Count the routes introduced by updates.
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    1s    Check_File_For_Word_Count    bgp_peer.log    total_received_nlri_prefix_counter: ${COUNT_APP_PEER_PREFIX_COUNT}    2
    [Teardown]    Report_Failure_Due_To_Bug    4681

Start_BGP_Application_Peer_To_Delete_All_Routes
    [Documentation]    Start BGP application peer tool and delete all routes.
    [Tags]    critical
    Switch_To_BGP_Application_Peer_Console
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_ALL_COMMAND}    ${BGP_APP_PEER_OPTIONS}

Wait_For_Stable_Topology_After_Deletion
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_emptying_timeout}    period=${CHECK_PERIOD_APP_PEER_PREFIX_COUNT}    repetitions=${REPETITIONS_APP_PEER_PREFIX_COUNT}    excluded_count=${COUNT_APP_PEER_PREFIX_COUNT}

Check_For_Empty_Ipv4_Topology_After_Deleting
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Check_Bgp_Peer_Updates_For_Prefix_Withdrawals
    [Documentation]    Count the routes withdrawn by updates.
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_emptying_timeout}    1s    Check_File_For_Word_Count    bgp_peer.log    total_received_withdrawn_prefix_counter: ${COUNT_APP_PEER_PREFIX_COUNT}    2
    [Teardown]    Report_Failure_Due_To_Bug    4682

Stop_BGP_Peer
    [Documentation]    Stop BGP peer tool
    [Tags]    critical
    Switch_To_BGP_Peer_Console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_peer.log    bgp_peer.log

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
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    Open_BGP_Peer_Console
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    Open_BGP_Aplicationp_Peer_Console
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/bgp_app_peer.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/ipv4-routes-template.xml
    # Calculate the timeout value based on how many routes are going to be pushed
    # TODO: Replace 20 with some formula from period and repetitions.
    ${timeout} =    BuiltIn.Evaluate    ${TEST_DURATION_MULTIPLIER} * ${COUNT_APP_PEER_PREFIX_COUNT} * 3.0 / 10000 + 20
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${bgp_filling_timeout*3.0/4}
    ${result} =    BuiltIn.Evaluate    str(int(${COUNT_APP_PEER_PREFIX_COUNT}) - int(${PREFILL}))
    Builtin.Set_Suite_Variable    ${remaining_prefixes}    ${result}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.protocol

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
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
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}

Read_And_Fail_If_Prompt_Is_Seen
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    ${passed}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Run_Keyword_And_Expect_Error    No match found for '${TOOLS_SYSTEM_PROMPT}' in *.    Read_Text_Before_Prompt
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
