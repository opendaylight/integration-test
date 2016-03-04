*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../../../variables/Variables.py

*** Variables ***
${SET_CONFIGURATION_URI}    restconf/operations/configuration:set-centinel-configurations
${SET_CONFIGURATION}    ../../../variables/centinel/set_configuration.json
${GET_CONFIGURATION_URI}    restconf/operational/configuration:configurationRecord/

*** Test Cases ***
Set Configurations
    ${body}    OperatingSystem.Get File    ${SET_CONFIGURATION}
    ${resp}    RequestsLibrary.Post    session    ${SET_CONFIGURATION_URI}    ${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Get Configurations
    ${resp}    RequestsLibrary.Get    session    ${GET_CONFIGURATION_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
