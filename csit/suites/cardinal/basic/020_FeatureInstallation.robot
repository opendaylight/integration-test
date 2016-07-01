*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           String
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Centinel Feature Installation
    Install a Feature    odl-cardinal    ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    120
    Verify Feature Is Installed    odl-cardinal
    ${strings_to_verify}=    Create List    CardinalProvider Session Initiated
    Wait Until Keyword Succeeds    180s    1s    Check For Elements On Karaf Command Output Message    log:display | grep "CardinalProvider Session Initiated"    ${strings_to_verify}
