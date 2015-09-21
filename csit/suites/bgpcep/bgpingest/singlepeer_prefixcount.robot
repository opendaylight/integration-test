*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter NOT used.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite uses play.py as single iBGP peer.
...               The suite only looks at example-ipv4-topology, so RIB is not examined.
...
...               The suite consists of two halves, differing on which side initiates BGP connection.
...               State of "work is being done" is detected by increasing value of prefixes in topology.
...               The time for Wait_For_Stable_* cases to finish is the main performance metric.
...               After waiting for stability is done, full check on number of prefixes present is performed.
...
...               TODO: Currently, if a bug causes prefix count to remain at zero,
...               affected test cases will wait for max time. Reconsider.
...               If zero is allowed as stable, higher period or repetitions would be required.
...
...               The prefix counting is quite heavyweight and may induce large variation in time.
...               Try the other version of the suite (singlepeer_changecount.robot) to get better precision.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
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
${HOLDTIME_PREFIX_COUNT}    ${HOLDTIME}
${COUNT}          1000000
${COUNT_PREFIX_COUNT}    ${COUNT}
${CHECK_PERIOD}    1
${CHECK_PERIOD_PREFIX_COUNT}    ${CHECK_PERIOD}
${REPETITIONS_PREFIX_COUNT}    1
${INSERT}    1
${WITHDRAW}    0
${PREFILL}    0
${SCENARIO}    separate
${BGP_TOOL_LOG_LEVEL}    info
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT
${RESULTS_FILE_NAME}    bgp-performance-prefixcount.csv

# TODO: Option names can be better.
${last_prefix_count}    -1

*** Test Cases ***
Set Karaf Log Levels
    [Documentation]    Set Karaf log level
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.protocol

Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Wait for example-ipv4-topology to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    # TODO: Choose which tags to assign and make sure they are assigned correctly.
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string} =    BuiltIn.Set_Variable    {'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNT}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_PREFIX_COUNT} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --${SCENARIO} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}

Wait_For_Stable_Talking_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking stability of prefix count.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}    excluded_count=0

Check_Talking_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Store_Results
    Store_File_To_Robot    ${RESULTS_FILE_NAME}

Wait_For_Stable_Ipv4_Topology_After_Talking
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    # TODO: Is is possible to have failed at Check_Talking_Ipv4_Topology_Count and still have initial period of constant count?
    # FIXME: If yes, do count here to get the initial value and use it (if nonzero).
    # TODO: If yes, decide whether access to the FailFast state should have keyword or just variable name.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}    excluded_count=${COUNT_PREFIX_COUNT}

Check_For_Empty_Ipv4_Topology_After_Talking
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_PREFIX_COUNT} --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --${SCENARIO} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    ${template_as_string} =    BuiltIn.Set_Variable    {'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNT}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Wait_For_Stable_Listening_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}    excluded_count=0

Check_Listening_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT}

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Wait_For_Stable_Ipv4_Topology_After_Listening
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}    excluded_count=${COUNT_PREFIX_COUNT}

Check_For_Empty_Ipv4_Topology_After_Listening
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Calculate the timeout value based on how many routes are going to be pushed
    ${count} =    Builtin.Convert_To_Integer    ${COUNT_PREFIX_COUNT}
    # TODO: Replace 20 with some formula from period and repetitions.
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${count*3/10000+20}
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${bgp_filling_timeout*3/4}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Store_File_To_Robot
    [Arguments]    ${file_name}
    [Documentation]    Store the provided file from the MININET to the ROBOT machine.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${file_name}    ${output_log}
