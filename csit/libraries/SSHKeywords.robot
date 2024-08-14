*** Settings ***
Documentation       Resource enhancing SSHLibrary with Keywords used in multiple suites.
...
...                 Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 Some suites evolved utility Keywords re-usable with other suites.
...                 When the Keywords assume a SSH session is active,
...                 and if the Keywords do not fit into a more specific Resource,
...                 you can place them here.

Library             SSHLibrary
Resource            ${CURDIR}/Utils.robot
Resource            ../variables/Variables.robot


*** Variables ***
${SSHKeywords__current_remote_working_directory}    .
${SSHKeywords__current_venv_path}                   /tmp/defaultvenv
${NETSTAT_COMMAND}                                  ss -punta


*** Keywords ***
Open_Connection_To_ODL_System
    [Documentation]    Open a connection to the ODL system at ${ip_address} and return its identifier.
    [Arguments]    ${ip_address}=${ODL_SYSTEM_IP}    ${timeout}=10s
    ${odl_connection} =    SSHLibrary.Open_Connection
    ...    ${ip_address}
    ...    prompt=${ODL_SYSTEM_PROMPT}
    ...    timeout=${timeout}
    Flexible_Controller_Login
    RETURN    ${odl_connection}

Open_Connection_To_Tools_System
    [Documentation]    Open a connection to the tools system at ${ip_address} and return its identifier.
    [Arguments]    ${ip_address}=${TOOLS_SYSTEM_IP}    ${timeout}=10s    ${prompt}=${TOOLS_SYSTEM_PROMPT}
    ${tools_connection} =    SSHLibrary.Open_Connection    ${ip_address}    prompt=${prompt}    timeout=${timeout}
    Flexible_Mininet_Login
    RETURN    ${tools_connection}

Restore_Current_Ssh_Connection_From_Index
    [Documentation]    Restore active SSH connection in SSHLibrary to given index.
    ...
    ...    Restore the currently active connection state in
    ...    SSHLibrary to match the state returned by "Switch
    ...    Connection" or "Get Connection". More specifically makes
    ...    sure that there will be no active connection when the
    ...    \${connection_index} reported by these means is None.
    ...
    ...    There is a misfeature in SSHLibrary: Invoking "SSHLibrary.Switch_Connection"
    ...    and passing None as the "index_or_alias" argument to it has exactly the
    ...    same effect as invoking "Close Connection".
    ...    https://github.com/robotframework/SSHLibrary/blob/master/src/SSHLibrary/library.py#L560
    ...
    ...    We want to have Keyword which will "switch out" to previous
    ...    "no connection active" state without killing the background one.
    ...
    ...    As some suites may hypothetically rely on non-writability of active connection,
    ...    workaround is applied by opening and closing temporary connection.
    ...    Unfortunately this will fail if run on Jython and there is no SSH server
    ...    running on localhost, port 22 but there is nothing easy that can be done about it.
    [Arguments]    ${connection_index}
    BuiltIn.Run Keyword And Return If
    ...    ${connection_index} is not None
    ...    SSHLibrary.Switch Connection
    ...    ${connection_index}
    # The background connection is still current, bury it.
    SSHLibrary.Open Connection    127.0.0.1
    SSHLibrary.Close Connection

Run_Keyword_Preserve_Connection
    [Documentation]    Store current connection index, run keyword returning its result, restore connection in teardown.
    ...    Note that in order to avoid "got positional argument after named arguments", it is safer to use positional (not named) arguments on call.
    [Arguments]    ${keyword_name}    @{args}    &{kwargs}
    ${current_connection} =    SSHLibrary.Get_Connection
    BuiltIn.Run_Keyword_And_Return    ${keyword_name}    @{args}    &{kwargs}
    # Resource name has to be prepended, as KarafKeywords still contains a redirect.
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_connection.index}

Run_Keyword_With_Ssh
    [Documentation]    Open temporary connection to given IP address, run keyword, close connection, restore previously active connection, return result.
    [Arguments]    ${ip_address}    ${keyword_name}    @{args}    &{kwargs}
    Run_Keyword_Preserve_Connection
    ...    Run_Unsafely_Keyword_Over_Temporary_Odl_Session
    ...    ${ip_address}
    ...    ${keyword_name}
    ...    @{args}
    ...    &{kwargs}

