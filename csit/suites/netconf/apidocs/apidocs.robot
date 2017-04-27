*** Settings ***
Documentation     Test suite to verify Apidocs is OK.
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${VAR_DIR}        ${CURDIR}/../../../variables/

*** Test Cases ***
Get Apidoc Apis
    [Documentation]    Get the Apidoc Apis list, check 200 status and apis string presence.
    ${resp} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/apidoc/apis    session=session
    BuiltIn.Should_Contain    ${resp}    apis
    BuiltIn.Log    ${resp}
