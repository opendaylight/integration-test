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
Library           SSHLibrary
Resource          ${CURDIR}/Utils.robot

*** Keywords ***
Open_Connection_To_ODL_System
    [Documentation]    Open a connection to the ODL system and return its identifier.
    ...    On clustered systems this opens the connection to the first node.
    ${odl}=    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    prompt=${ODL_SYSTEM_PROMPT}    timeout=10s
    Utils.Flexible_Controller_Login
    [Return]    ${odl}

Open_Connection_To_Tools_System
    [Documentation]    Open a connection to the tools system and return its identifier.
    ${tools}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    Utils.Flexible_Mininet_Login
    [Return]    ${tools}

Execute_Command_Passes
    [Arguments]    ${command}
    [Documentation]    Execute command via SSH. If RC is nonzero, log everything. Retrun bool string of command success.
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}
    [Return]    False

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
