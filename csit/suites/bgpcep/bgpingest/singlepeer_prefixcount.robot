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
${COUNT}          100000
${CHECK_PERIOD_POLLING}    5
${CHECK_PERIOD}    ${CHECK_PERIOD_POLLING}
${current_count}    -1
${player_error_log}    play.py.err
${prefix_pattern}    "prefix"[ :]\+"[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/[0-9]\+"

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Utils.Log_Message_To_Controller_Karaf    Checking for empty topology
    Wait_For_Topology_To_Become_Empty    timeout=120s    wasfilled=False
    # TODO: Verify that 120 seconds is not too short if this suite is run immediatelly after ODL is started.

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    Utils.Log_Message_To_Controller_Karaf    Reconfiguring ODL to accept a connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL, verify that the tool does not promptly exit.
    ${command}=    BuiltIn.Set_Variable    python play.py --amount ${COUNT} --myip=${MININET} --myport=17900 --peerip=${CONTROLLER} --peerport=1790 2>${player_error_log}
    # Myport value is needed for checking whether connection at precise port was established.
    # TODO: Do we want to define ${BGP_PORT} in Variables.py?
    Utils.Log_Message_To_Controller_Karaf    Starting talking BGP speaker
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Talking_Connection_Is_Established
    [Documentation]    See TCP (BGP) connection in established state.
    # This case is separate from the previous one, to resemble structure of the second half of this suite more closely.
    Utils.Log_Message_To_Controller_Karaf    Checking the BGP speaker is connected
    Check_Speaker_Is_Connected

Wait_For_Talking_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking the change counter.
    Utils.Log_Message_To_Controller_Karaf    Waiting for BGP topology to become filled
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD}

Check_Talking_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    Utils.Log_Message_To_Controller_Karaf    Checking that all routes are in the topology
    Check_Topology_Count    ${COUNT}

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
    Utils.Log_Message_To_Controller_Karaf    Waiting for topology to become empty
    Wait_For_Topology_To_Become_Empty    timeout=180s

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode, verify that the tool does not exit quickly.
    ${command}=    BuiltIn.Set_Variable    python play.py --amount ${COUNT} --listen --myip=${MININET} --myport=17900 --peerip=${CONTROLLER} 2>${player_error_log}
    # TODO: ${BGP_TOOL_PORT} is probably not worth the trouble.
    Utils.Log_Message_To_Controller_Karaf    Starting listening BGP speaker
    Builtin.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}
    Read_And_Fail_If_Prompt_Is_Seen

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    Utils.Log_Message_To_Controller_Karaf    Reconfiguring ODL to initiate the connection
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Check_Listening_Connection_Is_Established
    [Documentation]    See TCP (BGP) connection in established state.
    Utils.Log_Message_To_Controller_Karaf    Checking that the BGP speaker is now connected
    Check_Speaker_Is_Connected

Wait_For_Listening_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    Utils.Log_Message_To_Controller_Karaf    Waiting for the topology to fill up
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD}

Check_Listening_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    Utils.Log_Message_To_Controller_Karaf    Checking that all the routes are in the topology
    Check_Topology_Count    ${COUNT}

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
    Wait_For_Topology_To_Become_Empty    timeout=180s

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    Utils.Log_Message_To_Controller_Karaf    Deleting the BGP speaker configuration from ODL
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer
    # TODO: Do we need to check something else?

*** Keywords ***
Setup_Everything
    [Documentation]    setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    ConfigViaRestconf.Setup_Config_Via_Restconf
    FailFast.Do_Not_Fail_Fast_From_Now_On
    SSHLibrary.Set_Default_Configuration    prompt=${CONTROLLER_PROMPT}
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_SSH_Login    ${MININET_USER}    ${MININET_PASSWORD}
    RequestsLibrary.Create_Session    ses    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    # Calculate the timeout value based on how many routes are going to be pushed
    ${count}=    Builtin.Convert_To_Integer    ${COUNT}
    Builtin.Set_Suite_Variable    ${timeout}    ${count/25+60} s
    # Report that the suite is being run.
    Utils.Log_Message_To_Controller_Karaf    Starting the BGP ingestion test with ${COUNT} route(s) using topology polling

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

