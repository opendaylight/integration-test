*** Settings ***
Documentation     netconf-restperfclient Update performance test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Perform given count of update operations on device data mounted onto a
...               netconf connector (using the netconf-testtool-restperfclient tool) and
...               see how much time it took. More exactly, it sends the data to a restconf
...               mountpoint of the netconf connector belonging to the device, which turns
...               out to turn the first request sent to a "create" request and the
...               remaining requests to "update" requests (due to how the testtool device
...               behavior is implemented).
...
...               TODO: The "Wait_Until_Prompt" keyword shall probably be turned into a
...               reusable piece and moved into SSHKeywords. There is a bunch of other
...               test suites (e.g. PCEP, BGP) which contain the same or similar pieces of
...               code.
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
${REQUEST_COUNT}    65536

*** Test Cases ***
Create_Test_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    NetconfViaRestconf.Post_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}cars    {}

Deploy_And_Run_RestPerfClient
    [Documentation]    Deploy and execute restperfclient, asking it to send the specified amount of requests to the netconf connector of the device.
    SSHLibrary.Switch_Connection    ${restperfclient}
    SSHLibrary.Put_File    ${CURDIR}/../../../variables/netconf/RestPerfClient/request1.json
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool    rest-perf-client
    ${timeout}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/50+10
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    ${options}=    BuiltIn.Set_Variable    --ip ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --edits ${REQUEST_COUNT}
    ${options}=    BuiltIn.Set_Variable    ${options} --destination /restconf/config/car:cars
    ${options}=    BuiltIn.Set_Variable    ${options} --edit-content request1.json
    ${options}=    BuiltIn.Set_Variable    ${options} --auth ${ODL_RESTCONF_USER} ${ODL_RESTCONF_PASSWORD}
    ${command}    BuiltIn.Set_Variable    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} ${options}
    BuiltIn.Log    Running restperfclient: ${command}
    ${restperfclientlog}=    Utils.Get_Log_File_Name    restperfclient
    BuiltIn.Set_Suite_Variable    ${restperfclientlog}    ${restperfclientlog}
    Execute_Command_Passes    ${command} >${restperfclientlog} 2>&1
    SSHLibrary.Get_File    ${restperfclientlog}
    ${result}=    SSHLibrary.Execute_Command    grep "FINISHED. Execution time:" ${restperfclientlog}
    BuiltIn.Should_Not_Be_Equal    '${result}'    ''

Check_For_Failed_Requests
    [Documentation]    Make sure there are no failed requests in the restperfclient log.
    ...    This is a separate test case to distinguish between restperfclient
    ...    failure and failed requests. Failed requests are rejected because
    ...    we don't want to test performance of ODL rejecting our requests.
    ${result}=    SSHLibrary.Execute_Command    grep "Request failed" ${restperfclientlog}
    BuiltIn.Should_Be_Equal    '${result}'    ''

Delete_Test_Data
    [Documentation]    Deconfigure the testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfViaRestconf.Delete_Xml_Template_Folder_Via_Restconf    ${DIRECTORY_WITH_TEMPLATE_FOLDERS}${/}cars-delete    {}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the tools system (rest-perf-client)
    ${restperfclient}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${restperfclient}    ${restperfclient}
    # Initialize artifact deployment infrastructure.
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    ${testtool}=    SSHLibrary.Get Connection
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool.index}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Switch_Connection    ${testtool}
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool
