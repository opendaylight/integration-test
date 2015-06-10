*** Settings ***
Documentation     Test suite for finding out max number of docker ovs switches
Suite Setup       Setup Docker Test Suite
Suite Teardown    Scalability Docker Suite Teardown
Library           OperatingSystem
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/OVSDBScalabilityDocker.robot

*** Variables ***
${MIN_SWITCHES}    100
${MAX_SWITCHES}    500
${STEP_SWITCHES}    100
${SWITCHES_RESULT_FILE}    switches.csv

*** Test Cases ***
Find Max Switches
    [Documentation]    Find max number of switches starting from ${MIN_SWITCHES} till reaching ${MAX_SWITCHES} in steps of ${STEP_SWITCHES}
    [Tags]    Southbound
    Append To File    ${SWITCHES_RESULT_FILE}    Max Switches Docker\n
    ${max-switches}    Find Max Ovsdb Switches    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${max-switches}
    Append To File    ${SWITCHES_RESULT_FILE}    ${max-switches}\n