Wait_For_Topology_To_Become_Empty
    [Arguments]    ${timeout}=10s    ${refresh}=${CHECK_PERIOD} s    ${wasfilled}=True
    [Documentation]    Wait until topology becomes empty.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Check_Topology_Is_Empty    passonhttperror=${wasfilled}
    Fail_If_Status_Is_Wrong

Check_Topology_Is_Empty
    [Arguments]    ${passonhttperror}=False
    [Documentation]    Check that topology is empty, fail if it is not.
    ...    This keyword requires a call to Fail_If_Status_Is_Wrong as it passes
    ...    if the response status is not equal to 200.
    # Get_Topology_Count_Core generates a LOT of garbage, especially when large
    # route counts are involved. This garbage is not immediately reclaimed by
    # Python because Robot creates cycled structures that hold references to
    # this multi-megabyte garbage. Allowing this garbage to build could cause
    # "sudden death" (OOM killer) before Python decides to collect it on its
    # own so make sure to tell Python to do this collection now. This must be
    # done here because only here we can be sure that the multi-mega-byte
    # value was digested down to a single integer.
    ${count}=    Get_Topology_Count_Core
    Builtin.Evaluate    gc.collect()    modules=gc
    Builtin.Run_Keyword_Unless    ${passonhttperror}    Fail_If_Status_Is_Wrong
    Builtin.Run_Keyword_If    ${response_code} == 200    Builtin.Should_Be_Equal_As_Strings    ${count}    0

Check_Topology_Is_Stable
    [Documentation]    Check that there are no changes in the topology since last call.
    ...    This keyword requires a call to Fail_If_Status_Is_Wrong as it passes
    ...    if the response status is not equal to 200.
    ${expected_count}=    Builtin.Set_Variable    ${current_count}
    ${actual_count}=    Get_Topology_Count_Core
    Builtin.Set_Suite_Variable    ${current_count}    ${actual_count}
    # See the same line in Check_Topology_Is_Empty for an explanation of this.
    Builtin.Evaluate    gc.collect()    modules=gc
    Builtin.Run_Keyword_If    ${response_code} == 200    Builtin.Should_Be_Equal    ${expected_count}    ${actual_count}

Wait_For_Topology_To_Become_Stable
    [Arguments]    ${timeout}    ${check_period}
    [Documentation]    Wait until no more changes are happening in the topology.
    Builtin.Sleep    ${check_period}
    ${actual}=    Builtin.Wait_Until_Keyword_Succeeds    ${timeout}    ${check_period}    Check_Topology_Is_Stable
    Fail_If_Status_Is_Wrong

Get_Topology_Count_Core
    [Documentation]    Get count of prefixes in the topology. Works only for IPv4 prefixes and uses rather unsophisticated
    ...    way of counting them (it actually counts the IPv4 addresses in the resulting JSON data). Expects the
    ...    name of the file where the topology data should be stored. Stores the response code into
    ...    ${response_code} and does not fail if it is not 200 (call Fail_If_Status_Is_Wrong if that is
    ...    not the desired behavior).
    ${response}=    RequestsLibrary.Get    ses    topology/example-ipv4-topology
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
    Check_Speaker_Is_Not_Connected

Check_Speaker_Is_Not_Connected
    [Documentation]    Give it a few tries to see zero established connections.
    BuiltIn.Wait_Until_Keyword_Succeeds    3s    1s    Check_Number_Of_Speaker_Connections    0

Check_Speaker_Is_Connected
    [Documentation]    Give it several tries to see exactly one established connection.
    BuiltIn.Wait_Until_Keyword_Succeeds    5s    1s    Check_Number_Of_Speaker_Connections    1

Check_Number_Of_Speaker_Connections
    [Arguments]    ${howmany}
    [Documentation]    Run netstat in mininet machine and parse it for number of established connections. Check it is ${howmany}.
    ${output}=    SSHLibrary.Execute_Command    netstat -npt 2> /dev/null | grep -E ":17900 .+ ESTABLISHED .+python" | wc -l
    BuiltIn.Should_Be_Equal_As_Strings    ${output}    ${howmany}

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