Run_Unsafely_Keyword_Over_Temporary_Odl_Session
    [Documentation]    Open connection to given IP address, run keyword, close connection, return result.
    ...    This is unsafe in the sense that previously active session will be switched out off, but safe in the sense only the temporary connection is closed.
    [Arguments]    ${ip_address}    ${keyword_name}    @{args}    &{kwargs}
    Open_Connection_To_ODL_System    ${ip_address}
    # Not using Teardown, to avoid a call to close if the previous line fails.
    ${status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    ${keyword_name}    @{args}    &{kwargs}
    SSHLibrary.Close_Connection
    IF    "${status}" == "PASS"    RETURN    ${result}
    BuiltIn.Fail    ${result}

Log_Command_Results
    [Documentation]    Log everything returned by SSHLibrary.Execute_Command
    [Arguments]    ${stdout}    ${stderr}    ${rc}
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}

Execute_Command_Passes
    [Documentation]    Execute command via the active SSH connection. For success, rc has to be zero and optionally stderr has to be empty.
    ...    Log everything, depending on arguments and success. Return either success string or stdout.
    ...    TODO: Do we want to support customizing return values the same way as SSHLibrary.Execute_Command does?
    [Arguments]    ${command}    ${return_success_only}=True    ${log_on_success}=False    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command
    ...    ${command}
    ...    return_stderr=True
    ...    return_rc=True
    ${emptiness_status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${stderr}
    ${success} =    BuiltIn.Set_Variable_If
    ...    (${rc} == 0) and (("${emptiness_status}" == "PASS") or not ${stderr_must_be_empty})
    ...    True
    ...    False
    IF    (${log_on_success} and ${success}) or (${log_on_failure} and not ${success})
        Log_Command_Results    ${stdout}    ${stderr}    ${rc}
    END
    IF    ${return_success_only}    RETURN    ${success}
    IF    ${success}    RETURN    ${stdout}
    BuiltIn.Fail    Got rc: ${rc} or stderr was not empty: ${stderr}

Execute_Command_Should_Pass
    [Documentation]    A wrapper for Execute_Command_Passes with return_success_only=False
    ...    Also, log_on_success defaults to True (but is customizable, unlike return_success_only)..
    [Arguments]    ${command}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    BuiltIn.Run_Keyword_And_Return
    ...    Execute_Command_Passes
    ...    ${command}
    ...    return_success_only=False
    ...    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}
    ...    stderr_must_be_empty=${stderr_must_be_empty}

Execute_Command_At_Path_Should_Pass
    [Documentation]    A keyword similar to Execute_Command_Should_Pass which performs "cd" to ${path} before executing the ${command}.
    ...    This is useful when rewriting bash scripts, as series of SSHLibrary.Execute_Command do not share current working directory.
    ...    TODO: Perhaps a Keyword which sets up environment variables would be useful as well.
    [Arguments]    ${command}    ${path}=None    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    ${cd_and_command} =    BuiltIn.Set_Variable    cd '${path}' && ${command}
    BuiltIn.Run_Keyword_And_Return
    ...    Execute_Command_Passes
    ...    ${cd_and_command}
    ...    return_success_only=False
    ...    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}
    ...    stderr_must_be_empty=${stderr_must_be_empty}

Set_Cwd
    [Documentation]    Set \${SSHKeywords__current_remote_working_directory} variable to ${path}. If SSH default is desired, use dot.
    [Arguments]    ${path}
    BuiltIn.Set_Suite_Variable    \${SSHKeywords__current_remote_working_directory}    ${path}

Execute_Command_At_Cwd_Should_Pass
    [Documentation]    Run Execute_Command_At_Path_Should_Pass with previously set CWD as path.
    [Arguments]    ${command}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    BuiltIn.Run_Keyword_And_Return
    ...    Execute_Command_At_Path_Should_Pass
    ...    command=${command}
    ...    path=${SSHKeywords__current_remote_working_directory}
    ...    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}
    ...    stderr_must_be_empty=${stderr_must_be_empty}

Require_Python
    [Documentation]    Verify current SSH connection leads to machine with python working. Fatal fail otherwise.
    ${passed} =    Execute_Command_Passes    python3 --help
    IF    ${passed}    RETURN
    BuiltIn.Fatal_Error    Python 3 is not installed!

Assure_Library_Ipaddr
    [Documentation]    Tests whether ipaddr module is present on ssh-connected machine, Puts ipaddr.py to target_dir if not.
    [Arguments]    ${target_dir}=.
    ${passed} =    Execute_Command_Passes    bash -c 'cd "${target_dir}" && python -c "import ipaddr"'
    IF    ${passed}    RETURN
    SSHLibrary.Put_File    ${CURDIR}/BGPCEP/ipaddr.py    ${target_dir}/

Assure_Library_Counter
    [Documentation]    Tests whether Counter is present in collections on ssh-connected machine, Puts Counter.py to workspace if not.
    [Arguments]    ${target_dir}=.
    ${passed} =    Execute_Command_Passes
    ...    bash -c 'cd "${target_dir}" && python -c "from collections import Counter"'
    # TODO: Move the bash-cd wrapper to separate keyword?
    IF    ${passed}    RETURN
    SSHLibrary.Put_File    ${CURDIR}/Counter.py    ${target_dir}/

