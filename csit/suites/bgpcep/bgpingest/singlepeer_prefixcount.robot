*** Settings ***
Documentation     Basic tests for odl-bgpcep-bgp-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ChangeCounter.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${HOLDTIME_PREFIX_COUNT}    ${HOLDTIME}
${COUNT}          100000
${COUNT_PREFIX_COUNT}    ${COUNT}
${CHECK_PERIOD}    5
${CHECK_PERIOD_PREFIX_COUNT}    ${CHECK_PERIOD}
${PASS_COUNT_PREFIX_COUNT}    1
${last_prefix_count}    -1

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string} =    BuiltIn.Set_Variable    {'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNT}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL, verify that the tool does not promptly exit.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_PREFIX_COUNT} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER} --peerport=${ODL_BGP_PORT}

Wait_For_Talking_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}

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

Wait_For_Stable_Ipv4_Topology_After_Talking
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}

Check_For_Empty_Ipv4_Topology_After_Talking
    [Documentation]    See example-ipv4-topology empty again.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode, verify that the tool does not exit quickly.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_PREFIX_COUNT} --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER}

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    ${template_as_string} =    BuiltIn.Set_Variable    {'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNT}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Wait_For_Listening_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}

Check_Listening_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT}

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Wait_For_Stable_Ipv4_Topology_After_Listening
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT}    repetitions=${REPETITIONS_PREFIX_COUNT}

Check_For_Empty_Ipv4_Topology_After_Listening
    [Documentation]    See example-ipv4-topology empty again.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    FailFast.Do_Not_Fail_Fast_From_Now_On
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Calculate the timeout value based on how many routes are going to be pushed
    ${count} =    Builtin.Convert_To_Integer    ${COUNT_PREFIX_COUNT}
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${count/25+60} s
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${count/50+5} s

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections
