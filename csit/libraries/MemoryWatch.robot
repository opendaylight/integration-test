*** Settings ***
Documentation     Watch memory usage by ODL Java process
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           SSHLibrary
Resource          ${CURDIR}/ConsoleReporting.robot
Resource          ${CURDIR}/KarafKeywords.robot
Resource          ${CURDIR}/Timer.robot

*** Variables ***
${WATCH_MEMORY}    False
${MemoryWatch__Initialization_Needed}    True
${HEAP_SIZE_CHANGE_MIN}    0
${HEAP_SIZE_CHANGE_MAX}    65536

*** Keywords ***
Initialize
    [Documentation]    Initialize ODL memory watching.
    ...    Open a connection to the ODL machine and store its index to
    ...    the ${odl_index} suite variable. This connection is then used
    ...    to issue shell commands to obtain the memory usage.
    ...
    ...    Then invoke some shell commands to determine the Java process PID
    ...    which is necessary for the shell commands used to obtain the
    ...    memory usage. This command requires only one Java process to be
    ...    running, so this keyword must be called before the testtool or any
    ...    other Java tool is started on the ODL machine, because if the
    ...    "tools system" is configured to be the same machine as the "ODL
    ...    system", the shell commands trying to figure out the PID will get
    ...    confused by the presence of multiple "java" processes (one for
    ...    ODL, the other(s) for testtool and/or the other Java
    ...    tool(s)).
    ...
    ...    TODO: Move Restore_Current_SSH_Connection_From_Index from
    ...    KarafKeywords to SSHKeywords. Not possible in reasonable amount
    ...    of time before the refactor and keyword checker are completed.
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    ${odl}=    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Set_Client_Configuration    timeout=5m
    BuiltIn.Set_Suite_Variable    ${odl_index}    ${odl}
    Utils.Flexible_Controller_Login
    SSHLibrary.Write    ps -A | grep java | cut -b1-5
    ${pid}=    Read_Result
    BuiltIn.Set_Suite_Variable    ${odl_pid}    ${pid}
    KarafKeywords.Restore_Current_SSH_Connection_From_Index    ${current_ssh_connection.index}

MemoryWatch__Format_Memory_Amount
    [Arguments]    ${amount}    ${base}=0    ${places}=4
    ${amount}=    BuiltIn.Evaluate    ${amount}-${base}
    ${decimal}=    BuiltIn.Evaluate    4+int(${amount}<0)
    ${memory}=    BuiltIn.Evaluate    "%0${decimal}d"%((${amount}*1000)//1048576)
    ${memory}=    BuiltIn.Evaluate    "%${places}s"%('${memory}'[:-3])+"."+'${memory}'[-3:]+" MB"
    [Return]    ${memory}

Get_ODL_Heap_Size
    [Documentation]    Get the size of the ODL memory heap in use in bytes
    ${tools_index}=    SSHLibrary.Switch_Connection    ${odl_index}
    SSHLibrary.Write    jmap -histo:live ${odl_pid} | tail -1 | cut -b 20-34
    ${memory}=    Read_Result
    SSHLibrary.Switch_Connection    ${tools_index}
    [Return]    ${memory}

Get_Current_Memory_Usage
    [Documentation]    Get the memory usage report
    ...    Returns an empty string when the Initialize keyword was not called
    ...    (this is used to provide ability to bypass the memory usage
    ...    reporting if that feature is not desired in a particular test
    ...    suite) or when the memory usage reporting is not enabled.
    BuiltIn.Return_From_Keyword_If    not ${WATCH_MEMORY}    ${empty}
    BuiltIn.Return_From_Keyword_If    ${MemoryWatch__Initialization_Needed}    ${empty}
    Timer.Start_Timer
    ${memory}=    Get_ODL_Heap_Size
    ${gctime}=    Timer.Get_Time_From_Start
    ${devmem}=    MemoryWatch__Format_Memory_Amount    ${memory}    ${odl_memory}
    ${totmem}=    MemoryWatch__Format_Memory_Amount    ${memory}    ${odl_base_memory}    places=5
    BuiltIn.Set_Suite_Variable    ${odl_memory}    ${memory}
    [Return]    | ${devmem} | ${totmem} | ${gctime}

MemoryWatch__Check_Heap_Size_Stable
    ${memory}=    Get_ODL_Heap_Size
    ${heap}=    MemoryWatch__Format_Memory_Amount    ${memory}
    ${delta}=    BuiltIn.Evaluate    ${memory}-${odl_base_memory}
    ${heapdelta}=    MemoryWatch__Format_Memory_Amount    ${delta}
    ConsoleReporting.Report_To_Console    ${heap} | ${heapdelta}
    BuiltIn.Set_Suite_Variable    ${odl_base_memory}    ${memory}
    BuiltIn.Set_Suite_Variable    ${odl_memory}    ${memory}
    BuiltIn.Run_Keyword_If    ${delta}<${HEAP_SIZE_CHANGE_MIN} or ${delta}>${HEAP_SIZE_CHANGE_MAX}    BuiltIn.Fail    Heap size changed too much since last check

Wait_Heap_Size_Stable
    [Documentation]    Repeatedly query used ODL heap size until the heap size change falls into the toleration interval.
    ConsoleReporting.Start_Verbose_Test
    BuiltIn.Set_Suite_Variable    ${odl_base_memory}    0
    ${status}    ${message}=    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    5m    10s    MemoryWatch__Check_Heap_Size_Stable
    ConsoleReporting.End_Verbose_Test
    BuiltIn.Run_Keyword_If    '${status}' != 'PASS'    BuiltIn.Fail    ${message}
