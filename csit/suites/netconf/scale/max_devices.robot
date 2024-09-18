*** Settings ***
Documentation       netconf-connector scaling test suite to find max connected devices
...
...                 Copyright (c) 2019 Lumina Networks, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Increasing numbers of netconf devices will be connected and cleaned up
...                 while validating and profiling between each iteration.

Library             Collections
Library             String
Library             SSHLibrary    timeout=1000s
Library             ../../../libraries/TopologyNetconfNodes.py
Resource            ../../../libraries/KarafKeywords.robot
Resource            ../../../libraries/NetconfKeywords.robot
Resource            ../../../libraries/SetupUtils.robot
Resource            ../../../libraries/SSHKeywords.robot
Resource            ../../../variables/Variables.robot

Suite Setup         Setup_Everything
Suite Teardown      Teardown_Everything
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${INIT_DEVICE_COUNT}        250
${MAX_DEVICE_COUNT}         100000
${DEVICE_INCREMENT}         5000
${DEVICE_NAME_BASE}         netconf-scaling-device
${DEVICE_TYPE}              full-uri-device
${BASE_PORT}                17830
${NUM_WORKERS}              500
${TIMEOUT_FACTOR}           3
${MIN_CONNECT_TIMEOUT}      300
${DEVICES_RESULT_FILE}      devices.csv
${INSTALL_TESTTOOL}         True
${TESTTOOL_EXECUTABLE}      ${EMPTY}


*** Test Cases ***
Find Max Netconf Devices
    [Documentation]    Find max number of switches starting from ${MIN_SWITCHES} till reaching ${MAX_SWITCHES} in steps of ${STEP_SWITCHES}
    ${error_message} =    BuiltIn.Set Variable    Failure initializing suite
    ${maximum_devices} =    BuiltIn.Set Variable    ${0}
    ${discover_time} =    BuiltIn.Set Variable    0
    ${start} =    BuiltIn.Convert to Integer    ${INIT_DEVICE_COUNT}
    ${stop} =    BuiltIn.Convert to Integer    ${MAX_DEVICE_COUNT}
    ${increment} =    BuiltIn.Convert to Integer    ${DEVICE_INCREMENT}
    IF    "${SCHEMA_MODEL}" == "juniper"
        ${schema_dir} =    Get Juniper Device Schemas
    ELSE
        ${schema_dir} =    Set Variable    none
    END
    ${INSTALL_TESTTOOL} =    Set Variable If    '${IS_KARAF_APPL}' == 'False'    False    True
    ${TESTTOOL_EXECUTABLE} =    Set Variable If    '${IS_KARAF_APPL}' == 'False'    ${NETCONF_FILENAME}    ${EMPTY}
    ${SCHEMAS} =    Set Variable If
    ...    '${IS_KARAF_APPL}' == 'False'
    ...    ${CURDIR}/../../../variables/netconf/CRUD/schemas
    ...    ${schema_dir}
    ${restconf_url} =    BuiltIn.Set_Variable    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/rests
    ${device_names} =    BuiltIn.Set_Variable    []
    FOR    ${devices}    IN RANGE    ${start}    ${stop+1}    ${increment}
        ${timeout} =    BuiltIn.Evaluate    ${devices}*${TIMEOUT_FACTOR}
        ${timeout} =    Set Variable If    ${timeout} > ${MIN_CONNECT_TIMEOUT}    ${timeout}    ${MIN_CONNECT_TIMEOUT}
        Log To Console    Starting Iteration with ${devices} devices
        IF    "${INSTALL_TESTTOOL}"=="True"
            NetconfKeywords.Install_And_Start_Testtool
            ...    debug=false
            ...    schemas=${schema_dir}
            ...    device-count=${devices}
            ...    log_response=False
        ELSE
            NetconfKeywords.Start_Testtool
            ...    ${TESTTOOL_EXECUTABLE}
            ...    debug=false
            ...    schemas=${SCHEMAS}
            ...    device-count=${devices}
            ...    log_response=False
        END
        ${devices_to_configure} =    BuiltIn.Evaluate    ${devices} - len(${device_names})
        ${first_id} =    BuiltIn.Evaluate    len(${device_names}) + 1
        ${use_node_encapsulation}=    CompareStream.Set_Variable_If_At_Least_Scandium    True    False
        ${device_names} =    TopologyNetconfNodes.Configure Device Range
        ...    restconf_url=${restconf_url}
        ...    device_name_prefix=${DEVICE_NAME_BASE}
        ...    device_ipaddress=${TOOLS_SYSTEM_IP}
        ...    device_port=17830
        ...    device_count=${devices_to_configure}
        ...    use_node_encapsulation=${use_node_encapsulation}
        ...    first_device_id=${first_id}
        TopologyNetconfNodes.Await Devices Connected
        ...    restconf_url=${restconf_url}
        ...    device_names=${device_names}
        ...    deadline_seconds=${timeout}
        ${status}    ${result} =    Run Keyword And Ignore Error
        ...    Issue_Requests_On_Devices
        ...    ${TOOLS_SYSTEM_IP}
        ...    ${devices}
        ...    ${NUM_WORKERS}
        IF    '${status}' == 'FAIL'            BREAK
        ${maximum_devices} =    Set Variable    ${devices}
        NetconfKeywords.Stop_Testtool
    END
    [Teardown]    Run Keywords    NetconfKeywords.Stop_Testtool
    ...    AND    Collect_Data_Points    ${maximum_devices}


