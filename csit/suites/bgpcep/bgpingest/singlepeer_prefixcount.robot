*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
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
...               Brief description how to configure BGP peer can be found here:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:User_Guide#BGP_Peer
...               http://docs.opendaylight.org/en/stable-boron/user-guide/bgp-user-guide.html#bgp-peering
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
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot

*** Variables ***
${BGP_TOOL_LOG_LEVEL}    info
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${CHECK_PERIOD}    30
${CHECK_PERIOD_PREFIX_COUNT}    ${CHECK_PERIOD}
${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    ${CHECK_PERIOD_PREFIX_COUNT}
${COUNT}          1000000
${COUNT_PREFIX_COUNT}    ${COUNT}
${COUNT_POLICIES}    500000
${HOLDTIME}       180
${HOLDTIME_PREFIX_COUNT}    ${HOLDTIME}
${HOLDTIME_PREFIX_COUNT_SINGLE}    ${HOLDTIME_PREFIX_COUNT}
${INSERT}         1
${KARAF_LOG_LEVEL}    INFO
${KARAF_BGPCEP_LOG_LEVEL}    ${KARAF_LOG_LEVEL}
${KARAF_PROTOCOL_LOG_LEVEL}    ${KARAF_BGPCEP_LOG_LEVEL}
${PREFILL}        0
${REPETITIONS}    1
${REPETITIONS_PREFIX_COUNT}    ${REPETITIONS}
${REPETITIONS_PREFIX_COUNT_SINGLE}    ${REPETITIONS_PREFIX_COUNT}
${RESULTS_FILE_NAME}    bgp.csv
${TEST_DURATION_MULTIPLIER}    1
${TEST_DURATION_MULTIPLIER_PREFIX_COUNT}    ${TEST_DURATION_MULTIPLIER}
${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_SINGLE}    ${TEST_DURATION_MULTIPLIER_PREFIX_COUNT}
${UPDATE}         single
${WITHDRAW}       0
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
# TODO: Option names can be better.

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Wait for example-ipv4-topology to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    # TODO: Choose which tags to assign and make sure they are assigned correctly.
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME_PREFIX_COUNT_SINGLE}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}

Change_Karaf_Logging_Levels
    [Documentation]    We may want to set more verbose logging here after configuration is done.
    KarafKeywords.Set_Bgpcep_Log_Levels    bgpcep_level=${KARAF_BGPCEP_LOG_LEVEL}    protocol_level=${KARAF_PROTOCOL_LOG_LEVEL}

Start_Talking_BGP_Speaker
    [Documentation]    Start Python speaker to connect to ODL.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_Speaker    --amount ${COUNT_PREFIX_COUNT_SINGLE} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --update ${UPDATE} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}

Wait_For_Stable_Talking_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking stability of prefix count.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    repetitions=${REPETITIONS_PREFIX_COUNT_SINGLE}    excluded_count=0

Check_Talking_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT_SINGLE}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Store_Results_For_Talking_BGP_Speaker
    [Documentation]    Store results for plotting
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Store_File_To_Workspace    totals-${RESULTS_FILE_NAME}    totals-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    performance-${RESULTS_FILE_NAME}    performance-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    totals-${RESULTS_FILE_NAME}    prefixcount-talking-totals-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    performance-${RESULTS_FILE_NAME}    prefixcount-talking-performance-${RESULTS_FILE_NAME}

Wait_For_Stable_Ipv4_Topology_After_Talking
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    # TODO: Is is possible to have failed at Check_Talking_Ipv4_Topology_Count and still have initial period of constant count?
    # FIXME: If yes, do count here to get the initial value and use it (if nonzero).
    # TODO: If yes, decide whether access to the FailFast state should have keyword or just variable name.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    repetitions=${REPETITIONS_PREFIX_COUNT_SINGLE}    excluded_count=${COUNT_PREFIX_COUNT_SINGLE}

Check_For_Empty_Ipv4_Topology_After_Talking
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode.
    BGPSpeaker.Start_BGP_Speaker    --amount ${COUNT_PREFIX_COUNT_SINGLE} --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --update ${UPDATE} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME_PREFIX_COUNT_SINGLE}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=true    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=false    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}

Wait_For_Stable_Listening_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    repetitions=${REPETITIONS_PREFIX_COUNT_SINGLE}    excluded_count=0

Check_Listening_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT_SINGLE}

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Store_Results_For_Listening_BGP_Speaker
    [Documentation]    Store results for plotting
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Store_File_To_Workspace    totals-${RESULTS_FILE_NAME}    totals-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    performance-${RESULTS_FILE_NAME}    performance-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    totals-${RESULTS_FILE_NAME}    prefixcount-listening-totals-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    performance-${RESULTS_FILE_NAME}    prefixcount-listening-performance-${RESULTS_FILE_NAME}

Wait_For_Stable_Ipv4_Topology_After_Listening
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    repetitions=${REPETITIONS_PREFIX_COUNT_SINGLE}    excluded_count=${COUNT_PREFIX_COUNT_SINGLE}

Check_For_Empty_Ipv4_Topology_After_Listening
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Restore_Karaf_Logging_Levels
    [Documentation]    Set logging on bgpcep and protocol to the global value.
    KarafKeywords.Set_Bgpcep_Log_Levels    bgpcep_level=${KARAF_LOG_LEVEL}    protocol_level=${KARAF_LOG_LEVEL}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    PrefixCounting.PC_Setup
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    timeout=125    max_retries=0
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    SSHKeywords.Flexible_Mininet_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Change fluorine prefix count due to additional features.
    ${COUNT_PREFIX_COUNT_SINGLE}    CompareStream.Set_Variable_If_At_Least_Fluorine    ${COUNT_POLICIES}    ${COUNT_PREFIX_COUNT}
    BuiltIn.Set_Suite_Variable    ${COUNT_PREFIX_COUNT_SINGLE}
    # Calculate the timeout value based on how many routes are going to be pushed
    # TODO: Replace 20 with some formula from period and repetitions.
    ${timeout} =    BuiltIn.Evaluate    ${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_SINGLE} * (${COUNT_PREFIX_COUNT_SINGLE} * 9.0 / 10000 + 20)
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${KARAF_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    # Environment issue may have dropped the SSH connection, but we do not want Teardown to fail.
    BuiltIn.Run_Keyword_And_Ignore_Error    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    Utils.Get_Sysstat_Statistics
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Store_File_To_Workspace
    [Arguments]    ${src_file_name}    ${dst_file_name}
    [Documentation]    Store the provided file from the SSH client to workspace.
    ${files}=    SSHLibrary.List Files In Directory    .
    ${output_log}=    SSHLibrary.Execute_Command    cat ${src_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${dst_file_name}    ${output_log}
