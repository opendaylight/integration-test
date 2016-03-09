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
${SET_SUBSCRIBEUSER}    /restconf/operations/subscribe:subscribe-user
${SET_SUBSCRIBEUSER_JSON}    ${CURDIR}/../../../variables/centinel/set_subscribeUser.json
${GET_SUBSCRIPTION}    /restconf/config/subscribe:subscription/
${DELETE_SUBSCRIPTION}    /restconf/config/subscribe:subscription/

*** Test Cases ***
Set SubscribeUser
    ${body}    OperatingSystem.Get File    ${SET_SUBSCRIBEUSER_JSON}
    ${resp}    RequestsLibrary.Post Request    session    ${SET_SUBSCRIBEUSER}    ${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Subscription
    ${resp}    RequestsLibrary.Get Request    session    ${GET_SUBSCRIPTION}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Subscription
    ${delresp}    RequestsLibrary.Get Request    session    ${DELETE_SUBSCRIPTION}
    Should Be Equal As Strings    ${delresp.status_code}    200
