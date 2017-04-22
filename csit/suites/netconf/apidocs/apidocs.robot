*** Settings ***
Documentation     Test suite to verify Apidocs is OK.
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
${APIDOC_URL}     /apidoc/apis

*** Test Cases ***
Get Apidoc Apis
    [Documentation]    Get the Apidoc Apis list, check 200 status and apis string presence.
    ${resp} =    RequestsLibrary.Get_Request    session    ${APIDOC_URL}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain    ${resp.content}    apis
