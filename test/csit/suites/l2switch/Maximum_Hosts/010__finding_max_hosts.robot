*** Settings ***
Documentation     Test suite for finding out max number of switches
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Scalability.txt

*** Variables ***
${MIN_HOSTS}    100
${MAX_HOSTS}    2000
${STEP_HOSTS}    100
${HOSTS_RESULT_FILE}    hosts.csv

*** Test Cases ***
Find Max Supported Hosts
    [Documentation]    Find max number of hosts starting from ${MIN_HOSTS} till reaching ${MAX_HOSTS} in steps of ${STEP_HOSTS}
    Append To File    ${HOSTS_RESULT_FILE}    Max Hosts. All hosts connected to a single switch\n
    ${max-hosts}    Find Max Hosts    ${MIN_HOSTS}    ${MAX_HOSTS}    ${STEP_HOSTS}
    Log    ${max-hosts}
    Append To File    ${HOSTS_RESULT_FILE}    ${max-hosts}\n

