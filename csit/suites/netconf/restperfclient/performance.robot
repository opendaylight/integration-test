*** Settings ***
Documentation     netconf-restperfclient Update performance test suite.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
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
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           Collections
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/RestPerfClient.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_NAME}    ${FIRST_TESTTOOL_PORT}-sim-device
${REQUEST_COUNT}    65536
${directory_with_crud_templates}    ${CURDIR}/../../../variables/netconf/CRUD

*** Test Cases ***
Start_Testtool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    # Start test tool
    SSHLibrary.Switch_Connection    ${testtool}
    NetconfKeywords.Install_And_Start_Testtool    device-count=1    schemas=${CURDIR}/../../../variables/netconf/CRUD/schemas    mdsal=false    debug=false

Configure_Device_On_Netconf
    [Documentation]    Configure the testtool device on Netconf connector.
    NetconfKeywords.Configure_Device_In_Netconf    ${DEVICE_NAME}

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Connected    ${DEVICE_NAME}

Create_Device_Data
    [Documentation]    Send some sample test data into the device and check that the request went OK.
    ${template_as_string}=    BuiltIn.Set_Variable    {'DEVICE_NAME': '${DEVICE_NAME}'}
    TemplatedRequests.Post_As_Xml_Templated    ${directory_with_crud_templates}${/}cars    ${template_as_string}

Run_Restperfclient
    [Documentation]    Deploy and execute restperfclient, asking it to send the specified amount of requests to the netconf connector of the device.
    ${url}=    BuiltIn.Set_Variable    /restconf/config/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount/car:cars
    RestPerfClient.Invoke_Restperfclient    ${TESTTOOL_DEVICE_TIMEOUT}    ${url}    async=true

Check_For_Failed_Requests
    [Documentation]    Make sure there are no failed requests in the restperfclient log.
    ...    This is a separate test case to distinguish between restperfclient
    ...    failure and failed requests. Failed requests are rejected because
    ...    we don't want to test performance of ODL rejecting our requests.
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    thread timed out
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Request failed
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    RestPerfClient.Grep_Restperfclient_Log    Status code
    BuiltIn.Should_Be_Equal    '${result}'    ''

Cleanup_And_Collect
    [Documentation]    Deconfigure the testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    RestPerfClient.Collect_From_Restperfclient
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Calculate and set the value of the timeout
    ${value}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/50+10
    Utils.Set_User_Configurable_Variable_Default    TESTTOOL_DEVICE_TIMEOUT    ${value} s
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    RestPerfClient.Setup_Restperfclient
    # Connect to the tools system (testtool)
    ${testtool}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    RestPerfClient.Teardown_Restperfclient
    SSHLibrary.Switch_Connection    ${testtool}
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool
