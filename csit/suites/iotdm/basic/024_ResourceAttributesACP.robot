*** Settings ***
Documentation     Tests for Access Control Policy (ACP) resource attributes
Suite Setup       IOTDM Basic Suite Setup    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}
Suite Teardown    Kill The Tree    ${ODL_SYSTEM_1_IP}    InCSE1    admin    admin
Resource          ../../../libraries/SubStrings.robot
Library           ../../../libraries/IoTDM/criotdm.py
Library           Collections
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/IoTDM/IoTDMKeywords.robot

*** Variables ***
${rt_ae}          2
${rt_container}    3
${rt_contentInstance}    4
${rt_acp}         1

*** Test Cases ***
1.0.0 Test whether default ACP exist
    Modify Headers Origin    ${iserver}    admin
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/_defaultACP
    ${text} =    Text    ${r}
    LOG    ${text}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299

1.0.1 ACP C/R resource with mandatory common and specific attributes only
    [Documentation]    After Created, test whether all the mandatory attribtues exist.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35}, {"acor" : ["111","222"],"acop":35}]}, "pvs":{"acr":[{"acor" : ["111","222"],"acop":7}, {"acor" : ["111","222"],"acop":9}]}, "rn":"Acp1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Convert To String    ${r.text}
    Should Contain All Sub Strings    ${text}    "ct":    "lt":    "ty"    "ri":    "pi":

1.0.2 ACP D/R: resource with mandatory common and specific attributes only
    [Tags]    not-implemented    exclude
    TODO

2 ACP common attributes
    [Documentation]    (TODO remove when implemented), next TCs verifies particular common attribute of ACP.
    [Tags]    not-implemented    exclude
    TODO

2.01 ACP common attribute: resourceName
    [Tags]    not-implemented    exclude
    TODO

2.02 ACP common attribute: resourceType
    [Tags]    not-implemented    exclude
    TODO

2.03 ACP common attribute: resourceID
    [Tags]    not-implemented    exclude
    TODO

2.04 ACP common attribute: parentID
    [Tags]    not-implemented    exclude
    TODO

2.05 ACP common attribute: expirationTime
    [Tags]    not-implemented    exclude
    TODO

2.06 ACP common attribute: labels
    [Tags]    not-implemented    exclude
    TODO

2.07 ACP common attribute: creationTime
    [Tags]    not-implemented    exclude
    TODO

2.08 ACP common attribute: lastModifiedTime
    [Tags]    not-implemented    exclude
    TODO

2.09 ACP common attribute: announceTo
    [Tags]    not-implemented    exclude
    TODO

2.10 ACP common attribute: announcedAttribute
    [Tags]    not-implemented    exclude
    TODO

3 ACP specific attributes
    [Documentation]    (TODO remove when implemented), next TCs verifies particular specific attribute of ACP.
    [Tags]    not-implemented    exclude
    TODO

3.01 ACP specific attributes: priviliges, selfPrivileges
    [Tags]    not-implemented    exclude
    # TODO TCs here should implement all sub-cases as described in the help file
    # TODO next TC definities just shows subset of TCs and how it could be done
    TODO

3.01.01 ACP U/R: priviliges attribute: Update priviliges attribute only
    [Documentation]    Update only priviliges attribute of ACP and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.01.02 ACP U/R: selfPriviliges attribute: Update selfPriviliges attribute only
    [Documentation]    Update only selfPriviliges attribute of ACP and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.01.03 ACP U/R: priviliges attribute: Delete priviliges attribute only
    [Documentation]    NEGATIVE: Use Update operation to set priviliges attribute to null. Verify error message and
    ...    verify original ACP resource by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.01.04 ACP U/R: selfPriviliges attribute: Delete selfPriviliges attribute only
    [Documentation]    NEGATIVE: Use Update operation to set selfPriviliges attribute to null. Verify error message and
    ...    verify original ACP resource by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.02 ACP elements of specific attributes: priviliges, selfPrivileges
    [Tags]    not-implemented    exclude
    # TODO TCs here should implement all sub-cases as described in the help file
    # TODO next TC definities just shows subset of TCs and how it could be done
    TODO

3.02.01 ACP C/R: priviliges, selfPrivileges attributes: With valid IPv4 acip element
    [Documentation]    After Created, test whether all the mandatory elements exist.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv4":["127.0.0.1"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Convert To String    ${r.text}
    Should Contain All Sub Strings    ${text}    "ct":    "lt":    "ty"    "ri":    "pi":

