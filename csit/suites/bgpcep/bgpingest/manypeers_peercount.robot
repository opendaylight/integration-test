*** Settings ***
Documentation     BGP performance of ingesting from many iBGP rrc peers, iBGPs receive updates.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses play.py processes as iBGP rrc peers.
...               This is analogue of single peer performance suite, which uses many peers.
...               Each peer is of ibgp rrc type, and they contribute to the same example-bgp-rib,
...               and thus to the same single example-ipv4-topology.
...               The suite looks at example-ipv4-topology and checks BGP peers log for received updates.
...
...               ODL distinguishes peers by their IP addresses.
...               Currently, this suite requires python utils to be started on ODL System,
...               to guarantee IP address block is available for them to bind to.
...
...               Brief description how to configure BGP peer can be found here:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:User_Guide#BGP_Peer
...               http://docs.opendaylight.org/en/stable-boron/user-guide/bgp-user-guide.html#bgp-peering
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           DateTime
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${BGP_TOOL_LOG_LEVEL}    info
${BGP_PEERS_LOG_FILE_NAME}    bgp_peer.log
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${CHECK_PERIOD_PREFIX_COUNT_MANY_RRC}    10
${COUNT}          60000    # With AdjRibsOut, the amount of data present is on the same scale as 1M ingest with single peer.
${COUNT_PREFIX_COUNT_MANY_RRC}    ${COUNT}
${FIRST_PEER_IP}    127.0.0.1
${HOLDTIME}       180
${HOLDTIME_PREFIX_COUNT_MANY_RRC}    ${HOLDTIME}
${KARAF_LOG_LEVEL}    INFO
${KARAF_BGPCEP_LOG_LEVEL}    ${KARAF_LOG_LEVEL}
${KARAF_PROTOCOL_LOG_LEVEL}    ${KARAF_BGPCEP_LOG_LEVEL}
${MULTIPLICITY_PREFIX_COUNT_MANY_RRC}    10
${REPETITIONS_PREFIX_COUNT_MANY_RRC}    10
${TEST_DURATION_MULTIPLIER}    1
${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_MANY_RRC}    ${TEST_DURATION_MULTIPLIER}
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${DEVICE_NAME}    controller-config

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Wait for example-ipv4-topology to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY_PREFIX_COUNT_MANY_RRC}+1
    \    ${peer_name} =    BuiltIn.Set_Variable    example-bgp-peer-${index}
    \    ${peer_ip} =    BuiltIn.Evaluate    str(ipaddr.IPAddress('${FIRST_PEER_IP}') + ${index} - 1)    modules=ipaddr
    \    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=${peer_name}    IP=${peer_ip}    HOLDTIME=${HOLDTIME_PREFIX_COUNT_MANY_RRC}
    \    ...    PEER_PORT=${BGP_TOOL_PORT}    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true
    \    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    RR_CLIENT=true
    \    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}

Start_Talking_BGP_Manager
    [Documentation]    Start Python manager to connect speakers to ODL.
    BGPSpeaker.Start_BGP_Manager    --amount=${COUNT_PREFIX_COUNT_MANY_RRC} --multiplicity=${MULTIPLICITY_PREFIX_COUNT_MANY_RRC} --myip=${FIRST_PEER_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --logfile=${BGP_PEERS_LOG_FILE_NAME} --${BGP_TOOL_LOG_LEVEL}

Wait_For_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology reaches the target prefix count.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Log    max. ${bgp_filling_timeout}s    console=yes
    Init_Check_Ipv4_Topology_Keyword    ${COUNT_PREFIX_COUNT_MANY_RRC}    ${REPETITIONS_PREFIX_COUNT_MANY_RRC}
    ${message}=    BuiltIn.Wait_Until_Keyword_Succeeds    ${bgp_filling_timeout}    ${CHECK_PERIOD_PREFIX_COUNT_MANY_RRC}    Check_Ipv4_Topology
    BuiltIn.Should_Be_Equal_As_Strings    ${message}    Target value reached.

Check_Logs_For_Updates
    [Documentation]    Check BGP peer logs for received updates.
    [Tags]    critical
    ${timeout} =    BuiltIn.Set_Variable    ${bgp_filling_timeout}
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY_PREFIX_COUNT_MANY_RRC}+1
    \    ${bgp_peer_label} =    BuiltIn.Set_Variable    BGP-Dummy-${index}
    \    ${expected_prefixcount} =    BuiltIn.Evaluate    ${COUNT_PREFIX_COUNT_MANY_RRC} - ${COUNT_PREFIX_COUNT_MANY_RRC} / ${MULTIPLICITY_PREFIX_COUNT_MANY_RRC}
    \    ${expected_string} =    BuiltIn.Set_Variable    total_received_nlri_prefix_counter: ${expected_prefixcount}
    \    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    1s    Check_File_For_Occurence    ${BGP_PEERS_LOG_FILE_NAME}    ${bgp_peer_label}
    \    ...    ${expected_string}    2
    \    ${timeout} =    BuiltIn.Set_Variable    20s
    # FIXME: Calculation of ${expected_prefixcount} correct just when the ${COUNT_PREFIX_COUNT_MANY_RRC} is a multiplication of ${MULTIPLICITY_PREFIX_COUNT_MANY_RRC}

