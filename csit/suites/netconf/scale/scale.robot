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

*** Test Cases ***
Mount_Devices_On_Netconf
    [Documentation]    Make request to mount a testtool device on Netconf connector
    [Tags]    critical
    [Setup]    Start_Verbose_Test
    [Teardown]    End_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${current_port}    17832
    BuiltIn.Repeat_Keyword    ${DEVICE_COUNT} times    Mount_Next_Device

*** Keywords ***
Setup_Everything
    [Documentation]    Setup everything needed for the test cases.
    # Setup resources used by the suite.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    # Connect to the Mininet machine
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
    # Deploy testtool on it
    SSHKeywords.Install_And_Start_Testtool    device-count=10

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    Teardown_Netconf_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHKeywords.Stop_Testtool

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
    ${ellapsed}=    BuiltIn.Evaluate    '${ellapsed}'[:-3]+"."+'${ellapsed}'[-3:]
    Verbose_Line    Mounting device at port ${current_port} took ${ellapsed} s
    ${next}=    BuiltIn.Evaluate    ${current_port}+1
    BuiltIn.Set_Suite_Variable    ${current_port}    ${next}
