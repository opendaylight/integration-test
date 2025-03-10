*** Settings ***
Documentation       Test suite to verify Apidocs is OK.

Resource            ${CURDIR}/../../../libraries/CompareStream.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../../variables/Variables.robot

Suite Setup         TemplatedRequests.Create_Default_Session    timeout=30
Suite Teardown      RequestsLibrary.Delete_All_Sessions


*** Variables ***
${VAR_DIR}      ${CURDIR}/../../../variables/apidoc


*** Test Cases ***
Get Apidoc Apis
    [Documentation]    Get the Apidoc Apis list, check 200 status and apis string presence.
    CompareStream.Run_Keyword_If_Less_Than_Titanium
    ...    Skip_Netty_Test_Case    Skipping test: Not valid for Netty-based RESTCONF on ODL versions Scandium and earlier.
    ${path} =    CompareStream.Set_Variable_If_At_Least_Aluminium    openapi_18    apis
    ${path} =    CompareStream.Set_Variable_If_At_Least_Chlorine    openapi    ${path}
    ${path} =    CompareStream.Set_Variable_If_At_Least_Potassium    openapi_v3    ${path}
    ${resp} =    TemplatedRequests.Get_As_Json_Templated    folder=${VAR_DIR}/${path}    http_timeout=90
    BuiltIn.Should_Contain    ${resp}    api


*** Keywords ***
Skip_Netty_Test_Case
    [Documentation]    Skip test case, which is not applicable for netty implementation of restconf.
    [Arguments]    ${message}
    BuiltIn.Run_Keyword_If    "${RESTCONF_ROOT}" == "/restconf"
    ...    BuiltIn.Pass_Execution
    ...    ${message}