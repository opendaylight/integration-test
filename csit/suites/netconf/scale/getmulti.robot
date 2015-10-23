*** Settings ***
Documentation     netconf-connector scaling test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           Collections
Library           String
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_COUNT}    500
${WORKER_COUNT}    10
${device_name_base}    netconf-scaling-device
${base_port}      17830
${memory_usage_leeway}    16    # in MB

*** Test Cases ***
Configure_Devices_On_Netconf
    [Documentation]    Make requests to configure the testtool devices and measure the time taken.
    NetconfKeywords.Perform_Operation_On_Each_Device    Configure_Device

Wait_For_Devices_To_Connect
    [Documentation]    Wait for the devices to become connected and measure the time taken.
    NetconfKeywords.Perform_Operation_On_Each_Device    Wait_Connected

Issue_Requests_On_Devices
    [Documentation]    Spawn the specified count of worker threads to issue a GET request to each of the devices.
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Write    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${DEVICE_COUNT} --name=${device_name_base}
    : FOR    ${number}    IN RANGE    1    ${DEVICE_COUNT}+1
    \    Read_Python_Tool_Operation_Result    ${number}
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Close_Connection
    Restore Current SSH Connection From Index    ${current_ssh_connection.index}

Deconfigure_Devices
    [Documentation]    Make requests to deconfigure the testtool devices and measure the time taken.
    NetconfKeywords.Perform_Operation_On_Each_Device    Deconfigure_Device
    [Teardown]    Report_Failure_Due_To_Bug    4547

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the tools machine
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    # Deploy testtool on it
    NetconfKeywords.Install_And_Start_Testtool    device-count=${DEVICE_COUNT}
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/netconf_tools/getter.py
    SSHLibrary.Put_File    ${CURDIR}/../../../libraries/AuthStandalone.py

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Configure_Device
    [Documentation]    Operation for configuring the device.
    KarafKeywords.Log_Message_To_Controller_Karaf    Configuring device ${current_name} to Netconf
    NetconfKeywords.Configure_Device_In_Netconf    ${current_name}    device_port=${current_port}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} configured

Wait_Connected
    [Documentation]    Operation for waiting until the device is connected.
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    NetconfKeywords.Wait_Device_Connected    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Read_Python_Tool_Operation_Result
    [Arguments]    ${number}
    [Documentation]    Read and process a report line emitted from the Python tool that corresponds to the device with the given number.
    ${test}=    SSHLibrary.Read_Until_Regexp    \\n
    ${test}=    String.Split_String    ${test}    |
    ${response}=    Collections.Get_From_List    ${test}    0
    ${message}=    Collections.Get_From_List    ${test}    1
    BuiltIn.Run_Keyword_If    '${response}' == 'ERROR'    Fail    Error getting data: ${message}
    ${ellapsed}=    Collections.Get_From_List    ${test}    1
    BuiltIn.Log    ${ellapsed}
    ${data}=    Collections.Get_From_List    ${test}    2
    ${expected}=    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"></data>'
    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}

Deconfigure_Device
    [Documentation]    Operation for deconfiguring the device.
    KarafKeywords.Log_Message_To_Controller_Karaf    Deconfiguring device ${current_name}
    NetconfKeywords.Remove_Device_From_Netconf    ${current_name}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} deconfigured
