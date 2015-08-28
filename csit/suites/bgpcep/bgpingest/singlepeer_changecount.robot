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
...
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot

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
${player_error_log}    play.py.err

# The test might "silently fail" by stopping the ingestion and pretending
# that everything is up-to-date even when it is not. The most common cause
# is that the data change counter does not register any changes within one
# test period (due to some bottleneck or something). This "functional part"
# is used to make sure that the ingestion is really completed when the main
# performance test breaks out of the loop. The pattern here is very
# simplistic as it is not supposed to do a full functional test.
${prefix_pattern}    "prefix":"

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Log_Message_To_Controller_Karaf    Checking for empty topology
    Wait_For_Topology_To_Become_Empty    timeout=120s    stop_at_http_error=False
    # TODO: Verify that 120 seconds is not too short if this suite is run immediatelly after ODL is started.

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    Utils.Log_Message_To_Controller_Karaf    Reconfiguring ODL to accept a connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME_CHANGE_COUNTER}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Reconfigure_Data_Change_Counter
    [Documentation]    Configure data change counter to count transactions affecting
    ...    example-ipv4-topology instead of example-linkstate-topology.
    Utils.Log_Message_To_Controller_Karaf    Reconfiguring data change counter to start counting transactions in topology
    ${template_as_string}=    BuiltIn.Set_Variable    {}
    Builtin.Wait_Until_Keyword_Succeeds    60s    1s    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}change_counter    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL, verify that the tool does not promptly exit.
    ${command}=    BuiltIn.Set_Variable    python play.py --amount ${COUNT_CHANGE_COUNTER} --myip=${MININET} --myport=17900 --peerip=${CONTROLLER} --peerport=1790 2>${player_error_log}
    # Myport value is needed for checking whether connection at precise port was established.
    # TODO: Do we want to define ${BGP_PORT} in Variables.py?
    Utils.Log_Message_To_Controller_Karaf    Starting talking BGP speaker
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Wait_For_Talking_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking the change counter.
    Utils.Log_Message_To_Controller_Karaf    Waiting for BGP topology to become filled
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD_CHANGE_COUNTER}

Check_Talking_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    Utils.Log_Message_To_Controller_Karaf    Checking that all routes are in the topology
    Check_Topology_Count    ${COUNT_CHANGE_COUNTER}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Utils.Log_Message_To_Controller_Karaf    Stopping the BGP speaker
    Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Talking
    [Documentation]    See example-ipv4-topology empty again.
    [Tags]    critical
    Wait_For_Topology_To_Become_Unstable    timeout=180s    check_period=${CHECK_PERIOD_CHANGE_COUNTER} s
    Utils.Log_Message_To_Controller_Karaf    Waiting for topology to become empty
    Wait_For_Topology_To_Become_Empty    timeout=180s

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode, verify that the tool does not exit quickly.
    ${command}=    BuiltIn.Set_Variable    python play.py --amount ${COUNT_CHANGE_COUNTER} --listen --myip=${MININET} --myport=17900 --peerip=${CONTROLLER} 2>${player_error_log}
    # TODO: ${BGP_TOOL_PORT} is probably not worth the trouble.
    Utils.Log_Message_To_Controller_Karaf    Starting listening BGP speaker
    Builtin.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}
    Read_And_Fail_If_Prompt_Is_Seen

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    Utils.Log_Message_To_Controller_Karaf    Reconfiguring ODL to initiate the connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME_CHANGE_COUNTER}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Wait_For_Listening_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    Utils.Log_Message_To_Controller_Karaf    Waiting for the topology to fill up
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD_CHANGE_COUNTER}

