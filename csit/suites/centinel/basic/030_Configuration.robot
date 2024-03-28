*** Settings ***
Library             RequestsLibrary
Library             OperatingSystem
Resource            ../../../libraries/KarafKeywords.robot
Variables           ../../../variables/Variables.py
Resource            ../../../libraries/Utils.robot

Suite Setup         Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Variables ***
${SET_CONFIGURATION}    ${CURDIR}/../../../variables/centinel/set_configuration.json


*** Test Cases ***
Set Configurations
    ${body}    OperatingSystem.Get File    ${SET_CONFIGURATION}
    ${resp}    RequestsLibrary.Post Request    session    ${SET_CONFIGURATION_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Configurations
    ${resp}    RequestsLibrary.GET On Session    session    ${GET_CONFIGURATION_URI}    expected_status=200
    Log    ${resp.content}
