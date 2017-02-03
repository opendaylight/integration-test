*** Settings ***
Documentation     Test suite tests Container and ContentInstance resources according to OneM2M specifications:
...               <container>: (TS-0001: 10.2.4 <container> Resource Procedures; TS-0004 7.4.6 Resource Type <container>)
...               <contentInstance>: (TS-0001 10.2.19 <contentInstance> Resource Procedures; TS-0004 7.4.7 Resource Type <contentInstance>)
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 C/R Container, positive: With valid contentInstance resources
    [Documentation]    Create container resource with more than one contentInstance child resources.
    ...    Retrieve the container with all attributes and all child resources by one request and
    ...    verify the response.
    [Tags]    not-implemented    exclude
    TODO

1.01 C/R Container negative: Without contentInstance resources, without subscription
    [Documentation]    Create container resource without contentInstance child resources and without subscription
    ...    resource.
    ...    Retrieve the container with all attributes and all child resources by one request and
    ...    verify the error code and error message of the response.
    [Tags]    not-implemented    exclude
    TODO

1.02 C/R Container negative: Without contentInstance resources, with subscription, eventType != E
    [Documentation]    Create container resource without contentInstance child resources and with subscription resource
    ...    with eventType attribute set to other value than E.
    ...    Retrieve the container with all attributes and all child resources by one request and
    ...    verify the error code and error message of the response.
    [Tags]    not-implemented    exclude
    TODO

1.03 C/R Container positive: Without contentInstance resources, with subscription, eventType == E
    [Documentation]    Create container resource without contentInstance child resources and with subscription resource
    ...    with eventType attribute set to value E.
    ...    Verify this handling scenario from TS-0001, timer will not expire in this case:
    ...    "There is a subscription on the <container> resource with the eventType 'e)'
    ...    set (oneM2M TS-0001, table 9.6.8-3) so a notification is triggered, a timer shall be set and the
    ...    Receiver shall delay the response until a <constentInstance> resource is available in the
    ...    <container> resource, or until the timer expires; in that last case the Receiver shall respond
    ...    with an error. If the Result Expiration Timestamp parameter is received from the Originator, the
    ...    timer should be set to enforce this parameter, otherwise, the timer is set, based on the local
    ...    policy configured at the Hosting CSE."
    [Tags]    not-implemented    exclude
    TODO

1.04 C/R Container negative: Without contentInstance resources, with subscription, eventType == E
    [Documentation]    Create container resource without contentInstance child resources and with subscription resource
    ...    with eventType attribute set to value E.
    ...    Verify this handling scenario from TS-0001, timer will expire in this case:
    ...    "There is a subscription on the <container> resource with the eventType 'e)'
    ...    set (oneM2M TS-0001, table 9.6.8-3) so a notification is triggered, a timer shall be set and the
    ...    Receiver shall delay the response until a <constentInstance> resource is available in the
    ...    <container> resource, or until the timer expires; in that last case the Receiver shall respond
    ...    with an error. If the Result Expiration Timestamp parameter is received from the Originator, the
    ...    timer should be set to enforce this parameter, otherwise, the timer is set, based on the local
    ...    policy configured at the Hosting CSE."
    [Tags]    not-implemented    exclude
    TODO

1.05 C/R Container negative: With stale contentInstance resources, without subscription
    [Documentation]    Create container resource with more than one contentInstance child resources and without
    ...    subscription resource. Let the contentInstance resources become stale.
    ...    Retrieve the container with all attributes and all child resources by one request and
    ...    verify the error code and error message of the response.
    [Tags]    not-implemented    exclude
    TODO

1.06 C/R Container negative: With stale contentInstance resources, with subscription, eventType != E
    [Documentation]    Create container resource with more than one contentInstance child resources and with
    ...    subscription resource with eventType attribute set to other value than E.
    ...    Let the contentInstance resources become stale.
    ...    Retrieve the container with all attributes and all child resources by one request and
    ...    verify the error code and error message of the response.
    [Tags]    not-implemented    exclude
    TODO

