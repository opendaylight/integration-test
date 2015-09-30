*** Settings ***
Documentation     Metconf MDSAL Northbound test suite.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${netconf_prompt}    ]]>]]>
${datadir}        ${CURDIR}/../../../variables/netconf/MDSAL
${dataext}        msg

*** Test Cases ***
Connect_To_ODL_Netconf
    Open_ODL_Netconf_Connection
    ${hello_message}=    Get_Data    hello
    Transmit_Message    ${hello_message}

Get_Config_Running
    ${get_config}=    Get_Data    getconfig
    ${config}=    Get_Data    config
    Send_Message_And_Check_Reply    ${get_config}    ${config}

*** Keywords ***
Get_Data
    [Arguments]    ${name}
    [Documentation]    Load the specified data from the data directory and return it.
    ${data}=    OperatingSystem.Get_File    ${datadir}${/}${name}.${dataext}
    [Return]    ${data}

Open_ODL_Netconf_Connection
    [Arguments]    ${host}=${CONTROLLER}    ${port}=${ODL_NETCONF_PORT}    ${user}=${ODL_NETCONF_USER}    ${password}=${ODL_NETCONF_PASSWORD}
    [Documentation]    Open a netconf connecion to the given machine.
    SSHLibrary.Open_Connection    ${host}    prompt=~]\$    timeout=10s
    Utils.Flexible_Controller_Login
    SSHLibrary.Write    sshpass -p ${password} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${user}\@127.0.0.1 -p ${port} -s netconf
    ${hello}=    SSHLibrary.Read_Until    ${netconf_prompt}
    [Return]    ${hello}

Transmit_Message
    [Arguments]    ${message}
    [Documentation]    Transmit message to Netconf connection and discard the echo of the message.
    SSHLibrary.Write    ${message}
    SSHLibrary.Write    ${netconf_prompt}
    SSHLibrary.Read_Until    ${netconf_prompt}

Send_Message
    [Arguments]    ${message}
    [Documentation]    Send message to Netconf connection and get the reply.
    Transmit_Message    ${message}
    ${reply}=    SSHLibrary.Read_Until    ${netconf_prompt}
    [Return]    ${reply}

Send_Message_And_Check_Reply
    [Arguments]    ${message}    ${expected_reply}
    [Documentation]    Send message to Netconf connection and check that the reply matches what is expected.
    ${reply}=    Send_Message    ${message}
    ${expected}=    BuiltIn.Evaluate    "\\r\\n"+"\\r\\n".join("""${expected_reply}${netconf_prompt}""".split("\\n"))
    BuiltIn.Should_Be_Equal    ${reply}    ${expected}

Close_ODL_Netconf_Connection
    Utils.Write_Bare_Ctrl_D
    SSHLibrary.Read_Until_Prompt

Setup_Everything
    [Documentation]    Setup requests library.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Teardown_Everything
    [Documentation]    Destroy all sessions in the requests library.
    Close_ODL_Netconf_Connection
