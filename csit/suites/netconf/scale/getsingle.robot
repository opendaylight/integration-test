*** Settings ***
Documentation     netconf-connector scaling test suite (single-threaded GET requests).
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Performs scaling tests:
...               - Configuring devices one by one and measuring the time taken.
...               - Sending requests for configuration data and measuring the time taken.
...               - Deconfiguring devices one by one and measuring the time taken.
...
...               Additionally, it checks that the memory usage did not increase too much
...               after all these scaling tests were run.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/MemoryWatch.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_COUNT}    500
${memory_usage_leeway}    16    # in MB

*** Test Cases ***
Wait_For_Heap_Size_To_Stabilize
    [Documentation]    Wait for the heap size to become stable.
    MemoryWatch.Wait_Heap_Size_Stable

Configure_Devices_Onto_Netconf
    [Documentation]    Make requests to configure the testtool devices and measure the time taken.
    [Tags]    critical
    NetconfKeywords.Perform_Operation_On_Each_Device    Configure_Device

Get_Data_From_Devices
    [Documentation]    Ask testtool devices for data and measure the time taken.
    NetconfKeywords.Perform_Operation_On_Each_Device    Check_Device_Data

Deconfigure_Devices_From_Netconf
    [Documentation]    Make requests to deconfigure the testtool devices and measure the time taken.
    [Tags]    critical
    NetconfKeywords.Perform_Operation_On_Each_Device    Deconfigure_Device

Check_Memory_Usage_Netconf
    [Documentation]    Check whether all the memory used by the devices is gone along with the devices themselves.
    ${memory}=    MemoryWatch.Get_ODL_Heap_Size
    ${limit}=    BuiltIn.Evaluate    ${odl_base_memory}+${memory_usage_leeway}*1048576
    BuiltIn.Should_Be_True    ${memory} <= ${limit}
    [Teardown]    Report_Failure_Due_To_Bug    4514

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    RequestsLibrary.Create_Session    config    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${CONFIG_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    MemoryWatch.Initialize
    # Connect to the tools machine
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    # Deploy testtool on it
    NetconfKeywords.Install_And_Start_Testtool    device-count=${DEVICE_COUNT}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Configure_Device
    [Documentation]    Operation for configuring the device in the Netconf subsystem and connecting to it.
    KarafKeywords.Log_Message_To_Controller_Karaf    Connecting device ${current_name}
    NetconfKeywords.Configure_Device_In_Netconf    ${current_name}    device_port=${current_port}
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    NetconfKeywords.Wait_Device_Connected    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Check_Device_Data
    [Documentation]    Opration for getting the configuration data of the device and checking that it matches what is expected.
    KarafKeywords.Log_Message_To_Controller_Karaf    Getting data from device ${current_name}
    ${data}=    Utils.Get_Data_From_URI    config    network-topology:network-topology/topology/topology-netconf/node/${current_name}/yang-ext:mount    headers=${ACCEPT_XML}
    KarafKeywords.Log_Message_To_Controller_Karaf    Got data from device ${current_name}
    BuiltIn.Should_Be_Equal    ${data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>

Deconfigure_Device
    [Documentation]    Operation for deconfiguring the device from Netconf.
    KarafKeywords.Log_Message_To_Controller_Karaf    Removing device ${current_name}
    NetconfKeywords.Remove_Device_From_Netconf    ${current_name}
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to disappear
    NetconfKeywords.Wait_Device_Fully_Removed    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} removed
