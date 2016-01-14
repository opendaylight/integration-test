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
${PREDEFINE_ROLE_FILE}        ${CURDIR}/../../../variables/nemo/predefine/role.json

*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Add Pre-define Role
    [Documentation]    Add Pre-define Role
    [Tags]    Put
    ${body}    OperatingSystem.Get File   ${PREDEFINE_ROLE_FILE}
    ${resp}    RequestsLibrary.Put    session    ${PREDEFINE_ROLE_URI}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
