*** Settings ***
Documentation       netconf-connector scaling test suite (multi-threaded GET requests).
...
...                 Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Performs scaling tests:
...                 - Send configurations of the devices one by one (via restconf).
...                 - Wait for the devices to become connected.
...                 - Send requests for configuration data using ${WORKER_COUNT} worker threads
...                 (using external Python tool).
...                 - Deconfigure the devices one by one.

Library             Collections
Library             String
Library             SSHLibrary    timeout=10s
Resource            ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource            ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/SSHKeywords.robot
Variables           ${CURDIR}/../../../variables/Variables.py

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${DEVICE_COUNT}         500
${WORKER_COUNT}         10
${TIMEOUT_FACTOR}       10
${device_name_base}     netconf-scaling-device
${device_type}          full-uri-device
${base_port}            17830


*** Test Cases ***
Start_Test_Tool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    IF    '${IS_KARAF_APPL}' == 'True'
        NetconfKeywords.Install_And_Start_Testtool    device-count=${DEVICE_COUNT}
    ELSE
        NetconfKeywords.Start_Testtool    ${NETCONF_FILENAME}    device-count=${DEVICE_COUNT}
    END

Configure_Devices_On_Netconf
    [Documentation]    Make requests to configure the testtool devices.
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Configure_Device    timeout=${timeout}

Wait_For_Devices_To_Connect
    [Documentation]    Wait for the devices to become connected.
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Wait_Connected    timeout=${timeout}

Issue_Requests_On_Devices
    [Documentation]    Spawn the specified count of worker threads to issue a GET request to each of the devices.
    # FIXME: this test case is a keyword and nearly duplicated in the max_devices.robot suite. need to move it to a common lib
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    SSHKeywords.Flexible_Mininet_Login
    SSHLibrary.Write
    ...    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${DEVICE_COUNT} --name=${device_name_base} --workers=${WORKER_COUNT}
    FOR    ${number}    IN RANGE    1    ${DEVICE_COUNT}+1
        Read_Python_Tool_Operation_Result    ${number}
    END
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Close_Connection
    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection.index}

Deconfigure_Devices
    [Documentation]    Make requests to deconfigure the testtool devices.
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Deconfigure_Device    timeout=${timeout}
    [Teardown]    Report_Failure_Due_To_Bug    4547

Check_Devices_Are_Deconfigured
    [Documentation]    Check there are no netconf connectors or other stuff related to the testtool devices.
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Check_Device_Deconfigured    timeout=${timeout}


*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${REST_API}    auth=${AUTH}
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Deploy testing tools.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/netconf_tools/getter.py
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/AuthStandalone.py
    ${device_type}=    BuiltIn.Set_Variable_If    ${USE_NETCONF_CONNECTOR}==${True}    default    ${device_type}
    BuiltIn.Set_Suite_Variable    ${device_type}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Read_Python_Tool_Operation_Result
    [Documentation]    Read and process a report line emitted from the Python tool that corresponds to the device with the given number.
    [Arguments]    ${number}
    ${test}=    SSHLibrary.Read_Until_Regexp    \\n
    ${test}=    String.Split_String    ${test}    |
    ${response}=    Collections.Get_From_List    ${test}    0
    ${response}=    String.Remove_String_Using_Regexp    ${response}    ^.*2004l\\r
    ${message}=    Collections.Get_From_List    ${test}    1
    IF    '${response}' == 'ERROR'    Fail    Error getting data: ${message}
    ${start}=    Collections.Get_From_List    ${test}    1
    ${stop}=    Collections.Get_From_List    ${test}    2
    ${ellapsed}=    Collections.Get_From_List    ${test}    3
    BuiltIn.Log    DATA REQUEST RESULT: Device=${number} StartTime=${start} StopTime=${stop} EllapsedTime=${ellapsed}
    ${data}=    Collections.Get_From_List    ${test}    4
    IF    '${IS_KARAF_APPL}' == 'True'
        ${expected}=    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"></data>'
    ELSE
        ${expected}=    Set Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"/>'
    END
    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
