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
Library           SSHLibrary    prompt=${MININET_PROMPT}    timeout=10s
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${DEVICE_COUNT}    10000
${device_name_base}    netconf-scaling-device
${base_port}    17832

*** Test Cases ***
Mount_Devices_On_Netconf
    [Documentation]    Make request to mount a testtool device on Netconf connector
    [Tags]    critical
    [Setup]    Start_Verbose_Test
    [Teardown]    End_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    ${base_port}
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Mount_Next_Device

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
    SSHKeywords.Install_And_Start_Testtool    device-count=${DEVICE_COUNT}

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHKeywords.Stop_Testtool

Read_Result
    ${result}=    SSHLibrary.Read_Until_Prompt
    ${result}=    BuiltIn.Evaluate    """${result}""".split("\\n")[0]
    [Return]    ${result}

Initialize_Memory_Watching
    ${odl}=    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    prompt=${ODL_SYSTEM_PROMPT}
    BuiltIn.Set_Suite_Variable    ${odl_index}    ${odl}
    Utils.Flexible_Controller_Login
    SSHLibrary.Write    ps -A | grep java | cut -b1-5
    ${pid}=    Read_Result
    BuiltIn.Set_Suite_Variable    ${odl_pid}    ${pid}

Get_Current_Memory_Usage
    ${tools_index}=    SSHLibrary.Switch_Connection    ${odl_index}
    ${command}=    Set variable    jmap -histo:live ${odl_pid} | tail -1 | cut -b 20-34
    SSHLibrary.Write    ${command}
    ${result}=    Read_Result
    ${result}=    BuiltIn.Evaluate    "%04d"%((${result}*1000)//1048576)
    ${result}=    BuiltIn.Evaluate    "%4s"%('${result}'[:-3])+"."+'${result}'[-3:]+" MB"
    SSHLibrary.Switch_Connection    ${tools_index}
    [Return]    ${result}

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

Mount_Next_Device
    ${start}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    NetconfKeywords.Mount_Device_Onto_Netconf    ${device_name_base}-${current_port}    device_port=${current_port}
    ${end}=    BuiltIn.Evaluate    str(int(time.time()*1000))    modules=time
    ${ellapsed}=    BuiltIn.Evaluate    "%04d"%(${end}-${start})
    ${ellapsed}=    BuiltIn.Evaluate    "%4s"%('${ellapsed}'[:-3])+"."+'${ellapsed}'[-3:]+" s"
    ${number}=    BuiltIn.Evaluate    "%5d"%(${current_port}-${base_port}+1)
    ${memory}=    Get_Current_Memory_Usage
    Verbose_Line    ${number} | ${ellapsed} | ${memory}
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}
