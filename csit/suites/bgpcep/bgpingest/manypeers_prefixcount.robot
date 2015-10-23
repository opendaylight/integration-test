*** Settings ***
Documentation     BGP performance of ingesting from many iBGP peers, data change counter NOT used.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite uses play.py processes as iBGP peers.
...               This is analogue of single peer performance suite, which uses many peers.
...               Each peer is of ibgp type, and they contribute to the same example-bgp-rib,
...               and thus to the same single example-ipv4-topology.
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
...               Try the other version of the suite (manypeers_changecount.robot) to get better precision.
...
...               ODL distinguishes peers by their IP addresses.
...               Currently, this suite requires python utils to be started on ODL System,
...               to guarantee IP address block is available for them to bind to.
...               TODO: Figure out how to use Docker and docker IP pool available in RelEng.
...
...               Currently, 127.0.0.1 is hardcoded as the first peer address to use.
...               TODO: Figure out how to make it configurable.
...               As peer IP adresses are set incrementally, we need ipaddr to be used in Robot somehow.
...
...               TODO: Is there a need for version of this suite where ODL connects to pers?
...               Note that configuring ODL is slow, which may affect measured performance singificantly.
...               Advanced TODO: Give manager ability to start pushing on trigger long after connections are established.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           DateTime
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${HOLDTIME_PREFIX_COUNT}    ${HOLDTIME}
${COUNT}          1000000
${COUNT_PREFIX_COUNT}    ${COUNT}
${FIRST_PEER_IP}    127.0.0.1
${MULTIPLICITY}    2    # May be increased after Bug 4488 is fixed.
${MULTIPLICITY_PREFIX_COUNT}    ${MULTIPLICITY}
${CHECK_PERIOD}    4    # ${MULTIPLICITY*2}
${CHECK_PERIOD_PREFIX_COUNT}    ${CHECK_PERIOD}
${REPETITIONS}    1
${REPETITIONS_PREFIX_COUNT}    ${REPETITIONS}
${BGPCEP_LOG_LEVEL}    INFO
# TODO: Option names can be better.
${last_prefix_count}    -1

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Wait for example-ipv4-topology to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    # TODO: Choose which tags to assign and make sure they are assigned correctly.
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY}+1
    \    ${peer_name} =    BuiltIn.Set_Variable    example-bgp-peer-${index}
    \    ${peer_ip} =    BuiltIn.Evaluate    str(ipaddr.IPAddress('${FIRST_PEER_IP}') + ${index} - 1)    modules=ipaddr
    \    ${template_as_string} =    BuiltIn.Set_Variable    {'NAME': '${peer_name}', 'IP': '${peer_ip}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNT}', 'INITIATE': 'false'}
    \    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}
    # FIXME: Add testcase to change bgpcep and protocol log levels, when a Keyword that does it without messing with current connection is ready.

Set_Logging_Levels
    [Documentation]    For Bug 4488 examination, more verbose logging may be needed.
    KarafKeywords.Set_Bgpcep_Log_Levels    bgpcep_level=${BGPCEP_LOG_LEVEL}    protocol_level=${PROTOCOL_LOG_LEVEL}

Start_Talking_BGP_Manager
    [Documentation]    Start Python manager to connect speakers to ODL.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_Manager    --amount=${COUNT_PREFIX_COUNT} --multiplicity=${MULTIPLICITY} --myip=${FIRST_PEER_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT}

Wait_For_Stable_Talking_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking stability of prefix count.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}    excluded_count=0

Check_Talking_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT}

Kill_Talking_BGP_Speakers
    [Documentation]    Abort the Python speakers. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

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

Restore_Logging_Levels
    [Documentation]    Set logging on bgpcep and protocol to default values.
    KarafKeywords.Set_Bgpcep_Log_Levels

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    # TODO: Is it useful to extract peer naming logic to separate Keyword?
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY}+1
    \    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-${index}'}
    \    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLESFOLDER}${/}bgp_peer    ${template_as_string}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to ODL system,
    ...    create HTTP session, put Python tool to ODL system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}
    Utils.Flexible_Controller_Login
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/manage_play.py
    # Calculate the timeout value based on how many routes are going to be pushed.
    ${period} =    DateTime.Convert_Time    ${CHECK_PERIOD_PREFIX_COUNT}    result_format=number
    ${timeout} =    BuiltIn.Evaluate    ${COUNT_PREFIX_COUNT} * 3 / 10000 + ${period} * (${REPETITIONS_PREFIX_COUNT} + 1)
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}
    ${timeout} =    BuiltIn.Evaluate    ${COUNT_PREFIX_COUNT} * 2 / 10000 + ${period} * (${REPETITIONS_PREFIX_COUNT} + 1)
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${timeout}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections
