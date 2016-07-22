*** Settings ***
Documentation     Test suite to verify Restconf is OK
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/UtilsUsec.robot


*** Variables ***
${RESTCONF_MODULES_URI}    /restconf/modules


*** Test Cases ***
Fail To Get Token With Invalid Username And Password
    [Documentation]    Negative test to verify invalid user/password 
    ${resp1} =  RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH1}    headers=${HEADERS_XML}
    ${resp} =    RequestsLibrary.Get_Request    session    ${RESTCONF_MODULES_URI}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Not_Be_Equal    ${200}    ${resp.status_code}    # status_code is always integer.
    BuiltIn.Should_Not_Contain    ${resp.content}    ietf-restconf

Get Controller Modules
    [Documentation]    Get the controller modules via Restconf
     ${resp1} =  RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${resp}    RequestsLibrary.Get Request    session   ${RESTCONF_MODULES_URI}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ietf-restconf
