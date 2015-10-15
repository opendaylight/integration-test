*** Settings ***
Documentation     BGP performance test using multiple python peers.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This is analogue of single peer performance suite, which uses 10 peers.
...               Each peer is of ibgp type, and they contribute to the same example-bgp-rib,
...               and thus to the same single example-ipv4-topology.
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
${HOLDTIME_PREFIX_COUNTER}    ${HOLDTIME}
${COUNT}          100000
${COUNT_PREFIX_COUNTER}    ${COUNT}
${FIRST_PEER_IP}    127.0.0.1
${MULTIPLICITY}    10
${MULTIPLICITY_PREFIX_COUNTER}    ${MULTIPLICITY}
${CHECK_PERIOD}    5
${CHECK_PERIOD_PREFIX_COUNTER}    ${CHECK_PERIOD}
${BGPCEP_LOG_LEVEL}    INFO
${current_count}    -1

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check example-ipv4-topology is up but empty.
    [Tags]    critical
    KarafKeywords.Log_Message_To_Controller_Karaf    Checking for empty topology
    BGPKeywords.Initial_Wait_For_Topology_To_Become_Empty
    BGPKeywords.Check_Topology_Count    0

Set Karaf Log Levels
    [Documentation]    Set Karaf log level
    ${current_SSH_connection}=    Get Current SSH Connection Index
    ${output}=    Issue Command On Karaf Console    log:set ${BGPCEP_LOG_LEVEL} org.opendaylight.bgpcep
    ${output}=    Issue Command On Karaf Console    log:set ${BGPCEP_LOG_LEVEL} org.opendaylight.protocol
    Restore Current SSH Connection    ${current_SSH_connection}

Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure 10 BGP peer modules with initiate-connection set to false.
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY}+1
    \    ${peer_name}=    BuiltIn.Set_Variable    example-bgp-peer-${index}
    \    ${peer_ip}=    BuiltIn.Evaluate    str(netaddr.IPAddress('${FIRST_PEER_IP}') + ${index} - 1)    modules=netaddr
    \    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': '${peer_name}', 'IP': '${peer_ip}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'HOLDTIME': '${HOLDTIME_PREFIX_COUNTER}', 'INITIATE': 'false'}
    \    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

Start_Talking_BGP_Manager
    [Documentation]    Start Python speaker to connect to ODL.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_Manager    --amount=${COUNT_PREFIX_COUNTER} --multiplicity=${MULTIPLICITY} --myip=${FIRST_PEER_IP} --myport=${BGP_TOOL_PORT} --peerip=${CONTROLLER} --peerport=${ODL_BGP_PORT}

Wait_For_Talking_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking the change counter.
    Wait_For_Topology_To_Become_Stable    ${timeout}    ${CHECK_PERIOD_PREFIX_COUNTER}

Check_Talking_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    BGPKeywords.Check_Topology_Count    ${COUNT_PREFIX_COUNTER}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speakers. Also, attempt to stop failing fast.
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

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    # TODO: Is it needed to extract peer naming logic to separate Keyword?
    : FOR    ${index}    IN RANGE    1    ${MULTIPLICITY}+1
    \    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer-${index}'}
    \    ConfigViaRestconf.Delete_Xml_Template_Folder_Config_Via_Restconf    ${directory_with_template_folders}${/}bgp_peer    ${template_as_string}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to ODL machine,
    ...    create HTTP session, put Python tool to ODL machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    SSHLibrary.Set_Default_Configuration    prompt=${CONTROLLER_PROMPT}
    SSHLibrary.Open_Connection    ${CONTROLLER}
    Utils.Flexible_Controller_Login
    RequestsLibrary.Create_Session    operational    http://${CONTROLLER}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/manage_play.py
    Require_Python
    Assure_Library_Ipaddr    target_dir=.
    # Calculate the timeout value based on how many routes are going to be pushed
    ${count}=    Builtin.Convert_To_Integer    ${COUNT_PREFIX_COUNTER}
    Builtin.Set_Suite_Variable    ${timeout}    ${count/25+60} s

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Require_Python
    [Documentation]    Verify current SSH connection leads to machine with python working. Fatal fail otherwise.
    # FIXME: These three Keywords come from throughpcep suite. Extract to Utils or separate library.
    ${passed} =    Execute_Command_Passes    python --help
    BuiltIn.Return_From_Keyword_If    ${passed}
    BuiltIn.Fatal_Error    Python is not installed!

Assure_Library_Ipaddr
    [Arguments]    ${target_dir}=/tmp
    [Documentation]    Tests whether ipaddr module is present on ssh-connected machine, Puts ipaddr.py to target_dir if not.
    ${passed} =    Execute_Command_Passes    bash -c 'cd "${target_dir}" && python -c "import ipaddr"'
    BuiltIn.Return_From_Keyword_If    ${passed}
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/ipaddr.py    ${target_dir}/

Execute_Command_Passes
    [Arguments]    ${command}
    [Documentation]    Execute command via SSH. If RC is nonzero, log everything. Retrun bool of command success.
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}
    [Return]    False

Wait_For_Topology_To_Become_Empty
    [Arguments]    ${timeout}=10s    ${refresh}=${CHECK_PERIOD_PREFIX_COUNTER}    ${stop_at_http_error}=True
    [Documentation]    Wait until topology becomes empty.
    Utils.Wait_For_Data_To_Satisfy_Keyword    ${timeout}    ${refresh}    Check_Topology_Is_Empty

Check_Topology_Is_Stable
    [Arguments]    ${actual_count}
    [Documentation]    Check that there are no changes in the topology since last call.
    ...    This keyword requires a call to Utils.Fail_If_Status_Is_Wrong as it passes
    ...    if the response status is not equal to 200.
    ${expected_count}=    Builtin.Set_Variable    ${current_count}
    Builtin.Set_Suite_Variable    ${current_count}    ${actual_count}
    Builtin.Should_Be_Equal    ${expected_count}    ${actual_count}

Wait_For_Topology_To_Become_Stable
    [Arguments]    ${timeout}    ${refresh}
    Utils.Wait_For_Data_To_Satisfy_Keyword    ${timeout}    ${refresh}    Get_Topology_Count    Check_Topology_Is_Stable
