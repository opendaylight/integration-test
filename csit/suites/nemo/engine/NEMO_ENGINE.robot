*** Settings ***
Documentation     Test suite for nemo engine functionality
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CONTEXT}    /restconf/modules
${REGISTER_TENANT_URI}     /restconf/operations/nemo-intent:register-user/
${REGISTER_TENANT_FILE}     ${CURDIR}../../../variables/nemo/register-user.json
${PREDEFINE_ROLE_URI}      /restconf/config/nemo-user:user-roles/
${PREDEFINE_ROLE_FILE}        ${CURDIR}../../../variables/nemo/role.json


*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Add Pre-define Role
    [Documentation]    Add Pre-define Role
    Add Elements To URI From File    ${PREDEFINE_ROLE_URI}     ${PREDEFINE_ROLE_FILE}
    ${body}    OperatingSystem.Get File    ${PREDEFINE_ROLE_FILE}
    ${resp}    RequestsLibrary.Put Request    session    ${PPREDEFINE_ROLE_URI}    data=${body}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Register Tenant
    [Documentation]    Register Tenant
    Post Elements To URI From File    ${REGISTER_TENANT_URI}    ${REGISTER_TENANT_FILE}
    ${body}    OperatingSystem.Get File    ${REGISTER_TENANT_FILE}
    ${resp}    RequestsLibrary.Post Request    session    ${REGISTER_TENANT_URI}    data=${body}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
