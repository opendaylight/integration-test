*** Settings ***
Documentation     Robot keyword library (Resource) for killing possibly left-over Python utilities.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library assumes that a SSH connections exists (and is switched to)
...               to a Linux machine (usualy MININET) where the Python process should be killed.
...               TODO: The Utils.txt library has a "Run Command On Remote System" if we didn't want to make the assumption that an SSH connection was already open.
...               alternative TODO: Explain that it is not worth to perform separate SSH logins.
...
...               The argument ${filter} should hold what you would type to grep command in bash:
...               enclosed in single quotes, dots escaped by backslash and so on.
...               Note that single quote inside cannot be escaped, but may be typed as this: '"'"'

*** Keywords ***
Search_And_Kill_Remote_Python
    [Arguments]    ${filter}
    [Documentation]    The main keyword. Search for processes, Log the list of them, kill them.
    ${processes}=    Search_For_Remote_Python_Processes    ${filter}
    BuiltIn.Log    ${processes}
    Kill_Remote_Processes    ${processes}

Search_For_Remote_Python_Processes
    [Arguments]    ${filter}
    [Documentation]    Only searches for the list of processes, in case something else than kill has to be done with them.
    ${processes}=    SSHLibrary.Execute_Command    ps -elf | egrep python | egrep ${filter} | egrep -v grep
    # TODO: Is "python" worth such a special treatment to have it mentioned in keyword name?
    [Return]    ${processes}

Kill_Remote_Processes
    [Arguments]    ${pself_lines}    ${signal}=9
    [Documentation]    Kill processes by PIDs from given list (no-op if the list is empty), using specified signal. Log the kill commands used.
    ${arg_length}=    BuiltIn.Get_Length    ${pself_lines}
    Return_From_Keyword_If    ${arg_length} == 0    # nothing to kill here
    ${commands}=    SSHLibrary.Execute_Command    echo '${pself_lines}' | awk '{print "kill -${signal}",$4}'
    BuiltIn.Log    ${commands}
    ${stdout}    ${stderr}=    SSHLibrary.Execute_Command    echo 'set -exu; ${commands}' | sudo sh    return_stderr=True
    # TODO: Is -exu needed? Should we Log ${std*}?
