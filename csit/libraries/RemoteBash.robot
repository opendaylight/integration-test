*** Settings ***
Documentation     Resource for managing bash execution when SSHLibrary.Execute_Command is not enough.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               There are many test tools that need to be started from bash,
...               and then either waited upon or aborted.
...               Typical hurdles are usage of virtualenv or preventing idle SSH sessions from closing down.
...               This Resource contains keywords specifically for these situations,
...               in order to avoid SSHKeywords growing too big.
...
...               Each keyword assumes There is a SSH session already esteablished and active,
...               with properties such as timeout already configured.
...               No keyword should close or switch away from that session,
...               but the configured timeout may be changed if requested.
...
...               TODO: Backport improvements from project-specific Resources,
...               for example logging to generated filename from NetconfKeywords and NexusKeywords.
Library           SSHLibrary
Resource          ${CURDIR}/SSHKeywords.robot

*** Keywords ***
Write_Bare_Ctrl_C
    [Documentation]    Construct ctrl+c character and SSH-write it (without endline) to the current SSH connection.
    ...    Do not read anything yet.
    ${ctrl_c} =    BuiltIn.Evaluate    chr(int(3))
    SSHLibrary.Write_Bare    ${ctrl_c}

Write_Bare_Ctrl_D
    [Documentation]    Construct ctrl+d character and SSH-write it (without endline) to the current SSH connection.
    ...    Do not read anything yet.
    ${ctrl_d} =    BuiltIn.Evaluate    chr(int(4))
    SSHLibrary.Write_Bare    ${ctrl_d}

Flush_Read
    [Arguments]    ${delay}=1
    [Documentation]    Attempt to read excess data (probably just multiple prompts), ignoring failure.
    ...    Log the data or error message. Return None.
    ...    \${delay} parameter tunes how long a period of inactivity has to be to consider all excess data to be read.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read    delay=${delay}
    BuiltIn.Log    ${message}

Abort_Execution
    [Documentation]    Send ctrl+c, read until prompt, Log and return the read text.
    # TODO: Maybe timeout can be specified, but the tools usually return quickly.
    Write_Bare_Ctrl_C
    ${text} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}
    Flush_Read
    [Return]    ${text}

RemoteBash__Wait_Iteration
    [Documentation]    Send a newline and wait for prompt. On success, return the text before the prompt.
    ...    The newline is there to avoid disconnection due to idling.
    SSHLibrary.Write    ${EMPTY}
    ${text} =    SSHLibrary.Read_Until_Prompt
    [Return]    ${text}

Wait_Without_Idle
    [Arguments]    ${timeout}    ${refresh}=1s
    [Documentation]    Wait until prompt, while sending newlines to avoid idling.
    ...    Flush read and return the text before prompt.
    ${text} =    Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    RemoteBash__Wait_Iteration
    Flush_Read
    [Return]    ${text}

Invoke_With_Timeout
    [Arguments]    ${command}    ${timeout}
    [Documentation]    Enter ${command}, wait until it finishes and return the output.
    ...    If it does not finish within timeout, abort it and fail.
    ...    In either case, flush read.
    # TODO: Total duration is WUKS timeout plus RUP timeout. Should we do some computation?
    SSHLibrary.Write    ${command}
    ${text} =    Wait_Without_Idle    ${timeout}
    [Teardown]    BuiltIn.Run_Keyword_If    "${KEYWORD_STATUS}" != "PASS"    Abort_Execution
    [Return]    ${text}

RemoteBash__Log_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Verify_Tool_Has_Not_Finished_Yet is implemented.
    ${text} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

Verify_Tool_Has_Not_Finished_Yet
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    ...    Log any text seen, to help debug what happened when the tool exited early.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    RemoteBash__Log_Text_Before_Prompt
    BuiltIn.Return_From_Keyword_If    "${status}" == "FAIL"
    Builtin.Fail    The prompt was seen but it was not expected yet.

Check_Return_Code
    [Arguments]    ${expected_rc}=0
    [Documentation]    Get return code of the previous command, fail if it does not match the expectation..
    SSHLibrary.Write    echo \$?
    ${rc_and_prompt} =    SSHLibrary.Read_Until_Prompt
    ${rc} =    String.Fetch_From_Left    ${rc_and_prompt}    ${\n}
    BuiltIn.Should_Be_Equal_As_Integers    0    ${rc}
