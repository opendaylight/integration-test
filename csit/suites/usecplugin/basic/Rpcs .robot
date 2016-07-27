*** Settings ***
Documentation     Test suite for RPC
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${FILE_ID}        ${CURDIR}/../../../variables/xmls/f1UsecID.json
${FILE_FromIP}    ${CURDIR}/../../../variables/xmls/f1UsecFromIP.json
${FILE_ToIP}      ${CURDIR}/../../../variables/xmls/f1UsecToIP.json

*** Test Cases ***

Checking Attack Info(attackID)
    [Documentation]    Post a value through REST-API
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${FILE_ID}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON_ID}    headers=${HEADERS}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Checking Attack Info(attacksFromIP)
    [Documentation]    Post a value through REST-API
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${FILE_FromIP}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON_FromIP}    headers=${HEADERS}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Checking Attack Info(attacksToIP)
    [Documentation]    Post a value through REST-API
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${FILE_ToIP}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON_ToIP}    headers=${HEADERS}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
