*** Settings ***
Resource        ../../../libraries/KarafKeywords.robot

Suite Setup     Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}


*** Test Cases ***
Centinel Feature Uninstallation
    Uninstall a Feature    odl-cardinal
