*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

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
