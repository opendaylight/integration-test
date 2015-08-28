*** Settings ***
Documentation     Basic tests for odl-bgpcep-bgp-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite requires odl-bgpcep-data-change-counter to be installed so
...               make sure it is added to "install-features" of any jobs that are going
...               to invoke it.
...
...               Additionally this test suite is not compatible with Helium and Hydrogen
...               releases as they don't include data change counter feature. Use the other
...               version of the suite (singlepeer_prefixcount.robot) to test them.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/BGPKeywords.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${directory_with_template_folders}    ${CURDIR}/../../../variables/bgpuser/
${CONTROLLER_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       180
${HOLDTIME_CHANGE_COUNTER}       ${HOLDTIME}
${COUNT}          100000
${COUNT_CHANGE_COUNTER}   ${COUNT}
${CHECK_PERIOD}    5
${CHECK_PERIOD_CHANGE_COUNTER}    ${CHECK_PERIOD}
${current_count_text}    "No count obtained yet"
${change_counter_ok}    False

# The test might "silently fail" by stopping the ingestion and pretending
# that everything is up-to-date even when it is not. The most common cause
# is that the data change counter does not register any changes within one
# test period (due to some bottleneck or something). This "functional part"
# is used to make sure that the ingestion is really completed when the main
# performance test breaks out of the loop. The pattern here is very
# simplistic as it is not supposed to do a full functional test.

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    KarafKeywords.Log_Message_To_Controller_Karaf    Checking for empty topology
    BGPKeywords.Initial_Wait_For_Topology_To_Become_Empty
    BGPKeywords.Check_Topology_Count    0

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME_CHANGE_COUNTER}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Check_Data_Change_Counter_Ready
    [Documentation]    Fail if the data change counter is still not ready to be reconfigured.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Get_Change_Count
    BuiltIn.Set_Suite_Variable    ${change_counter_ok}    True
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Wait_For_Data_Change_Counter_Ready
    [Documentation]    Wait for the data change counter to become ready if the previous test case failed.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Run_Keyword_Unless    ${change_counter_ok}    Builtin.Wait_Until_Keyword_Succeeds    60s    1s    Get_Change_Count
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Reconfigure_Data_Change_Counter
    [Documentation]    Configure data change counter to count transactions affecting
    ...    example-ipv4-topology instead of example-linkstate-topology.
    ${template_as_string}=    BuiltIn.Set_Variable    {'TOPOLOGY_NAME': 'example-ipv4-topology'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}change_counter    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_CHANGE_COUNTER} --myip=${MININET} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER} --peerport=${ODL_BGP_PORT}

Wait_For_Talking_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking the change counter.
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD_CHANGE_COUNTER}

Check_Talking_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    BGPKeywords.Check_Topology_Count    ${COUNT_CHANGE_COUNTER}

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
    Wait_For_Topology_To_Become_Unstable    timeout=180s    check_period=${CHECK_PERIOD_CHANGE_COUNTER} s
    Wait_For_Topology_To_Become_Empty    timeout=180s
    BGPKeywords.Check_Topology_Count    0

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_CHANGE_COUNTER} --listen --myip=${MININET} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER}

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME_CHANGE_COUNTER}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Wait_For_Listening_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD_CHANGE_COUNTER}

Check_Listening_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    BGPKeywords.Check_Topology_Count    ${COUNT_CHANGE_COUNTER}

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Listening
    [Documentation]    Measure the time needed to clear the example-ipv4-topology topology
    ...    and check that the topology actually becomes clear.
    [Tags]    critical
    Wait_For_Topology_To_Become_Unstable    timeout=180s    check_period=${CHECK_PERIOD_CHANGE_COUNTER} s
    Wait_For_Topology_To_Become_Empty    timeout=180s
    BGPKeywords.Check_Topology_Count    0

Restore_Data_Change_Counter_Configuration
    [Documentation]    Configure data change counter back to count transactions affecting
    ...    example-linkstate-topology.
    ${template_as_string}=    BuiltIn.Set_Variable    {'TOPOLOGY_NAME': 'example-linkstate-topology'}
    # The data change counter might
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}change_counter    ${template_as_string}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    SSHLibrary.Set_Default_Configuration    prompt=${CONTROLLER_PROMPT}
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Calculate the timeout value based on how many routes are going to be pushed
    ${count}=    Builtin.Convert_To_Integer    ${COUNT_CHANGE_COUNTER}
    Builtin.Set_Suite_Variable    ${timeout}    ${count/25+60} s

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Get_Change_Count
    [Documentation]    Get the count of changes from BGP change counter. Fail on a HTTP
    ...    error.
    ${data}=    Utils.Get_Data_From_URI    operational    data-change-counter:data-change-counter
    [Return]    ${data}

Check_Topology_Stability
    [Arguments]    ${expect_stable}    ${actual_count_text}
    [Documentation]    Check that the change counter data indicates no changes in the topology
    ...    since last call (called "stable"; selected by passing ${expect_stable} = True) or
    ...    there are changes indicated since last call (called unstable; selected by passing
    ...    ${expect_stable} = False).
    ${expected_count_text}=    Builtin.Set_Variable    ${current_count_text}
    Builtin.Set_Suite_Variable    ${current_count_text}    ${actual_count_text}
    Builtin.Run_Keyword_If    ${expect_stable}    Builtin.Should_Be_Equal    ${expected_count_text}    ${actual_count_text}
    Builtin.Run_Keyword_Unless    ${expect_stable}    Builtin.Should_Not_Be_Equal    ${expected_count_text}    ${actual_count_text}

Wait_For_Topology_Stability
    [Arguments]    ${timeout}    ${check_period}    ${expect_stable}
    [Documentation]    Wait for topology to either become stable (when ${expectunstable} is 0)
    ...    or unstable (when ${expectunstable} is 1). Used by the convenience keywords
    ...    defined below. The loop is failed immediately when the topology becomes "wedged".
    Utils.Wait_For_Data_To_Satisfy_Keyword    ${timeout}    ${check_period}    Get_Change_Count    Check_Topology_Stability    ${expect_stable}

Wait_For_Topology_To_Become_Stable
    [Arguments]    ${timeout}    ${check_period}    ${stop_at_http_error}=True
    [Documentation]    Wait until no more changes are happening in the topology.
    Wait_For_Topology_Stability    ${timeout}    ${check_period}    expect_stable=True

Wait_For_Topology_To_Become_Unstable
    [Arguments]    ${timeout}    ${check_period}
    [Documentation]    Wait until changes start happening in the topology.
    Wait_For_Topology_Stability    ${timeout}    ${check_period}    expect_stable=False

Wait_For_Topology_To_Become_Empty
    [Arguments]    ${timeout}=10s    ${refresh}=${CHECK_PERIOD_CHANGE_COUNTER} s
    [Documentation]    Wait until topology becomes empty.
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${refresh}
    BGPKeywords.Check_Topology_Is_Empty
