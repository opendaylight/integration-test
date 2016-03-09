*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           Collections
Library           json
Library           String
Library           OperatingSystem
Variables         ../../../variables/Variables.py

*** Variables ***
${GET_STREAMRECORD_CONFIG}    restconf/config/stream:streamRecord/
${SET_STREAMRECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_streamRecord.json
${SET_STREAMRECORD}    restconf/operations/stream:set-stream
${DELETE_STREAMRECORD}    restconf/config/stream:streamRecord/

*** Test Cases ***
Set StreamRecord
    ${body}    OperatingSystem.Get File    ${SET_STREAMRECORD_JSON}
    ${resp}    RequestsLibrary.Post    session    ${SET_STREAMRECORD}    ${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Get StreamRecordConfig
    ${resp}    RequestsLibrary.Get    session    ${GET_STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete StreamRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${delresp}    RequestsLibrary.Get    session    ${DELETE_STREAMRECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200

