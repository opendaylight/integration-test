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
${GET_STREAMRECORD_CONFIG}    /restconf/config/stream:streamRecord/
${GET_ALERTFIELDCONTENTRULERECORD}    /restconf/config/alertrule:alertFieldContentRuleRecord
${SET_ALERTFIELDCONTENTRULERECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_alertFieldContentRuleRecord.json
${SET_ALERTFIELDCONTENTRULERECORD}    /restconf/operations/alertrule:set-alert-field-content-rule
${DELETE_ALERTFIELDCONTENTRULERECORD}    /restconf/config/alertrule:alertFieldContentRuleRecord/
${GET_ALERTFIELDVALUERULERECORD}    /restconf/config/alertrule:alertFieldValueRuleRecord
${SET_ALERTFIELDVALUERULERECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_alertFieldValueRuleRecord.json
${SET_ALERTFIELDVALUERULERECORD}    /restconf/operations/alertrule:set-alert-field-value-rule
${DELETE_ALERTFIELDVALUERULERECORD}    /restconf/config/alertrule:alertFieldValueRuleRecord/
${GET_ALERTMESSAGECOUNTRULERECORD}    /restconf/config/alertrule:alertMessageCountRuleRecord
${SET_ALERTMESSAGECOUNTRULERECORD_JSON}    ${CURDIR}/../../../variables/centinel/set_alertMessageCountRuleRecord.json
${SET_ALERTMESSAGECOUNTRULERECORD}    /restconf/operations/alertrule:set-alert-message-count-rule
${DELETE_ALERTMESSAGECOUNTRULERECORD}    /restconf/config/alertrule:alertMessageCountRuleRecord/

*** Test Cases ***
Set AlertFieldContentRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${streamRecord}    Get From Dictionary    ${result}    streamRecord
    ${streamList}    Get From Dictionary    ${streamRecord}    streamList
    ${stream}    Get From List    ${streamList}    0
    ${streamID}    Get From Dictionary    ${stream}    streamID
    ${body}    OperatingSystem.Get File    ${SET_ALERTFIELDCONTENTRULERECORD_JSON}
    ${str}    Replace String Using Regexp    ${body}    (streamId1)    ${streamID}
    ${response}    RequestsLibrary.Post    session    ${SET_ALERTFIELDCONTENTRULERECORD}    ${str}
    Should Be Equal As Strings    ${response.status_code}    200

Get AlertFieldContentRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_ALERTFIELDCONTENTRULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete AlertFieldContentRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_ALERTFIELDCONTENTRULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${delresp}    RequestsLibrary.Get    session    ${DELETE_ALERTFIELDCONTENTRULERECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200

Set AlertFieldValueRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${streamRecord}    Get From Dictionary    ${result}    streamRecord
    ${streamList}    Get From Dictionary    ${streamRecord}    streamList
    ${stream}    Get From List    ${streamList}    0
    ${streamID}    Get From Dictionary    ${stream}    streamID
    ${body}    OperatingSystem.Get File    ${SET_ALERTFIELDVALUERULERECORD_JSON}
    ${str}    Replace String Using Regexp    ${body}    (streamId2)    ${streamID}
    ${response}    RequestsLibrary.Post    session    ${SET_ALERTFIELDVALUERULERECORD}    ${str}
    Should Be Equal As Strings    ${response.status_code}    200

Get AlertFieldValueRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_ALERTFIELDVALUERULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete AlertFieldValueRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_ALERTFIELDVALUERULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${delresp}    RequestsLibrary.Get    session    ${DELETE_ALERTFIELDVALUERULERECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200

Set AlertMessageCountRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_STREAMRECORD_CONFIG}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${streamRecord}    Get From Dictionary    ${result}    streamRecord
    ${streamList}    Get From Dictionary    ${streamRecord}    streamList
    ${stream}    Get From List    ${streamList}    0
    ${streamID}    Get From Dictionary    ${stream}    streamID
    ${body}    OperatingSystem.Get File    ${SET_ALERTMESSAGECOUNTRULERECORD_JSON}
    ${str}    Replace String Using Regexp    ${body}    (streamId3)    ${streamID}
    ${response}    RequestsLibrary.Post    session    ${SET_ALERTMESSAGECOUNTRULERECORD}    ${str}
    Should Be Equal As Strings    ${response.status_code}    200

Get AlertMessageCountRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_ALERTMESSAGECOUNTRULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete AlertMessageCountRuleRecord
    ${resp}    RequestsLibrary.Get    session    ${GET_ALERTMESSAGECOUNTRULERECORD}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    ${delresp}    RequestsLibrary.Get    session    ${DELETE_ALERTMESSAGECOUNTRULERECORD}
    Should Be Equal As Strings    ${delresp.status_code}    200
