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
${SET_ALERTFIELDCONTENTRULERECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_alertFieldContentRuleRecord.json
${SET_ALERTFIELDVALUERULERECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_alertFieldValueRuleRecord.json
${SET_ALERTMESSAGECOUNTRULERECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_alertMessageCountRuleRecord.json

*** Test Cases ***
Set AlertFieldContentRuleRecord
    ${resp}    RequestsLibrary.Get Request    session    ${STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${streamRecord}    Get From Dictionary    ${result}    streamRecord
    ${streamList}    Get From Dictionary    ${streamRecord}    streamList
    ${stream}    Get From List    ${streamList}    0
    ${streamID}    Get From Dictionary    ${stream}    streamID
    ${body}    OperatingSystem.Get File    ${SET_ALERTFIELDCONTENTRULERECORD_JSON}
    ${str}    Replace String Using Regexp    ${body}    (streamId1)    ${streamID}
    ${response}    RequestsLibrary.Post Request    session    ${SET_ALERTFIELDCONTENTRULERECORD}    ${str}
    Should Be Equal As Strings    ${response.status_code}    200

Get AlertFieldContentRuleRecord
    ${resp}    RequestsLibrary.Get Request    session    ${ALERTFIELDCONTENTRULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete AlertFieldContentRuleRecord
    ${delresp}    RequestsLibrary.Get Request    session    ${ALERTFIELDCONTENTRULERECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200

Set AlertFieldValueRuleRecord
    ${resp}    RequestsLibrary.Get Request    session    ${STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${streamRecord}    Get From Dictionary    ${result}    streamRecord
    ${streamList}    Get From Dictionary    ${streamRecord}    streamList
    ${stream}    Get From List    ${streamList}    0
    ${streamID}    Get From Dictionary    ${stream}    streamID
    ${body}    OperatingSystem.Get File    ${SET_ALERTFIELDVALUERULERECORD_JSON}
    ${str}    Replace String Using Regexp    ${body}    (streamId2)    ${streamID}
    ${response}    RequestsLibrary.Post Request    session    ${SET_ALERTFIELDVALUERULERECORD}    ${str}
    Should Be Equal As Strings    ${response.status_code}    200

Get AlertFieldValueRuleRecord
    ${resp}    RequestsLibrary.Get Request    session    ${ALERTFIELDVALUERULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete AlertFieldValueRuleRecord
    ${delresp}    RequestsLibrary.Get Request    session    ${ALERTFIELDVALUERULERECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200

Set AlertMessageCountRuleRecord
    ${resp}    RequestsLibrary.Get Request    session    ${STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${streamRecord}    Get From Dictionary    ${result}    streamRecord
    ${streamList}    Get From Dictionary    ${streamRecord}    streamList
    ${stream}    Get From List    ${streamList}    0
    ${streamID}    Get From Dictionary    ${stream}    streamID
    ${body}    OperatingSystem.Get File    ${SET_ALERTMESSAGECOUNTRULERECORD_JSON}
    ${str}    Replace String Using Regexp    ${body}    (streamId3)    ${streamID}
    ${response}    RequestsLibrary.Post Request    session    ${SET_ALERTMESSAGECOUNTRULERECORD}    ${str}
    Should Be Equal As Strings    ${response.status_code}    200

Get AlertMessageCountRuleRecord
    ${resp}    RequestsLibrary.Get Request    session    ${ALERTMESSAGECOUNTRULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete AlertMessageCountRuleRecord
    ${delresp}    RequestsLibrary.Get Request    session    ${ALERTMESSAGECOUNTRULERECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200
