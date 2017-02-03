*** Settings ***
Documentation     Test suite tests resource specific operations of the oldest and latest resources according to
...               OneM2M specifications:
...               <oldest>: (TS-0001: 10.2.23 <oldest> Resource Procedure; TS-0004: 7.4.28.2 <oldest> Resource Specific Procedure on CRUD Operations)
...               <latest>: (TS-0001: 10.2.22 <latest> Resource Procedures; TS-0004: 7.4.27.2 <latest> Resource Specific Procedure on CRUD Operations)
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 Retrieve Oldest and Latest resources
    [Documentation]    Test retrieve operation of Oldest and Latest resources of containers:
    ...    1. Container without any content instance.
    ...    2. Container with single contentInstance, Oldest and Latest resources should be the same.
    ...    3. Container with more than one contentInstnce, verify that the expected oldest and latest
    ...    contentInstances has been returned.
    [Tags]    not-implemented    exclude
    TODO

1.01 C/R Oldest and Latest: Verify that Create operation is not allowed
    [Documentation]    Try to create Oldest and Latest resources of containers with and without contentInstance
    ...    resources. Verify the error response and check if the container has not been changed.
    [Tags]    not-implemented    exclude
    TODO

1.02 U/R Oldest and Latest: Verify that Update operation is not allowed
    [Documentation]    Try to update Oldest and Latest resources of containers with and without contentInstance
    ...    resources. Verify the error response and check if the container has not been changed.
    [Tags]    not-implemented    exclude
    TODO

1.03 Delete Oldest and Latest resources
    [Documentation]    Delete Oldest and Latest resources of containers:
    ...    1. Container without any content instance.
    ...    2. Container with single contentInstance and verify the Oldest, Latest and parent container.
    ...    3. Container with more than one contentInstance and verify the Oldest, Latest and parent container.
    ...    Delete util the parent container will include only one contentInstance and verify if the
    ...    Oldest and Latest are the same.
    ...    Delete also the last contentInstance and verify Oldest, Latest and parent container.
    [Tags]    not-implemented    exclude
    TODO

2.01 C/R ContentInstance: Create contentInstance and verify Oldest and Latest
    [Documentation]    Create contentInstances resource and verify Oldest and Latest in case of one contentInstance and
    ...    multiple contentInstances.
    [Tags]    not-implemented    exclude
    TODO

2.02 C/R ContentInstance: Create contentInstance which violates policy - positive
    [Documentation]    Create such contentInstance resource which trigers delete of Oldest and verify.
    [Tags]    not-implemented    exclude
    TODO

2.03 C/R ContentInstance: Create contentInstance which violates policy - negative
    [Documentation]    Create such contentInstance resource which results with NOT_ACCEPTABLE error and verify if
    ...    Oldest and Latest has not changed.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
