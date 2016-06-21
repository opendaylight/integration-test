*** Settings ***
Documentation     Basic tests for odl-bgpcep-bmp feature.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Set_It_Up
Suite Teardown    Tear_It_Down
Library           SSHLibrary
Library           RequestsLibrary
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${CONFIG_SESSION}    config-session
${BGP_BMP_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic
${BMP_LOG_FILE}    bmpmock.log

*** Test Cases ***
Start_Bmp_Mock
    [Documentation]    Starts bmp-mock on tools vm
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --local_address ${TOOLS_SYSTEM_IP} --remote_address ${ODL_SYSTEM_IP} --routers_count 1 --peers_count 1 2>&1 | tee ${BMP_LOG_FILE}
    Log    ${command}
    Write    ${command}
    Read_Until    successfully established.

Verify Data Reported
    [Documentation]    Verifies if the tool reported expected data
    &{mapping}    Create Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}    mapping=${mapping}    session=${CONFIG_SESSION}
    ...    verify=True

Stop_Bmp_Mock
    [Documentation]    Send ctrl+c to bmp-mock to stop it
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}

*** Keywords ***
Set_It_Up
    [Documentation]    Create SSH session to ToolsVm, prepare HTTP client session to Controller.
    ...    Figure out latest pcc-mock version and download it from Nexus to ToolsVm.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    RequestsLibrary.Create Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    bgp-bmp-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}

Tear_It_Down
    [Documentation]    Download pccmock.log and Log its contents.
    ...    Compute and Log the diff between expected and actual normalized responses.
    ...    Close both HTTP client session and SSH connection to Mininet.
    SSHLibrary.Get_File    ${BMP_LOG_FILE}
    ${cnt}=    OperatingSystem.Get File    ${BMP_LOG_FILE}
    Log    ${cnt}
    Delete_All_Sessions
    Close_All_Connections