*** Keywords ***
Collect_Data_Points
    [Documentation]    Parse and Log relevant information when Scale test finishes
    [Arguments]    ${devices}
    OperatingSystem.Append To File    ${DEVICES_RESULT_FILE}    Max Devices\n
    OperatingSystem.Append To File    ${DEVICES_RESULT_FILE}    ${devices}\n

Issue_Requests_On_Devices
    [Documentation]    Spawn the specified count of worker threads to issue a GET request to each of the devices.
    [Arguments]    ${client_ip}    ${expected_count}    ${worker_count}
    # FIXME: this keyword is nearly duplicated in the getmulti.robot suite. need to move it to a common lib
    ${current_ssh_connection} =    SSHLibrary.Get Connection
    SSHLibrary.Open_Connection    ${client_ip}
    SSHKeywords.Flexible_Mininet_Login
    SSHLibrary.Write
    ...    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${expected_count} --name=${device_name_base} --workers=${worker_count}
    SSHLibrary.Read_Until    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Write
    ...    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${expected_count} --name=${device_name_base} --workers=${worker_count}
    FOR    ${number}    IN RANGE    1    ${expected_count}+1
        Read_Python_Tool_Operation_Result    ${number}
    END
    SSHLibrary.Read_Until    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Close_Connection
    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection.index}

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
    ${device_type} =    BuiltIn.Set_Variable_If    ${USE_NETCONF_CONNECTOR}==${True}    default    ${device_type}
    BuiltIn.Set_Suite_Variable    ${device_type}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions
    NetconfKeywords.Stop_Testtool

Read_Python_Tool_Operation_Result
    [Documentation]    Read and process a report line emitted from the Python tool that corresponds to the device with the given number.
    [Arguments]    ${number}
    ${test} =    SSHLibrary.Read_Until_Regexp    \\n
    ${test} =    String.Split_String    ${test}    |
    ${response} =    Collections.Get_From_List    ${test}    0
    ${message} =    Collections.Get_From_List    ${test}    1
    IF    '${response}' == 'ERROR'    Fail    Error getting data: ${message}
    ${start} =    Collections.Get_From_List    ${test}    1
    ${stop} =    Collections.Get_From_List    ${test}    2
    ${ellapsed} =    Collections.Get_From_List    ${test}    3
    BuiltIn.Log    DATA REQUEST RESULT: Device=${number} StartTime=${start} StopTime=${stop} EllapsedTime=${ellapsed}
    ${data} =    Collections.Get_From_List    ${test}    4
    IF    '${IS_KARAF_APPL}' == 'False'
        ${expected} =    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"/>'
    ELSE
        ${expected} =    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"></data>'
    END
    Should Be Equal As Strings    ${data}    ${expected}

Check_Device_Deconfigured
    [Documentation]    Operation for making sure the device is really deconfigured.
    [Arguments]    ${current_name}    ${log_response}=True
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to disappear
    NetconfKeywords.Wait_Device_Fully_Removed
    ...    ${current_name}
    ...    period=0.5s
    ...    timeout=120s
    ...    log_response=${log_response}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} removed

Get Juniper Device Schemas
    OperatingSystem.Run    git clone https://github.com/Juniper/yang.git
    OperatingSystem.Run    mkdir /tmp/junos_19.4R1
    OperatingSystem.Run    find yang/19.4/19.4R1/junos -type f -name '*yang' -exec cp {} /tmp/junos_19.4R1/ \\;
    OperatingSystem.Run    cp yang/19.4/19.4R1/common/* /tmp/junos_19.4R1/
    OperatingSystem.List Directory    /tmp/junos_19.4R1/
    RETURN    /tmp/junos_19.4R1
