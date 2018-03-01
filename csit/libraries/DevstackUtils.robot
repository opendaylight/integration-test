*** Settings ***
Documentation     General Utils library. This library has broad scope, it can be used by any robot system tests.
Library           RequestsLibrary
Library           SSHLibrary
Resource          OpenStackOperations.robot
Resource          ../variables/Variables.robot

*** Variables ***
${DEFAULT_DEVSTACK_PROMPT_TIMEOUT}    10s
${DEVSTACK_SYSTEM_PASSWORD}    \    # set to empty, but provide for others to override if desired
${OS_CNTL_CONN_ID}    None
${OS_CMP1_CONN_ID}    None
${OS_CMP2_CONN_ID}    None
${OS_CNTL_IP}     ${EMPTY}
${OS_CMP1_IP}     ${EMPTY}
${OS_CMP2_IP}     ${EMPTY}
@{OS_ALL_IPS}     @{EMPTY}
@{OS_CMP_IPS}     @{EMPTY}

*** Keywords ***
Open Connection
    [Arguments]    ${name}    ${ip}
    ${conn_id} =    SSHLibrary.Open Connection    ${ip}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    BuiltIn.Set Suite Variable    \${${name}}    ${conn_id}
    [Return]    ${conn_id}

Devstack Suite Setup
    [Arguments]    ${odl_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Open connections to the nodes
    DevstackUtils.Get DevStack Nodes Data
    RequestsLibrary.Create Session    session    http://${odl_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    SSHLibrary.Set Default Configuration    timeout=${DEFAULT_DEVSTACK_PROMPT_TIMEOUT}
    BuiltIn.Run Keyword If    0 < ${NUM_OS_SYSTEM}    DevstackUtils.Open Connection    OS_CNTL_CONN_ID    ${OS_CONTROL_NODE_IP}
    BuiltIn.Run Keyword If    1 < ${NUM_OS_SYSTEM}    DevstackUtils.Open Connection    OS_CMP1_CONN_ID    ${OS_COMPUTE_1_IP}
    BuiltIn.Run Keyword If    2 < ${NUM_OS_SYSTEM}    DevstackUtils.Open Connection    OS_CMP2_CONN_ID    ${OS_COMPUTE_2_IP}

Write Commands Until Prompt
    [Arguments]    ${cmd}    ${timeout}=${DEFAULT_DEVSTACK_PROMPT_TIMEOUT}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    SSHLibrary.Read
    SSHLibrary.Write    ${cmd};echo Command Returns $?
    ${output} =    SSHLibrary.Read Until Prompt
    [Return]    ${output}

Write Commands Until Prompt And Log
    [Arguments]    ${cmd}    ${timeout}=${DEFAULT_DEVSTACK_PROMPT_TIMEOUT}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    ${output} =    DevstackUtils.Write Commands Until Prompt    ${cmd}    ${timeout}
    BuiltIn.Log    ${output}
    [Return]    ${output}

Log Devstack Nodes Data
    ${output} =    BuiltIn.Catenate    SEPARATOR=\n    OS_CNTL_HOSTNAME: ${OS_CNTL_HOSTNAME} - OS_CNTL_IP: ${OS_CNTL_IP} - OS_CONTROL_NODE_IP: ${OS_CONTROL_NODE_IP}    OS_CMP1_HOSTNAME: ${OS_CMP1_HOSTNAME} - OS_CMP1_IP: ${OS_CMP1_IP} - OS_COMPUTE_1_IP: ${OS_COMPUTE_1_IP}    OS_CMP2_HOSTNAME: ${OS_CMP2_HOSTNAME} - OS_CMP2_IP: ${OS_CMP2_IP} - OS_COMPUTE_2_IP: ${OS_COMPUTE_2_IP}    OS_ALL_IPS: @{OS_ALL_IPS}
    ...    OS_CMP_IPS: @{OS_CMP_IPS}
    BuiltIn.Log    DevStack Nodes Data:\n${output}

Get DevStack Hostnames
    [Documentation]    Assign hostname global variables for DevStack nodes
    ${OS_CNTL_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CNTL_IP}
    ${OS_CMP1_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP1_IP}
    ${OS_CMP2_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_CMP1_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_CMP2_HOSTNAME}

Set Node Data For AllinOne Setup
    [Documentation]    Assign global variables for DevStack nodes where the Control Node enables Compute service also.
    BuiltIn.Set Suite Variable    @{OS_ALL_IPS}    ${OS_CNTL_IP}

Set Node Data For Control And Compute Node Setup
    [Documentation]    Assign global variables for DevStack nodes where the control node is also the compute
    BuiltIn.Set Suite Variable    ${OS_CMP1_IP}    ${OS_CNTL_IP}
    BuiltIn.Set Suite Variable    ${OS_CMP2_IP}    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    @{OS_ALL_IPS}    ${OS_CNTL_IP}    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    @{OS_CMP_IPS}    ${OS_CMP1_IP}    ${OS_CMP2_IP}

Set Node Data For Control Only Node Setup
    [Documentation]    Assign global variables for DevStack nodes where the control node is different than the compute
    BuiltIn.Set Suite Variable    ${OS_CMP1_IP}    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    ${OS_CMP2_IP}    ${OS_COMPUTE_2_IP}
    BuiltIn.Set Suite Variable    @{OS_ALL_IPS}    ${OS_CNTL_IP}    ${OS_CMP1_IP}    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    @{OS_CMP_IPS}    ${OS_CMP1_IP}    ${OS_CMP2_IP}

Set Node Data For 3 Control Nodes And 2 Compute Nodes Setup
    [Documentation]    Assign global variables for DevStack nodes where we have 3 control nodes and 2 compute nodes
    BuiltIn.Set Suite Variable    ${OS_CMP1_IP}    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    ${OS_CMP2_IP}    ${OS_COMPUTE_2_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_1_IP}    ${OS_CONTROL_NODE_1_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_2_IP}    ${OS_CONTROL_NODE_2_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_3_IP}    ${OS_CONTROL_NODE_3_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_IP}    ${OS_CONTROL_NODE_1_IP}
    BuiltIn.Set Suite Variable    @{OS_CMP_IPS}    ${OS_CMP1_IP}    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    @{OS_CNTL_IPS}    ${OS_CNTL_1_IP}    ${OS_CNTL_2_IP}    ${OS_CNTL_3_IP}
    BuiltIn.Set Suite Variable    @{OS_ALL_IPS}    @{OS_CNTL_IPS}    @{OS_CMP_IPS}

Get DevStack Nodes Data
    [Documentation]    Assign global variables for DevStack nodes
    BuiltIn.Set Suite Variable    ${OS_CNTL_IP}    ${OS_CONTROL_NODE_IP}
    BuiltIn.Run Keyword If    ${NUM_OS_SYSTEM} == 1    DevstackUtils.Set Node Data For AllinOne Setup
    ...    ELSE IF    ${NUM_OS_SYSTEM} == 2    DevstackUtils.Set Node Data For Control And Compute Node Setup
    ...    ELSE IF    ${NUM_OS_SYSTEM} == 3    DevstackUtils.Set Node Data For Control Only Node Setup
    ...    ELSE IF    ${NUM_OS_SYSTEM} == 5    DevstackUtils.Set Node Data For 3 Control Nodes And 2 Compute Nodes Setup
    DevstackUtils.Get DevStack Hostnames
    DevstackUtils.Log Devstack Nodes Data
