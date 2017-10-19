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
${INTENT_CONTEXT}    /restconf/config/intent-limiter:intents-limiter
${INTENT_STATE_CONTEXT}    /restconf/config/intent-state-transaction:intent-state-transactions
${METERS_POOL_CONTEXT}    /restconf/config/id-manager:id-pools/id-pool/meters/id-entries/ED1c03aC-6eBD-63be-44E3-5Bfdb09bfBF2
${DATA_FLOW_CONTEXT}    /restconf/config/dataflow:dataflows
${DELAY_CONFIGS_CONTEXT}    /restconf/config/delay-config:delay-configs

${INTENT_LIMITER_DATA}    ${CURDIR}/../../../variables/nic/intent-limiter.json
${INTENT_LIMITER_EXPECTED}    ${CURDIR}/../../../variables/nic/intent-limiter-expected-result.json
${INTENT_STATE_EXPECTED}    ${CURDIR}/../../../variables/nic/intent-state-expected-result.json
${METERS_POOL_ID_EXPECTED}    ${CURDIR}/../../../variables/nic/expected-meters-pool-id.json
${DATA_FLOW_EXPECTED}    ${CURDIR}/../../../variables/nic/intent-limiter-dataflow-expected.json


*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf

Post Add Intent
    [Documentation]    Add an Intent using RESTCONF
    ${body}     OperatingSystem.Get File    ${INTENT_LIMITER_DATA}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${INTENT_CONTEXT}    headers=${HEADERS_YANG_JSON}    data=${body}
    Log    ${resp.content}
    Sleep    5
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204

Get Intent Limiters
    [Documentation]    Retrieve Intents using RESTCONF
    ${expected}     OperatingSystem.Get File    ${INTENT_LIMITER_EXPECTED}
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${INTENT_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    '${resp.content}'    '${expected}'
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Be Empty    ${resp.content}

Get Meters Pool Ids
    [Documentation]    Retrieve the Meters Pool IDs
    ${expected}     OperatingSystem.Get File    ${METERS_POOL_ID_EXPECTED}
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${METERS_POOL_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Contain    '${resp.content}'    '${expected}'
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Be Empty    ${resp.content}

Get Intent Limiter Dataflow
    [Documentation]    Retrieve generated Intent Limiter Dataflow
    ${expected}     OperatingSystem.Get File    ${DATA_FLOW_EXPECTED}
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${DATA_FLOW_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Be Empty    ${resp.content}

Get Delay configs
    [Documentation]    Retrieve generated Intent Limiter Dataflow
    ${expected}     OperatingSystem.Get File    ${DATA_FLOW_EXPECTED}
    Set Suite Variable    ${expected}
    ${resp}    RequestsLibrary.Get Request    session    ${DATA_FLOW_CONTEXT}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Not Be Empty    ${resp.content}

#Get Intent Limiter state
#    [Documentation]    Retrieve Intent Limiter state
#    ${expected}     OperatingSystem.Get File    ${INTENT_STATE_EXPECTED}
#    Set Suite Variable    ${expected}
#    ${resp}    RequestsLibrary.Get Request    session    ${INTENT_STATE_CONTEXT}    headers=${HEADERS_YANG_JSON}
#    Log    ${resp.content}
#    Should Contain    '${resp.content}'    '${expected}'

Remove Intent Limiter
    [Documentation]    Remove Intent Limiter
    ${resp}    RequestsLibrary.Delete Request    session    ${INTENT_CONTEXT}    headers=${HEADERS_YANG_JSON}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200