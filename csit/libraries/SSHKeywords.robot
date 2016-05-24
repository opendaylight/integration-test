*** Settings ***
Documentation     Resource enhancing SSHLibrary with Keywords used in multiple suites.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Some suites evolved utility Keywords re-usable with other suites.
...               When the Keywords assume a SSH session is active,
...               and if the Keywords do not fit into a more specific Resource,
...               you can place them here.
...
...               TODO: Migrate Keywords related to handling SSH here.
...               That may include Utils.Flexible_SSH_Login, KarafKeywords.Restore_Current_SSH_Connection_From_Index and similar.
Library           SSHLibrary
Resource          ${CURDIR}/Utils.robot

*** Keywords ***
Open_Connection_To_ODL_System
    [Arguments]    ${timeout}=10s
    [Documentation]    Open a connection to the ODL system and return its identifier.
    ...    On clustered systems this opens the connection to the first node.
    ${odl}=    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    prompt=${ODL_SYSTEM_PROMPT}    timeout=${timeout}
    Utils.Flexible_Controller_Login
    [Return]    ${odl}

Open_Connection_To_Tools_System
    [Arguments]    ${timeout}=10s
    [Documentation]    Open a connection to the tools system and return its identifier.
    ${tools}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${timeout}
    Utils.Flexible_Mininet_Login
    [Return]    ${tools}

Execute_Command_Passes
    [Arguments]    ${command}    ${return_success_only}=True    ${log_on_success}=False    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    [Documentation]    Execute command via the active SSH connection. For success, rc has to be zero and optionally stderr has to be empty.
    ...    Log everything, depending on arguments and success. Retrun either success string or stdout.
    ...    TODO: Do we want to support customizing return values the same way as SSHLibrary.Execute_Command does?
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    ${emptiness_status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${stderr}
    ${success} =    BuiltIn.Set_Variable_If    (${rc} == 0) and (("${emptiness_status}" == "PASS") or not ${stderr_must_be_empty})    True    False
    BuiltIn.Run_Keyword_If    (${log_on_success} and ${success}) or (${log_on_failure} and not ${success})    Log_Command_Results    ${stdout}    ${stderr}    ${rc}
    BuiltIn.Return_From_Keyword_If    ${return_success_only}    ${success}
    BuiltIn.Return_From_Keyword_If    ${success}    ${stdout}
    BuiltIn.Fail    Got rc: ${rc} or stdout was not empty: ${stdout}

Execute_Command_Should_Pass
    [Arguments]    ${command}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    [Documentation]    A wrapper for Execute_Command_Passes with return_success_only=False
    ...    Also, log_on_success defaults to True (but is customizable, unlike return_success_only)..
    BuiltIn.Run_Keyword_And_Return    Execute_Command_Passes    ${command}    return_success_only=False    log_on_success=${log_on_success}    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

Log_Command_Results
    [Arguments]    ${stdout}    ${stderr}    ${rc}
    [Documentation]    Log everything returned by SSHLibrary.Execute_Command
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}

Require_Python
    [Documentation]    Verify current SSH connection leads to machine with python working. Fatal fail otherwise.
    ${passed} =    Execute_Command_Passes    python --help
    BuiltIn.Return_From_Keyword_If    ${passed}
    BuiltIn.Fatal_Error    Python is not installed!

Assure_Library_Ipaddr
    [Arguments]    ${target_dir}=.
    [Documentation]    Tests whether ipaddr module is present on ssh-connected machine, Puts ipaddr.py to target_dir if not.
    ${passed} =    Execute_Command_Passes    bash -c 'cd "${target_dir}" && python -c "import ipaddr"'
    BuiltIn.Return_From_Keyword_If    ${passed}
    SSHLibrary.Put_File    ${CURDIR}/ipaddr.py    ${target_dir}/

Assure_Library_Counter
    [Arguments]    ${target_dir}=.
    [Documentation]    Tests whether Counter is present in collections on ssh-connected machine, Puts Counter.py to workspace if not.
    ${passed} =    Execute_Command_Passes    bash -c 'cd "${target_dir}" && python -c "from collections import Counter"'
    # TODO: Move the bash-cd wrapper to separate keyword?
    BuiltIn.Return_From_Keyword_If    ${passed}
    SSHLibrary.Put_File    ${CURDIR}/Counter.py    ${target_dir}/

Count_Port_Occurences
    [Arguments]    ${port}    ${state}    ${name}
    [Documentation]    Run 'netstat' on the remote machine and count occurences of given port in the given state connected to process with the given name.
    ${output}=    SSHLibrary.Execute_Command    netstat -natp 2> /dev/null | grep -E ":${port} .+ ${state} .+${name}" | wc -l
    [Return]    ${output}

Get_Tty_Id
    [Documentation]    Get the name of the tty associated with the currently
    ...    active SSH connection. Needed when searching for processes started
    ...    in this active SSH connection when there are multiple SSH
    ...    connections to the same machine.
    SSHLibrary.Write    tty >tty.txt
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    ${tty}=    SSHLibrary.Execute_Command    cat tty.txt
    ${tty}=    String.Split_To_Lines    ${tty}
    ${tty}=    Collections.Get_From_List    ${tty}    0
    ${tty}=    String.Fetch_From_Right    ${tty}    /dev/
    [Return]    ${tty}

Invoke
    [Arguments]    ${command}    ${return_stdout}=True    ${return_stderr}=False    ${return_rc}=False
    [Documentation]    SSHLibrary.Execute_Command is expected to be
    ...    equivalent to SSHLibrary.Write followed by
    ...    SSHLibrary.Read_Until_Prompt and then "automagically" stripping
    ...    everything that was not produced by the invoked command. The
    ...    actual behavior of SSHLibrary.Execute_Command is to invoke the
    ...    command with an undocumented state of the environment (which does
    ...    not match the environment in which commands invoked via
    ...    SSHLibrary.Write operate), leading to all sorts of subtle bugs
    ...    in the suites that use it. This keywords has the same API as
    ...    SSHLibrary.Execute_Command but it makes sure its behavior matches
    ...    what is expected. SSHLibrary.Execute_Command shall never be used
    ...    directly.
    # The current implementation augments the command with a stub that makes
    # sure the $HOME/.bash_profile bash startup file is executed prior to the
    # command (if it exists).
    ${augmented}=    BuiltIn.Set_Variable    if test -f $HOME/.bash_profile; then . $HOME/.bash_profile; fi; ${command}
    ${result}=    SSHLibrary.Execute_Command    ${augmented}    return_stdout=${return_stdout}    return_stderr=${return_stderr}    return_rc=${return_rc}
    [Return]    ${result}
