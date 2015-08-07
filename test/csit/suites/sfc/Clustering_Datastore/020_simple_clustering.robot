*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Library           RequestsLibrary
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SFC_API}    /restconf/config/service-function:service-functions
${SFC_FUNCTIONS_FILE}  ../../../variables/sfc/service-functions.json


*** Test Cases ***
Add Service Functions To One Node
    [Documentation]    Add service functions from JSON file
    Create Session    session    ${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SFC_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SFC__API}    ${SFC_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SFC_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Read Service Functions From Other Node
    Create Session    session    ${CONTROLLER1}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${SFC_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SFC_API}
    Should Be Equal As Strings    ${resp.status_code}   200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

*** Keywords ***
Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}
