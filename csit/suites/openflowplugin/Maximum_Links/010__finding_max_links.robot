*** Settings ***
Documentation     Test suite for finding out max number of Links
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${MIN_SWITCHES}    8
${MAX_SWITCHES}    128
${STEP_SWITCHES}    8
${LINKS_RESULT_FILE}    links.csv

*** Test Cases ***
Find Max Switch Links
    [Documentation]    Find max number of Links supported. Fully mesh topology starting from
    ...    ${MIN_SWITCHES} switches till ${MAX_SWITCHES} switches will be attempted in steps of ${STEP_SWITCHES}
    Append To File    ${LINKS_RESULT_FILE}    Max Links \n
    ${max_links}    Find Max Links    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${error_message}
    Log    ${max_links}
    Append To File    ${LINKS_RESULT_FILE}    ${max_links}\n
