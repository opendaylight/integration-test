*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${GBP_TENANTS_FILE}  ../../../variables/gbp/tenants.json

${GBP_TENENT_ID}     f5c7d344-d1c7-4208-8531-2c2693657e12
${GBP_TENANT1_API}    /restconf/config/policy:tenants/policy:tenant/${GBP_TENENT_ID}
${GBP_TENANT1_FILE}  ../../../variables/gbp/tenant1.json


*** Test Cases ***
Add Tenants
    [Documentation]    Add Tenants from JSON file
    Add Elements To URI From File    ${GBP_TENANTS_API}    ${GBP_TENANTS_FILE}
    ${body}    OperatingSystem.Get File    ${GBP_TENANTS_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANTS_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${jsonbody}    ${result}

Delete All Tenants
    [Documentation]    Delete all Tenants
    Add Elements To URI From File    ${GBP_TENANTS_API}    ${GBP_TENANTS_FILE}
    ${body}    OperatingSystem.Get File    ${GBP_TENANTS_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANTS_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${GBP_TENANTS_API}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANTS_API}
    Should Be Equal As Strings    ${resp.status_code}    404

Add one Tenant
    [Documentation]    Add one Tenant from JSON file
    Add Elements To URI From File    ${GBP_TENANT1_API}    ${GBP_TENANT1_FILE}
    ${body}    OperatingSystem.Get File    ${GBP_TENANT1_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANT1_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Get A Non-existing Tenant
    [Documentation]    Get A Non-existing Tenant
    Remove All Elements At URI    ${GBP_TENANTS_API}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANT1_API}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete one Tenant
    [Documentation]    Delete one Tenant
    Remove All Elements At URI    ${GBP_TENANTS_API}
    Add Elements To URI From File    ${GBP_TENANT1_API}    ${GBP_TENANT1_FILE}
    Remove All Elements At URI    ${GBP_TENANT1_API}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TENANTS_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    ${GBP_TENENT_ID}

Clean Datastore After Tests
    [Documentation]    Clean All Tenants In Datastore After Tests
    Remove All Elements At URI    ${GBP_TENANTS_API}
