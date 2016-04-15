*** Settings ***
Documentation     Test suite to find max number of OVSDB Netvirt switches
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${MIN_SWITCHES}    150
${MAX_SWITCHES}    1800
${STEP_SWITCHES}    150
${NV_SWITCHES_RESULT_FILE}    nv_switches.csv

*** Test Cases ***
Find Max Ovsdb Netvirt Switches
    [Documentation]    Find max switches from ${MIN_SWITCHES} to ${MAX_SWITCHES} in steps ${STEP_SWITCHES}
    Append To File    ${NV_SWITCHES_RESULT_FILE}    Max Ovsdb NetVirt Switches Linear Topo\n
    ${max-switches}    Find Max Ovsdb Netvirt Switches    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${max-switches}
    Append To File    ${NV_SWITCHES_RESULT_FILE}    ${max-switches}\n
