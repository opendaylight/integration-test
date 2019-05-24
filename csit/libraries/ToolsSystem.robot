*** Settings ***
Documentation     Library for the tools system nodes.
Library           Collections
Library           SSHLibrary
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Variables ***
@{TOOLS_SYSTEM_ALL_IPS}    @{EMPTY}
@{TOOLS_SYSTEM_ALL_CONN_IDS}    @{EMPTY}

*** Keywords ***
Get Tools System Nodes Data
    FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM} + 1
        ${ip} =    BuiltIn.Set Variable    ${TOOLS_SYSTEM_${i}_IP}
        Collections.Append To List    ${TOOLS_SYSTEM_ALL_IPS}    ${ip}
        ${conn_id} =    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
        Collections.Append To List    ${TOOLS_SYSTEM_ALL_CONN_IDS}    ${conn_id}
    END

Run Command On All Tools Systems
    [Arguments]    ${cmd}
    [Documentation]    Run command on all tools systems
    FOR    ${ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
        Utils.Run Command On Remote System    ${ip}    ${cmd}
    END
