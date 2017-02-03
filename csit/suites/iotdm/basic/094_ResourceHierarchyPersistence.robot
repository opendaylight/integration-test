*** Settings ***
Documentation     This test suite verifies resource tree after restart of IoTDM.
...               Hierarchy of resources is created first, including: cseBase/AE/Container/ContentInstance
...               IoTDM is restarted and the hierarchy is verified using Retrieve operation.
...               New resources are created and verified.
...               IoTDM is restarted again and resources are verified by Retrieve operation.
...               Tests creation of new reqsources after the restart.
...               Some resources are deleted and result is verified also by retrieve operation.
...               IoTDM is restarted again and data tree is checked if all deleted resources are not present.
...               Simulates also such state when DAO plugin is not installed and IoTDM is not able to write data
...               into data store. Verifies error responses of CRUD operations.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 Add Test Cases
    [Documentation]    Define testcases according to test suite documentation above.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