Count_Port_Occurences
    [Documentation]    Run 'netstat' on the remote machine and count occurences of given port in the given state connected to process with the given name.
    [Arguments]    ${port}    ${state}    ${name}
    ${output} =    SSHLibrary.Execute_Command
    ...    ${NETSTAT_COMMAND} 2> /dev/null | grep -E ":${port} .+ ${state} .+${name}" | wc -l
    RETURN    ${output}

Virtual_Env_Set_Path
    [Documentation]    Set \${SSHKeywords__current_venv_path} variable to ${venv_path}. Path should be absolute.
    [Arguments]    ${venv_path}
    BuiltIn.Set_Global_Variable    \${SSHKeywords__current_venv_path}    ${venv_path}

Virtual_Env_Create
    [Documentation]    Creates virtual env. If not to use the default name, use Virtual_Env_Set_Path kw. Returns stdout.
    [Arguments]    ${upgrade_pip}=True
    Execute_Command_At_Cwd_Should_Pass    virtualenv ${SSHKeywords__current_venv_path}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${upgrade_pip}
    ...    Virtual_Env_Run_Cmd_At_Cwd
    ...    pip install --upgrade pip
    ...    stderr_must_be_empty=False

Virtual_Env_Create_Python3
    [Documentation]    Creates virtual env. If not to use the default name, use Virtual_Env_Set_Path kw. Returns stdout.
    [Arguments]    ${upgrade_pip}=True
    Execute_Command_At_Cwd_Should_Pass    python3 -m venv ${SSHKeywords__current_venv_path}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${upgrade_pip}
    ...    Virtual_Env_Run_Cmd_At_Cwd
    ...    pip install --upgrade pip
    ...    stderr_must_be_empty=False

Virtual_Env_Delete
    [Documentation]    Deletes a directory with virtual env.
    Execute_Command_At_Cwd_Should_Pass    rm -rf ${SSHKeywords__current_venv_path}

Virtual_Env_Run_Cmd_At_Cwd
    [Documentation]    Runs given command within activated virtual env and returns stdout.
    [Arguments]    ${cmd}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    BuiltIn.Run_Keyword_And_Return
    ...    Execute_Command_At_Cwd_Should_Pass
    ...    source ${SSHKeywords__current_venv_path}/bin/activate; ${cmd}; deactivate
    ...    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}
    ...    stderr_must_be_empty=${stderr_must_be_empty}

Virtual_Env_Install_Package
    [Documentation]    Installs python package into virtual env. Use with version if needed (e.g. exabgp==3.4.16). Returns stdout.
    [Arguments]    ${package}
    BuiltIn.Run_Keyword_And_Return
    ...    Virtual_Env_Run_Cmd_At_Cwd
    ...    pip install ${package}
    ...    stderr_must_be_empty=False

Virtual_Env_Uninstall_Package
    [Documentation]    Uninstalls python package from virtual env and returns stdout.
    [Arguments]    ${package}
    BuiltIn.Run_Keyword_And_Return
    ...    Virtual_Env_Run_Cmd_At_Cwd
    ...    pip uninstall -y ${package}
    ...    stderr_must_be_empty=False

Virtual_Env_Freeze
    [Documentation]    Shows installed packages within the returned stdout.
    BuiltIn.Run_Keyword_And_Return    Virtual_Env_Run_Cmd_At_Cwd    pip freeze --all    stderr_must_be_empty=False

Virtual_Env_Activate_On_Current_Session
    [Documentation]    Activates virtual environment. To run anything in the env activated this way you should use SSHLibrary.Write and Read commands.
    [Arguments]    ${log_output}=${False}
    SSHLibrary.Write    source ${SSHKeywords__current_venv_path}/bin/activate
    ${output} =    SSHLibrary.Read_Until_Prompt
    IF    ${log_output}==${True}    BuiltIn.Log    ${output}

Virtual_Env_Deactivate_On_Current_Session
    [Documentation]    Deactivates virtual environment.
    [Arguments]    ${log_output}=${False}
    SSHLibrary.Write    deactivate
    ${output} =    SSHLibrary.Read_Until_Prompt
    IF    ${log_output}==${True}    BuiltIn.Log    ${output}

