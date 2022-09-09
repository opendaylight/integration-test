*** Settings ***
Library             RequestsLibrary
Library             OperatingSystem
Library             String
Library             Collections
Resource            ../../../libraries/KarafKeywords.robot
Variables           ../../../variables/Variables.py

Suite Setup         Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Test Cases ***
Centinel Feature Uninstallation
    Uninstall a Feature    odl-centinel-all
