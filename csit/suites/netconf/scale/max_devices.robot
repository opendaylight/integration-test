*** Settings ***
Documentation     netconf-connector scaling test suite to find max connected devices
...
...               Copyright (c) 2019 Lumina Networks, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Increasing numbers of netconf devices will be connected and cleaned up
...               while validating and profiling between each iteration.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           Collections
Library           String
Library           SSHLibrary    timeout=60s
Resource          ../../../libraries/CheckJVMResource.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/NetconfKeywords.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${INIT_DEVICE_COUNT}    250
${MAX_DEVICE_COUNT}    100000
${DEVICE_INCREMENT}    5000
${DEVICE_NAME_BASE}    netconf-scaling-device
${DEVICE_TYPE}    full-uri-device
${BASE_PORT}      17830
${NUM_WORKERS}    10
${TIMEOUT_FACTOR}    3
${MIN_CONNECT_TIMEOUT}    300
${DEVICES_RESULT_FILE}    devices.csv
${INSTALL_TESTTOOL}     True
${TESTTOOL_EXECUTABLE}    ${EMPTY}

*** Test Cases ***
Find Max Netconf Devices
    [Documentation]    Find max number of switches starting from ${MIN_SWITCHES} till reaching ${MAX_SWITCHES} in steps of ${STEP_SWITCHES}
    ${error_message} =    BuiltIn.Set Variable    Failure initializing suite
    ${maximum_devices} =    BuiltIn.Set Variable    ${0}
    ${discover_time} =    BuiltIn.Set Variable    0
    ${start} =    BuiltIn.Convert to Integer    ${INIT_DEVICE_COUNT}
    ${stop} =    BuiltIn.Convert to Integer    ${MAX_DEVICE_COUNT}
    ${increment} =    BuiltIn.Convert to Integer    ${DEVICE_INCREMENT}
    ${INSTALL_TESTTOOL} =    Set Variable If    '${SKIP_KARAF}' == 'TRUE'     False     True
    ${TESTTOOL_EXECUTABLE} =    Set Variable If    '${SKIP_KARAF}' == 'TRUE'     ${NETCONF_FILENAME}      ${EMPTY}
    ${SCHEMAS} =    Set Variable If    '${SKIP_KARAF}' == 'TRUE'     ${CURDIR}/../../../variables/netconf/CRUD/schemas      ${schema_dir}
    FOR    ${devices}    IN RANGE    ${start}    ${stop+1}    ${increment}
        ${timeout} =    BuiltIn.Evaluate    ${devices}*${TIMEOUT_FACTOR}
        ${timeout} =    Set Variable If    ${timeout} > ${MIN_CONNECT_TIMEOUT}    ${timeout}    ${MIN_CONNECT_TIMEOUT}
        Log To Console    Starting Iteration with ${devices} devices
        Run Keyword If    "${INSTALL_TESTTOOL}"=="True"    NetconfKeywords.Install_And_Start_Testtool    debug=false    schemas=${schema_dir}    device-count=${devices}
        ...    ELSE    NetconfKeywords.Start_Testtool    ${TESTTOOL_EXECUTABLE}    debug=false    schemas=${SCHEMAS}    device-count=${devices}
        ${status}    ${result} =    Run Keyword And Ignore Error    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Configure_Device    timeout=${timeout}
        Exit For Loop If    '${status}' == 'FAIL'
        ${status}    ${result} =    Run Keyword And Ignore Error    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Wait_Connected    timeout=${timeout}    log_response=False
        Exit For Loop If    '${status}' == 'FAIL'
        ${status}    ${result} =    Run Keyword And Ignore Error    Issue_Requests_On_Devices    ${TOOLS_SYSTEM_IP}    ${devices}
        ...    ${NUM_WORKERS}
        Exit For Loop If    '${status}' == 'FAIL'
        ${status}    ${result} =    Run Keyword And Ignore Error    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Wait_Connected    timeout=${timeout}    log_response=False
        Exit For Loop If    '${status}' == 'FAIL'
        ${status}    ${result} =    Run Keyword And Ignore Error    NetconfKeywords.Perform_Operation_On_Each_Device    NetconfKeywords.Deconfigure_Device    timeout=${timeout}
        Exit For Loop If    '${status}' == 'FAIL'
        ${status}    ${result} =    Run Keyword And Ignore Error    NetconfKeywords.Perform_Operation_On_Each_Device    Check_Device_Deconfigured    timeout=${timeout}    log_response=False
        Exit For Loop If    '${status}' == 'FAIL'
        ${maximum_devices} =    Set Variable    ${devices}
        Run Keyword And Ignore Error    CheckJVMResource.Get JVM Memory
        NetconfKeywords.Stop_Testtool
    END
    [Teardown]    Run Keywords    NetconfKeywords.Stop_Testtool
    ...    AND    Collect_Data_Points    ${maximum_devices}
    ...    AND    Run Keyword And Ignore Error    CheckJVMResource.Get JVM Memory

