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
${REGISTER_TENANT_FILE}     ${CURDIR}/../../../variables/nemo/register-user.json
${STRUCTURE_HOST_FILE}      ${CURDIR}/../../../variables/nemo/intent-node-host.json
${STRUCTURE_INTENT_FILE}      ${CURDIR}/../../../variables/nemo/structure-intent.json
${PREDEFINE_ROLE_FILE}        ${CURDIR}/../../../variables/nemo/predefine/role.json
${PREDEFINE_NODE_FILE}        ${CURDIR}/../../../variables/nemo/predefine/node.json
${PREDEFINE_CONNECTION_FILE}        ${CURDIR}/../../../variables/nemo/predefine/connection.json

*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Add Pre-define Role
    [Documentation]    Add Pre-define Role
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Add Elements To URI From File    ${PREDEFINE_ROLE_URI}     ${PREDEFINE_ROLE_FILE}
    ${resp}    RequestsLibrary.Get    session    ${SPREDEFINE_ROLE_URI}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Pre-define Node
    [Documentation]    Add Pre-define Role
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Add Elements To URI From File    ${PREDEFINE_NODE_URI}     ${PREDEFINE_NODE_FILE}
    ${resp}    RequestsLibrary.Get    session    ${PREDEFINE_NODE_URI}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Pre-define Connection
    [Documentation]    Add Pre-define Connection
    Add Elements To URI From File    ${PREDEFINE_CONNECTION_URI}     ${PREDEFINE_CONNECTION_FILE}
    ${body}    OperatingSystem.Get File    ${PREDEFINE_CONNECTION_FILE}
    ${jsonbody}     To Json      ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${PREDEFINE_CONNECTION_URI}    data=${jsonbody}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Register Tenant
    [Documentation]    Register Tenant
    Post Elements To URI From File    ${REGISTER_TENANT_URI}    ${REGISTER_TENANT_FILE}
    ${body}    OperatingSystem.Get File    ${REGISTER_TENANT_FILE}
    ${jsonbody}     To Json      ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${REGISTER_TENANT_URI}    data=${jsonbody}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Host Intent
    [Documentation]   Add Host Intent
    Post Elements To URI From File    ${STRUCTURE_INTENT_URI}    ${STRUCTURE_HOST_FILE}
    ${body}    OperatingSystem.Get File    ${STRUCTURE_HOST_FILE}
    ${jsonbody}     To Json      ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${STRUCTURE_INTENT_URI}    data=${jsonbody}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Structure Intent
    [Documentation]   Add Structure Intent
    Post Elements To URI From File    ${STRUCTURE_INTENT_URI}    ${STRUCTURE_INTENT_FILE}
    ${body}    OperatingSystem.Get File    ${STRUCTURE_INTENT_FILE}
    ${jsonbody}     To Json      ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${STRUCTURE_INTENT_URI}    data=${jsonbody}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Intents From DataStore
    [Documentation]   Get Intents From DataStore
    Run Keyword    REST Get List of Intents

Clean Datastore After Tests
    [Documentation]    Clean All Intents In Datastore After Tests
    Remove All Elements At URI    ${GET_INTENTS_URI}
    ${resp}    RequestsLibrary.Delete Request    session    ${GET_INTENTS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200

*** Keywords ***
REST Get List of Intents
    [Documentation]    Get the list of intents configured
    ${resp}    RequestsLibrary.Get    session    ${GET_INTENTS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "users"
    [Return]    ${resp.content}
