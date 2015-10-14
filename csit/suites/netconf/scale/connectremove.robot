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
Library           RequestsLibrary
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../libraries/ConsoleReporting.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/MemoryWatch.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_COUNT}    500
${device_name_base}    netconf-scaling-device
${base_port}      17830
${memory_usage_leeway}    16    # in MB

*** Test Cases ***
Wait_For_Heap_Size_To_Stabilize
    [Documentation]    Wait for the heap size to become stable.
    MemoryWatch.Wait_Heap_Size_Stable

Connect_Devices_Onto_Netconf
    [Documentation]    Make request to mount the testtool devices and measure time and memory usage.
    [Tags]    critical
    [Setup]    ConsoleReporting.Start_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Connect_Device
    [Teardown]    ConsoleReporting.End_Verbose_Test

Remove_Devices_From_Netconf
    [Documentation]    Make request to unmount the testtool devices and measure time and memory usage.
    [Tags]    critical
    [Setup]    ConsoleReporting.Start_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Remove_Device
    [Teardown]    ConsoleReporting.End_Verbose_Test

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

Start_Timer
    ${start}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    BuiltIn.Set_Suite_Variable    ${timer_start}    ${start}

Get_Time_From_Start
    ${end}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    ${ellapsed}=    BuiltIn.Evaluate    "%04d"%(${end}-${timer_start})
    ${ellapsed}=    BuiltIn.Evaluate    "%4s"%('${ellapsed}'[:-3])+"."+'${ellapsed}'[-3:]+" s"
    [Return]    ${ellapsed}

Read_Result
    ${data}=    SSHLibrary.Read_Until_Prompt
    ${data}=    BuiltIn.Evaluate    "\\n".join("""${data}""".split("\\n")[:-1])
    [Return]    ${data}

Connect_Device
    KarafKeywords.Log_Message_To_Controller_Karaf    Connecting device ${current_name}
    NetconfKeywords.Configure_Device_In_Netconf    ${current_name}    device_port=${current_port}
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    NetconfKeywords.Wait_Device_Connected    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Remove_Device
    KarafKeywords.Log_Message_To_Controller_Karaf    Removing device ${current_name}
    NetconfKeywords.Remove_Device_From_Netconf    ${current_name}
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to disappear
    NetconfKeywords.Wait_Device_Fully_Removed    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} removed

Perform_Operation_With_Checking_On_Next_Device
    [Arguments]    ${operation}
    ${number}=    BuiltIn.Evaluate    ${current_port}-${base_port}+1
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    NetconfKeywords.Check_Device_Up_And_Running    ${number}
    ${current_name}=    BuiltIn.Set_Suite_Variable    ${current_name}    ${device_name_base}-${number}
    Start_Timer
    BuiltIn.Run_Keyword    ${operation}
    ${ellapsed}=    Get_Time_From_Start
    ${number}=    BuiltIn.Evaluate    "%5d"%${number}
    ${memory}=    MemoryWatch.Get_Current_Memory_Usage
    ConsoleReporting.Report_To_Console    ${number} | ${ellapsed} ${memory}
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}
