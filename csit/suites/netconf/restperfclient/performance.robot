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
Resource          ${CURDIR}/../../../libraries/NetconfViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
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
    NetconfViaRestconf.Post_Xml_Template_Folder_Via_Restconf    ${directory_with_crud_templates}${/}cars    ${template_as_string}

Deploy_And_Run_RestPerfClient
    [Documentation]    Deploy and execute restperfclient, asking it to send the specified amount of requests to the netconf connector of the device.
    [Timeout]    ${TESTTOOL_DEVICE_TIMEOUT_FOR_TESTCASE}
    SSHLibrary.Switch_Connection    ${restperfclient}
    SSHLibrary.Put_File    ${CURDIR}/../../../variables/netconf/RestPerfClient/request1.json
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool    rest-perf-client
    ${timeout}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/100+10
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    ${options}=    BuiltIn.Set_Variable    --ip ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --edits ${REQUEST_COUNT}
    ${options}=    BuiltIn.Set_Variable    ${options} --destination /restconf/config/network-topology:network-topology/topology/topology-netconf/node/${DEVICE_NAME}/yang-ext:mount/car:cars
    ${options}=    BuiltIn.Set_Variable    ${options} --edit-content request1.json
    ${options}=    BuiltIn.Set_Variable    ${options} --auth ${ODL_RESTCONF_USER} ${ODL_RESTCONF_PASSWORD}
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -Xmx1G -XX:MaxPermSize=256M -jar ${filename} ${options}
    BuiltIn.Log    Running restperfclient: ${command}
    ${restperfclientlog}=    Utils.Get_Log_File_Name    restperfclient
    BuiltIn.Set_Suite_Variable    ${restperfclientlog}    ${restperfclientlog}
    SSHKeywords.Execute_Command_Passes    ${command} >${restperfclientlog} 2>&1
    SSHLibrary.Get_File    ${restperfclientlog}
    ${result}=    SSHLibrary.Execute_Command    grep "FINISHED. Execution time:" ${restperfclientlog}
    BuiltIn.Should_Not_Be_Equal    '${result}'    ''

Check_For_Failed_Requests
    [Documentation]    Make sure there are no failed requests in the restperfclient log.
    ...    This is a separate test case to distinguish between restperfclient
    ...    failure and failed requests. Failed requests are rejected because
    ...    we don't want to test performance of ODL rejecting our requests.
    ${result}=    SSHLibrary.Execute_Command    grep "thread timed out" ${restperfclientlog}
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    SSHLibrary.Execute_Command    grep "Request failed" ${restperfclientlog}
    BuiltIn.Should_Be_Equal    '${result}'    ''
    ${result}=    SSHLibrary.Execute_Command    grep "Status code" ${restperfclientlog}
    BuiltIn.Should_Be_Equal    '${result}'    ''

Deconfigure_Device_From_Netconf
    [Documentation]    Deconfigure the testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${DEVICE_NAME}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Calculate and set the value of the timeout
    ${value}=    BuiltIn.Evaluate    ${REQUEST_COUNT}/50+10
    Utils.Set_User_Configurable_Variable_Default    TESTTOOL_DEVICE_TIMEOUT    ${value} s
    ${value}=    DateTime.Add_Time_To_Time    ${TESTTOOL_DEVICE_TIMEOUT}    60s    result_format=compact
    Utils.Set_User_Configurable_Variable_Default    TESTTOOL_DEVICE_TIMEOUT_FOR_TESTCASE    ${value}
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the tools system (rest-perf-client)
    ${restperfclient}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${restperfclient}    ${restperfclient}
    ${testtool}=    SSHLibrary.Get Connection
    BuiltIn.Set_Suite_Variable    ${testtool}    ${testtool.index}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Switch_Connection    ${testtool}
    BuiltIn.Run_Keyword_And_Ignore_Error    NetconfKeywords.Stop_Testtool
