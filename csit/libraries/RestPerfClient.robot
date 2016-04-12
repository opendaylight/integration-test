*** Settings ***
Documentation     RestPerfClient handling singleton resource.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This singleton manages RestPerfClient invocation, tracks the log file
...               produced by the invocation, allows the test suite to easily search this
...               log file and collect it once done.
...
...               TODO: Currently only one RestPerfClient invocation running at a time is
...               supported. Support for multiple concurrently running RestPerfClient
...               invocations might be needed for example when performance testing cluster
...               nodes. However no such suites are planned for now.
...
...               FIXME: There may be suites which want to use this Resource without
...               NetconfKeywords, in which case NexusKeywords will not be initialized
...               and Setup_Restperfclient will fail. Fixing this problem will require
...               updating NexusKeywords initialization (which may break other suites)
...               and currently all suites using this use also NetconfKeywords so this
...               was postponed. Workaround for the problem: Initialize NexusKeywords
...               manually before initializing this resource.
Library           DateTime
Library           SSHLibrary
Resource          ${CURDIR}/NexusKeywords.robot
Resource          ${CURDIR}/SetupUtils.robot
Resource          ${CURDIR}/SSHKeywords.robot
Resource          ${CURDIR}/Utils.robot

*** Variables ***
${RestPerfClient__restperfclientlog}    ${EMPTY}

*** Keywords ***
Setup_Restperfclient
    [Documentation]    Deploy RestPerfClient and determine the Java command to use to call it.
    ...    Open a SSH connection through which the RestPerfClient will be
    ...    invoked, deploy RestPerfClient and the data files it needs to do
    ...    its work and initialize the internal state for the remaining
    ...    keywords.
    ${connection}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${RestPerfClient__restperfclient}    ${connection}
    SSHLibrary.Put_File    ${CURDIR}/../variables/netconf/RestPerfClient/request1.json
    ${filename}=    NexusKeywords.Deploy_Test_Tool    netconf    netconf-testtool    rest-perf-client
    ${prefix}=    NexusKeywords.Compose_Full_Java_Command    -Xmx1G -XX:MaxPermSize=256M -jar ${filename}
    BuiltIn.Set_Suite_Variable    ${RestPerfClient__restperfclient_invocation_command_prefix}    ${prefix}

RestPerfClient__Kill
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Set_Client_Configuration    timeout=5
    SSHLibrary.Read_Until_Prompt

Restperfclient__Invoke_With_Timeout
    [Arguments]    ${timeout}    ${command}
    [Timeout]    ${timeout}
    Execute_Command_Passes    ${command} >${RestPerfClient__restperfclientlog} 2>&1

Invoke_Restperfclient
    [Arguments]    ${timeout}    ${url}    ${testcase}=${EMPTY}    ${ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${count}=${REQUEST_COUNT}
    ...    ${async}=false    ${user}=${ODL_RESTCONF_USER}    ${password}=${ODL_RESTCONF_PASSWORD}
    [Documentation]    Invoke RestPerfClient on the specified URL with the specified timeout.
    ...    Assemble the RestPerfClient invocation commad, setup the specified
    ...    timeout for the SSH connection, invoke the assembled command and
    ...    then check that RestPerfClient finished its run correctly.
    ${restperfclient_running}=    Set_Variable    False
    ${logname}=    Utils.Get_Log_File_Name    restperfclient    ${testcase}
    BuiltIn.Set_Suite_Variable    ${RestPerfClient__restperfclientlog}    ${logname}
    ${options}=    BuiltIn.Set_Variable    --ip ${ip} --port ${port} --edits ${count}
    ${options}=    BuiltIn.Set_Variable    ${options} --edit-content request1.json --async-requests ${async}
    ${options}=    BuiltIn.Set_Variable    ${options} --auth ${user} ${password}
    ${timeout_in_minutes}=    Utils.Convert_To_Minutes    ${timeout}
    ${options}=    BuiltIn.Set_Variable    ${options} --timeout ${timeout_in_minutes} --destination ${url}
    ${command}=    BuiltIn.Set_Variable    ${RestPerfClient__restperfclient_invocation_command_prefix} ${options}
    BuiltIn.Log    Running restperfclient: ${command}
    SSHLibrary.Switch_Connection    ${RestPerfClient__restperfclient}
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    ${keyword_timeout}=    DateTime.Add_Time_To_Time    ${timeout}    2m    result_format=compact
    SetupUtils.Set_Known_Bug_Id    5413
    ${restperfclient_running}=    Set_Variable    True
    Restperfclient__Invoke_With_Timeout    ${keyword_timeout}    ${command}
    ${restperfclient_running}=    Set_Variable    False
    SetupUtils.Set_Unknown_Bug_Id
    ${result}=    Grep_Restperfclient_Log    FINISHED. Execution time:
    BuiltIn.Should_Not_Be_Equal    '${result}'    ''
    [Teardown]    BuiltIn.Run_Keyword_If    ${restperfclient_running}    BuiltIn.Run_Keyword_And_Ignore_Error    RestPerfClient__Kill

Grep_Restperfclient_Log
    [Arguments]    ${pattern}
    [Documentation]    Search for the specified string in the log file produced by latest invocation of RestPerfClient
    BuiltIn.Should_Not_Be_Equal    '${RestPerfClient__restperfclientlog}'    ''
    ${result}=    SSHLibrary.Execute_Command    grep '${pattern}' ${RestPerfClient__restperfclientlog}
    [Return]    ${result}

Collect_From_Restperfclient
    [Documentation]    Collect useful data produced by restperfclient
    BuiltIn.Should_Not_Be_Equal    '${RestPerfClient__restperfclientlog}'    ''
    SSHLibrary.Get_File    ${RestPerfClient__restperfclientlog}
    BuiltIn.Set_Suite_Variable    ${RestPerfClient__restperfclientlog}    ${EMPTY}

Teardown_Restperfclient
    [Documentation]    Free resources allocated during the RestPerfClient setup
    SSHLibrary.Switch_Connection    ${RestPerfClient__restperfclient}
    SSHLibrary.Close_Connection
