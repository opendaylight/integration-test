*** Settings ***
Library           SSHLibrary
Resource          ../../variables/Variables.robot
Library           OperatingSystem

*** Variables ***
${abc}            hi
@{array}          1    2    3

*** Test Cases ***
t1
    Comment    Log    ${abc}
    Comment    log    @{array}[0]
    ${i} =    Set Variable    0
    Comment    :FOR    ${i}    IN RANGE    1    5
    Comment    \    log    ${i}
    Comment    :FOR    ${a}    IN    @{array}
    Comment    \    log    ${a}
    Comment    ${a}    ${output} =    key    3    4
    Comment    log    ${output}
    ${conn id 1} =    Open Connection    192.168.56.101
    Login    faseela    faseela
    Create Directory    home/faseela/abcd
    Comment    ${path} =    Execute Command    pwd
    Comment    ${conn id 2} =    Open Connection    127.0.0.2
    Comment    Login    user    pass
    Comment    Switch Connection    ${conn id 1}
    Comment    Execute Command    ls
    Comment    Write
    Comment    Read Until Prompt
    Comment    ${a}

*** Keywords ***
key
    [Arguments]    ${a}    ${b}
    log    ${a}
    log    ${b}
    ${c} =    Set Variable    56
    [Return]    ${c}    ${d}
