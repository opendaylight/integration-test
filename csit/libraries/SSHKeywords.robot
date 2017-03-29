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
...               That may include Utils.Flexible_SSH_Login, and similar.
Library           SSHLibrary
Resource          ${CURDIR}/Utils.robot

*** Variables ***
${SSHKeywords__current_remote_working_directory}    .
${SSHKeywords__current_venv_path}    /tmp/defaultvenv

*** Keywords ***
Open_Connection_To_ODL_System
    [Arguments]    ${ip_address}=${ODL_SYSTEM_IP}    ${timeout}=10s
    [Documentation]    Open a connection to the ODL system at ${ip_address} and return its identifier.
    ${odl_connection} =    SSHLibrary.Open_Connection    ${ip_address}    prompt=${ODL_SYSTEM_PROMPT}    timeout=${timeout}
    Utils.Flexible_Controller_Login
    [Return]    ${odl_connection}

Open_Connection_To_Tools_System
    [Arguments]    ${ip_address}=${TOOLS_SYSTEM_IP}    ${timeout}=10s
    [Documentation]    Open a connection to the tools system at ${ip_address} and return its identifier.
    ${tools_connection} =    SSHLibrary.Open_Connection    ${ip_address}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${timeout}
    Utils.Flexible_Mininet_Login
    [Return]    ${tools_connection}

Restore_Current_Ssh_Connection_From_Index
    [Arguments]    ${connection_index}
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
    BuiltIn.Run Keyword And Return If    ${connection_index} is not None    SSHLibrary.Switch Connection    ${connection_index}
    # The background connection is still current, bury it.
    SSHLibrary.Open Connection    127.0.0.1
    SSHLibrary.Close Connection

Run_Keyword_Preserve_Connection
    [Arguments]    ${keyword_name}    @{args}    &{kwargs}
    [Documentation]    Store current connection index, run keyword returning its result, restore connection in teardown.
    ...    Note that in order to avoid "got positional argument after named arguments", it is safer to use positional (not named) arguments on call.
    ${current_connection}=    SSHLibrary.Get_Connection
    BuiltIn.Run_Keyword_And_Return    ${keyword_name}    @{args}    &{kwargs}
    # Resource name has to be prepended, as KarafKeywords still contains a redirect.
    [Teardown]    SSHKeywords.Restore_Current_SSH_Connection_From_Index    ${current_connection.index}

Log_Command_Results
    [Arguments]    ${stdout}    ${stderr}    ${rc}
    [Documentation]    Log everything returned by SSHLibrary.Execute_Command
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}

