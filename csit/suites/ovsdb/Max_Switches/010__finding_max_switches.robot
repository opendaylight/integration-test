*** Settings ***
Documentation     Test suite to find max number of OVSDB SB switches
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${MIN_SWITCHES}    200
${MAX_SWITCHES}    1200
${STEP_SWITCHES}    200
${SB_SWITCHES_RESULT_FILE}    sb_switches.csv

*** Test Cases ***
Find Max Ovsdb Sb Switches
    [Documentation]    Find max switches from ${MIN_SWITCHES} to ${MAX_SWITCHES} in steps ${STEP_SWITCHES}
    Append To File    ${SB_SWITCHES_RESULT_FILE}    Max Ovsdb SB Switches Linear Topo\n
    ${max-switches}    Find Max Ovsdb Sb Switches    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${max-switches}
    Append To File    ${SB_SWITCHES_RESULT_FILE}    ${max-switches}\n
