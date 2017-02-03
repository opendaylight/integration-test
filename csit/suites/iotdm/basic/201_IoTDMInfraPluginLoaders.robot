*** Settings ***
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***

*** Test Cases ***
1.00 Add Test Cases
    [Documentation]    no test cases defined
    [Tags]    not-implemented
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