Execute_Command_Passes
    [Arguments]    ${command}    ${return_success_only}=True    ${log_on_success}=False    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    [Documentation]    Execute command via the active SSH connection. For success, rc has to be zero and optionally stderr has to be empty.
    ...    Log everything, depending on arguments and success. Return either success string or stdout.
    ...    TODO: Do we want to support customizing return values the same way as SSHLibrary.Execute_Command does?
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    ${emptiness_status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Be_Empty    ${stderr}
    ${success} =    BuiltIn.Set_Variable_If    (${rc} == 0) and (("${emptiness_status}" == "PASS") or not ${stderr_must_be_empty})    True    False
    BuiltIn.Run_Keyword_If    (${log_on_success} and ${success}) or (${log_on_failure} and not ${success})    Log_Command_Results    ${stdout}    ${stderr}    ${rc}
    BuiltIn.Return_From_Keyword_If    ${return_success_only}    ${success}
    BuiltIn.Return_From_Keyword_If    ${success}    ${stdout}
    BuiltIn.Fail    Got rc: ${rc} or stderr was not empty: ${stderr}

Execute_Command_Should_Pass
    [Arguments]    ${command}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    [Documentation]    A wrapper for Execute_Command_Passes with return_success_only=False
    ...    Also, log_on_success defaults to True (but is customizable, unlike return_success_only)..
    BuiltIn.Run_Keyword_And_Return    Execute_Command_Passes    ${command}    return_success_only=False    log_on_success=${log_on_success}    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

Execute_Command_At_Path_Should_Pass
    [Arguments]    ${command}    ${path}=None    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=False
    [Documentation]    A keyword similar to Execute_Command_Should_Pass which performs "cd" to ${path} before executing the ${command}.
    ...    This is useful when rewriting bash scripts, as series of SSHLibrary.Execute_Command do not share current working directory.
    ...    TODO: Perhaps a Keyword which sets up environment variables would be useful as well.
    ${cd_and_command} =    BuiltIn.Set_Variable    cd '${path}' && ${command}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_Passes    ${cd_and_command}    return_success_only=False    log_on_success=${log_on_success}    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

Set_Cwd
    [Arguments]    ${path}
    [Documentation]    Set \${SSHKeywords__current_remote_working_directory} variable to ${path}. If SSH default is desired, use dot.
    BuiltIn.Set_Suite_Variable    \${SSHKeywords__current_remote_working_directory}    ${path}

Execute_Command_At_Cwd_Should_Pass
    [Arguments]    ${command}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    [Documentation]    Run Execute_Command_At_Path_Should_Pass with previously set CWD as path.
    BuiltIn.Run_Keyword_And_Return    Execute_Command_At_Path_Should_Pass    command=${command}    path=${SSHKeywords__current_remote_working_directory}    log_on_success=${log_on_success}    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

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
    ${output} =    SSHLibrary.Execute_Command    netstat -natp 2> /dev/null | grep -E ":${port} .+ ${state} .+${name}" | wc -l
    [Return]    ${output}

Virtual_Env_Set_Path
    [Arguments]    ${venv_path}
    [Documentation]    Set \${SSHKeywords__current_venv_path} variable to ${venv_path}. Path should be absolute.
    BuiltIn.Set_Global_Variable    \${SSHKeywords__current_venv_path}    ${venv_path}

Virtual_Env_Create
    [Documentation]    Creates virtual env. If not to use the default name, use Virtual_Env_Set_Path kw. Returns stdout.
    Execute_Command_At_Cwd_Should_Pass    virtualenv ${SSHKeywords__current_venv_path}
    BuiltIn.Run_Keyword_And_Return    Virtual_Env_Run_Cmd_At_Cwd    pip install --upgrade pip

Virtual_Env_Delete
    [Documentation]    Deletes a directory with virtual env.
    Execute_Command_At_Cwd_Should_Pass    rm -rf ${SSHKeywords__current_venv_path}

Virtual_Env_Run_Cmd_At_Cwd
    [Arguments]    ${cmd}    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    [Documentation]    Runs given command within activated virtual env and returns stdout.
    BuiltIn.Run_Keyword_And_Return    Execute_Command_At_Cwd_Should_Pass    source ${SSHKeywords__current_venv_path}/bin/activate; ${cmd}; deactivate    log_on_success=${log_on_success}    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

Virtual_Env_Install_Package
    [Arguments]    ${package}
    [Documentation]    Installs python package into virtual env. Use with version if needed (e.g. exabgp==3.4.16). Returns stdout.
    BuiltIn.Run_Keyword_And_Return    Virtual_Env_Run_Cmd_At_Cwd    pip install ${package}    stderr_must_be_empty=False

Virtual_Env_Uninstall_Package
    [Arguments]    ${package}
    [Documentation]    Uninstalls python package from virtual env and returns stdout.
    BuiltIn.Run_Keyword_And_Return    Virtual_Env_Run_Cmd_At_Cwd    pip uninstall -y ${package}

Virtual_Env_Freeze
    [Documentation]    Shows installed packages within the returned stdout.
    BuiltIn.Run_Keyword_And_Return    Virtual_Env_Run_Cmd_At_Cwd    pip freeze --all

Virtual_Env_Activate_On_Current_Session
    [Arguments]    ${log_output}=${False}
    [Documentation]    Activates virtual environment. To run anything in the env activated this way you should use SSHLibrary.Write and Read commands.
    SSHLibrary.Write    source ${SSHKeywords__current_venv_path}/bin/activate
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Run_Keyword_If    ${log_output}==${True}    BuiltIn.Log    ${output}

Virtual_Env_Deactivate_On_Current_Session
    [Arguments]    ${log_output}=${False}
    [Documentation]    Deactivates virtual environment.
    SSHLibrary.Write    deactivate
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Run_Keyword_If    ${log_output}==${True}    BuiltIn.Log    ${output}

Unsafe_Copy_File_To_Remote_System
    [Arguments]    ${source}    ${destination}=./    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${TOOLS_SYSTEM_USER}    ${password}=${TOOLS_SYSTEM_PASSWORD}    ${prompt}=${TOOLS_SYSTEM_PROMPT}
    ...    ${prompt_timeout}=5s
    [Documentation]    Copy the ${source} file to the ${destination} file on the remote ${system}. The keyword opens and closes a single
    ...    ssh connection and does not rely on any existing ssh connection that may be open.
    SSHLibrary.Open_Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Utils.Flexible_SSH_Login    ${user}    ${password}
    SSHLibrary.Put_File    ${source}    ${destination}
    SSHLibrary.Close Connection

Copy_File_To_Remote_System
    [Arguments]    ${source}    ${destination}=./    ${system}=${TOOLS_SYSTEM_IP}    ${user}=${DEFAULT_USER}    ${password}=${DEFAULT_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}
    ...    ${prompt_timeout}=5s
    [Documentation]    Copy the ${source} file to the ${destination} file on the remote ${system}. Any pre-existing active
    ...    ssh connection will be retained.
    SSHKeywords.Run_Keyword_Preserve_Connection    SSHKeywords.Unsafe_Copy_File_To_Remote_System    ${source}    ${destination}    ${system}    ${user}    ${password}
    ...    ${prompt}    ${prompt_timeout}
