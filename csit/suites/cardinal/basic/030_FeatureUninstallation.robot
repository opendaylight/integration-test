*** Settings ***
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Resource          ../../../libraries/KarafKeywords.robot

*** Test Cases ***
Centinel Feature Uninstallation
    Uninstall a Feature    odl-cardinal
