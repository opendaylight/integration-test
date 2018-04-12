*** Settings ***
Documentation     Robot keyword library (Resource) for handling the BGP speaker Python utilities.
...
...               Copyright (c) 2015,2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library assumes that a SSH connection exists (and is switched to)
...               to a Linux machine (usualy TOOLS_SYSTEM) where the Python BGP speaker should be run.
...               It also assumes that the current working directory on that connection is the
...               directory where the speaker tool was deployed as there are no paths to neither
...               the play.py nor the log files in the commands.
...
...               Aside BGP Speaker utility, there is also BGP Manager starting utilities in parallel.
...               For purpose of dumping logs and killing, Manager behaves the same as Speaker.
...
...               TODO: RemoteBash.robot contains logic which could be reused here.
...
...               TODO: Update the following TODOs, as SSHKeywords.robot was introduced.
...               TODO: The Utils.robot library has a "Run Command On Remote System" if we didn't
...               want to make the assumption that an SSH connection was already open.
...               alternative TODO: Explain that it is not worth to perform separate SSH logins.
Library           SSHLibrary
Library           RequestsLibrary
Resource          RemoteBash.robot


*** Variables ***
${BGPSpeaker__OUTPUT_LOG}    play.py.out
${PEER_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F

*** Keywords ***
Start_BGP_Speaker
    [Arguments]    ${arguments}
    [Documentation]    Start the BGP speaker python utility. Redirect its error output to a log file
    ...    so it can be dumped into the logs later, when stopping it. This also avoids polluting the
    ...    output seen by "Read Until Prompt" with false propmpts so it won't stop prematurely
    ...    leading to a spurious test failure, messy log content or other misbehavior.
    ${command} =    BuiltIn.Set_Variable    python play.py ${arguments} &> ${BGPSpeaker__OUTPUT_LOG}
    BuiltIn.Log    ${command}
    ${output} =    SSHLibrary.Write    ${command}

Start_BGP_Speaker_And_Verify_Connected
    [Arguments]    ${arguments}    ${session}    ${speaker_ip}=${TOOLS_SYSTEM_IP}    ${connected}=${True}
    [Documentation]    Start the BGP speaker python utility, and verifies it's connection.
    ...    We can change connected variable to false to verify Speaker did not connect.
    Start_BGP_Speaker    ${arguments}
    ${status}    ${message}    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_BGP_Speaker_Connection    ${session}    ${speaker_ip}    ${connected}
    BuiltIn.Return_From_Keyword_If    '${status}' == '${expected_status}'    ${message}
    [Return]    ${message}

Verify_BGP_Speaker_Connection
    [Documentation]    Verifies peer's presence in bgp rib.
    [Arguments]    ${session}    ${ip}    ${connected}=${True}
    ${exp_status_code}    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${url}    BuiltIn.Set_Variable    ${PEER_URL}${ip}
    ${response}    RequestsLibrary.Get_Request    ${session}    ${url}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${response.status_code}
    [Return]    ${response.content}

Start_BGP_Manager
    [Arguments]    ${arguments}
    [Documentation]    Start the BGP manager python utility. Redirect its error output to a log file.
    ${command}=    BuiltIn.Set_Variable    python play.py ${arguments} &> ${BGPSpeaker__OUTPUT_LOG}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Dump_BGP_Speaker_Logs
    [Documentation]    Send all output produced by the play.py utility to Robot logs.
    ...    This needs to be called if your suite detects play.py crashing and bypasses
    ...    Kill_BGP_Speaker in that case otherwise the output of play.py (which most
    ...    likely contains clues about why it crashed) will be lost.
    ${output_log} =    SSHLibrary.Execute_Command    cat ${BGPSpeaker__OUTPUT_LOG}
    BuiltIn.Log    ${output_log}

Kill_BGP_Speaker
    [Documentation]    Interrupt play.py, fail if no prompt is seen within SSHLibrary timeout.
    ...    Also dump the logs with the output the program produced.
    ...    This keyword is also suitable for stopping BGP manager.
    RemoteBash.Write_Bare_Ctrl_C
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    Dump_BGP_Speaker_Logs
    # TODO: When Propagate_Failure is moved to better Resource, use it instead of the following.
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'
    BuiltIn.Log    ${message}
    BuiltIn.Fail    The prompt was not seen within timeout period.
