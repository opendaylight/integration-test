*** Settings ***
Resource    SSHKeywords.robot
Library     SSHLibrary

*** Test Cases ***
A
    SSHKeywords.Open_Connection_To_Tools_System   
    #${a}=     SSHKeywords.Virtual_Env_Create
    #Log To Console      ${a}
    #${a}=     SSHKeywords.Virtual_Env_Freeze
    #Log To Console      ${a}
    #${a}=     SSHKeywords.Virtual_Env_Create
    #Log To Console      ${a}
    ${a}=      SSHKeywords.Virtual_Env_Run_Cmd_At_Cwd    pip freeze --all
    Log To Console      NoActivate: ${a}
    ${a}=     SSHKeywords.Virtual_Env_Activate
    Log To Console      ${a}
    #${a}=     SSHKeywords.Execute_Command_At_Cwd_Should_Pass      pip freeze --all
    ${a}=     SSHLibrary.Execute_Command     pip freeze --all
    #SSHLibrary.Write     pip freeze --all
    #${a}=      SSHLibrary.Read_Until_Prompt
    Log To Console      Activate1: ${a}
    ${a}=     SSHKeywords.Virtual_Env_Deactivate
    Log To Console      ${a}
    ${a}=     SSHKeywords.Virtual_Env_Activate2
    Log To Console      ${a}
    #${a}=     SSHKeywords.Execute_Command_At_Cwd_Should_Pass      pip freeze --all
    SSHLibrary.Write     pip freeze --all
    ${a}=      SSHLibrary.Read_Until_Prompt
    Log To Console      Activate2: ${a}
    ${a}=     SSHKeywords.Virtual_Env_Deactivate2
    Log To Console      ${a}