1.07 C/R Container positive: With stale contentInstance resources, with subscription, eventType == E
    [Documentation]    Create container resource with more than one contentInstance child resources and with
    ...    subscription resource with eventType attribute set to value E. Let the contentInstance resources
    ...    become stale.
    ...    Verify this handling scenario from TS-0001, timer will not expire in this case:
    ...    "There is a subscription on the <container> resource with the eventType 'e)'
    ...    set (oneM2M TS-0001, table 9.6.8-3) so a notification is triggered, a timer shall be set and the
    ...    Receiver shall delay the response until a <constentInstance> resource is available in the
    ...    <container> resource, or until the timer expires; in that last case the Receiver shall respond
    ...    with an error. If the Result Expiration Timestamp parameter is received from the Originator, the
    ...    timer should be set to enforce this parameter, otherwise, the timer is set, based on the local
    ...    policy configured at the Hosting CSE."
    [Tags]    not-implemented    exclude
    TODO

1.08 C/R Container negative: With stale contentInstance resources, with subscription, eventType == E
    [Documentation]    Create container resource with more than one contentInstance child resources and with
    ...    subscription resource with eventType attribute set to value E. Let the contentInstance resources
    ...    become stale.
    ...    Verify this handling scenario from TS-0001, timer will expire in this case:
    ...    "There is a subscription on the <container> resource with the eventType 'e)'
    ...    set (oneM2M TS-0001, table 9.6.8-3) so a notification is triggered, a timer shall be set and the
    ...    Receiver shall delay the response until a <constentInstance> resource is available in the
    ...    <container> resource, or until the timer expires; in that last case the Receiver shall respond
    ...    with an error. If the Result Expiration Timestamp parameter is received from the Originator, the
    ...    timer should be set to enforce this parameter, otherwise, the timer is set, based on the local
    ...    policy configured at the Hosting CSE."
    [Tags]    not-implemented    exclude
    TODO

2.00 C/R Containers: Prepare set of container resources for next TCs
    [Documentation]    This TC prepares container resources for testing of this procedure described in TS-0001:
    ...    "If the newly created <contentInstance> resource violates any of the policies defined in the
    ...    parent <container> resource (e.g. maxNrOfInstances or maxByteSize), then the oldest
    ...    <contentInstance> resources shall be removed from the <container> to enable the creation of the
    ...    new <contentInstance> resource."
    [Tags]    not-implemented    exclude
    TODO

2.01 C/R ContentInstance: Container with maxNrOfInstances set to 3
    [Documentation]    Create at least 5 contentInstance resources in container with maxNrOfInstances
    ...    attribute set to 3 and verify result of each create operation if the first three passed and
    ...    none contentInstance deleted. Verify that the next two operations passed and oldest
    ...    contentInstance resources has been deleted.
    [Tags]    not-implemented    exclude
    TODO

2.02 C/R ContentInstance: Container with maxByteSize set to N, multiple contentInstances
    [Documentation]    Create at least 5 contentInstance resources in container with maxByteSize
    ...    attribute set to N and verify result of each create operation if the first three passed and
    ...    none contentInstance deleted. Verify that the next two operations passed and oldest
    ...    contentInstance resources has been deleted.
    [Tags]    not-implemented    exclude
    TODO

2.03 C/R ContentInstance: Container with maxByteSize set to N, single contentInstance
    [Documentation]    Try to create such contentInstance resource which is the first contentInstance resource of the
    ...    parent container resource and which has content size higher than N value set in maxByteSize
    ...    attribute of the parent container.
    ...    Verify if the response includes NOT_ACCEPTABLE error.
    ...    Create also contentInstance with content size equal to N and verify if such contentInstance has
    ...    been successfully created.
    [Tags]    not-implemented    exclude
    TODO

2.04 C/R ContentInstance: Container with maxNrOfInstances and maxByteSize, violation of maxNrOfInstances
    [Documentation]    Create at least 5 contentInstance resources in container with maxNrOfInstances
    ...    attribute set to 3 and and maxByteSize set to N. Sum of all five contentInstance resources
    ...    content sizes is lower than N so the maxByteSize is not violated in this TC.
    ...    Verify result of create operations if the first three passed and none contentInstance is
    ...    deleted. Verify that the next two operations passed and oldest contentInstance resources has
    ...    been deleted.
    [Tags]    not-implemented    exclude
    TODO

2.05 C/R ContentInstance: Container with maxNrOfInstances and maxByteSize, violation of maxByteSize
    [Documentation]    Create at least 4 contentInstance resources in container with maxNrOfInstances
    ...    attribute set to 4 and and maxByteSize set to N. Sum of all first two contentInstance
    ...    resources content sizes is lower than N so the maxByteSize is not violated by them.
    ...    Verify result of create operations if the first two passed and none contentInstance is
    ...    deleted. Verify that the next two operations passed and oldest contentInstance resources has
    ...    been deleted due to violation of the maxByteSize.
    [Tags]    not-implemented    exclude
    TODO

