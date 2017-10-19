*** Settings ***
Documentation     Test suite to verify Restconf is OK
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           Collections
Library           HttpLibrary.HTTP
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CONTEXT}    /restconf/modules
${INTENT_CONTEXT}    /restconf/config/intent:intents
${INTENT_STATE_CONTEXT}    /restconf/config/intent-state-transaction:intent-state-transactions
${INTENT01_BY_ID_CONTEXT}    /restconf/config/intent:intents/intent/bEeFBc8B-cbBB-7efc-7eac-efCd98AEAfAf
${INTENT02_BY_ID_CONTEXT}    /restconf/config/intent:intents/intent/080ea9fb-189f-497d-b6ac-912064ec6db8
${INTENT02_UPDATE_ENDPOINT_CONTEXT}    /restconf/config/intent:intents/intent/080ea9fb-189f-497d-b6ac-912064ec6db8/subjects/0


${INTENT_ALLOW}    ${CURDIR}/../../../variables/nic/basic-intent-allow.json
${INTENT_ALLOW_EXPECTED}    ${CURDIR}/../../../variables/nic/basic-intent-allow-expected.json
${INTENT_ALLOW_WITHOUT_SUBJECTS}     ${CURDIR}/../../../variables/nic/basic-intent-allow-without-subjects.json
${INTENT_ALLOW_WITHOUT_SUBJECTS_EXPETED}    ${CURDIR}/../../../variables/nic/basic-intent-allow-without-subjects-expected.json
${INTENT_ALLOW_ENDPOINT}    ${CURDIR}/../../../variables/nic/basic-intent-endpoint-group.json
${INTENT_ALLOW_ENDPOINT_EXPECTED}    ${CURDIR}/../../../variables/nic/basic-intent-after-update-endpoint-expected.json


*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Post Add Intent Allow
    [Documentation]    Add an Intent using RESTCONF
    ${body}     OperatingSystem.Get File    ${INTENT_ALLOW}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${INTENT_CONTEXT}    headers=${HEADERS_YANG_JSON}    data=${body}
    Sleep    5
    Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204

Get Retrieve Intent Allow
    [Documentation]    Retrieve Intents using RESTCONF
    ${expected}     OperatingSystem.Get File    ${INTENT_ALLOW_EXPECTED}
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${INTENT01_BY_ID_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    '${resp.content}'    '${expected}'
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Be Empty    ${resp.content}

Get Intent state
    [Documentation]    Retrieve Intent Limiter state
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${INTENT_STATE_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Be Empty    ${resp.content}

Remove Intent Allow
    [Documentation]    Remove Intent Allow
    ${resp}    RequestsLibrary.Delete Request    session    ${INTENT01_BY_ID_CONTEXT}    headers=${HEADERS_YANG_JSON}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Post Add Intent Allow without Subjects
    [Documentation]    Add an Intent using RESTCONF
    ${body}     OperatingSystem.Get File    ${INTENT_ALLOW_WITHOUT_SUBJECTS}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${INTENT_CONTEXT}    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Sleep    5
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204

Get Retrieve Intent Allow without Subjects
    [Documentation]    Retrieve Intents using RESTCONF
    ${expected}     OperatingSystem.Get File    ${INTENT_ALLOW_WITHOUT_SUBJECTS_EXPETED}
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${INTENT02_BY_ID_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    '${resp.content}'    '${expected}'
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Be Empty    ${resp.content}

Put Add Endpoint group to an existing Intent
    [Documentation]    Add an Intent using RESTCONF
    ${body}     OperatingSystem.Get File    ${INTENT_ALLOW_ENDPOINT}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${INTENT02_UPDATE_ENDPOINT_CONTEXT}    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Remove updated Intent
    [Documentation]    Remove Intent Limiter
    ${resp}    RequestsLibrary.Delete Request    session    ${INTENT02_BY_ID_CONTEXT}    headers=${HEADERS_YANG_JSON}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200