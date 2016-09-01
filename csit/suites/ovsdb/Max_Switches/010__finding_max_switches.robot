*** Settings ***
Documentation     Test suite to find max number of OVSDB SB switches
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Scalability.robot


*** Variables ***
${MIN_SWITCHES}    200
${MAX_SWITCHES}    2000
${STEP_SWITCHES}    200
${SB_SWITCHES_RESULT_FILE}    sb_switches.csv
${NUM_TOOLS_SYSTEM}    1

*** Test Cases ***
Find Max Ovsdb Sb Switches
    [Documentation]    Find max OVSDB nodes from ${MIN_SWITCHES} to ${MAX_SWITCHES} in steps ${STEP_SWITCHES}
    Append To File    ${SB_SWITCHES_RESULT_FILE}    Max Ovsdb SB Switches Linear Topo\n
    ${max-switches}    Find Max Ovsdb Switches    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}    odl-ovsdb-southbound-impl-rest
    Log    ${max-switches}
    Append To File    ${SB_SWITCHES_RESULT_FILE}    ${max-switches}\n

