*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           Collections
Library           json
Library           String
Library           OperatingSystem
Resource          ${CURDIR}/../../../variables/centinel/centinel_vars.robot

*** Variables ***
# TODO: Move this into centinel_vars.robot
${SET_SUBSCRIBEUSER_JSON}    ${CURDIR}/../../../variables/centinel/set_subscribeUser.json

*** Test Cases ***
Set SubscribeUser
    ${body}    OperatingSystem.Get File    ${SET_SUBSCRIBEUSER_JSON}
    ${resp}    RequestsLibrary.Post Request    session    ${SET_SUBSCRIBEUSER}    ${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Subscription
    ${resp}    RequestsLibrary.Get Request    session    ${SUBSCRIPTION}
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Subscription
    ${delresp}    RequestsLibrary.Delete Request    session    ${SUBSCRIPTION}
    Should Be Equal As Strings    ${delresp.status_code}    200
