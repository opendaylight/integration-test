*** Settings ***
Documentation     Test suite to verify Restconf is OK for NetIDE.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py

*** Variables ***
${MODULES_API}    /restconf/modules

*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
    ${resp}    RequestsLibrary.Get    session    ${MODULES_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf
