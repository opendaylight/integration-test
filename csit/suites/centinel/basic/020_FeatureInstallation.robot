*** Settings ***
Library             RequestsLibrary
Library             OperatingSystem
Library             String
Library             Collections
Library             DateTime
Resource            ../../../libraries/KarafKeywords.robot
Variables           ../../../variables/Variables.py

Suite Setup         Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Test Cases ***
Centinel Feature Installation
    Install a Feature    odl-centinel-all    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    120
    Verify Feature Is Installed    odl-centinel-all
    ${strings_to_verify}=    Create List    Stream handler provider initated
    Wait Until Keyword Succeeds
    ...    180s
    ...    1s
    ...    Check For Elements On Karaf Command Output Message
    ...    log:display | grep "Stream handler provider initated"
    ...    ${strings_to_verify}
