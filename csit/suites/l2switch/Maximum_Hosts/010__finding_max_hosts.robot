*** Settings ***
Documentation     Test suite for finding out max number of switches
Suite Setup       Workflow Setup
Suite Teardown    Workflow Teardown
Library           OperatingSystem
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/WorkflowsL2switch.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${MIN_HOSTS}      100
${MAX_HOSTS}      2000
${STEP_HOSTS}     100
${HOSTS_RESULT_FILE}    hosts.csv

*** Test Cases ***
Find Max Supported Hosts
    [Documentation]    Find max number of hosts starting from ${MIN_HOSTS} till reaching ${MAX_HOSTS} in steps of ${STEP_HOSTS}
    ${error_message}=    Set Variable    Fail initializing suite
    ${maximum_hosts}=    Set Variable    ${0}
    ${discover_time}=    Set Variable    0
    ${start}=    Convert to Integer    ${MIN_HOSTS}
    ${stop}=    Convert to Integer    ${MAX_HOSTS}
    ${step}=    Convert to Integer    ${STEP_HOSTS}
    : FOR    ${hosts}    IN RANGE    ${start}    ${stop+1}    ${step}
    \    ${status}    ${error_message}    ${host_discover_time}    WorkflowsL2switch.Workflow Single Switch Multiple Hosts    ${hosts}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${maximum_hosts}=    Set variable    ${hosts}
    \    ${discover_time}=    Set Variable    ${host_discover_time}
    Log to console    ${\n}
    Log To Console    Execution stopped because: ${error_message}
    Log To Console    Max Hosts: ${maximum_hosts}
    OperatingSystem.Append To File    ${HOSTS_RESULT_FILE}    Max Hosts\n
    OperatingSystem.Append To File    ${HOSTS_RESULT_FILE}    ${maximum_hosts}\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    Discover Time\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    ${discover_time}\n
