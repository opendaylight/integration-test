*** Settings ***
Documentation     Robot keyword library (Resource) for handling the BGP speaker Python utilities.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library assumes that a SSH connections exists (and is switched to)
...               to a Linux machine (usualy MININET) where the Python BGP speaker should be running.
...               It also assumes that the current working directory on that connection is the
...               directory where the speaker tool was deployed as there are no paths to neither
...               the play.py nor the log files in the commands.
...               TODO: The Utils.robot library has a "Run Command On Remote System" if we didn't
...               want to make the assumption that an SSH connection was already open.
...               alternative TODO: Explain that it is not worth to perform separate SSH logins.
Library           SSHLibrary
Resource          ${CURDIR}/Utils.robot

*** Variables ***
${player_output_log}    play.py.out

*** Keywords ***
Start_BGP_Speaker
    [Arguments]    ${arguments}
    [Documentation]    Start the BGP speaker python utility. Redirect its error output to a log file
    ...    so it can be dumped into the logs later, when stopping it. This also avoids polluting the
    ...    output seen by "Read Until Prompt" with false propmpts so it won't stop prematurely
    ...    leading to a spurious test failure, messy log content or other misbehavior.
    ${command}=    BuiltIn.Set_Variable    python play.py ${arguments} &> ${player_output_log}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Start_BGP_Manager
    [Arguments]    ${arguments}
    [Documentation]    Start the BGP manager python utility. Redirect its error output to a log file.
    ${command}=    BuiltIn.Set_Variable    python manage_play.py ${arguments} &> ${player_output_log}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Dump_BGP_Speaker_Logs
    [Documentation]    Send all output produced by the play.py utility to Robot logs.
    ...    This needs to be called if your suite detects play.py crashing and bypasses
    ...    Kill_BGP_Speaker in that case otherwise the output of play.py (which most
    ...    likely contains clues about why it crashed) will be lost.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${player_output_log}
    BuiltIn.Log    ${output_log}

Kill_BGP_Speaker
    [Documentation]    Interrupt play.py, fail if no prompt is seen within SSHLibrary timeout.
    ...    Also dump the logs with the output the program produced.
    ...    This keyword is also suitable for stopping BGP manager.
    Utils.Write_Bare_Ctrl_C
    ${status}    ${message}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    Dump_BGP_Speaker_Logs
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'
    BuiltIn.Log    ${message}
    BuiltIn.Fail    The prompt was not seen within timeout period.
