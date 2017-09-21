*** Settings ***
Documentation     Test suite to verify Restconf is OK
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           Collections
Library           HttpLibrary.HTTP
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CONTEXT}    /restconf/modules
${INTENT_CONTEXT}    /restconf/config/intent:intents
@{intent1_correct}    10.0.0.5    10.0.0.2,10.0.0.3    allow
@{intent2_correct}    10.0.0.5    10.0.0.2,10.0.0.10    block
@{intent3_correct}    10.0.0.1,10.0.0.4    10.0.0.2    allow
@{all_intents_correct}    ${intent1_correct}    ${intent2_correct}    ${intent3_correct}
@{intent1_bad}    10.0.0.3    10.0.0.22,10.0.0.33    allow
@{intent2_bad}    10.0.0.1    10.0.0.12,10.0.0.102    block
@{intent3_bad}    10.0.0.2,10.0.0.10    10.0.0.42    allow
@{all_intents_bad}    ${intent1_bad}    ${intent2_bad}    ${intent3_bad}
@{all_intents_ids}

*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

*** Keywords ***
REST Get List of Intents
    [Documentation]    Get the list of intents configured
    ${resp}    RequestsLibrary.Get Request    session    ${INTENT_CONTEXT}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "intents"
    [Return]    ${resp.content}

REST Get Intent From Id
    [Arguments]    ${id}
    [Documentation]    Get the intent detail from id
    ${resp}    RequestsLibrary.Get Request    session    ${INTENT_CONTEXT}/intent/${id}
    Log Json    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${id}
    [Return]    ${resp.content}

Generate Random UUID
    [Documentation]    Generates random UUID for use with creating intents on REST API. Has the format
    ...    (alphanumeric) 8-4-4-4-12.
    ${id1}=    Generate Random String    8    [NUMBERS]abcdef
    ${id2}=    Generate Random String    4    [NUMBERS]abcdef
    ${id3}=    Generate Random String    4    [NUMBERS]abcdef
    ${id4}=    Generate Random String    4    [NUMBERS]abcdef
    ${id5}=    Generate Random String    12    [NUMBERS]abcdef
    ${id}=    Catenate    SEPARATOR=-    ${id1}    ${id2}    ${id3}    ${id4}
    ...    ${id5}
    [Return]    ${id}

REST Add Intent
    [Arguments]    ${intent_from}    ${intent_to}    ${intent_permission}
    [Documentation]    Make an Intent and return the id of the new intent
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${id}=    Generate Random UUID
    ${data}=    Catenate    {"intent":{"id": "${id}","subjects":[{"order": 1,"end-point-group": {"name": "${intent_from}"}},{"order": 2,"end-point-group": { "name": "${intent_to}"}}],"actions": [{"order": 1,"${intent_permission}": {}}]}}
    ${resp}    RequestsLibrary.Post Request    session    ${INTENT_CONTEXT}    headers=${headers}    data=${data}
    Should Be Equal As Strings    ${resp.status_code}    204
    [Return]    ${id}

REST Update Intent By Id
    [Arguments]    ${id}    ${intent_from}    ${intent_to}    ${intent_permission}
    [Documentation]    Make an Intent and return the id of the new intent
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${data}=    Catenate    {"intent":{"id": "${id}","subjects":[{"order": 1,"end-point-group": {"name": "${intent_from}"}},{"order": 2,"end-point-group": { "name": "${intent_to}"}}],"actions": [{"order": 1,"${intent_permission}": {}}]}}
    ${resp}    RequestsLibrary.Put Request    session    ${INTENT_CONTEXT}/intent/${id}    headers=${headers}    data=${data}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp}

REST Delete All Intents
    [Documentation]    Delete all of the Intents
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${resp}    RequestsLibrary.Delete Request    session    ${INTENT_CONTEXT}    headers=${headers}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

REST Delete Intent By Id
    [Arguments]    ${id}
    [Documentation]    Delete Intent by Id
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${resp}    RequestsLibrary.Delete Request    session    ${INTENT_CONTEXT}/intent/${id}    headers=${headers}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}
