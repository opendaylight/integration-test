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
...               TODO: Currently, if there are always zero data changes, test cases will wait for max time. Reconsider.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
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
${HOLDTIME_CHANGE_COUNTER}    ${HOLDTIME}
${COUNT}          100000
${COUNT_CHANGE_COUNTER}    ${COUNT}
${CHECK_PERIOD}    1
${CHECK_PERIOD_CHANGE_COUNTER}    ${CHECK_PERIOD}
${REPETITIONS_CHANGE_COUNTER}    5
${last_change_count}    -1

*** Test Cases ***
Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    120s    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string} =    BuiltIn.Set_Variable    {'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_CHANGE_COUNTER}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Wait_For_Data_Change_Counter_Ready
    [Documentation]    Data change counter might have been slower to start than ipv4 topology, wait for it.
    BuiltIn.Wait_Until_Keyword_Succeeds    60s    1s    ChangeCounter.Get_Change_Count

Reconfigure_Data_Change_Counter
    [Documentation]    Configure data change counter to count transactions affecting
    ...    example-ipv4-topology instead of example-linkstate-topology.

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL.
    Store_Change_Count
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_CHANGE_COUNTER} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER} --peerport=${ODL_BGP_PORT}

Wait_For_Stable_Talking_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking the change counter.
    ChangeCounter.Wait_For_Change_Count_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_CHANGE_COUNTER}    repetitions=${REPETITIONS_CHANGE_COUNTER}    count_to_overcome=${last_change_count}

Check_Talking_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_CHANGE_COUNTER}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Store_Change_Count
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing fast, if both previous and this test have failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Wait_For_Stable_Ipv4_Topology_After_Talking
    [Documentation]    See example-ipv4-topology stable again.
    [Tags]    critical
    ChangeCounter.Wait_For_Change_Count_To_Become_Stable    timeout=${bgp_emptying_timeout}    period=${CHECK_PERIOD_CHANGE_COUNTER}    repetitions=${REPETITIONS_CHANGE_COUNTER}    count_to_overcome=${last_change_count}

Check_For_Empty_Ipv4_Topology_After_Talking
    [Documentation]    Example-ipv4-topology should be empty now.
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Start_Listening_BGP_Speaker
    [Documentation]    Start Python speaker in listening mode.
    BGPSpeaker.Start_BGP_speaker    --amount ${COUNT_CHANGE_COUNTER} --listen --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER}

Reconfigure_ODL_To_Initiate_Connection
    [Documentation]    Replace BGP peer config module, now with initiate-connection set to true.
    Store_Change_Count
    ${template_as_string} =    BuiltIn.Set_Variable    {'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME_CHANGE_COUNTER}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'true'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    ${template_as_string}

Wait_For_Listening_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable.
    ChangeCounter.Wait_For_Change_Count_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_CHANGE_COUNTER}    repetitions=${REPETITIONS_CHANGE_COUNTER}    count_to_overcome=${last_change_count}

Check_Listening_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_CHANGE_COUNTER}

Kill_Listening_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Store_Change_Count
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On
    # NOTE: It is still possible to remain failing, if both previous and this test failed.
    [Teardown]    FailFast.Do_Not_Start_Failing_If_This_Failed

Wait_For_Stable_Ipv4_Topology_After_Listening
    [Documentation]    See example-ipv4-topology stable again.
    [Tags]    critical
    ChangeCounter.Wait_For_Change_Count_To_Become_Stable    timeout=${bgp_emptying_timeout}    period=${CHECK_PERIOD_CHANGE_COUNTER}    repetitions=${REPETITIONS_CHANGE_COUNTER}    count_to_overcome=${last_change_count}

Check_For_Empty_Ipv4_Topology_After_Listening
    [Documentation]    Example-ipv4-topology should be empty now.
    PrefixCounting.Check_Ipv4_Topology_Is_Empty

Restore_Data_Change_Counter_Configuration
    [Documentation]    Configure data change counter back to count transactions affecting
    ...    example-linkstate-topology.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ChangeCounter.Reconfigure_Topology_Name    example-linkstate-topology

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    ChangeCounter.CC_Setup
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
    ${count} =    Builtin.Convert_To_Integer    ${COUNT_CHANGE_COUNTER}
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${count/25+60} s
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${count/50+5} s

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Store_Change_Count
    [Documentation]    Get the count of changes from BGP change counter. Ignore error or store the value.
    ${status}    ${count} =    BuiltIn.Run_Keyword_And_Ignore_Error    ChangeCounter.Get_Change_Count
    BuiltIn.Run_Keyword_If    '${status}' == 'PASS'    BuiltIn.Set_Suite_Variable    ${last_change_count}    ${count}
