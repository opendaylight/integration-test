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
    ${centinel_cmd}=    set variable    log:display | grep "Stream handler provider initated"
    ${metric}=    set variable    Stream handler provider initated
    ${output}=    Issue Command On Karaf Console    ${centinel_cmd}    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    120s
    Should Contain    ${output}    ${metric}
