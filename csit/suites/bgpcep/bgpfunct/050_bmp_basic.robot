*** Settings ***
Documentation     Basic tests for odl-bgpcep-bmp feature
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This is a basic suite for bgp monitoring protocol feature.
...               After the feature odl-bgpcep-bmp installation the port 12345 should be
...               bound for listening,
...               To test this feature bgp-bmp-mock tool is used. It is a part of the
...               bgpcep project. It is a java tool which simulates more peers and more
...               routers.
...               In this particular test suite it simulates 1 peer with 1 router, which
...               means it advertizes one peer ipv4 address towards odl. As a result one
...               route should appear in the restconf/operational/bmp-monitor:bmp-monitor.
Suite Setup       Set_It_Up
Suite Teardown    Tear_It_Down
Library           SSHLibrary
Library           RequestsLibrary
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/RemoteBash.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${CONFIG_SESSION}    config-session
${BGP_BMP_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/filled_structure
${BGP_BMP_FEAT_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/empty_structure
${BMP_LOG_FILE}    bmpmock.log

*** Test Cases ***
Verify BMP Feature
    [Documentation]    Verifies if feature is up
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    180s    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_FEAT_DIR}    mapping=${mapping}    session=${CONFIG_SESSION}
    ...    verify=True

Start_Bmp_Mock
    [Documentation]    Starts bmp-mock on tools vm
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --local_address ${TOOLS_SYSTEM_IP} --remote_address ${ODL_SYSTEM_IP}:12345 --routers_count 1 --peers_count 1 --log_level DEBUG 2>&1 | tee ${BMP_LOG_FILE}
    BuiltIn.Log    ${command}
    SSHLibrary.Set_Client_Configuration    timeout=30s
    SSHLibrary.Write    ${command}
    ${until_phrase}=    Set Variable    successfully established.
    SSHLibrary.Read_Until    ${until_phrase}

Verify Data Reported
    [Documentation]    Verifies if the tool reported expected data
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}    mapping=${mapping}    session=${CONFIG_SESSION}
    ...    verify=True

Stop_Bmp_Mock
    [Documentation]    Send ctrl+c to bmp-mock to stop it
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to ToolsVm, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to ToolsVm.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    bgp-bmp-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}

Tear_It_Down
    [Documentation]    Download bmpmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    SSHLibrary.Get_File    ${BMP_LOG_FILE}
    ${cnt}=    OperatingSystem.Get_File    ${BMP_LOG_FILE}
    Log    ${cnt}
    Delete_All_Sessions
    Close_All_Connections
