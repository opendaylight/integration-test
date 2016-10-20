*** Settings ***
Documentation     Test suite for finding out max number of Links
Suite Setup       Workflow Setup
Suite Teardown    Workflow Teardown
Library           OperatingSystem
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/WorkflowsOpenFlow.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
@{SWITCH_LIST}    ${16}    ${32}    ${40}    ${48}    ${52}    ${56}    ${60}
...               ${64}
${LINKS_RESULT_FILE}    links.csv
${TIME_RESULT_FILE}    time.csv

*** Test Cases ***
Find Max Links
    [Documentation]    Find max number of Links supported. Fully mesh topology starting from
    ...    ${MIN_SWITCHES} switches till ${MAX_SWITCHES} switches will be attempted in steps of ${STEP_SWITCHES}
    ${max_links}=    Set Variable    ${0}
    : FOR    ${switches}    IN    @{SWITCH_LIST}
    \    ${status}    ${error_message}    ${topology_discover_time}    WorkflowsOpenFlow.Workflow Full Mesh Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max_links}=    Evaluate    ${switches} * ${switches-1}
    Log to console    ${\n}
    Log To Console    Execution stopped because: ${error_message}
    Log To Console    Max Links: ${max_links}
    OperatingSystem.Append To File    ${LINKS_RESULT_FILE}    Max Links\n
    OperatingSystem.Append To File    ${LINKS_RESULT_FILE}    ${max_links}\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    Discover Time\n
    OperatingSystem.Append To File    ${TIME_RESULT_FILE}    ${topology_discover_time}\n