Unsafe_Copy_File_To_Remote_System
    [Documentation]    Copy the ${source} file to the ${destination} file on the remote ${system}. The keyword opens and closes a single
    ...    ssh connection and does not rely on any existing ssh connection that may be open.
    [Arguments]    ${system}    ${source}    ${destination}=./    ${user}=${DEFAULT_USER}    ${password}=${DEFAULT_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=5s
    SSHLibrary.Open_Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible_SSH_Login    ${user}    ${password}
    SSHLibrary.Put_File    ${source}    ${destination}
    SSHLibrary.Close Connection

Copy_File_To_Remote_System
    [Documentation]    Copy the ${source} file to the ${destination} file on the remote ${system}. Any pre-existing active
    ...    ssh connection will be retained.
    [Arguments]    ${system}    ${source}    ${destination}=./    ${user}=${DEFAULT_USER}    ${password}=${DEFAULT_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=5s
    SSHKeywords.Run_Keyword_Preserve_Connection
    ...    SSHKeywords.Unsafe_Copy_File_To_Remote_System
    ...    ${system}
    ...    ${source}
    ...    ${destination}
    ...    ${user}
    ...    ${password}
    ...    ${prompt}
    ...    ${prompt_timeout}

Copy_File_To_Odl_System
    [Documentation]    Wrapper keyword to make it easier to copy a file to an ODL specific system
    [Arguments]    ${system}    ${source}    ${destination}=./
    SSHKeywords.Copy_File_To_Remote_System
    ...    ${system}
    ...    ${source}
    ...    ${destination}
    ...    ${ODL_SYSTEM_USER}
    ...    ${ODL_SYSTEM_PASSWORD}
    ...    ${ODL_SYSTEM_PROMPT}

Copy_File_To_Tools_System
    [Documentation]    Wrapper keyword to make it easier to copy a file to an Tools specific system
    [Arguments]    ${system}    ${source}    ${destination}=./
    SSHKeywords.Copy_File_To_Remote_System
    ...    ${system}
    ...    ${source}
    ...    ${destination}
    ...    ${TOOLS_SYSTEM_USER}
    ...    ${TOOLS_SYSTEM_PASSWORD}
    ...    ${TOOLS_SYSTEM_PROMPT}

Flexible_SSH_Login
    [Documentation]    On active SSH session: if given non-empty password, do Login, else do Login With Public Key.
    [Arguments]    ${user}    ${password}=${EMPTY}    ${delay}=0.5s
    ${pwd_length} =    BuiltIn.Get Length    ${password}
    # ${pwd_length} is guaranteed to be an integer, so we are safe to evaluate it as Python expression.
    BuiltIn.Run Keyword And Return If
    ...    ${pwd_length} > 0
    ...    SSHLibrary.Login
    ...    ${user}
    ...    ${password}
    ...    delay=${delay}
    BuiltIn.Run Keyword And Return
    ...    SSHLibrary.Login With Public Key
    ...    ${user}
    ...    ${USER_HOME}/.ssh/${SSH_KEY}
    ...    ${KEYFILE_PASS}
    ...    delay=${delay}

Flexible_Mininet_Login
    [Documentation]    Call Flexible SSH Login, but with default values suitable for Mininet machine.
    [Arguments]    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${delay}=0.5s
    BuiltIn.Run Keyword And Return    Flexible SSH Login    user=${user}    password=${password}    delay=${delay}

Flexible_Controller_Login
    [Documentation]    Call Flexible SSH Login, but with default values suitable for Controller machine.
    [Arguments]    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}    ${delay}=0.5s
    BuiltIn.Run Keyword And Return    Flexible SSH Login    user=${user}    password=${password}    delay=${delay}

Move_File_To_Remote_System
    [Documentation]    Moves the ${source} file to the ${destination} file on the remote ${system}. Any pre-existing active
    ...    ssh connection will be retained.
    [Arguments]    ${system}    ${source}    ${destination}=./    ${user}=${DEFAULT_USER}    ${password}=${DEFAULT_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=5s
    SSHKeywords.Run_Keyword_Preserve_Connection
    ...    Unsafe_Move_File_To_Remote_System
    ...    ${system}
    ...    ${source}
    ...    ${destination}
    ...    ${user}
    ...    ${password}
    ...    ${prompt}
    ...    ${prompt_timeout}

Unsafe_Move_File_To_Remote_System
    [Documentation]    Moves the ${source} file to the ${destination} file on the remote ${system}. The keyword opens and closes a single
    ...    ssh connection and does not rely on any existing ssh connection that may be open.
    [Arguments]    ${system}    ${source}    ${destination}=./    ${user}=${DEFAULT_USER}    ${password}=${DEFAULT_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=5s
    SSHLibrary.Open_Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible_SSH_Login    ${user}    ${password}
    SSHLibrary.Put File    ${source}    ${destination}
    OperatingSystem.Remove File    ${source}
    SSHLibrary.Close Connection
