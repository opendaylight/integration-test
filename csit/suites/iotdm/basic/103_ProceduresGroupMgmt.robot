*** Settings ***
Documentation     Test suite tests procedures related to Group resource and its child resources according
...               to OneM2M specifications:
...               <group>: (TS-0001: 10.2.7 Group Management Procedures; TS-0004: 7.4.13 Resource Type <group>)
...               <fanOutPoint>: (TS-0001: 10.2.7.6 <fanOutPoint> Management Procedures; TS-0004: 7.4.14 Resource Type <fanOutPoint>)
...               <semanticFanOutPoint>: (TS-0001: 10.2.7.14 Retrieve <semanticFanOutPoint>; TS-0004: 7.4.35 Resource Type <semanticFanOutPoint>)
...               <semanticDescriptor>: (TS-0001: 10.2.32 <semanticDescriptor> Resource Procedures; TS-0004: 7.4.34 Resource Type <semanticDescriptor>)
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 C/R valid Group resource without child resources
    [Documentation]    Create simple Group resource without child resources and verify by Retrieve operation and
    ...    check the received resource representation of includes all expected attributes.
    [Tags]    not-implemented    exclude
    TODO

1.01 C/R Group resource: valid memberIDs
    [Documentation]    Positive TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that there are no duplicate members present in the memberIDs attribute"
    [Tags]    not-implemented    exclude
    TODO

1.02 C/R Group resource: invalid memberIDs
    [Documentation]    Negative TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that there are no duplicate members present in the memberIDs attribute"
    [Tags]    not-implemented    exclude
    TODO

1.03 C/R Group resource: valid memberTypes
    [Documentation]    Positive TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that the resource type of every member on each member Hosting CSE
    ...    conforms to the memberType attribute in the request, if the memberType attribute of the <group>
    ...    resource is not 'mixed'. Set the memberTypeValidated attribute to TRUE upon successful validation."
    [Tags]    not-implemented    exclude
    TODO

1.04 C/R Group resource: invalid memberTypes
    [Documentation]    Negative TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that the resource type of every member on each member Hosting CSE
    ...    conforms to the memberType attribute in the request, if the memberType attribute of the <group>
    ...    resource is not 'mixed'. Set the memberTypeValidated attribute to TRUE upon successful validation."
    [Tags]    not-implemented    exclude
    TODO

1.05 C/R Group resource: Verify <fanOutPoint> and <semanticFanOutPoint> child resources
    [Documentation]    Test all possible scenarios related to this Group resource Create handling step:
    ...    "TS-0001: Upon successful validation of the provided attributes, create a new group resource
    ...    including the <fanOutPoint> child-resource in the Hosting CSE. If the CSE supports semantic
    ...    discovery functionality, the Hosting CSE shall also set the semanticSupportIndicator attribute
    ...    to TRUE and create the <semanticFanOutPoint> child-resource"
    [Tags]    not-implemented    exclude
    TODO

1.06 C/R Group resource: Verify memberTypeValidated attribute
    [Documentation]    Test all possible scenarios related to this Group resource Create handling steps:
    ...    "TS-0001: Conditionally, in the case that the group resource contains temporarily unreachable
    ...    Hosting CSE of sub-group resources as member resource, set the memberTypeValidated attribute
    ...    of the <group> resource to FALSE"
    ...    "TS-0001: Respond to the Originator with the appropriate generic Response with the
    ...    representation of the <group> resource if the memberTypeValidated attribute is FALSE, and the
    ...    address of the created <group> resource if the CREATE was successful"
    [Tags]    not-implemented    exclude
    TODO

1.07 C/R Group resource: resource become reachable
    [Documentation]    Test all possible scenarios related to this Group resource Create handling step:
    ...    "TS-0001: As soon as any Hosting CSE that hosts the unreachable resource becomes reachable,
    ...    the memberType validation procedure shall be performed. If the memberType validation fails,
    ...    the Hosting CSE shall deal with the <group> resource according to the policy defined by the
    ...    consistencyStrategy attribute of the <group> resource provided in the request or by default if
    ...    the attribute is not provided"
    [Tags]    not-implemented    exclude
    TODO

2.01 U/R Group resource: valid memberIDs
    [Documentation]    Positive TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that there are no duplicate members present in the memberIDs attribute"
    [Tags]    not-implemented    exclude
    TODO

2.02 U/R Group resource: invalid memberIDs
    [Documentation]    Negative TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that there are no duplicate members present in the memberIDs attribute"
    [Tags]    not-implemented    exclude
    TODO

2.03 U/R Group resource: valid memberTypes
    [Documentation]    Positive TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that the resource type of every member on each member Hosting CSE
    ...    conforms to the memberType attribute in the request, if the memberType attribute of the <group>
    ...    resource is not 'mixed'. Set the memberTypeValidated attribute to TRUE upon successful validation."
    [Tags]    not-implemented    exclude
    TODO

2.04 U/R Group resource: invalid memberTypes
    [Documentation]    Negative TC related to this Group resource Create handling step:
    ...    "TS-0001: Validate that the resource type of every member on each member Hosting CSE
    ...    conforms to the memberType attribute in the request, if the memberType attribute of the <group>
    ...    resource is not 'mixed'. Set the memberTypeValidated attribute to TRUE upon successful validation."
    [Tags]    not-implemented    exclude
    TODO

2.05 U/R Group resource: Verify memberTypeValidated attribute
    [Documentation]    Test all possible scenarios related to this Group resource Create handling steps:
    ...    "TS-0001: Conditionally, in the case that the <group> resource contains temporarily unreachable
    ...    Hosting CSE of sub-group resources as members resource set the memberTypeValidated attribute of
    ...    the <group> resource to FALSE"
    ...    "TS-0001: Respond to the Originator with the appropriate generic response with the
    ...    representation of the <group> resource if the memberTypeValidated attribute is FALSE, and the
    ...    address of the created <group> resource if the UPDATE is successful"
    [Tags]    not-implemented    exclude
    TODO

2.06 U/R Group resource: resource become reachable
    [Documentation]    Test all possible scenarios related to this Group resource Create handling step:
    ...    "TS-0001: As soon as any Hosting CSE that hosts unreachable resource becomes reachable, the
    ...    memberType validation procedure shall be performed. If the memberType validation fails, the
    ...    Hosting CSE shall deal with the <group> resource according to the policy defined by the
    ...    consistencyStrategy attribute of the <group> resource provided in the request, or by default if
    ...    the attribute is not provided"
    [Tags]    not-implemented    exclude
    TODO

3. CRUD fanOutPoint resource
    [Documentation]    Test CRUD operations targetted to fanOutPoint child resource of Group resource.
    ...    TODO: Split this TC if needed
    [Tags]    not-implemented    exclude
    TODO

4. CRUD semanticFanOutPoint and semanticDescriptor resources
    [Documentation]    Test CRUD operations targetted to semanticFanOutPoint and semanticDescriptor resources.
    ...    TODO: Split this TC if needed
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
