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

*** Variables ***
${player_output_log}    play.py.out

*** Keywords ***
Start_BGP_Speaker
    [Arguments]    ${arguments}
    [Documentation]    Start the BGP speaker python utility. Redirect its error output to a log file
    ...    so it can be dumped into the logs later (when stopping it).
    ${command}=    BuiltIn.Set_Variable    python play.py ${arguments} &>${player_output_log}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Write_Bare_Ctrl_C
    [Documentation]    Construct ctrl+c character and SSH-write it (without endline). Do not read anything yet.
    # TODO: Place this keyword to some Resource so that it can be re-used in other suites.
    ${command}=    BuiltIn.Evaluate    chr(int(3))
    SSHLibrary.Write_Bare    ${command}

Kill_BGP_Speaker
    [Documentation]    Interrupt play.py, fail if no prompt is seen within SSHLibrary timeout.
    ...    Also dump the logs with the output the program produced.
    Write_Bare_Ctrl_C
    Builtin.Run_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    ${output_log}=    SSHLibrary.Execute_Command    cat ${player_output_log}
    Builtin.Log    ${output_log}
