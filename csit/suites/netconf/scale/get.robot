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
Resource          ${CURDIR}/../../../libraries/ConsoleReporting.robot
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
    [Documentation]    Make request to mount the testtool devices and measure time and memory usage.
    [Setup]    ConsoleReporting.Start_Verbose_Test
    NetconfKeywords.Perform_Operation_On_Each_Device    Configure_Device
    [Teardown]    ConsoleReporting.End_Verbose_Test

Wait_For_Devices_To_Connect
    [Setup]    ConsoleReporting.Start_Verbose_Test
    NetconfKeywords.Perform_Operation_On_Each_Device    Wait_Connected
    [Teardown]    ConsoleReporting.End_Verbose_Test

Issue_Requests_On_Devices
    [Setup]    ConsoleReporting.Start_Verbose_Test
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Write    python getter.py --odladdress=${ODL_SYSTEM_IP} --count=${DEVICE_COUNT} --name=${device_name_base}
    : FOR    ${number}    IN RANGE    1    ${DEVICE_COUNT}+1
    \    Read_Python_Tool_Operation_Result    ${number}
    SSHLibrary.Read_Until_Prompt
    SSHLibrary.Close_Connection
    Restore Current SSH Connection From Index    ${current_ssh_connection.index}
    [Teardown]    ConsoleReporting.End_Verbose_Test

Deconfigure_Devices
    [Setup]    ConsoleReporting.Start_Verbose_Test
    NetconfKeywords.Perform_Operation_On_Each_Device    Deconfigure_Device
    [Teardown]    Teardown__Unmount_Devices

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

Teardown__Unmount_Devices
    Report_Failure_Due_To_Bug    4547
    ConsoleReporting.End_Verbose_Test

Start_Timer
    ${start}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    BuiltIn.Set_Suite_Variable    ${timer_start}    ${start}

Get_Time_From_Start
    ${end}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    ${ellapsed}=    BuiltIn.Evaluate    "%04d"%(${end}-${timer_start})
    ${ellapsed}=    BuiltIn.Evaluate    "%4s"%('${ellapsed}'[:-3])+"."+'${ellapsed}'[-3:]+" s"
    [Return]    ${ellapsed}

Configure_Device
    KarafKeywords.Log_Message_To_Controller_Karaf    Configuring device ${current_name} to Netconf
    NetconfKeywords.Configure_Device_In_Netconf    ${current_name}    device_port=${current_port}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} configured

Wait_Connected
    KarafKeywords.Log_Message_To_Controller_Karaf    Waiting for device ${current_name} to connect
    NetconfKeywords.Wait_Device_Connected    ${current_name}    period=0.5s
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} connected

Deconfigure_Device
    KarafKeywords.Log_Message_To_Controller_Karaf    Deconfiguring device ${current_name}
    NetconfKeywords.Remove_Device_From_Netconf    ${current_name}
    KarafKeywords.Log_Message_To_Controller_Karaf    Device ${current_name} deconfigured

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
    ConsoleReporting.Report_To_Console    ${number} | ${ellapsed} | OK
