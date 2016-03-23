*** Settings ***
Documentation     RestPerfClient handling singleton resource.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           SSHLibrary
Resource          ${CURDIR}/NexusKeywords.robot
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

Invoke_Restperfclient
    [Arguments]    ${timeout}    ${url}    ${testcase}=${EMPTY}    ${ip}=${ODL_SYSTEM_IP}    ${port}=${RESTCONFPORT}    ${count}=${REQUEST_COUNT}
    ...    ${async}=false    ${user}=${ODL_RESTCONF_USER}    ${password}=${ODL_RESTCONF_PASSWORD}
    [Documentation]    Invoke RestPerfClient on the specified URL with the specified timeout.
    ...    Assemble the RestPerfClient invocation commad, setup the specified
    ...    timeout for the SSH connection, invoke the assembled command and
    ...    then check that RestPerfClient finished its run correctly.
    ${logname}=    Utils.Get_Log_File_Name    restperfclient    ${testcase}
    BuiltIn.Set_Suite_Variable    ${RestPerfClient__restperfclientlog}    ${logname}
    ${options}=    BuiltIn.Set_Variable    --ip ${ip} --port ${port} --edits ${count}
    ${options}=    BuiltIn.Set_Variable    ${options} --edit-content request1.json --async-requests ${async}
    ${options}=    BuiltIn.Set_Variable    ${options} --auth ${user} ${password}
    ${options}=    BuiltIn.Set_Variable    ${options} --destination ${url}
    ${command}=    BuiltIn.Set_Variable    ${RestPerfClient__restperfclient_invocation_command_prefix} ${options}
    BuiltIn.Log    Running restperfclient: ${command}
    SSHLibrary.Switch_Connection    ${RestPerfClient__restperfclient}
    SSHLibrary.Set_Client_Configuration    timeout=${timeout}
    Set_Known_Bug_Id    5413
    Execute_Command_Passes    ${command} >${RestPerfClient__restperfclientlog} 2>&1
    Set_Unknown_Bug_Id
    ${result}=    Grep_Restperfclient_Log    FINISHED. Execution time:
    BuiltIn.Should_Not_Be_Equal    '${result}'    ''

Grep_Restperfclient_Log
    [Documentation]    Search for the specified string in the log file produced by latest invocation of RestPerfClient
    [Arguments]    ${string}
    ${result}=    SSHLibrary.Execute_Command    grep "${string}" ${RestPerfClient__restperfclientlog}
    [Return]    ${result}

Get_Current_Log_Name
    [Return]    ${RestPerfClient__restperfclientlog}

Collect_From_Restperfclient
    [Documentation]    Collect useful data produced by restperfclient
    BuiltIn.Should_Not_Be_Equal    '${RestPerfClient__restperfclientlog}'    ''
    SSHLibrary.Get_File    ${RestPerfClient__restperfclientlog}
    BuiltIn.Set_Suite_Variable    ${RestPerfClient__restperfclientlog}    ${EMPTY}

Teardown_Restperfclient
    [Documentation]    Free resources allocated during the RestPerfClient setup
    SSHLibrary.Switch_Connection    ${RestPerfClient__restperfclient}
    SSHLibrary.Close_Connection
