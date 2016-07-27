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

*** Variables ***
${SSHKeywords__current_remote_working_directory}    .
${SSHKeywords__current_venv_name}    defaultvenv

*** Keywords ***
Open_Connection_To_ODL_System
    [Documentation]    Open a connection to the ODL system and return its identifier.
    ...    On clustered systems this opens the connection to the first node.
    ${odl} =    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    [Return]    ${odl}

Open_Connection_To_Tools_System
    [Documentation]    Open a connection to the tools system and return its identifier.
    ${tools} =    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    Utils.Flexible_Mininet_Login
    [Return]    ${tools}

Log_Command_Results
    [Arguments]    ${stdout}    ${stderr}    ${rc}
    [Documentation]    Log everything returned by SSHLibrary.Execute_Command
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}

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

Virtual_Env_Set_Name
    [Arguments]    ${venv_name}
    [Documentation]    Set \${SSHKeywords__current_venv_name} variable to ${venv_name}.
    BuiltIn.Set_Suite_Variable    \${SSHKeywords__current_venv_name}    ${venv_name}

Virtual_Env_Create
    [Documentation]     Creates virtual env. If not to use the default name, use Set_Venv_Name
    Execute_Command_At_Cwd_Should_Pass      virtualenv ${SSHKeywords__current_venv_name}

Virtual_Env_Run_Cmd_Inside_Env
    [Documentation]     Runs given command within activated virtual env.
    [Arguments]     ${cmd}
    Execute_Command_At_Cwd_Should_Pass     source ${SSHKeywords__current_remote_working_directory}/${SSHKeywords__current_venv_name}/bin/activate; ${cmd}; deactivate

Virtual_Env_Install_Package
    [Documentation]     Installs python package into virtual env. Use with version if needed (e.g. exabgp==3.4.16)
    [Arguments]     ${package}
    Virtual_Env_Run_Cmd_Inside_Env      pip install ${package}

Virtual_Env_Uninstall_Package
    [Documentation]     Uninstalls python package from virtual env.
    [Arguments]     ${package}
    Virtual_Env_Run_Cmd_Inside_Env      pip uninstall -y ${package}

Virtual_Env_Freeze
    [Documentation]     Shows installed packages. To really see them you have to check stdout of the inner KWs.
    Virtual_Env_Run_Cmd_Inside_Env      pip freeze
