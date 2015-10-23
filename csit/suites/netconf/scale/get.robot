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
Library           SSHLibrary    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_COUNT}    500
${device_name_base}    netconf-scaling-device
${base_port}    17830
${memory_usage_leeway}    16  # in MB

*** Test Cases ***
Mount_Devices_Onto_Netconf
    [Documentation]    Make request to mount the testtool devices and measure time and memory usage.
    [Setup]    Start_Verbose_Test
    [Teardown]    End_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Mount_Device

Wait_For_Devices_
    [Setup]    Start_Verbose_Test
    [Teardown]    End_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Perform_Operation_With_Checking_On_Next_Device    Wait_Connected

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Initialize ODL memory watching if requested. This must be done before
    # the testtool is started because if both are running at the same machine
    # then the initialization will get confused by the presence of two "java"
    # processes (one for ODL, the other for testtool).
    Initialize_Memory_Watching
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

Perform_Operation_With_Checking_On_Next_Device
    [Arguments]    ${operation}
    ${current_name}=    BuiltIn.Set_Suite_Variable    ${current_name}    ${device_name_base}-${current_port}
    Start_Timer
    BuiltIn.Run_Keyword    ${operation}
    ${ellapsed}=    Get_Time_From_Start
    ${number}=    BuiltIn.Evaluate    "%5d"%(${current_port}-${base_port}+1)
    Verbose_Line    ${number} | ${ellapsed}
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}
