*** Settings ***
Documentation     BGP peer reset session tests
...
...               Copyright (c) 2017 AT&T Intellectual Property. All rights reserved.
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
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/KillPythonTool.robot
Resource          ../../../libraries/BGPcliKeywords.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${TOOLS_SYSTEM_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${CONFIG_SESSION}    session
${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
${BGP_TOOL_LOG_LEVEL}    info
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${OPERATIONAL_TOPO_URI}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/restconf/operational

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=false    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Talking_BGP_speaker
    [Documentation]    Start Python speaker to connect to ODL, verify that the tool does not promptly exit.
    # Myport value is needed for checking whether connection at precise port was established.
    BGPSpeaker.Start_BGP_Speaker    --amount 1 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_TOOL_LOG_LEVEL}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Check_Bgp_Peer_Configuration
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor ${TOOLS_SYSTEM_IP}
    Log    ${output}
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    Log    ${output}

Reset_Bgp_Peer_Session3
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    Run Keyword And Ignore Error    TemplatedRequests.Post_As_Xml_Templated    folder=${BGP_VARIABLES_FOLDER}${/}peer_session/restart    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    Create Dictionary    IP=${ODL_SYSTEM_IP}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    Run Keyword And Ignore Error    TemplatedRequests.Post_As_Xml_Templated    folder=${BGP_VARIABLES_FOLDER}${/}peer_session/restart    mapping=${mapping}    session=${CONFIG_SESSION}

Check_Bgp_Peer_Configuration2
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor ${TOOLS_SYSTEM_IP}
    Log    ${output}
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor ${ODL_SYSTEM_IP}
    Log    ${output}
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    Log    ${output}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    SSHKeywords.Flexible_Mininet_Login
    # Both TODOs would probably need to update every suite relying on current Variables.
    Run Keyword And Ignore Error    OperatingSystem.Remove_Directory    ${EXPECTED_RESPONSES_FOLDER}    recursive=True
    Run Keyword And Ignore Error    OperatingSystem.Remove_Directory    ${ACTUAL_RESPONSES_FOLDER}    recursive=True
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
    [Documentation]    Teardown everything
    ${diff}=    OperatingSystem.Run    diff -dur ${EXPECTED_RESPONSES_FOLDER} ${ACTUAL_RESPONSES_FOLDER}
    BuiltIn.Log    ${diff}
    Run Keyword And Ignore Error    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections
