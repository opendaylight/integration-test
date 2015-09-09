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
...               TODO: The Utils.robot library has a "Run Command On Remote System" if we didn't want to make the assumption that an SSH connection was already open.
...               alternative TODO: Explain that it is not worth to perform separate SSH logins.

*** Variables ***
${player_output_log}    play.py.out
${player_error_log}    play.py.err

*** Keywords ***
Start_BGP_Speaker
    [Arguments]    ${arguments}
    [Documentation]    Start the BGP speaker python utility. Redirect its error output to a log file
    ...    so it can be dumped into the logs later (when stopping it).
    ${command}=    BuiltIn.Set_Variable    python play.py ${arguments} 1>${player_output_log} 2>${player_error_log}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Write_Bare_Ctrl_C
    [Documentation]    Construct ctrl+c character and SSH-write it (without endline). Do not read anything yet.
    # TODO: Place this keyword to some Resource so that it can be re-used in other suites.
    ${command}=    BuiltIn.Evaluate    chr(int(3))
    SSHLibrary.Write_Bare    ${command}

Kill_BGP_Speaker
    [Documentation]    Interrupt play.py, fail if no prompt is seen within SSHLibrary timeout.
    ...    Also, check that TCP connection is no longer established.
    Write_Bare_Ctrl_C
    SSHLibrary.Read_Until_Prompt
    ${output_log}=    SSHLibrary.Execute_Command    cat ${player_output_log}
    Builtin.Log    ${output_log}
    ${error_log}=    SSHLibrary.Execute_Command    cat ${player_error_log}
    Builtin.Log    ${error_log}
