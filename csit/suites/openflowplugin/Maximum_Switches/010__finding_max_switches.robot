*** Settings ***
Documentation     Test suite for finding out max number of switches
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${MIN_SWITCHES}    100
${MAX_SWITCHES}    500
${STEP_SWITCHES}    100
${SWITCHES_RESULT_FILE}    switches.csv

*** Test Cases ***
Find Max Switches
    [Documentation]    Find max number of switches starting from ${MIN_SWITCHES} till reaching ${MAX_SWITCHES} in steps of ${STEP_SWITCHES}
    Append To File    ${SWITCHES_RESULT_FILE}    Max Switches Linear Topo\n
    ${max-switches}    Find Max Switches    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${max-switches}
    Append To File    ${SWITCHES_RESULT_FILE}    ${max-switches}\n

