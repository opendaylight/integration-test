*** Settings ***
Documentation       netconf-connector scaling test suite (single-threaded GET requests).
...
...                 Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Performs scaling tests:
...                 - Configuring devices one by one.
...                 - Sending requests for configuration data.
...                 - Deconfiguring devices one by one.

Library             RequestsLibrary
Library             SSHLibrary    timeout=10s
Resource            ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource            ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/Utils.robot
Variables           ${CURDIR}/../../../variables/Variables.py

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${DEVICE_COUNT}         500
${TIMEOUT_FACTOR}       10
${device_type}          full-uri-device


*** Test Cases ***
Start_Test_Tool
    [Documentation]    Deploy and start test tool, then wait for all its devices to become online.
    IF    '${IS_KARAF_APPL}' == 'True'
        NetconfKeywords.Install_And_Start_Testtool    device-count=${DEVICE_COUNT}
    ELSE
        NetconfKeywords.Start_Testtool    ${NETCONF_FILENAME}    device-count=${DEVICE_COUNT}
    END

Configure_Devices_Onto_Netconf
    [Documentation]    Make requests to configure the testtool devices.
    [Tags]    critical
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    Configure_Device_And_Verify    timeout=${timeout}

Get_Data_From_Devices
    [Documentation]    Ask testtool devices for data.
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    Check_Device_Data    timeout=${timeout}

Deconfigure_Devices_From_Netconf
    [Documentation]    Make requests to deconfigure the testtool devices.
    [Tags]    critical
    ${timeout}=    BuiltIn.Evaluate    ${DEVICE_COUNT}*${TIMEOUT_FACTOR}
    NetconfKeywords.Perform_Operation_On_Each_Device    Deconfigure_Device_And_Verify    timeout=${timeout}
    [Teardown]    Report_Failure_Due_To_Bug    4547


*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
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

Check_Device_Data
    [Documentation]    Opration for getting the configuration data of the device and checking that it matches what is expected.
    [Arguments]    ${current_name}    ${log_response}=True
    KarafKeywords.Log_Message_To_Controller_Karaf    Getting data from device ${current_name}
    # Use 'default' session created by Setup_Netconf_Keywords
    ${data}=    Utils.Get_Data_From_URI
    ...    default
    ...    ${REST_API}/network-topology:network-topology/topology=topology-netconf/node=${current_name}/yang-ext:mount?content=config
    ...    headers=${ACCEPT_XML}
    KarafKeywords.Log_Message_To_Controller_Karaf    Got data from device ${current_name}
    IF    '${IS_KARAF_APPL}' == 'True'
        ${expected}=    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"></data>'
    ELSE
        ${expected}=    Set Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"/>'
    END
    Should Be Equal As Strings    '${data}'    ${expected}
