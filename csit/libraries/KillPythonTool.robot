*** Settings ***
Documentation       Robot keyword library (Resource) for killing possibly left-over Python utilities.
...
...                 Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This library assumes that a SSH connections exists (and is switched to)
...                 to a Linux machine (usualy TOOLS_SYSTEM_IP) where the Python process should be killed.
...                 TODO: The Utils.robot library has a "Run Command On Remote System" if we didn't want to make the assumption that an SSH connection was already open.
...                 alternative TODO: Explain that it is not worth to perform separate SSH logins.
...
...                 The argument ${filter} should hold what you would type to grep command in bash:
...                 enclosed in single quotes, dots escaped by backslash and so on.
...                 Note that single quote inside cannot be escaped, but may be typed as this: '"'"'


*** Keywords ***
Search_And_Kill_Remote_Python
    [Documentation]    The main keyword. Search for processes, Log the list of them, kill them.
    [Arguments]    ${filter}
    ${processes}=    Search_For_Remote_Python_Processes    ${filter}
    BuiltIn.Log    ${processes}
    Kill_Remote_Processes    ${processes}

Search_For_Remote_Python_Processes
    [Documentation]    Only searches for the list of processes, in case something else than kill has to be done with them.
    [Arguments]    ${filter}
    ${processes}=    SSHLibrary.Execute_Command    ps -elf | egrep python | egrep ${filter} | egrep -v grep
    RETURN    ${processes}

    # TODO: Is "python" worth such a special treatment to have it mentioned in keyword name?

Kill_Remote_Processes
    [Documentation]    Kill processes by PIDs from given list (no-op if the list is empty), using specified signal. Log the kill commands used.
    [Arguments]    ${pself_lines}    ${signal}=9
    ${arg_length}=    BuiltIn.Get_Length    ${pself_lines}
    # nothing to kill here
    IF    ${arg_length} == 0    RETURN
    ${commands}=    SSHLibrary.Execute_Command    echo '${pself_lines}' | awk '{print "kill -${signal}",$4}'
    BuiltIn.Log    ${commands}
    ${stdout}    ${stderr}=    SSHLibrary.Execute_Command
    ...    echo 'set -exu; ${commands}' | sudo sh
    ...    return_stderr=True
    # TODO: Is -exu needed? Should we Log ${std*}?
