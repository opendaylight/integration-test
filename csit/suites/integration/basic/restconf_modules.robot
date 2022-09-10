*** Settings ***
Documentation       Test suite to verify Restconf is OK.

Library             RequestsLibrary
Resource            ${CURDIR}/../../../variables/Variables.robot

Suite Setup         RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown      RequestsLibrary.Delete_All_Sessions


*** Test Cases ***
Get Controller Modules
    [Documentation]    Get the restconf modules, check 200 status and ietf-restconf presence.
    ${resp} =    RequestsLibrary.Get_Request    session    ${MODULES_API}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain    ${resp.text}    ietf-restconf
