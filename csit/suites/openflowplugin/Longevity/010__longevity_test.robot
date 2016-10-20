*** Settings ***
Documentation     Beta Version of the Longevity Test. Currently it does a single test:
...               1. runs one iteration of the link scale test based on ${NUM_SWITCHES}
...               Step 1 runs in a psuedo infinite loop and before each loop is
...               run, a time check is made against the ${TEST_LENGTH}. If the test duration
...               has expired, the loop is exited and the test is marked PASS
Suite Setup       Workflow Setup
Suite Teardown    Workflow Teardown
Library           DateTime
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/WorkflowsOpenFlow.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${NUM_SWITCHES}    36
${SUSTAIN_TIME}    60s
${TEST_LENGTH}    2h

*** Test Cases ***
Longevity Test
    [Documentation]    Uses OpenFlow Full Mesh Topology workflow in a loop for given period of time ${TEST_LENGTH}
    ${error_message}=    Set Variable    Fail initializing suite
    ${switches}=    Convert to Integer    ${NUM_SWITCHES}
    ${max_duration}=    DateTime.Convert Time    ${TEST_LENGTH}    number
    ${start_time}=    DateTime.Get Current Date
    #    This loop is not infinite, so going "sufficiently large" for now.
    : FOR    ${i}    IN RANGE    1    65536
    \    ${status}    ${error_message}    ${topology_discover_time}    WorkflowsOpenFlow.Workflow Full Mesh Topology    ${switches}    ${SUSTAIN_TIME}
    \    ${current_time}=    DateTime.Get Current Date
    \    ${duration}=    DateTime.Subtract Date From Date    ${current_time}    ${start_time}    number
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Exit For Loop If    ${duration} > ${max_duration}
    ${duration_compact}=    DateTime.Convert Time    ${duration}    compact
    Log to console    ${\n}
    Log To Console    Execution stopped because: ${error_message}
    Log To Console    Test executed for ${duration_compact} seconds
    Run Keyword If    '${status}' == 'FAIL'    Fail    ${error_message}
