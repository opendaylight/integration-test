*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../variables/centinel/centinel_vars.robot

*** Variables ***
${SET_CONFIGURATION}    ${CURDIR}/../../../variables/centinel/set_configuration.json

*** Test Cases ***
Set Configurations
    ${body}    OperatingSystem.Get File    ${SET_CONFIGURATION}
    ${resp}    RequestsLibrary.Post Request    session    ${SET_CONFIGURATION_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Configurations
    ${resp}    RequestsLibrary.Get Request    session    ${GET_CONFIGURATION_URI}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
