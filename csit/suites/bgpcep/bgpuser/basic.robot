*** Settings ***
Documentation     Basic tests for odl-bgpcep-bgp-all feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic BGP functional test cases:
...               BGP peer initiated connection
...               - introduce and check 3 prefixes in one update message
...               ODL controller initiated connection:
...               - introduce and check 3 prefixes in one update message
...               - introduce 2 prefixes in first update message and then additional 2 prefixes
...               in another update while the very first prefix is withdrawn
...               - introduce 3 prefixes and try to withdraw the first one
...               (to be ignored by controller) in a single update message
...
...               For versions Oxygen and further, there are TC_R (test case reset) which
...               test session-reset functionality.
...               Resets the session, and than verifies that example-ipv4-topology is empty again.
...
...               For versions Fluorine and further, there are test cases:
...               TC_PG (test case peer group) which
...               tests configuration and reconfiguration of peer-groups and neighbors configured by them.
...               - configure peer-group, and assign neighbor to this peer-group
...               - check filled topology
...               - reconfigure peer-group without ipv4 unicast afi-safi
...               - check empty topology
...               - reconfigre neighbor without peer-group, delete peer-group
...
...               TC_LA (test case local address)
...               test configuration of internal peer with local-address configured
...               - configure peer with local-address and connect bgp-speaker to it
...               with tools_system_ip
...               - check filled topology
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
Library           ../../../libraries/norm_json.py
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/KillPythonTool.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/CompareStream.robot
Variables         ../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}    ${ODL_STREAM}

*** Variables ***
${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
${BGP_PEER_NAME}    example-bgp-peer
${BGP_TOOL_LOG_LEVEL}    info
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${CONFIG_SESSION}    session
${DEVICE_NAME}    controller-config
${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
${HOLDTIME}       180
${ODL_BGP_LOG_LEVEL}    DEFAULT
${ODL_LOG_LEVEL}    INFO
${PEER_GROUP}     internal-neighbors
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${RIB_INSTANCE}    example-bgp-rib
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    Wait_For_Topology_To_Change_To    ${empty_json}    010_Empty.json    timeout=180s

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

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

TC_R_Reset_Bgp_Peer_Session
    [Documentation]    Reset Peer Session
    [Tags]    Critical
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    CompareStream.Run_Keyword_If_At_Least_Oxygen    TemplatedRequests.Post_As_Xml_Templated    folder=${BGP_VARIABLES_FOLDER}${/}peer_session/restart    mapping=${mapping}    session=${CONFIG_SESSION}

TC_R_Check_For_Empty_Topology_After_Resetting
    [Documentation]    See example-ipv4-topology empty after resetting session
    [Tags]    critical
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Wait_For_Topology_To_Change_To    ${empty_json}    030_Empty.json

TC_PG_Reconfigure_ODL_With_Peer_Group_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Configure_Peer_Group
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_GROUP_NAME=${PEER_GROUP}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer_group    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

TC_PG_Restart_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Restart_Talking_BGP_Speaker
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

TC_PG_Check_Talking_Topology_Is_Filled
    [Documentation]    See new routes in example-ipv4-topology as a proof that synchronization was correct.
    [Tags]    critical
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Wait_For_Topology_To_Change_To    ${filled_json}    021_Filled.json

TC_PG_Reconfigure_ODL_With_Peer_Group_Without_Ipv4_Unicast
    [Documentation]    Configure BGP peer module with initiate-connection set to false. (Fluorine only)
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Configure_Peer_Group    peer_group_folder=peer_group_without_ipv4
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

TC_PG_Check_For_Empty_Topology_After_Deconfiguration
    [Documentation]    See example-ipv4-topology empty after resetting session (Fluorine only)
    [Tags]    critical
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Wait_For_Topology_To_Change_To    ${empty_json}    031_Empty.json

TC_PG_Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false. (Fluorine only)
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_GROUP_NAME=${PEER_GROUP}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer_group    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    Deconfigure_Peer_Group
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

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
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=true    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=false    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

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
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

TC_LA_Reconfigure_Odl_To_Accept_Connection
    [Documentation]    Configure ibgp peer with local-address.
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid only for versions fluorine and above.
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=false    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    LOCAL=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_local_address    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

TC_LA_Start_Bgp_Speaker_And_Verify_Connected
    [Documentation]    Verify that peer is present in odl's rib under local-address ip.
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid only for versions fluorine and above.
    ${speaker_args}    BuiltIn.Set_Variable    --amount 1 --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --${BGP_TOOL_LOG_LEVEL}
    ${output}    BGPSpeaker.Start_BGP_Speaker_And_Verify_Connected    ${speaker_args}    ${CONFIG_SESSION}
    BuiltIn.Log    ${output}

TC_LA_Kill_Bgp_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid only for versions fluorine and above.
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

TC_LA_Delete_Bgp_Peer_Configuration
    [Documentation]    Delete peer configuration.
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid only for versions fluorine and above.
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_local_address    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. SSH-login to mininet machine, create HTTP session,
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
    SSHKeywords.Flexible_Mininet_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.protocol

Teardown_Everything
    [Documentation]    Create and Log the diff between expected and actual responses, make sure Python tool was killed.
    ...    Tear down imported Resources.
    ${diff}=    OperatingSystem.Run    diff -dur ${EXPECTED_RESPONSES_FOLDER} ${ACTUAL_RESPONSES_FOLDER}
    BuiltIn.Log    ${diff}
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
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
    [Documentation]    Normalize given json using norm_json library. Log and save the result to given filename under given directory.
    ${json_normalized}=    norm_json.normalize_json_text    ${json_text}
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

Configure_Peer_Group
    [Arguments]    ${peer_group_folder}=peer_group
    [Documentation]    Configures peer group which is template for all the neighbors which are going
    ...    to be configured. Also after PUT, this case verifies presence of peer group within
    ...    peer-groups. This case is specific to versions Fluorine and above.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    PEER_GROUP_NAME=${PEER_GROUP}    RR_CLIENT=false
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}${peer_group_folder}    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Get_As_Json_Templated    ${BGP_VARIABLES_FOLDER}${/}verify_${peer_group_folder}    mapping=${mapping}    session=${CONFIG_SESSION}    verify=True

Deconfigure_Peer_Group
    [Documentation]    Deconfigures peer group which is template for all the neighbors
    ...    This test case is specific to versions Fluorine and above.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    PEER_GROUP_NAME=${PEER_GROUP}    RR_CLIENT=false
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}peer_group    mapping=${mapping}    session=${CONFIG_SESSION}

Restart_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast. And Start it again.
    ...    We have to restart it this way because we reset session before
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    BGPSpeaker.Start_BGP_Speaker    --amount 3 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_TOOL_LOG_LEVEL}
    Read_And_Fail_If_Prompt_Is_Seen