Kill_Talking_BGP_Speakers
    [Documentation]    Abort the Python speakers. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Wait_For_Stable_Ipv4_Topology_After_Talking
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_emptying_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_MANY_RRC}    repetitions=${REPETITIONS_PREFIX_COUNT_MANY_RRC}    excluded_count=${COUNT_PREFIX_COUNT_MANY_RRC}

Check_For_Empty_Ipv4_Topology_After_Talking
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY_PREFIX_COUNT_MANY_RRC}+1
    \    ${peer_name} =    BuiltIn.Set_Variable    example-bgp-peer-${index}
    \    ${peer_ip} =    BuiltIn.Evaluate    str(ipaddr.IPAddress('${FIRST_PEER_IP}') + ${index} - 1)    modules=ipaddr
    \    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=${peer_name}    IP=${peer_ip}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    \    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to ODL system,
    ...    create HTTP session, put Python tool to ODL system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    PrefixCounting.PC_Setup
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    timeout=125    max_retries=0
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    SSHKeywords.Flexible_Controller_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Calculate the timeout value based on how many routes are going to be pushed.
    ${period} =    DateTime.Convert_Time    ${CHECK_PERIOD_PREFIX_COUNT_MANY_RRC}    result_format=number
    ${timeout} =    BuiltIn.Evaluate    ${MULTIPLICITY_PREFIX_COUNT_MANY_RRC} * ${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_MANY_RRC} * (${COUNT_PREFIX_COUNT_MANY_RRC} * 6.0 / 10000 + ${period} * (${REPETITIONS_PREFIX_COUNT_MANY_RRC} + 1)) + 20
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}
    ${timeout} =    BuiltIn.Evaluate    ${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_MANY_RRC} * (${COUNT_PREFIX_COUNT_MANY_RRC} * 2.0 / 10000 + ${period} * (${REPETITIONS_PREFIX_COUNT_MANY_RRC} + 1)) + 20
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${timeout}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${KARAF_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    # Environment issue may have dropped the SSH connection, but we do not want Teardown to fail.
    BuiltIn.Run_Keyword_And_Ignore_Error    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ${status}    ${output}    BuiltIn.Run_Keyword_And_Ignore_Error    Utils.Get_Sysstat_Statistics
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Init_Check_Ipv4_Topology_Keyword
    [Arguments]    ${expected_count}=0    ${deadlock_cycles}=-1
    [Documentation]    Initialise test variables for Check_Ipv4_Topology keyword.
    ${deadlock_cycles}=    Convert To Integer    ${deadlock_cycles}
    BuiltIn.Set_Test_Variable    ${deadlock_cycles}
    BuiltIn.Set_Test_Variable    ${ipv4_topology_deadlock_countdown}    ${deadlock_cycles}
    BuiltIn.Set_Test_Variable    ${expected_count}
    BuiltIn.Set_Test_Variable    ${ipv4_topology_last_count}    -1

Check_Ipv4_Topology
    [Documentation]    Check and log the IPv4 topology count. PASS if ${expected_count} or ${actual_count} not changed for ${deadlock_cycles} keyword calls.
    ${actual_count} =    PrefixCounting.Get_Ipv4_Topology_Count
    ${ipv4_topology_deadlock_countdown}=    BuiltIn.Set_Variable_If    (${actual_count} == ${ipv4_topology_last_count}) and (${ipv4_topology_deadlock_countdown} >= 0)    ${ipv4_topology_deadlock_countdown - 1}    ${deadlock_cycles}
    ${hour}    ${min}    ${sec} =    BuiltIn.Get_Time    hour min sec
    BuiltIn.Set_Test_Variable    ${ipv4_topology_deadlock_countdown}
    BuiltIn.Set_Test_Variable    ${ipv4_topology_last_count}    ${actual_count}
    BuiltIn.Log    ${hour}:${min}:${sec} actual/expected prefix count is ${actual_count}/${expected_count} (countdown:${ipv4_topology_deadlock_countdown})    console=yes
    BuiltIn.Return_From_Keyword_If    ${ipv4_topology_deadlock_countdown} == 0    Deadlock detected (ipv4-topology not changed for ${deadlock_cycles} cycles)
    BuiltIn.Should_Be_Equal_As_Integers    ${actual_count}    ${expected_count}
    [Return]    Target value reached.

Check_File_For_Occurence
    [Arguments]    ${file_name}    ${keyword}    ${value}=''    ${threshold}=1
    [Documentation]    Check file for ${keyword} or ${keyword} ${value} pair and returns number of occurences
    ${output_log}=    SSHLibrary.Execute_Command    grep '${keyword}' '${file_name}' | grep -c '${value}'
    ${count}=    Convert To Integer    ${output_log}
    BuiltIn.Should_Be_True    ${count} >= ${threshold}
    [Return]    ${count}
