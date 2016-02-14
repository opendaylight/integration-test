*** Settings ***
Documentation     Test suite for nemo engine functionality
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REGISTER_TENANT_FILE}    ${CURDIR}/../../../variables/nemo/register-user.json
${STRUCTURE_HOST_FILE}    ${CURDIR}/../../../variables/nemo/intent-node-host.json
${STRUCTURE_INTENT_FILE}    ${CURDIR}/../../../variables/nemo/structure-intent.json
${PREDEFINE_ROLE_FILE}    ${CURDIR}/../../../variables/nemo/predefine/role.json
${PREDEFINE_NODE_FILE}    ${CURDIR}/../../../variables/nemo/predefine/node.json
${PREDEFINE_CONNECTION_FILE}    ${CURDIR}/../../../variables/nemo/predefine/connection.json

*** Test Cases ***
Add Pre-define Role
    [Documentation]    Add Pre-define Role
    [Tags]    Put
    ${body}    OperatingSystem.Get File    ${PREDEFINE_ROLE_FILE}
    ${resp}    RequestsLibrary.Put Request    session    ${PREDEFINE_ROLE_URI}    data=${body}    headers=${HEADERS_YANG_JSON}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Pre-define Node
    [Documentation]    Add Pre-define Node
    [Tags]    Put
    ${body}    OperatingSystem.Get File    ${PREDEFINE_NODE_FILE}
    ${resp}    RequestsLibrary.Put Request    session    ${PREDEFINE_NODE_URI}    data=${body}    headers=${HEADERS_YANG_JSON}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Pre-define Connection
    [Documentation]    Add Pre-define Connection
    [Tags]    Put
    ${body}    OperatingSystem.Get File    ${PREDEFINE_CONNECTION_FILE}
    ${resp}    RequestsLibrary.Put Request    session    ${PREDEFINE_CONNECTION_URI}    data=${body}    headers=${HEADERS_YANG_JSON}
    Should Be Equal As Strings    ${resp.status_code}    200

Register Tenant
    [Documentation]    Register Tenant
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${REGISTER_TENANT_FILE}
    ${resp}    RequestsLibrary.Post Request    session    ${REGISTER_TENANT_URI}    data=${body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Host Intent
    [Documentation]    Add Host Intent
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${STRUCTURE_HOST_FILE}
    ${resp}    RequestsLibrary.Post Request    session    ${STRUCTURE_INTENT_URI}    data=${body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Structure Intent
    [Documentation]    Add Structure Intent
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${STRUCTURE_INTENT_FILE}
    ${resp}    RequestsLibrary.Post Request    session    ${STRUCTURE_INTENT_URI}    data=${body}    headers=${HEADERS_YANG_JSON}
    Should Be Equal As Strings    ${resp.status_code}    200
