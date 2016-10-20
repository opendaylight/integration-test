*** Settings ***
Documentation     Test suite for finding out max number of switches
Suite Setup       Workflow Setup
Suite Teardown    Workflow Teardown
Library           OperatingSystem
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/WorkflowsOpenFlow.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${MIN_SWITCHES}    100
${MAX_SWITCHES}    800
${STEP_SWITCHES}    100
${SWITCHES_RESULT_FILE}    switches.csv
${TIME_RESULT_FILE}    time.csv

*** Test Cases ***
Find Max Switches
    [Documentation]    Find max number of switches starting from ${MIN_SWITCHES} till reaching ${MAX_SWITCHES} in steps of ${STEP_SWITCHES}
    ${error_message}=    Set Variable    Fail initializing suite
    ${maximum_switches}=    Set Variable    ${0}
    ${start}=    Convert to Integer    ${MIN_SWITCHES}
    ${stop}=    Convert to Integer    ${MAX_SWITCHES}
    ${step}=    Convert to Integer    ${STEP_SWITCHES}
    : FOR    ${switches}    IN RANGE    ${start}    ${stop+1}    ${step}
    \    ${status}    ${error_message}    ${topology_discover_time}    WorkflowsOpenFlow.Workflow Linear Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${maximum_switches}=    Set variable    ${switches}
    \    ${discover_time}=    Set Variable    ${topology_discover_time}
    Log to console    ${\n}
    Log To Console    Execution stopped because: ${error_message}
    Log To Console    Max Switches: ${maximum_switches}
    OperatingSystem.Append To File    ${SWITCHES_RESULT_FILE}    Max Switches\n
    OperatingSystem.Append To File    ${SWITCHES_RESULT_FILE}    ${maximum_switches}\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    Discover Time\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    ${discover_time}\n