2.06 C/R ContentInstance: Container with maxNrOfInstances and maxByteSize, no contentInstance, too big content
    [Documentation]    Create single contentInstance in container without contentInstances and with maxNrOfInstances
    ...    attribute set to 4 and maxByteSize set to N. Content size of the new contentInstance
    ...    resource is higher than N so it violates the maxByteSize and the operation results with
    ...    NOT_ACCEPTABLE error.
    ...    Verify the error received in response and verify that the contentInstanse has not been created.
    [Tags]    not-implemented    exclude
    TODO

2.07 C/R ContentInstance: Container with maxNrOfInstances and maxByteSize, with contentInstance, too big content
    [Documentation]    Create single contentInstance in container with three contentInstances and with maxNrOfInstances
    ...    attribute set to 4 and maxByteSize set to N. Content size of the new contentInstance
    ...    resource is higher than N so it violates the maxByteSize and the operation results with
    ...    NOT_ACCEPTABLE error.
    ...    Verify the error received in response and verify that the contentInstanse has not been created
    ...    and no any contentInstance child resource has been deleted from the parent container.
    [Tags]    not-implemented    exclude
    TODO

2.08 C/R ContentInstance: No violation after violation of maxByteSize
    [Documentation]    Use container with maxNrOfInstances set to 2 and maxByteSize set to N.
    ...    1. Create first contentInstance which doesn't violate maxByteSize.
    ...    2. Create second contentInstance which violates maxByteSize so the first one is deleted.
    ...    3. Create third contentInstance which doesn't violate maxByteSize. (So 2. and 3. are there)
    ...    4. Create fourth contentInstance with content size so big that second and third
    ...    contentInstances must be deleted.
    [Tags]    not-implemented    exclude
    TODO

3.00 U/R ContentInstance: Operation not allowed
    [Documentation]    Test update operation targetted to contentInstance resource. Verify the error response if
    ...    includes OPERATION_NOT_ALLOWED and verify that the contentInstance has not been updated.
    [Tags]    not-implemented    exclude
    TODO

4.00 Container stateTag: Update of the container itself
    [Documentation]    Test update of container resource and verify that stateTag attribute has been incremented.
    [Tags]    not-implemented    exclude
    TODO

4.01.00 Container stateTag: Create operation of contentInstance
    [Documentation]    Test Create operation of child contentInstance resource of the container. Verify that
    ...    stateTag of the container has been incremented and stateTag of the contentInstance resource
    ...    was set to the value of container's stateTag.
    [Tags]    not-implemented    exclude
    TODO

4.01.01 Container stateTag: CUD operations of child resources - contentInstance
    [Documentation]    Test CUD operations with contentInstance child resoruces of the container resource and
    ...    verify that stateTag attribute of the parent container has been incremented.
    [Tags]    not-implemented    exclude
    TODO

4.01.02 Container stateTag: CUD operations of child resources - container
    [Documentation]    Test CUD operations with container child resoruces of the container parent resource and
    ...    verify that stateTag attribute of the parent container has been incremented.
    [Tags]    not-implemented    exclude
    TODO

4.01.03 Container stateTag: CUD operations of child resources - subscription
    [Documentation]    Test CUD operations with subscription child resoruces of the container parent resource and
    ...    verify that stateTag attribute of the parent container has been incremented.
    [Tags]    not-implemented    exclude
    TODO

4.02.01 Container stateTag + notification: CUD operations of child resources - contentInstance
    [Documentation]    Test CUD operations with contentInstance child resoruces of the container resource
    ...    with subscription.
    ...    Verify that stateTag attribute of the parent container has been incremented and it has
    ...    trigerred notification.
    [Tags]    not-implemented    exclude
    TODO

4.02.02 Container stateTag + notification: CUD operations of child resources - container
    [Documentation]    Test CUD operations with container child resoruces of the container resource
    ...    with subscription.
    ...    Verify that stateTag attribute of the parent container has been incremented and it has
    ...    trigerred notification.
    [Tags]    not-implemented    exclude
    TODO

4.02.03 Container stateTag + notification: CUD operations of child resources - subscription
    [Documentation]    Test CUD operations with subscription child resoruces of the container resource
    ...    with subscription.
    ...    Verify that stateTag attribute of the parent container has been incremented and it has
    ...    trigerred notification.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
