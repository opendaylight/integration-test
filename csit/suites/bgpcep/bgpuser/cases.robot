*** Settings ***
Documentation     Basic tests for odl-bgpcep-bgp-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Brief description of what this suite should do:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:Lithium_Feature_Tests#How_to_test_2
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        FailFast.Fail_This_Fast_On_Previous_Error
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s    # The default prompt is now assigned in Setup_Everything KEYWORD to ${CONTROLLER_PROMPT} value.
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${MININET}
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot

*** Variables ***
${directory_for_actual_responses}    ${TEMPDIR}/actual
${directory_for_expected_responses}    ${TEMPDIR}/expected
${directory_with_template_folders}    ${CURDIR}/../../../variables/bgpuser/
${CONTROLLER_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}    180

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    010_Empty.json    timeout=120s
    # TODO: Verify that 120 seconds is not too short if this suite is run immediatelly after ODL is started.

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL, verify that the tool does not promptly exit.
    # Myport value is needed for checking whether connection at precise port was established.
    # TODO: Do we want to define ${BGP_PORT} in Variables.py?
    BGPSpeaker.Start_BGP_Speaker    --amount 2 --myip=${MININET} --myport=17900 --peerip=${CONTROLLER} --peerport=1790
    Read_And_Fail_If_Prompt_Is_Seen

Check_Talking_Connection_Is_Established
    [Documentation]    See TCP (BGP) connection in established state.
    # This case is separate from the previous one, to resemble structure of the second half of this suite more closely.
    Check_Speaker_Is_Connected

Check_Talking_Topology_Is_Filled
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    020_Filled.json

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Talking
    [Documentation]    See example-ipv4-topology empty again.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    030_Empty.json

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode, verify that the tool does not exit quickly.
    # TODO: ${BGP_TOOL_PORT} is probably not worth the trouble.
    BGPSpeaker.Start_BGP_Speaker    --amount 2 --listen --myip=${MININET} --myport=17900 --peerip=${CONTROLLER}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Listening_Connection_Is_Not_Established_Yet
    [Documentation]    See no TCP connection, as both ODL and tool are in listening mode.
    Check_Speaker_Is_Not_Connected

Check_For_Empty_Topology_Before_Listening
    [Documentation]    Sanity check example-ipv4-topology is still empty.
    [Tags]    critical
    Verify_That_Topology_Does_Not_Change_From    ${empty_json}    040_Empty.json

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    ${template_as_string}=    BuiltIn.Set_Variable    {'IP': '${MININET}', 'HOLDTIME': '${HOLDTIME}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Check_Listening_Connection_Is_Established
    [Documentation]    See TCP (BGP) connection in established state.
    Check_Speaker_Is_Connected

Check_Listening_Topology_Is_Filled
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    050_Filled.json

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Listening
    [Documentation]    Post-condition: Check example-ipv4-topology is empty again.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    060_Empty.json

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer
    # TODO: Do we need to check something else?

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, save prompt to variable, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SSHLibrary.Set_Default_Configuration    prompt=${CONTROLLER_PROMPT}
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_SSH_Login     ${MININET_USER}    ${MININET_PASSWORD}
#    ${current_connection}=    Get_Connection
#    ${current_prompt}=    BuiltIn.Set_Variable    ${current_connection.prompt}
#    BuiltIn.Log    ${current_prompt}
#    Builtin.Set_Suite_Variable    ${prompt}    ${current_prompt}
    RequestsLibrary.Create_Session    ses    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    OperatingSystem.Remove_Directory    ${directory_for_expected_responses}    recursive=True
    OperatingSystem.Remove_Directory    ${directory_for_actual_responses}    recursive=True
    # The previous suite may have been using the same directories.
    OperatingSystem.Create_Directory    ${directory_for_expected_responses}
    OperatingSystem.Create_Directory    ${directory_for_actual_responses}
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    ConfigViaRestconf.Setup_Config_Via_Restconf
    FailFast.Do_Not_Fail_Fast_From_Now_On

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    ${diff}=    OperatingSystem.Run    diff -dur ${directory_for_expected_responses} ${directory_for_actual_responses}
    BuiltIn.Log    ${diff}
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Wait_For_Topology_To_Change_To
    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Normalize the expected json topology and save it to ${directory_for_expected_responses}.
    ...    Wait until Compare_Topology matches. ${directory_for_actual_responses} will hold its last result.
    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${directory_for_expected_responses}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}

Verify_That_Topology_Does_Not_Change_From
    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Normalize the expected json topology and save it to ${directory_for_expected_responses}.
    ...    Verify that Compare_Topology keeps passing. ${directory_for_actual_responses} will hold its last result.
    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${directory_for_expected_responses}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}

Compare_Topology
    [Arguments]    ${expected_normalized}    ${filename}
    [Documentation]    Get current example-ipv4-topology as json, normalize it, save to ${directory_for_actual_responses}.
    ...    Check that status code is 200, check that normalized jsons match exactly.
    ${response}=    RequestsLibrary.Get    ses    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    ${actual_normalized}=    Normalize_And_Save_Expected_Json    ${response.text}    ${filename}    ${directory_for_actual_responses}
    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
    BuiltIn.Should_Be_Equal    ${actual_normalized}    ${expected_normalized}

Normalize_And_Save_Expected_Json
    [Arguments]    ${json_text}    ${filename}    ${directory}
    [Documentation]    Normalize given json using hsf_json library. Log and save the result to given filename under given directory.
    ${json_normalized}=    hsf_json.Hsf_Json    ${json_text}
    BuiltIn.Log    ${json_normalized}
    OperatingSystem.Create_File    ${directory}${/}${filename}    ${json_normalized}
    # TODO: Should we prepend .json to the filename? When we detect it is not already prepended?
    [Return]    ${json_normalized}

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

Read_And_Fail_If_Prompt_Is_Seen
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    ${passed}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Run_Keyword_And_Expect_Error    No match found for '${CONTROLLER_PROMPT}' in *.    Read_Text_Before_Prompt
    BuiltIn.Return_From_Keyword_If    ${passed}
    Dump_BGP_Speaker_Logs
    Fail    The prompt was seen but it was not expected yet

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}
