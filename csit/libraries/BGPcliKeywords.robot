*** Settings ***
Documentation     Robot keyword library (Resource) for handling the BGP speaker CLI tools
...
...               Copyright (c) 2015,2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This library contains keywords to handle command line tools in BGP Application
...               for handling shell connections.
...
...               TODO: RemoteBash.robot contains logic which could be reused here.
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ../variables/Variables.robot
Resource          RemoteBash.robot
Resource          NexusKeywords.robot

*** Keywords ***
Start_Console_Tool
    [Arguments]    ${command}    ${tool_opt}
    [Documentation]    Start the tool ${command} ${tool_opt}
    ${start_cmd}    BuiltIn.Set_Variable    ${command} ${tool_opt}
    BuiltIn.Log    ${start_cmd}
    ${output}=    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Start_Java_Tool_And_Verify_Connection
    [Arguments]    ${command}    ${until_phrase}
    ${start_cmd}    NexusKeywords.Compose_Full_Java_Command    ${command}
    BuiltIn.Log    ${start_cmd}
    SSHLibrary.Set_Client_Configuration    timeout=30s
    SSHLibrary.Write    ${start_cmd}
    ${output}=    SSHLibrary.Read_Until    ${until_phrase}
    BuiltIn.Log    ${output}

Wait_Until_Console_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt

Stop_Console_Tool
    [Documentation]    Stop the tool if still running.
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}

Stop_Console_Tool_And_Wait_Until_Prompt
    [Documentation]    Stops the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Read_And_Fail_If_Prompt_Is_Seen
    [Documentation]    Try to read SSH to see prompt, but expect to see no prompt within SSHLibrary's timeout.
    ${passed}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Run_Keyword_And_Expect_Error    No match found for '${ODL_SYSTEM_PROMPT}' in *.    Read_Text_Before_Prompt
    BuiltIn.Return_From_Keyword_If    ${passed}
    BGPSpeaker.Dump_BGP_Speaker_Logs
    Builtin.Fail    The prompt was seen but it was not expected yet

Read_Text_Before_Prompt
    [Documentation]    Log text gathered by SSHLibrary.Read_Until_Prompt.
    ...    This needs to be a separate keyword just because how Read_And_Fail_If_Prompt_Is_Seen is implemented.
    ${text}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${text}

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}

Check_File_For_Word_Count
    [Arguments]    ${file_name}    ${word}    ${expected_count}
    [Documentation]    Count ${word} in ${file_name}. Expect ${expected_count} occurence(s)
    ${output_log}=    SSHLibrary.Execute_Command    grep -o '${word}' ${file_name} | wc -l
    BuiltIn.Log    ${output_log}
    BuiltIn.Should_Be_Equal_As_Strings    ${output_log}    ${expected_count}

Count_Key_Value_Pairs
    [Arguments]    ${file_name}    ${keyword}    ${value}=''
    [Documentation]    Check file for ${keyword} or ${keyword} ${value} pair and returns number of occurences
    ${output_log}=    SSHLibrary.Execute_Command    grep '${keyword}' ${file_name} | grep -c ${value}
    ${count}=    Convert To Integer    ${output_log}
    [Return]    ${count}

Check_File_For_Occurence
    [Arguments]    ${file_name}    ${keyword}    ${value}=''
    [Documentation]    Check file for ${keyword} or ${keyword} ${value} pair and returns number of occurences
    ${output_log}=    SSHLibrary.Execute_Command    grep '${keyword}' ${file_name} | grep -c ${value}
    ${count}=    Convert To Integer    ${output_log}
    [Return]    ${count}
