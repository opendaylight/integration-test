*** Settings ***
Documentation     Test suite to verify Apidocs is OK.
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${APIDOC_URL}     /apidoc/apis
${VAR_DIR}        ${CURDIR}/../../../variables/

*** Test Cases ***
Get Apidoc Apis
    [Documentation]    Get the Apidoc Apis list, check 200 status and apis string presence.
#    ${resp} =    RequestsLibrary.Get_Request    session    ${APIDOC_URL}
    ${resp} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/apidoc    session    ${APIDOC_URL}    verify=True
#    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain    ${resp.content}    apis