*** Keywords ***
Collect_Data_Points
    [Arguments]    ${devices}
    [Documentation]    Parse and Log relevant information when Scale test finishes
    OperatingSystem.Append To File    ${DEVICES_RESULT_FILE}    Max Devices\n
    OperatingSystem.Append To File    ${DEVICES_RESULT_FILE}    ${devices}\n

Issue_Requests_On_Devices
    # FIXME: this keyword is nearly duplicated in the getmulti.robot suite. need to move it to a common lib
    [Arguments]    ${client_ip}    ${expected_count}    ${worker_count}
    [Documentation]    Spawn the specified count of worker threads to issue a GET request to each of the devices.
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Open_Connection    ${client_ip}
    SSHKeywords.Flexible_Mininet_Login
    SSHLibrary.Write    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${expected_count} --name=${device_name_base} --workers=${worker_count}
    SSHLibrary.Read_Until    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Write    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${expected_count} --name=${device_name_base} --workers=${worker_count}
    FOR    ${number}    IN RANGE    1    ${expected_count}+1
        Read_Python_Tool_Operation_Result    ${number}
    END
    SSHLibrary.Read_Until    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Close_Connection
    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection.index}

Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
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
    [Arguments]    ${number}
    [Documentation]    Read and process a report line emitted from the Python tool that corresponds to the device with the given number.
    ${test}=    SSHLibrary.Read_Until_Regexp    \\n
    ${test}=    String.Split_String    ${test}    |
    ${response}=    Collections.Get_From_List    ${test}    0
    ${message}=    Collections.Get_From_List    ${test}    1
    BuiltIn.Run_Keyword_If    '${response}' == 'ERROR'    Fail    Error getting data: ${message}
    ${start}=    Collections.Get_From_List    ${test}    1
    ${stop}=    Collections.Get_From_List    ${test}    2
    ${ellapsed}=    Collections.Get_From_List    ${test}    3
    BuiltIn.Log    DATA REQUEST RESULT: Device=${number} StartTime=${start} StopTime=${stop} EllapsedTime=${ellapsed}
    ${data}=    Collections.Get_From_List    ${test}    4
    ${expected}=    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"/>'
    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}

Check_Device_Deconfigured
    [Arguments]    ${current_name}    ${log_response}=True
    [Documentation]    Operation for making sure the device is really deconfigured.
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to disappear
    NetconfKeywords.Wait_Device_Fully_Removed    ${current_name}    period=0.5s    timeout=120s    log_response=${log_response}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} removed

Get Juniper Device Schemas
    OperatingSystem.Run    git clone https://github.com/Juniper/yang.git
    OperatingSystem.Run    mkdir /tmp/junos_19.4R1
    OperatingSystem.Run    find yang/19.4/19.4R1/junos -type f -name '*yang' -exec cp {} /tmp/junos_19.4R1/ \\;
    OperatingSystem.Run    cp yang/19.4/19.4R1/common/* /tmp/junos_19.4R1/
    OperatingSystem.List Directory    /tmp/junos_19.4R1/
    [Return]    /tmp/junos_19.4R1
