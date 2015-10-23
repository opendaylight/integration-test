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
Resource          ${CURDIR}/../../../libraries/FailFast.robot
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
Mount_Devices_Onto_Netconf
    [Documentation]    Make request to mount the testtool devices and measure time and memory usage.
    [Setup]    Start_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Mount_Device
    [Teardown]    End_Verbose_Test

Wait_For_Devices_To_Connect
    [Setup]    Start_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Wait_Connected
    [Teardown]    End_Verbose_Test

Issue_Requests_On_Devices
    [Setup]    Start_Verbose_Test
#    Verbose_Line    Test skipped due to debugging
#    Pass_Execution    Switch this off
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Write    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${DEVICE_COUNT} --name=${device_name_base}
    : FOR    ${number}    IN RANGE    1    ${DEVICE_COUNT}+1
    \    Read_Python_Tool_Operation_Result    ${number}
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Close_Connection
    Restore Current SSH Connection From Index    ${current_ssh_connection.index}
    [Teardown]    End_Verbose_Test

Unmount_Devices
    [Setup]    Start_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Unmount_Device
    [Teardown]    Teardown__Unmount_Devices

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
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

Teardown__Unmount_Devices
    Report_Failure_Due_To_Bug    4547
    End_Verbose_Test

Start_Timer
    ${start}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    BuiltIn.Set_Suite_Variable    ${timer_start}    ${start}

Get_Time_From_Start
    ${end}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    ${ellapsed}=    BuiltIn.Evaluate    "%04d"%(${end}-${timer_start})
    ${ellapsed}=    BuiltIn.Evaluate    "%4s"%('${ellapsed}'[:-3])+"."+'${ellapsed}'[-3:]+" s"
    [Return]    ${ellapsed}

Delimiter
    ${line}=    BuiltIn.Evaluate    '-- '*23+'-+'+' '*6+'|'
    BuiltIn.Log_To_Console    ${line}

Start_Verbose_Test
    ${line}=    BuiltIn.Evaluate    ' '*6
    BuiltIn.Log_To_Console    |${line}|
    Delimiter

Verbose_Line
    [Arguments]    ${text}
    ${length}=    BuiltIn.Evaluate    70-len('${text}')
    ${line}=    BuiltIn.Evaluate    ' '*${length}
    ${small}=    BuiltIn.Evaluate    ' '*6
    BuiltIn.Log_To_Console    ${text}${line}|${small}|

End_Verbose_Test
    Delimiter
    ${line}=    BuiltIn.Evaluate    ' '*70
    BuiltIn.Log_To_Console    ${line}    no_newline=True

Mount_Device
    KarafKeywords.Log_Message_To_Controller_Karaf    Mounting device ${current_name}
    NetconfKeywords.Mount_Device_Onto_Netconf    ${current_name}    device_port=${current_port}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} mounted

Wait_Connected
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    NetconfKeywords.Wait_Device_Mounted    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Unmount_Device
    KarafKeywords.Log_Message_To_Controller_Karaf    Unmounting device ${current_name}
    NetconfKeywords.Unmount_Device_From_Netconf    ${current_name}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} unmounted

Perform_Operation_With_Checking_On_Next_Device
    [Arguments]    ${operation}
    ${number}=    BuiltIn.Evaluate    ${current_port}-${base_port}+1
    BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    NetconfKeywords.Check_Device_Up_And_Running    ${number}
    ${current_name}=    BuiltIn.Set_Suite_Variable    ${current_name}    ${device_name_base}-${number}
    Start_Timer
    BuiltIn.Run_Keyword    ${operation}
    ${ellapsed}=    Get_Time_From_Start
    ${number}=    BuiltIn.Evaluate    "%5d"%${number}
    Verbose_Line    ${number} | ${ellapsed}
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}

Read_Python_Tool_Operation_Result
    [Arguments]    ${number}
    ${test}=    SSHLibrary.Read_Until_Regexp    \\n
    ${test}=    String.Split_String    ${test}    |
    ${response}=    Collections.Get_From_List    ${test}    0
    ${message}=    Collections.Get_From_List    ${test}    1
    BuiltIn.Run_Keyword_If    '${response}' == 'ERROR'    Fail    Error getting data: ${message}
    ${ellapsed}=    Collections.Get_From_List    ${test}    1
    ${data}=    Collections.Get_From_List    ${test}    2
    ${expected}=    BuiltIn.Set_Variable    '<data xmlns="${ODL_NETCONF_NAMESPACE}"></data>'
    BuiltIn.Should_Be_Equal_As_Strings    ${data}    ${expected}
    ${number}=    BuiltIn.Evaluate    "%5d"%${number}
    Verbose_Line    ${number} | ${ellapsed} | OK
