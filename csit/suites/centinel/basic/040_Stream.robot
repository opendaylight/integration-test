*** Settings ***
Library             RequestsLibrary
Library             Collections
Library             json
Library             String
Library             OperatingSystem
Resource            ../../../libraries/KarafKeywords.robot
Variables           ../../../variables/Variables.py

Suite Setup         Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Variables ***
${SET_STREAMRECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_streamRecord.json


*** Test Cases ***
Set StreamRecord
    ${body}    OperatingSystem.Get File    ${SET_STREAMRECORD_JSON}
    ${resp}    RequestsLibrary.Post Request    session    ${SET_STREAMRECORD}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get StreamRecordConfig
    ${resp}    RequestsLibrary.GET On Session    session    ${STREAMRECORD_CONFIG}    expected_status=200
    Log    ${resp.content}

Delete StreamRecord
    ${delresp}    RequestsLibrary.Delete Request    session    ${STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${delresp.status_code}    200
