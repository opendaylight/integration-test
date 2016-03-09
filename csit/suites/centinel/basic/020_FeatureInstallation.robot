*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Library           Collections
Library           DateTime
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Centinel Feature Installation
    Install a Feature    odl-centinel-all    ${CONTROLLER}    ${KARAF_SHELL_PORT}    60
    Verify Feature Is Installed    odl-centinel-all
    Wait Until Keyword Succeeds    120s    1s    Verify the Keyword?    log:display | grep "Stream handler provider initated"    Stream handler provider initated

*** Keywords ***
Verify the Keyword?
    [Arguments]    ${centinel_cmd}    ${keyword}    ${remote}=${ODL_SYSTEM_IP}    ${prompt_timeout}=120s
    [Documentation]    Verify the ${centinel_cmd} output contains ${keyword}
    ${output}=    Issue Command On Karaf Console    ${centinel_cmd}    ${remote}    ${KARAF_SHELL_PORT}    ${prompt_timeout}
    Should Contain    ${output}    ${keyword}
