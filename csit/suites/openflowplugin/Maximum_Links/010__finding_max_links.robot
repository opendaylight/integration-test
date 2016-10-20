*** Settings ***
Documentation     Test suite for finding out max number of Links
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Scalability Suite Teardown
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Scalability.robot
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${MIN_SWITCHES}    16
${MAX_SWITCHES}    64
${STEP_SWITCHES}    8
${LINKS_RESULT_FILE}    links.csv
${TIME_RESULT_FILE}    time.csv

*** Test Cases ***
Find Max Switch Links
    [Documentation]    Find max number of Links supported. Fully mesh topology starting from
    ...    ${MIN_SWITCHES} switches till ${MAX_SWITCHES} switches will be attempted in steps of ${STEP_SWITCHES}
    Wait Until Keyword Succeeds    3x    1s    KarafKeywords.Issue Command On Karaf Console    log:set ERROR
    ${max_links}    ${topology_discover_time}    ${error_message}    Find Max Links    ${MIN_SWITCHES}    ${MAX_SWITCHES}    ${STEP_SWITCHES}
    Log    ${error_message}
    Log    ${max_links}
    Append To File    ${LINKS_RESULT_FILE}    Max Links\n
    Append To File    ${LINKS_RESULT_FILE}    ${max_links}\n
    Append To File    ${TIME_RESULT_FILE}    Topology Discover Time\n
    Append To File    ${TIME_RESULT_FILE}    ${topology_discover_time}\n