Check_Listening_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    Utils.Log_Message_To_Controller_Karaf    Checking that all the routes are in the topology
    Check_Topology_Count    ${COUNT_CHANGE_COUNTER}

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Utils.Log_Message_To_Controller_Karaf    Stopping the BGP speaker
    Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Listening
    [Documentation]    Post-condition: Check example-ipv4-topology is empty again.
    [Tags]    critical
    Utils.Log_Message_To_Controller_Karaf    Waiting for topology to become empty
    Wait_For_Topology_To_Become_Unstable    timeout=180s    check_period=${CHECK_PERIOD_CHANGE_COUNTER} s
    Wait_For_Topology_To_Become_Empty    timeout=180s

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    Utils.Log_Message_To_Controller_Karaf    Deleting the BGP speaker configuration from ODL
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer
    # TODO: Do we need to check something else?

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    ConfigViaRestconf.Setup_Config_Via_Restconf
    FailFast.Do_Not_Fail_Fast_From_Now_On
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
    # Report that the suite is being run.
    Utils.Log_Message_To_Controller_Karaf    Starting the BGP ingestion test with ${COUNT_CHANGE_COUNTER} route(s) using change counter

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Fail_If_Status_Is_Wrong
    [Documentation]    Shall be called immediately after another keyword that makes a request
    ...    and passes if the status is not 200. It checks the status and if it is not 200, logs
    ...    the content of the response (it may contain valuable error information about why
    ...    the status went wrong) and fails. If the status is 200, it does nothing.
    Builtin.Return_From_Keyword_If    ${response_code} == 200
    Builtin.Log    ${response_content}
    Builtin.Fail    The topology got wedged

Check_Topology_Is_Empty
    [Documentation]    Check that topology is empty, fail if it is not.
    ...    This keyword requires a call to Fail_If_Status_Is_Wrong as it passes
    ...    if the response status is not equal to 200.
    ${count}=    Get_Topology_Count_Core
    Builtin.Run_Keyword_If    ${response_code} == 200    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Topology_Stability
    [Arguments]    ${expectstable}    ${passonhttperror}
    [Documentation]    Check that there are no changes in the topology since last call (called "stable";
    ...    selected by passing ${expectstable} = True) or there are changes since last call
    ...    (called unstable; selected by passing ${expectunstable} = 1). This passes when
    ...    topology gets "wedged" (indicated by getting response code other than 200).
    ...    Used by the convenience keywords defined below.
    ${response}=    RequestsLibrary.Get    operational    data-change-counter:data-change-counter
    Builtin.Set_Suite_Variable    ${response_code}    ${response.status_code}
    Builtin.Run_Keyword_Unless    ${passonhttperror}    Fail_If_Status_Is_Wrong
    Builtin.Run_Keyword_If    ${response_code} <> 200    Builtin.Set_Suite_Variable    ${response_content}    ${response.text}
    Builtin.Run_Keyword_If    ${response_code} <> 200    Builtin.Return_From_Keyword
    ${expected_count_text}=    Builtin.Set_Variable    ${current_count_text}
    ${actual_count_text}=    Builtin.Set_Variable    ${response.text}
    Builtin.Set_Suite_Variable    ${current_count_text}    ${actual_count_text}
    Builtin.Run_Keyword_If    ${expectstable}    Builtin.Should_Be_Equal    ${expected_count_text}    ${actual_count_text}
    Builtin.Run_Keyword_Unless    ${expectstable}    Builtin.Should_Not_Be_Equal    ${expected_count_text}    ${actual_count_text}

Check_Topology_Is_Stable
    [Documentation]    Check that there are no changes in the topology since last call.
    ...    This keyword requires a call to Fail_If_Status_Is_Wrong as it passes
    ...    if the response status is not equal to 200.
    Check_Topology_Stability    expectstable=True

Wait_For_Topology_Stability
    [Arguments]    ${timeout}    ${check_period}    ${expectstable}    ${stop_at_http_error}=False
    [Documentation]    Wait for topology to either become stable (when ${expectunstable} is 0)
    ...    or unstable (when ${expectunstable} is 1). Used by the convenience keywords
    ...    defined below. The loop is failed immediately when the topology becomes "wedged".
    # The change counter mechanics requires that the Builtin.Wait_Until_Keyword_Succeeds
    # loop starts with the waiting period. However Builtin.Wait_Until_Keyword_Succeeds
    # keyword performs the first test immediately which may cause the loop to terminate
    # prematurely by skipping a waiting period that would give ODL enough opportunity
    # to accumulate a few changes if it is still working. So add an artifical waiting
    # pretiod just before 
    Builtin.Sleep    ${check_period}
    ${actual}=    Builtin.Wait_Until_Keyword_Succeeds    ${timeout}    ${check_period}    Check_Topology_Stability    expectstable=${expectstable}    passonhttperror=${stop_at_http_error}
    Fail_If_Status_Is_Wrong

