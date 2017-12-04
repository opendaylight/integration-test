*** Settings ***
Documentation     Test suite to verify Apidocs is OK.
Suite Setup       TemplatedRequests.Create_Default_Session    timeout=30
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${VAR_DIR}        ${CURDIR}/../../../variables/

*** Test Cases ***
Get Apidoc Apis
    [Documentation]    Get the Apidoc Apis list, check 200 status and apis string presence.
    ${resp} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/apidoc/apis
    BuiltIn.Should_Contain    ${resp}    apis
