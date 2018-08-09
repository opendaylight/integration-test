*** Settings ***
Documentation     Library for the tools system nodes.
Library           SSHLibrary
Resource          SSHKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
@{TOOLS_SYSTEM_ALL_IPS}    @{EMPTY}
@{TOOLS_SYSTEM_ALL_CONN_IDS}    @{EMPTY}

*** Keywords ***
Get System Tools Data
    : FOR    ${i}    IN RANGE    1    ${NUM_TOOLS_SYSTEM} + 1
    \    ${ip} =    ${TOOLS_SYSTEM_${i}_IP}
    \    Collections.Append To List    ${TOOLS_SYSTEM_ALL_IPS}    ${ip}
    \    ${conn_id} =    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    \    Collections.Append To List    ${TOOLS_SYSTEM_ALL_CONN_IDS}    ${conn_id}
