*** Settings ***
Documentation     Test suite for finding out max number of switches
Suite Setup       Workflow Setup
Suite Teardown    Workflow Teardown
Library           OperatingSystem
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/WorkflowsL2switch.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${MIN_HOSTS}      50
${MAX_HOSTS}      1000
${STEP_HOSTS}     50
${HOSTS_RESULT_FILE}    hosts.csv
${TIME_RESULT_FILE}    time.csv

*** Test Cases ***
Find Max Supported Hosts
    [Documentation]    Find max number of hosts starting from ${MIN_HOSTS} till reaching ${MAX_HOSTS} in steps of ${STEP_HOSTS}
    ${error_message}=    BuiltIn.Set Variable    Fail initializing suite
    ${maximum_hosts}=    BuiltIn.Set Variable    ${0}
    ${discover_time}=    BuiltIn.Set Variable    0
    ${start}=    BuiltIn.Convert to Integer    ${MIN_HOSTS}
    ${stop}=    BuiltIn.Convert to Integer    ${MAX_HOSTS}
    ${step}=    BuiltIn.Convert to Integer    ${STEP_HOSTS}
    FOR    ${hosts}    IN RANGE    ${start}    ${stop+1}    ${step}
        ${status}    ${error_message}    ${host_discover_time}    WorkflowsL2switch.Workflow Single Switch Multiple Hosts    ${hosts}
        BuiltIn.Exit For Loop If    '${status}' == 'FAIL'
        ${maximum_hosts}=    BuiltIn.Set variable    ${hosts}
        ${discover_time}=    BuiltIn.Set Variable    ${host_discover_time}
    END
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log To Console    Execution stopped because: ${error_message}
    BuiltIn.Log To Console    Max Hosts: ${maximum_hosts}
    OperatingSystem.Append To File    ${HOSTS_RESULT_FILE}    Max Hosts\n
    OperatingSystem.Append To File    ${HOSTS_RESULT_FILE}    ${maximum_hosts}\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    Discover Time\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    ${discover_time}\n