Wait_For_Topology_To_Become_Stable
    [Arguments]    ${timeout}    ${check_period}    ${stop_at_http_error}=True
    [Documentation]    Wait until no more changes are happening in the topology.
    Wait_For_Topology_Stability    ${timeout}    ${check_period}    expectstable=True

Wait_For_Topology_To_Become_Unstable
    [Arguments]    ${timeout}    ${check_period}
    [Documentation]    Wait until changes start happening in the topology.
    Wait_For_Topology_Stability    ${timeout}    ${check_period}    expectstable=False    stop_at_http_error=True

Wait_For_Topology_To_Become_Empty
    [Arguments]    ${timeout}=10s    ${refresh}=${CHECK_PERIOD_CHANGE_COUNTER} s    ${stop_at_http_error}=True
    [Documentation]    Wait until topology becomes empty.
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${refresh}    stop_at_http_error=${stop_at_http_error}
    Check_Topology_Is_Empty
    Fail_If_Status_Is_Wrong

Get_Topology_Count_Core
    [Documentation]    Get count of prefixes in the topology. Expects the name of the file where
    ...    the topology data should be stored. Stores the response code into ${response_code} and
    ...    does not fail if it is not 200 (call Fail_If_Status_Is_Wrong afterwards if that is
    ...    not the desired behavior).
    ${response}=    RequestsLibrary.Get    operational    network-topology:network-topology/topology/example-ipv4-topology
    Builtin.Set_Suite_Variable    ${response_code}    ${response.status_code}
    Builtin.Run_Keyword_If    ${response_code} <> 200    Builtin.Set_Suite_Variable    ${response_content}    ${response.text}
    Builtin.Run_Keyword_If    ${response_code} <> 200    Builtin.Return_From_Keyword    -1
    ${actual_count}=    Builtin.Evaluate    len(re.findall('${prefix_pattern}', '''${response.text}'''))    modules=re
    Builtin.Return_From_Keyword    ${actual_count}

Get_Topology_Count
    [Documentation]    Get count of prefixes in the topology. Works only for IPv4 prefixes and uses rather unsophisticated
    ...    way of counting them (it actually counts the IPv4 addresses in the resulting JSON data). Expects the
    ...    name of the file where the topology data should be stored. Fails if the response is not 200.
    ${result}=    Get_Topology_Count_Core
    Fail_If_Status_Is_Wrong
    Builtin.Return_From_Keyword    ${result}

Check_Topology_Count
    [Arguments]    ${expected_count}
    [Documentation]    Check that the count of prefixes matches the expected count. Fails if it does not.
    ...    Fails if the status code is not 200.
    ${actual_count}=    Get_Topology_Count
    BuiltIn.Should_Be_Equal_As_Strings    ${actual_count}    ${expected_count}

Kill_BGP_Speaker
    [Documentation]    Interrupt play.py, fail if no prompt is seen within SSHLibrary timeout.
    ...    Also, check that TCP connection is no longer established.
    Write_Bare_Ctrl_C
    SSHLibrary.Read_Until_Prompt

Dump_Player_Error_Log
    [Documentation]    Dump the content of the file saving the stderr output from play.py
    ${output}=    SSHLibrary.Execute_Command    cat ${player_error_log}
    Builtin.Log    ${output}

Read_And_Fail_If_Prompt_Is_Seen
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    ${status}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Run_Keyword_And_Expect_Error    No match found for '${prompt}' in *.    Read_Text_Before_Prompt
    Builtin.Return_From_Keyword_If    ${status}
    Dump_Player_Error_Log
    Builtin.Fail    The prompt was seen but it should not be seen.

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

Write_Bare_Ctrl_C
    [Documentation]    Construct ctrl+c character and SSH-write it (without endline). Do not read anything yet.
    # TODO: Place this keyword to some Resource so that it can be re-used in other suites.
    ${command}=    BuiltIn.Evaluate    chr(int(3))
    SSHLibrary.Write_Bare    ${command}
