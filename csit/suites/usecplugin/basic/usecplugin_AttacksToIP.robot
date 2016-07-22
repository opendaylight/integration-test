*** Settings ***
Documentation     Test suite for Attack Info.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CON}      /restconf/operations/usecplugin:attacksToIP
${FILE}           ${CURDIR}/../../../variables/xmls/f1UsecToIP.json

*** Test Cases ***
Checking Attack Info(attacksToIP)#
    [Documentation]    Post a value through REST-API
    [Tags]    Post
    ${body}    OperatingSystem.Get File    ${FILE}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}    headers=${HEADERS}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

