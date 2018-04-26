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
...               BGP application peer. BGP application peer introduces routes -
...               using restconf - in two steps:
...               1. introduces the ${PREFILL} number of routes in one POST request
...               2. POSTs the rest of routes (up to the ${COUNT} number) one by one
...               Test suite checks that the prefixes are propagated to
...               IPv4 topology and announced to BGP peer via updates. Test case
...               where the BGP peer is disconnected and reconnected and all routes
...               are deleted by BGP application peer are performed as well.
...               Brief description how to configure BGP application peer and
...               how to use restconf application peer interface:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:User_Guide#BGP_Application_Peer
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:Programmer_Guide#BGP
...               http://docs.opendaylight.org/en/stable-boron/user-guide/bgp-user-guide.html#bgp-peering
...               http://docs.opendaylight.org/en/stable-boron/user-guide/bgp-user-guide.html#application-peer-configuration
...
...               Reported bugs:
...               Bug 4689 - Not a reasonable duration of 1M prefix introduction from BGP application peer via restconf
...               Bug 4791 - BGPSessionImpl: Failed to send message Update logged even all UPDATE mesages received by iBGP peer
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Force Tags        critical
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${HOLDTIME_APP_PEER_PREFIX_COUNT}    ${HOLDTIME}
${COUNT}          200000
${PREFILL}        100000
${COUNT_APP_PEER_PREFIX_COUNT}    ${COUNT}
${CHECK_PERIOD}    1
${CHECK_PERIOD_APP_PEER_PREFIX_COUNT}    ${CHECK_PERIOD}
${REPETITIONS_APP_PEER_PREFIX_COUNT}    1
${BGP_PEER_LOG_LEVEL}    info
${BGP_APP_PEER_LOG_LEVEL}    info
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${BGP_PEER_COMMAND}    python play.py --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_PEER_OPTIONS}    &>bgp_peer.log
${BGP_APP_PEER_ID}    10.0.0.10
${BGP_APP_PEER_INITIAL_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command post --count ${PREFILL} --prefix 8.0.0.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_PUT_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command put --count ${PREFILL} --prefix 8.0.0.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_DELETE_ALL_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command delete-all --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_GET_COMMAND}    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command get --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM}
${BGP_APP_PEER_OPTIONS}    &>bgp_app_peer.log
${TEST_DURATION_MULTIPLIER}    30
${last_prefix_count}    -1
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Starting
    [Documentation]    Wait for example-ipv4-topology to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME_APP_PEER_PREFIX_COUNT}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}

Reconfigure_ODL_To_Accept_BGP_Application_Peer
    [Documentation]    Configure BGP application peer module.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer-app    RIB_INSTANCE_NAME=${RIB_INSTANCE}    IP=${BGP_APP_PEER_ID}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    mapping=${mapping}

Connect_BGP_Peer
    [Documentation]    Start BGP peer tool
    SSHLibrary.Switch Connection    bgp_peer_console
    Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen

BGP_Application_Peer_Prefill_Routes
    [Documentation]    Start BGP application peer tool and prefill routes.
    SSHLibrary.Switch Connection    bgp_app_peer_console
    Start_Console_Tool    ${BGP_APP_PEER_INITIAL_COMMAND} ${script_uri_opt}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${bgp_filling_timeout}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_prefill.log

Wait_For_Ipv4_Topology_Is_Prefilled
    [Documentation]    Wait until example-ipv4-topology reaches the target prfix count.
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    10s    PrefixCounting.Check_Ipv4_Topology_Count    ${PREFILL}

Check_Bgp_Peer_Updates_For_Prefilled_Routes
    [Documentation]    Count the routes introduced by updates.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    1s    Check_File_For_Word_Count    bgp_peer.log    total_received_nlri_prefix_counter: ${PREFILL}    2

BGP_Application_Peer_Introduce_Single_Routes
    [Documentation]    Start BGP application peer tool and introduce routes.
    SSHLibrary.Switch Connection    bgp_app_peer_console
    Start_Console_Tool    python bgp_app_peer.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --command add --count ${remaining_prefixes} --prefix 12.0.0.0 --prefixlen 28 --${BGP_APP_PEER_LOG_LEVEL} --stream=${ODL_STREAM} ${script_uri_opt}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${bgp_filling_timeout}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_singles.log

Wait_For_Ipv4_Topology_Is_Filled
    [Documentation]    Wait until example-ipv4-topology reaches the target prfix count.
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    10s    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_APP_PEER_PREFIX_COUNT}

