*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Init Variables
    [Documentation]    Initialize ODL version specific variables
    log    ${ODL_VERSION}
    Run Keyword If    '${ODL_VERSION}' == 'stable-lithium'    Init Variables Lithium
    ...    ELSE    Init Variables Master

Add Tenant to one node
    [Documentation]    Add one Tenant from JSON file
    Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${GBP_TENANT1_FILE}
    Add Elements To URI From File    ${GBP_TENANT1_API}    ${GBP_TENANT1_FILE}    headers=${HEADERS_YANG_JSON}
    ${resp}    RequestsLibrary.Get Request    session    ${GBP_TENANT1_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Read Tenant from other node
    Create Session    session    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${jsonbody}    Read JSON From File    ${GBP_TENANT1_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${GBP_TENANT1_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

*** Keywords ***
Read JSON From File
    [Arguments]    ${filepath}
    ${body}    OperatingSystem.Get File    ${filepath}
    ${jsonbody}    To Json    ${body}
    [Return]    ${jsonbody}

Init Variables Master
    [Documentation]    Sets variables specific to latest(master) version
    Set Suite Variable    ${GBP_TENANT_ID}    tenant-red
    Set Suite Variable    ${GBP_TENANT1_API}    /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}
    Set Suite Variable    ${GBP_TENANT1_FILE}    ${CURDIR}/../../../variables/gbp/master/tenant1.json

Init Variables Lithium
    [Documentation]    Sets variables specific to Lithium version
    Set Suite Variable    ${GBP_TENANT_ID}    f5c7d344-d1c7-4208-8531-2c2693657e12
    Set Suite Variable    ${GBP_TENANT1_API}    /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}
    Set Suite Variable    ${GBP_TENANT1_FILE}    ${CURDIR}/../../../variables/gbp/lithium/tenant1.json
