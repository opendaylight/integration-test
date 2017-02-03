*** Settings ***
Documentation     Every resource type has defined list of allowed child resources, this test suite tests Create
...               operations of valid and invalid child resources according to TS-0001 and TS-0004 OneM2M specifications.
...               TODO: add positive and negative TCs for all resource types
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 C/R: Negative: All resources as root resource
    [Documentation]    None root resource can be created using OneM2M API.
    [Tags]    not-implemented    exclude
    TODO

2.01 C/R: Positive: All valid child resources of accessControlPolicy resource
    [Documentation]    Test Create operation with all resource types of accessControlPolicy child resources and verify by
    ...    Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

2.02 C/R: Negative: All invalid child resources of accessControlPolicy resource
    [Documentation]    Test Create operation with all invalid resource types of accessControlPolicy child resources and verify by
    ...    Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.01 C/R: Positive: All valid child resources of cseBase resource
    [Documentation]    Test Create operation with all resource types of cseBase child resources and verify by
    ...    Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.02 C/R: Negative: All invalid child resources of cseBase resource
    [Documentation]    Test Create operation with all invalid resource types of cseBase child resources and verify by
    ...    Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

4.01 C/R: Positive: All valid child resources of remoteCSE resource
    [Documentation]    Test Create operation with all resource types of remoteCSE child resources and verify by
    ...    Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

4.02 C/R: Negative: All invalid child resources of remoteCSE resource
    [Documentation]    Test Create operation with all invalid resource types of remoteCSE child resources and verify by
    ...    Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
