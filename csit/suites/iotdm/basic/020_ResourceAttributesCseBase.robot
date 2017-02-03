*** Settings ***
Documentation     Test suite tests CRUD operations with cseBase resource attributes
...               CseBase resource must not be CRUD-able through OneM2M API so this test suite
...               implements also negative TCs which makes attemts to CRUD cseBase and its attributes
...               through OneM2M API.
...               TODO: implement TCs according to 000_ResourceAttributesNotes.txt
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 Add Test Cases
    [Documentation]    no test cases defined
    [Tags]    not-implemented    exclude
    TODO

2.00 Add Test Cases using IoTDM's core RESTCONF call
    [Documentation]    CRUD cseBase resouce by IoTDM's RESTCONF call
    [Tags]    not-implemented    exclude
    TODO

3.00 Test OneM2M API CRUD operations with cseBase
    [Documentation]    CRUD operations with cseBase using OneM2M API must be dropped. Verify each failed operation by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
