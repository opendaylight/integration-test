*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${GBP_TENENT_ID}    f5c7d344-d1c7-4208-8531-2c2693657e12
${GBP_TENANT1_API}    /restconf/config/policy:tenants/tenant/${GBP_TENENT_ID}
${GBP_TENANT1_FILE}    ${CURDIR}/../../../variables/gbp/tenant1.json

*** Test Cases ***
Add Tenant to one node
    [Documentation]    Add one Tenant from JSON file
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${GBP_TENANT1_FILE}
    Add Elements To URI From File    ${GBP_TENANT1_API}    ${GBP_TENANT1_FILE}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANT1_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Read Tenant from other node
    Create Session    session    http://${CONTROLLER1}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${GBP_TENANT1_FILE}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANT1_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

*** Keywords ***
Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}
