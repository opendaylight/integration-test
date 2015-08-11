*** Settings ***
Documentation     Test suite for finding out max number of Links
Suite Setup       Link Scale Suite Setup
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${MIN_SWITCHES}    10
${MAX_SWITCHES}    200
${STEP_SWITCHES}    5
${LINKS_RESULT_FILE}    links.csv


*** Test Cases ***
Find Max Switch Links
    [Documentation]    Find max number of Links supported. Fully mesh topology starting from
    ...     ${MIN_SWITCHES} switches till ${MAX_SWITCHES} switches will be attempted in steps of ${STEP_SWITCHES}
    Append To File    ${LINKS_RESULT_FILE}    Max Links \n
    ${max-links}    Find Max Links    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${max-links}
    Append To File    ${LINKS_RESULT_FILE}    ${max-links}\n

*** Keywords ***
Link Scale Suite Setup
    [Documentation]    Do initial steps for link scale tests
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${mininet_conn_id}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log     Copying ${CREATE_FULLYMESH_TOPOLOGY_FILE_PATH} file to Mininet VM
    Put File  ${CURDIR}/../../../${CREATE_FULLYMESH_TOPOLOGY_FILE_PATH}
    Close Connection