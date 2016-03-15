*** Settings ***
Documentation     Basic tests for odl-bgpcep-bgp-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               TODO: Rename this file after Beryllium is out, for example to basic.robot
...
...               Test suite performs basic BGP functional test cases:
...               BGP peer initiated coonection
...               - introduce and check 3 prefixes in one update message
...               ODL controller initiated coonection:
...               - introduce and check 3 prefixes in one update message
...               - introduce 2 prefixes in first update message and then additional 2 prefixes
...               in another update while the very first prefix is withdrawn
...               - introduce 3 prefixes and try to withdraw the first one
...               (to be ignored by controller) in a single update message
...
...               Brief description how to perform BGP functional test:
...               https://wiki.opendaylight.org/view/BGP_LS_PCEP:Lithium_Feature_Tests#How_to_test_2
...
...               Reported bugs:
...               https://bugs.opendaylight.org/show_bug.cgi?id=4409
...               https://bugs.opendaylight.org/show_bug.cgi?id=4634
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       180
${BGP_TOOL_LOG_LEVEL}    info
${CONTROLLER_LOG_LEVEL}    INFO
${CONTROLLER_BGP_LOG_LEVEL}    DEFAULT

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    010_Empty.json    timeout=120s
    # TODO: Verify that 120 seconds is not too short if this suite is run immediatelly after ODL is started.

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL, verify that the tool does not promptly exit.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_Speaker    --amount 3 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_TOOL_LOG_LEVEL}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Talking_Connection_Is_Established
    [Documentation]    See TCP (BGP) connection in established state.
    # This case is separate from the previous one, to resemble structure of the second half of this suite more closely.
    Check_Speaker_Is_Connected
    [Teardown]    Utils.Report_Failure_Due_To_Bug    5171

Check_Talking_Topology_Is_Filled
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    020_Filled.json

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
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
    BGPSpeaker.Start_BGP_Speaker    --amount 3 --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --${BGP_TOOL_LOG_LEVEL}
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
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Check_Listening_Connection_Is_Established
    [Documentation]    See TCP (BGP) connection in established state.
    Check_Speaker_Is_Connected

Check_Listening_Topology_Is_Filled
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    050_Filled.json

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Listening
    [Documentation]    Post-condition: Check example-ipv4-topology is empty again.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    060_Empty.json

Start_Listening_BGP_Speaker_Case_2
    [Documentation]    BGP Speaker introduces 2 prefixes in the first update & another 2 prefixes while the very first is withdrawn in 2nd update
    BGPSpeaker.Start_BGP_Speaker    --amount 3 --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --prefill=2 --insert=2 --withdraw=1 --updates=single --firstprefix=8.0.0.240 --${BGP_TOOL_LOG_LEVEL}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Listening_Connection_Is_Established_Case_2
    [Documentation]    See TCP (BGP) connection in established state.
    Check_Speaker_Is_Connected

Check_Listening_Topology_Is_Filled_Case_2
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    050_Filled.json
    [Teardown]    Report_Failure_Due_To_Bug    4409

Kill_Listening_BGP_Speaker_Case_2
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Listening_Case_2
    [Documentation]    Post-condition: Check example-ipv4-topology is empty again.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    060_Empty.json

Start_Listening_BGP_Speaker_Case_3
    [Documentation]    BGP Speaker introduces 3 prefixes while the first one occures again in the withdrawn list (to be ignored bu controller)
    BGPSpeaker.Start_BGP_Speaker    --amount 2 --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --prefill=0 --insert=3 --withdraw=1 --updates=single --${BGP_TOOL_LOG_LEVEL}
    Read_And_Fail_If_Prompt_Is_Seen

Check_Listening_Connection_Is_Established_Case_3
    [Documentation]    See TCP (BGP) connection in established state.
    Check_Speaker_Is_Connected

Check_Listening_Topology_Is_Filled_Case_3
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${filled_json}    050_Filled.json
    [Teardown]    Report_Failure_Due_To_Bug    4634

Kill_Listening_BGP_Speaker_Case_3
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Check_For_Empty_Topology_After_Listening_Case_3
    [Documentation]    Post-condition: Check example-ipv4-topology is empty again.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    060_Empty.json

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer'}
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}
    # TODO: Do we need to check something else?

*** Keywords ***
Setup_Everything
    [Documentation]    SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    OperatingSystem.Remove_Directory    ${EXPECTED_RESPONSES_FOLDER}    recursive=True
    OperatingSystem.Remove_Directory    ${ACTUAL_RESPONSES_FOLDER}    recursive=True
    # The previous suite may have been using the same directories.
    OperatingSystem.Create_Directory    ${EXPECTED_RESPONSES_FOLDER}
    OperatingSystem.Create_Directory    ${ACTUAL_RESPONSES_FOLDER}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    ConfigViaRestconf.Setup_Config_Via_Restconf
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_BGP_LOG_LEVEL} org.opendaylight.protocol

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    ${diff}=    OperatingSystem.Run    diff -dur ${EXPECTED_RESPONSES_FOLDER} ${ACTUAL_RESPONSES_FOLDER}
    BuiltIn.Log    ${diff}
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Wait_For_Topology_To_Change_To
    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Normalize the expected json topology and save it to ${EXPECTED_RESPONSES_FOLDER}.
    ...    Wait until Compare_Topology matches. ${ACTUAL_RESPONSES_FOLDER} will hold its last result.
    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${EXPECTED_RESPONSES_FOLDER}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}

Verify_That_Topology_Does_Not_Change_From
    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    [Documentation]    Normalize the expected json topology and save it to ${EXPECTED_RESPONSES_FOLDER}.
    ...    Verify that Compare_Topology keeps passing. ${ACTUAL_RESPONSES_FOLDER} will hold its last result.
    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${EXPECTED_RESPONSES_FOLDER}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}

Compare_Topology
    [Arguments]    ${expected_normalized}    ${filename}
    [Documentation]    Get current example-ipv4-topology as json, normalize it, save to ${ACTUAL_RESPONSES_FOLDER}.
    ...    Check that status code is 200, check that normalized jsons match exactly.
    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    BuiltIn.Log    ${response.status_code}
    BuiltIn.Log    ${response.text}
    ${actual_normalized}=    Normalize_And_Save_Expected_Json    ${response.text}    ${filename}    ${ACTUAL_RESPONSES_FOLDER}
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
    ${output}=    SSHKeywords.Count_Port_Occurences    17900    ESTABLISHED    python
    BuiltIn.Should_Be_Equal_As_Strings    ${output}    ${howmany}