Check_Bgp_Peer_Updates_For_All_Routes
    [Documentation]    Count the routes introduced by updates.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    1s    Check_File_For_Word_Count    bgp_peer.log    total_received_nlri_prefix_counter: ${COUNT_APP_PEER_PREFIX_COUNT}    2

Disconnect_BGP_Peer
    [Documentation]    Stop BGP peer tool
    SSHLibrary.Switch Connection    bgp_peer_console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_peer.log    bgp_peer_reconnect.log

Reconnect_BGP_Peer
    [Documentation]    Start BGP peer tool
    SSHLibrary.Switch Connection    bgp_peer_console
    Start_Console_Tool    ${BGP_PEER_COMMAND}    ${BGP_PEER_OPTIONS}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Bgp_Peer_Updates_For_Reintroduced_Routes
    [Documentation]    Count the routes introduced by updates.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_filling_timeout}    1s    Check_File_For_Word_Count    bgp_peer.log    total_received_nlri_prefix_counter: ${COUNT_APP_PEER_PREFIX_COUNT}    2

BGP_Application_Peer_Delete_All_Routes
    [Documentation]    Start BGP application peer tool and delete all routes.
    SSHLibrary.Switch Connection    bgp_app_peer_console
    Start_Console_Tool    ${BGP_APP_PEER_DELETE_ALL_COMMAND} --stream=${ODL_STREAM} ${script_uri_opt}    ${BGP_APP_PEER_OPTIONS}
    Wait_Until_Console_Tool_Finish    ${bgp_emptying_timeout}
    Store_File_To_Workspace    bgp_app_peer.log    bgp_app_peer_delete_all.log

Wait_For_Stable_Topology_After_Deletion
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_emptying_timeout}    period=${CHECK_PERIOD_APP_PEER_PREFIX_COUNT}    repetitions=${REPETITIONS_APP_PEER_PREFIX_COUNT}    excluded_count=${COUNT_APP_PEER_PREFIX_COUNT}

Check_For_Empty_Ipv4_Topology_After_Deleting
    [Documentation]    Example-ipv4-topology should be empty now.
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Check_Bgp_Peer_Updates_For_Prefix_Withdrawals
    [Documentation]    Count the routes withdrawn by updates.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
    BuiltIn.Wait Until Keyword Succeeds    ${bgp_emptying_timeout}    1s    Check_File_For_Word_Count    bgp_peer.log    total_received_withdrawn_prefix_counter: ${COUNT_APP_PEER_PREFIX_COUNT}    2

Stop_BGP_Peer
    [Documentation]    Stop BGP peer tool
    SSHLibrary.Switch Connection    bgp_peer_console
    Stop_Console_Tool
    Store_File_To_Workspace    bgp_peer.log    bgp_peer_reconnect.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}

Delete_Bgp_Application_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer-app    IP=${BGP_APP_PEER_ID}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_application_peer    mapping=${mapping}

Check_Bug_4791
    [Documentation]    Check controller's log for errors
    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Failed to send message Update

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    timeout=125    max_retries=0
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    Open_BGP_Peer_Console
    Open_BGP_Aplicationp_Peer_Console
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/bgp_app_peer.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/ipv4-routes-template.xml*
    # Calculate the timeout value based on how many routes are going to be pushed.
    # The offset (20) is set for keeping reasonable timeout for low COUNT values.
    ${timeout} =    BuiltIn.Evaluate    ${TEST_DURATION_MULTIPLIER} * ${COUNT_APP_PEER_PREFIX_COUNT} * 3.0 / 10000 + 20
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${bgp_filling_timeout*3.0/4}
    ${result} =    BuiltIn.Evaluate    str(int(${COUNT_APP_PEER_PREFIX_COUNT}) - int(${PREFILL}))
    Builtin.Set_Suite_Variable    ${remaining_prefixes}    ${result}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.protocol
    ${script_uri_opt}=    Set Variable    --uri config/bgp-rib:application-rib/${BGP_APP_PEER_ID}/tables/bgp-types:ipv4-address-family/bgp-types:unicast-subsequent-address-family/
    BuiltIn.Set_Suite_Variable    ${script_uri_opt}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    SSHLibrary.Switch Connection    bgp_peer_console
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    KillPythonTool.Search_And_Kill_Remote_Python    'bgp_app_peer\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Open_BGP_Peer_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_peer_console
    SSHKeywords.Flexible_Mininet_Login

Open_BGP_Aplicationp_Peer_Console
    [Documentation]    Create a session for BGP peer.
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    alias=bgp_app_peer_console
    SSHKeywords.Flexible_Mininet_Login