3.02.02 ACP U/R: priviliges, selfPrivileges attributes: With valid IPv4 acip element
    [Documentation]    After Updated, test whether all the mandatory elements exist.
    ...    Update resources with/without tested element.
    [Tags]    not-implemented    exclude
    TODO

3.02.03 ACP D/R: priviliges, selfPrivileges attributes: With valid IPv4 acip element
    [Documentation]    After Deleted, verify by Retrieve operation. Delete resources with/without tested element.
    [Tags]    not-implemented    exclude
    TODO

3.02.04 ACP C/R: priviliges, selfPrivileges attributes: With invalid IPv4 acip element
    [Documentation]    NEGATIVE: Create with invalid ipv4 address, check error message and verify by Retrieve operation.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv4":["127.0.01"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp3"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_acp}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    not a valid Ipv4 address
    # TODO Verify by Retrieve no operation

3.02.05 ACP U/R: priviliges, selfPrivileges attributes: With invalid IPv4 acip element
    [Documentation]    NEGATIVE: Update with invalid ipv4 address, check error message and verify by Retrieve operation.
    ...    Update resources with/without tested element.
    [Tags]    not-implemented    exclude
    TODO

3.02.06 ACP C/R: priviliges, selfPrivileges attributes: With valid IPv6 acip element
    [Documentation]    After Created, test whether all the mandatory elements exist.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv6":["2001:db8:0:0:0:ff00:42:8329"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp4"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Convert To String    ${r.text}
    Should Contain All Sub Strings    ${text}    "ct":    "lt":    "ty"    "ri":    "pi":
    # TODO verify by Retrieve operation

3.02.07 ACP U/R: priviliges, selfPrivileges attributes: With valid IPv6 acip element
    [Documentation]    After Updated, test whether all the mandatory elements exist. Update ACP resources with/without
    ...    tested element.
    [Tags]    not-implemented    exclude
    TODO

3.02.08 ACP D/R: priviliges, selfPrivileges attributes: With valid IPv6 acip element
    [Documentation]    After Deleted, test whether all the mandatory elements exist. Delete ACP resources with/without
    ...    tested element.
    [Tags]    not-implemented    exclude
    TODO

3.02.09 ACP C/R: priviliges, selfPrivileges attributes: With invalid IPv6 acip element
    [Documentation]    NEGATIVE: Create with invalid ipv6 address, check error message and verify by Retrieve operation.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv6":["2001:db8:0:0:0:ff00:42"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp3"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_acp}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    not a valid Ipv6 address
    # TODO: verify by retrieve operation

3.02.10 ACP U/R: priviliges, selfPrivileges attributes: With invalid IPv6 acip element
    [Documentation]    NEGATIVE: Update with invalid ipv6 address, check error message and verify by Retrieve operation.
    ...    Update resources with/without tested element.
    [Tags]    not-implemented    exclude
    TODO

3.03.01 ACP C/R: priviliges, selfPrivileges attributes: With accessControlWindow element
    [Documentation]    Create ACP with accessControlWindow element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.02 ACP U/R: priviliges, selfPrivileges attributes: With accessControlWindow element
    [Documentation]    Update the accessControlWindow element of ACP resources with/without tested element and verify
    ...    by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.03 ACP D/R: priviliges, selfPrivileges attributes: With accessControlWindow element
    [Documentation]    Delete ACP with accessControlWindow element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.04 ACP C/R: priviliges, selfPrivileges attributes: With invalid accessControlWindow element
    [Documentation]    NEGTIVE: Create ACP with invalid accessControlWindow element and check error message and
    ...    verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.05 ACP U/R: priviliges, selfPrivileges attributes: With invalid accessControlWindow element
    [Documentation]    Update the invalid value of accessControlWindow element of ACP resources with/without tested
    ...    element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.06 ACP C/R: priviliges, selfPrivileges attributes: With multiple accessControlWindow elements
    [Documentation]    Create ACP with multiple accessControlWindow elements and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.07 ACP U/R: priviliges, selfPrivileges attributes: With multiple accessControlWindow elements
    [Documentation]    Update multiple accessControlWindow elements of ACP resources with/without tested elements and verify
    ...    by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.08 ACP D/R: priviliges, selfPrivileges attributes: With multiple accessControlWindow elements
    [Documentation]    Delete ACP with multiple accessControlWindow elements and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.09 ACP C/R: priviliges, selfPrivileges attributes: With multiple invalid accessControlWindow elements
    [Documentation]    NEGTIVE: Create ACP with multiple invalid accessControlWindow elements and check error message and
    ...    verify by Retrieve operation.
    ...    Test also combinations of valid and invalid elements.
    [Tags]    not-implemented    exclude
    TODO

