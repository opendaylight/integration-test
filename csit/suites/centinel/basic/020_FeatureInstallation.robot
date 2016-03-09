*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
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
