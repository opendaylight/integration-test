*** Settings ***
Documentation     Tests registration of AE and CSE entities resulting in creation of
...               AE and remoteCSE resources.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 Add Test Cases
    [Documentation]    no all test cases defined
    [Tags]    not-implemented    exclude
    TODO

1.01 Create AE with resourceName
    [Documentation]    Register AE using request primitive with resourceName specified. The resourceName
    ...    parameter is used as AE-ID.
    ...    Verify successful registration using retrieve operation with the new resource.
    [Tags]    not-implemented    exclude
    TODO

1.02 Create AE without resourceName
    [Documentation]    Register AE using request primitive without resourceName specified. From parameter
    ...    is used as AE-ID.
    ...    Verify successful registration using retrieve operation with the new resource.
    [Tags]    not-implemented    exclude
    TODO

1.03 Create AE with conflicting AE-ID and with resourceName
    [Documentation]    Register AE using request primitive with resourceName specified. The resourceName
    ...    parameter is used as AE-ID but it is AE-ID of already registered AE so the registration
    ...    fails.
    ...    Verify the resource in conflict using retrieve operation before and after registration attempt.
    [Tags]    not-implemented    exclude
    TODO

1.04 Create AE with conflicting AE-ID and without resourceName
    [Documentation]    Register AE using request primitive without resourceName specified. From parameter
    ...    is used as AE-ID but it is AE-ID of already registered AE so the registration
    ...    fails.
    ...    Verify the resource in conflict using retrieve operation before and after registration attempt.
    [Tags]    not-implemented    exclude
    TODO

2.01 Create remoteCSE with resourceName == CSE-ID
    [Documentation]    Register CSE using request primitive with resourceName specified. The resourceName
    ...    parameter is equal to CSE-ID.
    ...    Verify successful registration using retrieve operation with the new resource.
    [Tags]    not-implemented    exclude
    TODO

2.02 Create remoteCSE with resourceName != CSE-ID
    [Documentation]    Register CSE using request primitive with resourceName specified. The resourceName
    ...    parameter is different than CSE-ID.
    ...    Verify successful registration using retrieve operation with the new resource.
    [Tags]    not-implemented    exclude
    TODO

2.03 Create remoteCSE without resourceName
    [Documentation]    Register CSE using request primitive without resourceName specified.
    ...    Verify successful registration using retrieve operation with the new resource.
    [Tags]    not-implemented    exclude
    TODO

2.04 Create remoteCSE with conflicting CSE-ID and non-conflicting resourceName
    [Documentation]    Register CSE using request primitive with resourceName specified. The resourceName
    ...    parameter is unique but CSE-ID is in conflict with already registered CSE so the registration
    ...    fails.
    ...    Verify the resource in conflict using retrieve operation before and after registration attempt.
    [Tags]    not-implemented    exclude
    TODO

2.05 Create remoteCSE with conflicting CSE-ID and without resourceName
    [Documentation]    Register CSE using request primitive without resourceName specified. The CSE-ID is in conflict
    ...    with already registered CSE so the registration fails.
    ...    Verify the resource in conflict using retrieve operation before and after registration attempt.
    [Tags]    not-implemented    exclude
    TODO

2.06 Create remoteCSE with uniqeu CSE-ID and conflicting resourceName
    [Documentation]    Register CSE using request primitive with resourceName specified. The resourceName
    ...    parameter is conflict with already registered CSE so the registration fails.
    ...    Verify the resource in conflict using retrieve operation before and after registration attempt.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