3.03.10 ACP U/R: priviliges, selfPrivileges attributes: With multiple invalid accessControlWindow elements
    [Documentation]    Update the invalid value of accessControlWindow element of ACP resources with/without tested
    ...    element and verify by Retrieve operation.
    ...    Test also combinations of valid and invalid elements.
    [Tags]    not-implemented    exclude
    TODO

3.03.11 ACP C/R: priviliges, selfPrivileges attributes: With accessControlLocationRegions element
    [Documentation]    Create ACP with accessControlLocationRegions element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.12 ACP U/R: priviliges, selfPrivileges attributes: With accessControlLocationRegions element
    [Documentation]    Update the accessControlLocationRegions element of ACP resources with/without tested element and verify
    ...    by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.13 ACP D/R: priviliges, selfPrivileges attributes: With accessControlLocationRegions element
    [Documentation]    Delete ACP with accessControlLocationRegions element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.14 ACP C/R: priviliges, selfPrivileges attributes: With invalid accessControlLocationRegions element
    [Documentation]    NEGTIVE: Create ACP with invalid accessControlLocationRegions element and check error message and
    ...    verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.15 ACP U/R: priviliges, selfPrivileges attributes: With invalid accessControlLocationRegions element
    [Documentation]    Update the invalid value of accessControlLocationRegions element of ACP resources with/without tested
    ...    element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.16 ACP C/R: priviliges, selfPrivileges attributes: With accessControlAuthenticationFlag element
    [Documentation]    Create ACP with accessControlAuthenticationFlag element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.17 ACP U/R: priviliges, selfPrivileges attributes: With accessControlAuthenticationFlag element
    [Documentation]    Update the accessControlAuthenticationFlag element of ACP resources with/without tested element and verify
    ...    by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.18 ACP D/R: priviliges, selfPrivileges attributes: With accessControlAuthenticationFlag element
    [Documentation]    Delete ACP with accessControlAuthenticationFlag element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.19 ACP C/R: priviliges, selfPrivileges attributes: With invalid accessControlAuthenticationFlag element
    [Documentation]    NEGTIVE: Create ACP with invalid accessControlAuthenticationFlag element and check error message and
    ...    verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.20 ACP U/R: priviliges, selfPrivileges attributes: With invalid accessControlAuthenticationFlag element
    [Documentation]    Update the invalid value of accessControlAuthenticationFlag element of ACP resources with/without tested
    ...    element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.21 ACP C/R: priviliges, selfPrivileges attributes: With multiple accessControlContext (acco) elements
    [Documentation]    Create ACP with multiple accessControlContext elements and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.22 ACP U/R: priviliges, selfPrivileges attributes: With multiple accessControlContext (acco) elements
    [Documentation]    Update ACP with multiple accessControlContext elements and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.23 ACP D/R: priviliges, selfPrivileges attributes: With multiple accessControlContext (acco) elements
    [Documentation]    Delete ACP with multiple accessControlContext elements and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

3.03.24 ACP C/R: priviliges, selfPrivileges attributes: With multiple accessControlRules elements
    [Documentation]    Create ACP with multiple accessControlRules element and verify by Retrieve operation.
    [Tags]    not-implemented    exclude
    TODO

4.01 ACP C/R: With all mandatory and optional common and specific attributes
    [Tags]    not-implemented    exclude
    TODO

4.02 ACP U(modify)/R: With all mandatory and optional common and specific attributes
    [Tags]    not-implemented    exclude
    TODO

4.03 ACP D/R: With all mandatory and optional common and specific attributes
    [Tags]    not-implemented    exclude
    TODO

4.04 ACP Test Create and Update operations with non-existing attributes and elements
    [Tags]    not-implemented    exclude
    # TODO use the approach described in the help file
    TODO

5.00 ACP CRUD with all valid RCN values
    [Documentation]    CRUD operations with all mandatory and optiona common and specific attributes, test all RCN values
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
Connect And Create Resource
    [Arguments]    ${targetURI}    ${resoutceType}    ${attr}    ${resourceName}=${EMPTY}
    ${iserver} =    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}    http
    ${r} =    Create Resource    ${iserver}    ${targetURI}    ${resoutceType}    ${attr}    ${resourceName}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201

Response Is Correct
    [Arguments]    ${r}
    ${text} =    Text    ${r}
    LOG    ${text}
    ${json} =    Json    ${r}
    LOG    ${json}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299

TODO
    Fail    "Not implemented"
