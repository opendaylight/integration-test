*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SFC_API}        /restconf/config/service-function:service-functions

*** Test Cases ***
Add Service Functions To First Node
    [Documentation]    Add service functions from JSON file
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SFC_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SFC_API}    ${SFC_FUNCTIONS_FILE}    ${HEADERS_YANG_JSON}
    ${resp}    RequestsLibrary.Get Request    session    ${SFC_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Read Service Functions From Second Node
    Create Session    session    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SFC_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SFC_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Read Service Functions From Third Node
    Create Session    session    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SFC_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SFC_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

*** Keywords ***
Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

Init Suite
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SFC_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json
