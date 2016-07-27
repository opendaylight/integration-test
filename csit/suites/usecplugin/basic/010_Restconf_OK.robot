*** Settings ***
Documentation     Test suite to verify Restconf is OK
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           String
Library           DateTime
Library           Process
Library           Collections
Library           OperatingSystem
Library           ../../../libraries/UtilLibrary.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/UtilsUsec.robot


*** Variables ***
${RESTCONF_MODULES_URI}    /restconf/modules


*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
     ${resp1} =  RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    session   ${RESTCONF_MODULES_URI}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf
   


