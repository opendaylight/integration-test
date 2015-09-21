*** Settings ***
Documentation     Test to cover the bgpcep bug_4409 correction (https://bugs.opendaylight.org).
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
Resource          ${CURDIR}/../../../libraries/BGPKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/bgpuser/
${MININET_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       180
${HOLDTIME_PREFIX_COUNT}       ${HOLDTIME}
${COUNT}          3
${COUNT_PREFIX_COUNT}   ${COUNT}
${CHECK_PERIOD}    5
${CHECK_PERIOD_PREFIX_COUNT}    ${CHECK_PERIOD}
${PASS_COUNT_PREFIX_COUNT}    1
${current_count}    -1
${player_error_log}    play.py.err
${BGP_IPADD}    2
${BGP_IPDEL}    1
${BGP_RANDOMIZE}    0
${BGP_LOG_LEVEL}    error
${ODL_LOG_LEVEL}    DEFAULT

*** Test Cases ***
Set Karaf Log Levels
    [Documentation]    Set Karaf log level
    ${current_SSH_connection}=    Get Current SSH Connection Index
    ${output}=    Issue Command On Karaf Console    log:set ${ODL_LOG_LEVEL} org.opendaylight.bgpcep
    ${output}=    Issue Command On Karaf Console    log:set ${ODL_LOG_LEVEL} org.opendaylight.protocol
    Restore Current SSH Connection    ${current_SSH_connection}

Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    BGPKeywords.Initial_Wait_For_Topology_To_Become_Empty
    BGPKeywords.Check_Topology_Count    0

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNT}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker. Update messages with standalone Withdrawn Routes variable only in case of route withdrawal.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_PREFIX_COUNT} --myip=${MININET} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER} --peerport=${ODL_BGP_PORT} --ipadd=${BGP_IPADD} --ipdel=${BGP_IPDEL} --${BGP_LOG_LEVEL} --single 2

Wait_For_Talking_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking the change counter.
    Wait_For_Topology_To_Become_Stable    ${timeout_for_topology_filling}

Check_Talking_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    BGPKeywords.Check_Topology_Count    ${COUNT_PREFIX_COUNT}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Talking
    [Documentation]    See example-ipv4-topology empty again.
    [Tags]    critical
    Wait_For_Topology_To_Become_Empty    timeout=180s
    BGPKeywords.Check_Topology_Count    0

Start_Talking_BGP_speaker_2
    [Documentation]    Start Python speaker. Update messages with both Withdrawn Routes & NLRI variables in case of route withdrawal.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_PREFIX_COUNT} --myip=${MININET} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER} --peerport=${ODL_BGP_PORT} --ipadd=${BGP_IPADD} --ipdel=${BGP_IPDEL} --${BGP_LOG_LEVEL} --combined 2

Wait_For_Talking_Topology_2
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    Wait_For_Topology_To_Become_Stable    ${timeout_for_topology_filling}

Check_Talking_Topology_Count_2
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct. Check for bug_4409 correction.
    [Tags]    critical
    BGPKeywords.Check_Topology_Count    ${COUNT_PREFIX_COUNT}

Kill_Talking_BGP_Speaker_2
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Talking_2
    [Documentation]    Post-condition: Check example-ipv4-topology is empty again.
    [Tags]    critical
    Wait_For_Topology_To_Become_Empty    timeout=180s
    BGPKeywords.Check_Topology_Count    0

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    FailFast.Do_Not_Fail_Fast_From_Now_On
    SSHLibrary.Set_Default_Configuration    prompt=${MININET_PROMPT}
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Calculate the timeout value based on how many routes are going to be pushed
    ${count}=    Builtin.Convert_To_Integer    ${COUNT_PREFIX_COUNT}
    Builtin.Set_Suite_Variable    ${timeout_for_topology_filling}    ${count/25+60} s

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Wait_For_Topology_To_Become_Empty
    [Arguments]    ${timeout}=10s    ${refresh}=${CHECK_PERIOD_PREFIX_COUNT} s    ${count}=${PASS_COUNT_PREFIX_COUNT}    ${stop_at_http_error}=True
    [Documentation]    Wait until topology becomes empty.
    Utils.Wait_For_Data_To_Satisfy_Keyword    ${timeout}    ${refresh}    ${count}    Check_Topology_Is_Empty

Check_Topology_Is_Stable
    [Arguments]    ${actual_count}
    [Documentation]    Check that there are no changes in the topology since last call.
    ...    This keyword requires a call to Utils.Fail_If_Status_Is_Wrong as it passes
    ...    if the response status is not equal to 200.
    ${expected_count}=    Builtin.Set_Variable    ${current_count}
    Builtin.Set_Suite_Variable    ${current_count}    ${actual_count}
    Builtin.Should_Be_Equal    ${expected_count}    ${actual_count}

Wait_For_Topology_To_Become_Stable
    [Arguments]    ${timeout}    ${refresh}=${CHECK_PERIOD_PREFIX_COUNT}    ${count}=${PASS_COUNT_PREFIX_COUNT}
    Utils.Wait_For_Data_To_Satisfy_Keyword    ${timeout}    ${refresh}    ${count}    Get_Topology_Count    Check_Topology_Is_Stable
