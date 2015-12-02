*** Settings ***
Documentation     netconf-restperfclient CRUD test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform basic operations (Create, Read, Update and Delete or CRUD) on device
...               data mounted onto a netconf connector and see if they work.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DIRECTORY_WITH_TEMPLATE_FOLDERS}    ${CURDIR}/../../../variables/netconf/RestPerfClient
${device_name}    ${FIRST_TESTTOOL_PORT}-sim-device
${REQUEST_COUNT}    10000

*** Test Cases ***
Configure_Device_On_Netconf
    [Documentation]    Configure the testtool device on Netconf connector.
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}

Deploy_And_Run_RestPerfClient
    ${filename}=    NexusKeywords.Deploy_Artifact    netconf/netconf-testtool    netconf-testtool    rest-perf-client
    ${timeout}=    BuiltIn.Evaluate    ${REQUEST_COUNT}*2
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    ${options}=    BuiltIn.Set_Variable    --ip ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --edits ${REQUEST_COUNT}
    ${options}=    BuiltIn.Set_Variable    ${options} --destination /network-topology:network-topology/topology/topology-netconf/node/${device_name}/yang-ext:mount
    ${options}=    BuiltIn.Set_Variable    ${options} --edit-content ${CURDIR}/../../../variables/netconf/RestPerfClient/request1.xml
    ${command}    BuiltIn.Set_Variable    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} ${options}
    BuiltIn.Log    Running restperfclient: ${command}
    SSHLibrary.Write    ${command} >restperfclient.log 2>&1
    Wait_Until_Prompt
    ${result}=    SSHLibrary.Execute_Command    grep "FINISHED. Execution time:" restperfclient.log
    BuiltIn.Should_Not_Be_Equal    '${result}'    ''

Deconfigure_Device_From_Netconf
    [Documentation]    Deconfigure the testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${device_name}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the tools system (testtool)
    ${testtool}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool}
    Utils.Flexible_Mininet_Login
    # Deploy and start test tool.
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas
    # Connect to the tools system again (rest-perf-client)
    ${restperfclient}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    Utils.Flexible_Mininet_Login

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Switch_Connection    ${testtool}
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool

Wait_Until_Prompt
    ${status}    ${result}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    Return_From_Keyword_If    '${status}' == 'PASS'    ${result}
    Utils.Write_Bare_Ctrl_C
    ${result}=    SSHLibrary.Read_Until_Prompt
    [Return]    ${result}
