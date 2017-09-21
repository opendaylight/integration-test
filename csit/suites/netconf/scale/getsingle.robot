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
...               - Configuring devices one by one.
...               - Sending requests for configuration data.
...               - Deconfiguring devices one by one.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_COUNT}    500
${TIMEOUT_FACTOR}    10
${device_type}    all-nodes
${device_name_prefix}    netconf-scaling-device-

*** Test Cases ***
Start_Test_Tool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    NetconfKeywords.Install_And_Start_Testtool    device-count=${DEVICE_COUNT}    mdsal=false

Configure_Devices_Onto_Netconf
    [Documentation]    Make requests to configure the testtool devices.
    [Tags]    critical
    KarafKeywords.Log_Message_To_Controller_Karaf    Connecting devices
    NetconfKeywords.Configure_Devices_In_Netconf    ${device_name_prefix}    device_type=${device_type}    device_port=${current_port}    iterations=500
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    Waiting_To_Configure_Devices    count=1    timeout=${timeout}

Get_Data_From_Devices
    [Documentation]    Ask testtool devices for data.
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    Check_Device_Data    count=1    timeout=${timeout}

Deconfigure_Devices_From_Netconf
    [Documentation]    Make requests to deconfigure the testtool devices.
    [Tags]    critical
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    Deconfigure_Devices    count=1    timeout=${timeout}
    [Teardown]    Report_Failure_Due_To_Bug    4547

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    RequestsLibrary.Create_Session    config    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${CONFIG_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    KarafKeywords.Configure_Timeout_For_Karaf_Console    120s
    ${device_type}=    BuiltIn.Set_Variable_If    ${USE_NETCONF_CONNECTOR}==${True}    default    ${device_type}
    BuiltIn.Set_Suite_Variable    ${device_type}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Waiting_To_Configure_Devices
    [Arguments]    ${current_name}
    [Documentation]    Operation waiting for configuring the devices in the Netconf subsystem and connecting to it.
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for devices to connect
    NetconfKeywords.Wait_Device_Connected    ${current_name}    period=1s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Check_Devices_Data
    [Arguments]    ${current_name}
    [Documentation]    Opration for getting the configuration data of the device and checking that it matches what is expected.
    KarafKeywords.Log_Message_To_Controller_Karaf    Getting data from device ${current_name}
    ${data}=    Utils.Get_Data_From_URI    config    network-topology:network-topology/topology/topology-netconf/yang-ext:mount    headers=${ACCEPT_XML}
    KarafKeywords.Log_Message_To_Controller_Karaf    Got data from device ${current_name}
    BuiltIn.Should_Be_Equal    ${data}    <data xmlns="${ODL_NETCONF_NAMESPACE}"></data>

Deconfigure_Devices
    [Arguments]    ${current_name}
    [Documentation]    Operation for deconfiguring the device from Netconf.
    KarafKeywords.Log_Message_To_Controller_Karaf    Removing device ${current_name}
    NetconfKeywords.Delete_Whole_Netconf_Topology    device_type=${device_type}
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to disappear
    NetconfKeywords.Wait_Device_Fully_Removed    ${current_name}    period=1s    timeout=120s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} removed
