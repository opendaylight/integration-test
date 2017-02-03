*** Settings ***
Documentation     Testing of request and response primitives parameters
...               Check specifications for more details:
...               Request primitive parameters: TS-0004: 7.2.1.1 Request primitive format
...               Response primitive parameters: TS-0004: 7.2.1.2 Response primitive format
Suite Setup       Connect And Create The Tree
Suite Teardown    Kill The Tree    ${ODL_SYSTEM_1_IP}    InCSE1    admin    admin
Resource          ../../../libraries/SubStrings.robot
Library           ../../../libraries/criotdm.py
Library           Collections
Resource          ../../../variables/Variables.robot

*** Variables ***
${rt_ae}          2
${rt_container}    3
${rt_contentInstance}    4

*** Test Cases ***
Set Suite Variable
    ${iserver} =    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}    http
    Set Suite Variable    ${iserver}

1.00 REQ: Create: With mandatory parameters only
    [Documentation]    Tests Create REQ with mandatory parameters only.
    [Tags]    not-implemented    exclude
    TODO

1.01 REQ: Create: Missing mandatory parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Create REQ with some mandatory parameter(s) missing.
    [Tags]    not-implemented    exclude
    TODO

1.02 REQ: Create: With non-provided parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Create REQ with non-provided parameter(s).
    [Tags]    not-implemented    exclude
    TODO

1.03 REQ: Create: With Role IDs parameter
    [Documentation]    Tests Create REQ with Role IDs parameter.
    [Tags]    not-implemented    exclude
    TODO

1.04 REQ: Create: With Originating Timestamp parameter
    [Documentation]    Tests Create REQ with Originating Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

1.05 REQ: Create: With Request Expiration Timestamp parametr
    [Documentation]    Tests Create REQ with Request Expiration Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

1.06 REQ: Create: With Result Expiration Time parameter
    [Documentation]    Tests Create REQ with Result Expiration Time parameter.
    [Tags]    not-implemented    exclude
    TODO

1.07 REQ: Create: With Operation Execution Time parameter
    [Documentation]    Tests Create REQ with Operation Execution Time parameter.
    [Tags]    not-implemented    exclude
    TODO

1.08 REQ: Create: With Response Type parameter
    [Documentation]    Tests Create REQ with Response Type parameter.
    [Tags]    not-implemented    exclude
    TODO

1.09 REQ: Create: With Result Persistence parameter
    [Documentation]    Tests Create REQ with Result Persistence parameter.
    [Tags]    not-implemented    exclude
    TODO

1.10.1 REQ: Create: With Result Content parameter - legal
    [Documentation]    Tests Create REQ with Result Content parameter set to legal values.
    ...    rcn=1, 2, 3, 0 is legal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    : FOR    ${rcn}    IN    \    1    2    3
    ...    0
    \    ${r} =    Create Resource With Command    ${iserver}    InCSE1    ${rt_ae}    rcn=${rcn}
    \    ...    ${attr}

1.10.2 REQ: Create: With Result Content parameter - illegal
    [Documentation]    NEGATIVE: Tests Create REQ with Result Content parameter set to illegal values.
    ...    rcn=4, 5, 6, 7 is illegal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    : FOR    ${rcn}    IN    4    5    6    7
    \    ${error} =    Run Keyword And Expect Error    *    Create Resource With Command    ${iserver}    InCSE1
    \    ...    ${rt_ae}    rcn=${rcn}    ${attr}
    \    Should Start with    ${error}    Cannot create this resource [400]
    \    Should Contain    ${error}    rcn

1.11 REQ: Create: With Event Category parameter
    [Documentation]    Tests Create REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

1.12 REQ: Create: With Delivery Aggregation parameter
    [Documentation]    Tests Create REQ with Delivery Aggregation parameter
    [Tags]    not-implemented    exclude
    TODO

1.13 REQ: Create: With Group Request Identifier parameter
    [Documentation]    Tests Create REQ with Group Request Identifier parameter
    [Tags]    not-implemented    exclude
    TODO

1.14 REQ: Create: With Tokens parameter
    [Documentation]    Tests Create REQ with Tokens parameter
    [Tags]    not-implemented    exclude
    TODO

1.15 REQ: Create: With Token IDs parameter
    [Documentation]    Tests Create REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

1.99 REQ: Create: With all optional parameters set
    [Documentation]    Tests Create REQ with all mandatory and optional parameters set
    [Tags]    not-implemented    exclude
    TODO

2.00 REQ: Retrieve: With mandatory parameters only
    [Documentation]    Tests Retrieve REQ with mandatory parameters only.
    [Tags]    not-implemented    exclude
    TODO

2.01 REQ: Retrieve: Missing mandatory parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Retrieve REQ with some mandatory parameter(s) missing.
    [Tags]    not-implemented    exclude
    TODO

2.02 REQ: Retrieve: With non-provided parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Retrieve REQ with non-provided parameter(s).
    [Tags]    not-implemented    exclude
    TODO

2.03 REQ: Retrieve: With Role IDs parameter
    [Documentation]    Tests Retrieve REQ with Role IDs parameter.
    [Tags]    not-implemented    exclude
    TODO

2.04 REQ: Retrieve: With Originating Timestamp parameter
    [Documentation]    Tests Retrieve REQ with Originating Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

2.05 REQ: Retrieve: With Request Expiration Timestamp parametr
    [Documentation]    Tests Retrieve REQ with Request Expiration Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

2.06 REQ: Retrieve: With Result Expiration Time parameter
    [Documentation]    Tests Retrieve REQ with Result Expiration Time parameter.
    [Tags]    not-implemented    exclude
    TODO

2.07 REQ: Retrieve: With Operation Execution Time parameter
    [Documentation]    Tests Retrieve REQ with Operation Execution Time parameter.
    [Tags]    not-implemented    exclude
    TODO

2.08 REQ: Retrieve: With Response Type parameter
    [Documentation]    Tests Retrieve REQ with Response Type parameter.
    [Tags]    not-implemented    exclude
    TODO

2.09 REQ: Retrieve: With Result Persistence parameter
    [Documentation]    Tests Retrieve REQ with Result Persistence parameter.
    [Tags]    not-implemented    exclude
    TODO

2.10.1 REQ: Retrieve: With Result Content parameter - legal
    [Documentation]    Tests Retrieve REQ with Result Content parameter set to legal values.
    ...    rcn=1, 4, 5, 6 null is legal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    : FOR    ${rcn}    IN    \    1    4    5
    ...    6
    \    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=${rcn}
    # when rcn=7 can be retrieved

2.10.2 REQ: Retrieve: With Result Content parameter - illegal
    [Documentation]    NEGATIVE: Tests Retrieve REQ with Result Content parameter set to illegal values.
    ...    rcn=0, 2, 3 is illegal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    : FOR    ${rcn}    IN    0    2    3
    \    ${error} =    Run Keyword And Expect Error    *    Retrieve Resource With Command    ${iserver}    InCSE1/AE1
    \    ...    rcn=${rcn}
    \    Should Start with    ${error}    Cannot retrieve this resource [400]
    \    Should Contain    ${error}    rcn

2.11 REQ: Retrieve: With Event Category parameter
    [Documentation]    Tests Retrieve REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

2.12 REQ: Retrieve: With Delivery Aggregation parameter
    [Documentation]    Tests Retrieve REQ with Delivery Aggregation parameter
    [Tags]    not-implemented    exclude
    TODO

2.13 REQ: Retrieve: With Group Request Identifier parameter
    [Documentation]    Tests Retrieve REQ with Group Request Identifier parameter
    [Tags]    not-implemented    exclude
    TODO

2.14 REQ: Retrieve: With Tokens parameter
    [Documentation]    Tests Retrieve REQ with Tokens parameter
    [Tags]    not-implemented    exclude
    TODO

2.15 REQ: Retrieve: With Token IDs parameter
    [Documentation]    Tests Retrieve REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

2.16 REQ: Retrieve: With Content parameter
    [Documentation]    Tests Retrieve REQ with Content parameter.
    [Tags]    not-implemented    exclude
    TODO

2.17 REQ: Retrieve: With Discovery Result Type parameter
    [Documentation]    Tests Retrieve REQ with Discovery Result Type parameter.
    [Tags]    not-implemented    exclude
    TODO

2.18.01 REQ: Retrieve: With Filter Criteria parameter - element createdBefore
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with createdBefore element.
    # need to sleep at least one second becase we are checking if resource was created before resource time and if
    # this test and test before was created in the same second then this test will fail.
    Sleep    1
    # time format is specified in TS0004 specification at http://onem2m.org/technical/published-documents page 35
    # DateTime string using 'Basic Format' specified in ISO8601 [27]. Time zone shall be interpreted as UTC timezone.
    ${cty} =    Get Time    year    UTC
    ${ctm} =    Get Time    month    UTC
    ${ctd} =    Get Time    day    UTC
    ${cth} =    Get Time    hour    UTC
    ${ctmin} =    Get Time    min    UTC
    ${ctsec} =    Get Time    sec    UTC
    Set Suite Variable    ${ts}    ${cty}${ctm}${ctd}T${cth}${ctmin}${ctsec}
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&crb=${ts}
    Log    ${r.text}
    ${rs} =    Child Resource    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    Container2    Container1

2.18.02 REQ: Retrieve: With Filter Criteria parameter - element createdAfter
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with createdAfter element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&cra=20150612T033748
    Log    ${r.text}
    ${rs} =    Child Resource    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    Container2    Container1

2.18.03 REQ: Retrieve: With Filter Criteria parameter - element modifiedSince
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with modifiedSince element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&ms=20150612T033748
    Log    ${r.text}
    ${rs} =    Child Resource    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    Container2    Container1

2.18.04 REQ: Retrieve: With Filter Criteria parameter - element unmodifiedSince
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with unmodifiedSince element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&us=${ts}
    Log    ${r.text}
    ${rs} =    Child Resource    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    Container2    Container1

2.18.05 REQ: Retrieve: With Filter Criteria parameter - element stateTagSmaller
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with stateTagSmaller element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/Container3    rcn=4&sts=3
    Log    ${r.text}
    ${rs} =    Child Resource First    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    5
    Should Contain All Sub Strings    '${rs}'    Container7    Container8    Container9    conIn3    conIn4

2.18.06 REQ: Retrieve: With Filter Criteria parameter - element stateTagBigger
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with stateTagBigger element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/Container3    rcn=4&stb=1
    Log    ${r.text}
    ${rs} =    Child Resource    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    conIn5    conIn4

2.18.07 REQ: Retrieve: With Filter Criteria parameter - element expireBefore
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with expireBefore element.
    [Tags]    not-implemented    exclude
    TODO

2.18.08 REQ: Retrieve: With Filter Criteria parameter - element expireAfter
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with expireAfter element.
    [Tags]    not-implemented    exclude
    TODO

2.18.09.01 REQ: Retrieve: With Filter Criteria parameter - element labels (one)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with one labels element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/Container3    rcn=4&sts=3&lbl=contentInstanceUnderContainerContainer
    Log    ${r.text}
    ${rs} =    Child Resource First    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    conIn3    conIn4

2.18.09.02 REQ: Retrieve: With Filter Criteria parameter - element labels (two)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with two labels elements.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    fu=1&rcn=4&sts=4&lbl=contentInstanceUnderContainerContainer&lbl=underCSE
    Log    ${r.text}
    ${count} =    Get Length    ${r.json()}
    Should Be Equal As Integers    ${count}    6
    Should Contain All Sub Strings    ${r.text}    Container3    Container4    Container5    conIn3    conIn4
    ...    conIn5

2.18.10 REQ: Retrieve: With Filter Criteria parameter - element resourceType
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with resourceType element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    rcn=4&rty=3
    Log    ${r.text}
    ${rs} =    Child Resource First    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    3
    Should Contain All Sub Strings    '${rs}'    Container3    Container4    Container5

2.18.11 REQ: Retrieve: With Filter Criteria parameter - element sizeAbove
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with sizeAbove element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    rcn=4&rty=3&sza=5
    Log    ${r.text}
    ${rs} =    Child Resource First    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    2
    Should Contain All Sub Strings    '${rs}'    Container3    Container4

2.18.12 REQ: Retrieve: With Filter Criteria parameter - element sizeBelow
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with sizeBelow element.
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    rcn=4&rty=3&szb=5
    Log    ${r.text}
    ${rs} =    Child Resource First    ${r}
    ${count} =    Get Length    ${rs}
    Should Be Equal As Integers    ${count}    1
    Should Contain All Sub Strings    '${rs}'    Container5

2.18.13.01 REQ: Retrieve: With Filter Criteria parameter - element contentType (one)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with one contentType element.
    [Tags]    not-implemented    exclude
    TODO

2.18.13.02 REQ: Retrieve: With Filter Criteria parameter - element contentType (two)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with two contentType elements.
    [Tags]    not-implemented    exclude
    TODO

2.18.14.01 REQ: Retrieve: With Filter Criteria parameter - element attribute (one)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with one attribute element.
    [Tags]    not-implemented    exclude
    TODO

2.18.14.02 REQ: Retrieve: With Filter Criteria parameter - element attribute (two)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with two attribute elements.
    [Tags]    not-implemented    exclude
    TODO

2.18.15 REQ: Retrieve: With Filter Criteria parameter - element filterUsage
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with filterUsage element.
    [Tags]    not-implemented    exclude
    TODO

2.18.16 REQ: Retrieve: With Filter Criteria parameter - element limit
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with limit element.
    [Tags]    not-implemented    exclude
    TODO

2.18.17.01 REQ: Retrieve: With Filter Criteria parameter - element semanticsFilter (one)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with one semanticsFilter element.
    [Tags]    not-implemented    exclude
    TODO

2.18.17.02 REQ: Retrieve: With Filter Criteria parameter - element semanticsFilter (two)
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with two semanticsFilter element.
    [Tags]    not-implemented    exclude
    TODO

2.18.18 REQ: Retrieve: With Filter Criteria parameter - element filterOperation
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with filterOperation element.
    [Tags]    not-implemented    exclude
    TODO

2.18.19 REQ: Retrieve: With Filter Criteria parameter - element contentFilterSyntax
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with contentFilterSyntax element.
    [Tags]    not-implemented    exclude
    TODO

2.18.20 REQ: Retrieve: With Filter Criteria parameter - element contentFilterQuery
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with contentFilterQuery element.
    [Tags]    not-implemented    exclude
    TODO

2.18.21 REQ: Retrieve: With Filter Criteria parameter - element level
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with level element.
    [Tags]    not-implemented    exclude
    TODO

2.18.22 REQ: Retrieve: With Filter Criteria parameter - element offset
    [Documentation]    Tests Retrieve REQ with Filter Criteria parameter with offset element.
    [Tags]    not-implemented    exclude
    TODO

2.99 REQ: Retrieve: With all optional parameters set
    [Documentation]    Tests Retrieve REQ with all mandatory and optional parameters set
    [Tags]    not-implemented    exclude
    TODO

3.00 REQ: Update: With mandatory parameters only
    [Documentation]    Tests Update REQ with mandatory parameters only.
    [Tags]    not-implemented    exclude
    TODO

3.01 REQ: Update: Missing mandatory parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Update REQ with some mandatory parameter(s) missing.
    [Tags]    not-implemented    exclude
    TODO

3.02 REQ: Update: With non-provided parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Update REQ with non-provided parameter(s).
    [Tags]    not-implemented    exclude
    TODO

3.03 REQ: Update: With Role IDs parameter
    [Documentation]    Tests Update REQ with Role IDs parameter.
    [Tags]    not-implemented    exclude
    TODO

3.04 REQ: Update: With Originating Timestamp parameter
    [Documentation]    Tests Update REQ with Originating Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

3.05 REQ: Update: With Request Expiration Timestamp parametr
    [Documentation]    Tests Update REQ with Request Expiration Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

3.06 REQ: Update: With Result Expiration Time parameter
    [Documentation]    Tests Update REQ with Result Expiration Time parameter.
    [Tags]    not-implemented    exclude
    TODO

3.07 REQ: Update: With Operation Execution Time parameter
    [Documentation]    Tests Update REQ with Operation Execution Time parameter.
    [Tags]    not-implemented    exclude
    TODO

3.08 REQ: Update: With Response Type parameter
    [Documentation]    Tests Update REQ with Response Type parameter.
    [Tags]    not-implemented    exclude
    TODO

3.09 REQ: Update: With Result Persistence parameter
    [Documentation]    Tests Update REQ with Result Persistence parameter.
    [Tags]    not-implemented    exclude
    TODO

3.10.1 REQ: Update: With Result Content parameter - legal
    [Documentation]    Tests Update REQ with Result Content parameter set to legal values.
    ...    rcn=1, 0/ null is legal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    ${attr} =    Set Variable    "or":"http://hey/you"
    : FOR    ${rcn}    IN    \    0    1    5
    ...    6
    \    ${r} =    Update Resource With Command    ${iserver}    InCSE1/AE1    ${rt_ae}    rcn=${rcn}
    \    ...    ${attr}

3.10.2 REQ: Update: With Result Content parameter - illegal
    [Documentation]    NEGATIVE: Tests Update REQ with Result Content parameter set to illegal values.
    ...    rcn=2, 3, 7 is illegal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    ${attr} =    Set Variable    "or":"http://hey/you"
    : FOR    ${rcn}    IN    2    3    4    7
    \    ${error} =    Run Keyword And Expect Error    *    Update Resource With Command    ${iserver}    InCSE1/AE1
    \    ...    ${rt_ae}    rcn=${rcn}    ${attr}
    \    Should Start with    ${error}    Cannot update this resource [400]
    \    Should Contain    ${error}    rcn

3.11 REQ: Update: With Event Category parameter
    [Documentation]    Tests Update REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

3.12 REQ: Update: With Delivery Aggregation parameter
    [Documentation]    Tests Update REQ with Delivery Aggregation parameter
    [Tags]    not-implemented    exclude
    TODO

3.13 REQ: Update: With Group Request Identifier parameter
    [Documentation]    Tests Update REQ with Group Request Identifier parameter
    [Tags]    not-implemented    exclude
    TODO

3.14 REQ: Update: With Tokens parameter
    [Documentation]    Tests Update REQ with Tokens parameter
    [Tags]    not-implemented    exclude
    TODO

3.15 REQ: Update: With Token IDs parameter
    [Documentation]    Tests Update REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

3.16.01 REQ: Update: With Filter Criteria parameter - element createdBefore
    [Documentation]    Tests Update REQ with Filter Criteria parameter with createdBefore element.
    [Tags]    not-implemented    exclude
    TODO

3.16.02 REQ: Update: With Filter Criteria parameter - element createdAfter
    [Documentation]    Tests Update REQ with Filter Criteria parameter with createdAfter element.
    [Tags]    not-implemented    exclude
    TODO

3.16.03 REQ: Update: With Filter Criteria parameter - element modifiedSince
    [Documentation]    Tests Update REQ with Filter Criteria parameter with modifiedSince element.
    [Tags]    not-implemented    exclude
    TODO

3.16.04 REQ: Update: With Filter Criteria parameter - element unmodifiedSince
    [Documentation]    Tests Update REQ with Filter Criteria parameter with unmodifiedSince element.
    [Tags]    not-implemented    exclude
    TODO

3.16.05 REQ: Update: With Filter Criteria parameter - element stateTagSmaller
    [Documentation]    Tests Update REQ with Filter Criteria parameter with stateTagSmaller element.
    [Tags]    not-implemented    exclude
    TODO

3.16.06 REQ: Update: With Filter Criteria parameter - element stateTagBigger
    [Documentation]    Tests Update REQ with Filter Criteria parameter with stateTagBigger element.
    [Tags]    not-implemented    exclude
    TODO

3.16.07 REQ: Update: With Filter Criteria parameter - element expireBefore
    [Documentation]    Tests Update REQ with Filter Criteria parameter with expireBefore element.
    [Tags]    not-implemented    exclude
    TODO

3.16.08 REQ: Update: With Filter Criteria parameter - element expireAfter
    [Documentation]    Tests Update REQ with Filter Criteria parameter with expireAfter element.
    [Tags]    not-implemented    exclude
    TODO

3.16.09.01 REQ: Update: With Filter Criteria parameter - element labels (one)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with one labels element.
    [Tags]    not-implemented    exclude
    TODO

3.16.09.02 REQ: Update: With Filter Criteria parameter - element labels (two)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with two labels elements.
    [Tags]    not-implemented    exclude
    TODO

3.16.10 REQ: Update: With Filter Criteria parameter - element resourceType
    [Documentation]    Tests Update REQ with Filter Criteria parameter with resourceType element.
    [Tags]    not-implemented    exclude
    TODO

3.16.11 REQ: Update: With Filter Criteria parameter - element sizeAbove
    [Documentation]    Tests Update REQ with Filter Criteria parameter with sizeAbove element.
    [Tags]    not-implemented    exclude
    TODO

3.16.12 REQ: Update: With Filter Criteria parameter - element sizeBelow
    [Documentation]    Tests Update REQ with Filter Criteria parameter with sizeBelow element.
    [Tags]    not-implemented    exclude
    TODO

3.16.13.01 REQ: Update: With Filter Criteria parameter - element contentType (one)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with one contentType element.
    [Tags]    not-implemented    exclude
    TODO

3.16.13.02 REQ: Update: With Filter Criteria parameter - element contentType (two)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with two contentType elements.
    [Tags]    not-implemented    exclude
    TODO

3.16.14.01 REQ: Update: With Filter Criteria parameter - element attribute (one)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with one attribute element.
    [Tags]    not-implemented    exclude
    TODO

3.16.14.02 REQ: Update: With Filter Criteria parameter - element attribute (two)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with two attribute elements.
    [Tags]    not-implemented    exclude
    TODO

3.16.15 REQ: Update: With Filter Criteria parameter - element filterUsage
    [Documentation]    Tests Update REQ with Filter Criteria parameter with filterUsage element.
    [Tags]    not-implemented    exclude
    TODO

3.16.16 REQ: Update: With Filter Criteria parameter - element limit
    [Documentation]    Tests Update REQ with Filter Criteria parameter with limit element.
    [Tags]    not-implemented    exclude
    TODO

3.16.17.01 REQ: Update: With Filter Criteria parameter - element semanticsFilter (one)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with one semanticsFilter element.
    [Tags]    not-implemented    exclude
    TODO

3.16.17.02 REQ: Update: With Filter Criteria parameter - element semanticsFilter (two)
    [Documentation]    Tests Update REQ with Filter Criteria parameter with two semanticsFilter element.
    [Tags]    not-implemented    exclude
    TODO

3.16.18 REQ: Update: With Filter Criteria parameter - element filterOperation
    [Documentation]    Tests Update REQ with Filter Criteria parameter with filterOperation element.
    [Tags]    not-implemented    exclude
    TODO

3.16.19 REQ: Update: With Filter Criteria parameter - element contentFilterSyntax
    [Documentation]    Tests Update REQ with Filter Criteria parameter with contentFilterSyntax element.
    [Tags]    not-implemented    exclude
    TODO

3.16.20 REQ: Update: With Filter Criteria parameter - element contentFilterQuery
    [Documentation]    Tests Update REQ with Filter Criteria parameter with contentFilterQuery element.
    [Tags]    not-implemented    exclude
    TODO

3.16.21 REQ: Update: With Filter Criteria parameter - element level
    [Documentation]    Tests Update REQ with Filter Criteria parameter with level element.
    [Tags]    not-implemented    exclude
    TODO

3.16.22 REQ: Update: With Filter Criteria parameter - element offset
    [Documentation]    Tests Update REQ with Filter Criteria parameter with offset element.
    [Tags]    not-implemented    exclude
    TODO

3.99 REQ: Update: With all optional parameters set
    [Documentation]    Tests Update REQ with all mandatory and optional parameters set
    [Tags]    not-implemented    exclude
    TODO

4.00 REQ: Delete: With mandatory parameters only
    [Documentation]    Tests Delete REQ with mandatory parameters only.
    [Tags]    not-implemented    exclude
    TODO

4.01 REQ: Delete: Missing mandatory parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Delete REQ with some mandatory parameter(s) missing.
    [Tags]    not-implemented    exclude
    TODO

4.02 REQ: Delete: With non-provided parameters
    [Documentation]    NEGATIVE: Tests multiple cases of Delete REQ with non-provided parameter(s).
    [Tags]    not-implemented    exclude
    TODO

4.03 REQ: Delete: With Role IDs parameter
    [Documentation]    Tests Delete REQ with Role IDs parameter.
    [Tags]    not-implemented    exclude
    TODO

4.04 REQ: Delete: With Originating Timestamp parameter
    [Documentation]    Tests Delete REQ with Originating Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

4.05 REQ: Delete: With Request Expiration Timestamp parametr
    [Documentation]    Tests Delete REQ with Request Expiration Timestamp parameter.
    [Tags]    not-implemented    exclude
    TODO

4.06 REQ: Delete: With Result Expiration Time parameter
    [Documentation]    Tests Delete REQ with Result Expiration Time parameter.
    [Tags]    not-implemented    exclude
    TODO

4.07 REQ: Delete: With Operation Execution Time parameter
    [Documentation]    Tests Delete REQ with Operation Execution Time parameter.
    [Tags]    not-implemented    exclude
    TODO

4.08 REQ: Delete: With Response Type parameter
    [Documentation]    Tests Delete REQ with Response Type parameter.
    [Tags]    not-implemented    exclude
    TODO

4.09 REQ: Delete: With Result Persistence parameter
    [Documentation]    Tests Delete REQ with Result Persistence parameter.
    [Tags]    not-implemented    exclude
    TODO

4.10.1 REQ: Delete: With Result Content parameter - legal
    [Documentation]    Tests Delete REQ with Result Content parameter set to legal values.
    ...    rcn=2, 3, 4, 5, 6, 7 is illegal
    # TODO: check with TS-0004: 7.5.2 Elements contained in the Content primitive parameter
    ${attr} =    Set Variable    "or":"http://hey/you"
    : FOR    ${rcn}    IN    2    3    4    7
    \    ${error} =    Run Keyword And Expect Error    *    Delete Resource With Command    ${iserver}    InCSE1/AE1
    \    ...    rcn=${rcn}
    \    Should Start with    ${error}    Cannot delete this resource [400]
    \    Should Contain    ${error}    rcn

4.10.2 REQ: Delete: With Result Content parameter - illegal
    [Documentation]    NEGATIVE: Tests Delete REQ with Result Content parameter set to illegal values.
    [Tags]    not-implemented    exclude
    TODO

4.11 REQ: Delete: With Event Category parameter
    [Documentation]    Tests Delete REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

4.12 REQ: Delete: With Delivery Aggregation parameter
    [Documentation]    Tests Delete REQ with Delivery Aggregation parameter
    [Tags]    not-implemented    exclude
    TODO

4.13 REQ: Delete: With Group Request Identifier parameter
    [Documentation]    Tests Delete REQ with Group Request Identifier parameter
    [Tags]    not-implemented    exclude
    TODO

4.14 REQ: Delete: With Tokens parameter
    [Documentation]    Tests Delete REQ with Tokens parameter
    [Tags]    not-implemented    exclude
    TODO

4.15 REQ: Delete: With Token IDs parameter
    [Documentation]    Tests Delete REQ with Event Category parameter
    [Tags]    not-implemented    exclude
    TODO

4.16.01 REQ: Delete: With Filter Criteria parameter - element createdBefore
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with createdBefore element.
    [Tags]    not-implemented    exclude
    TODO

4.16.02 REQ: Delete: With Filter Criteria parameter - element createdAfter
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with createdAfter element.
    [Tags]    not-implemented    exclude
    TODO

4.16.03 REQ: Delete: With Filter Criteria parameter - element modifiedSince
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with modifiedSince element.
    [Tags]    not-implemented    exclude
    TODO

4.16.04 REQ: Delete: With Filter Criteria parameter - element unmodifiedSince
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with unmodifiedSince element.
    [Tags]    not-implemented    exclude
    TODO

4.16.05 REQ: Delete: With Filter Criteria parameter - element stateTagSmaller
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with stateTagSmaller element.
    [Tags]    not-implemented    exclude
    TODO

4.16.06 REQ: Delete: With Filter Criteria parameter - element stateTagBigger
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with stateTagBigger element.
    [Tags]    not-implemented    exclude
    TODO

4.16.07 REQ: Delete: With Filter Criteria parameter - element expireBefore
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with expireBefore element.
    [Tags]    not-implemented    exclude
    TODO

4.16.08 REQ: Delete: With Filter Criteria parameter - element expireAfter
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with expireAfter element.
    [Tags]    not-implemented    exclude
    TODO

4.16.09.01 REQ: Delete: With Filter Criteria parameter - element labels (one)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with one labels element.
    [Tags]    not-implemented    exclude
    TODO

4.16.09.02 REQ: Delete: With Filter Criteria parameter - element labels (two)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with two labels elements.
    [Tags]    not-implemented    exclude
    TODO

4.16.10 REQ: Delete: With Filter Criteria parameter - element resourceType
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with resourceType element.
    [Tags]    not-implemented    exclude
    TODO

4.16.11 REQ: Delete: With Filter Criteria parameter - element sizeAbove
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with sizeAbove element.
    [Tags]    not-implemented    exclude
    TODO

4.16.12 REQ: Delete: With Filter Criteria parameter - element sizeBelow
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with sizeBelow element.
    [Tags]    not-implemented    exclude
    TODO

4.16.13.01 REQ: Delete: With Filter Criteria parameter - element contentType (one)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with one contentType element.
    [Tags]    not-implemented    exclude
    TODO

4.16.13.02 REQ: Delete: With Filter Criteria parameter - element contentType (two)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with two contentType elements.
    [Tags]    not-implemented    exclude
    TODO

4.16.14.01 REQ: Delete: With Filter Criteria parameter - element attribute (one)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with one attribute element.
    [Tags]    not-implemented    exclude
    TODO

4.16.14.02 REQ: Delete: With Filter Criteria parameter - element attribute (two)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with two attribute elements.
    [Tags]    not-implemented    exclude
    TODO

4.16.15 REQ: Delete: With Filter Criteria parameter - element filterUsage
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with filterUsage element.
    [Tags]    not-implemented    exclude
    TODO

4.16.16 REQ: Delete: With Filter Criteria parameter - element limit
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with limit element.
    [Tags]    not-implemented    exclude
    TODO

4.16.17.01 REQ: Delete: With Filter Criteria parameter - element semanticsFilter (one)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with one semanticsFilter element.
    [Tags]    not-implemented    exclude
    TODO

4.16.17.02 REQ: Delete: With Filter Criteria parameter - element semanticsFilter (two)
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with two semanticsFilter element.
    [Tags]    not-implemented    exclude
    TODO

4.16.18 REQ: Delete: With Filter Criteria parameter - element filterOperation
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with filterOperation element.
    [Tags]    not-implemented    exclude
    TODO

4.16.19 REQ: Delete: With Filter Criteria parameter - element contentFilterSyntax
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with contentFilterSyntax element.
    [Tags]    not-implemented    exclude
    TODO

4.16.20 REQ: Delete: With Filter Criteria parameter - element contentFilterQuery
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with contentFilterQuery element.
    [Tags]    not-implemented    exclude
    TODO

4.16.21 REQ: Delete: With Filter Criteria parameter - element level
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with level element.
    [Tags]    not-implemented    exclude
    TODO

4.16.22 REQ: Delete: With Filter Criteria parameter - element offset
    [Documentation]    Tests Delete REQ with Filter Criteria parameter with offset element.
    [Tags]    not-implemented    exclude
    TODO

4.99 REQ: Delete: With all optional parameters set
    [Documentation]    Tests Delete REQ with all mandatory and optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

5.01 RSP: Create OK: With mandatory parameters only
    [Documentation]    Sends such Create request which results with successful response with mandatory parameters only.
    [Tags]    not-implemented    exclude
    TODO

5.02 RSP: Create OK: With optional parameters
    [Documentation]    Sends such Create request which results with successful response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

5.03 RSP: Retrieve OK: With mandatory parameters only
    [Documentation]    Sends such Retrieve request which results with successful response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

5.04 RSP: Retrieve OK: With optional parameters
    [Documentation]    Sends such Retrieve request which results with successful response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

5.05 RSP: Update OK: With mandatory parameters only
    [Documentation]    Sends such Update request which results with successful response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

5.06 RSP: Update OK: With optional parameters
    [Documentation]    Sends such Update request which results with successful response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

5.07 RSP: Delete OK: With mandatory parameters only
    [Documentation]    Sends such Delete request which results with successful response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

5.08 RSP: Delete OK: With optional parameters
    [Documentation]    Sends such Delete request which results with successful response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

6.01 RSP: Create ERROR: With mandatory parameters only
    [Documentation]    Sends such Create request which results with error response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

6.02 RSP: Create ERROR: With optional parameters
    [Documentation]    Sends such Create request which results with error response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

6.03 RSP: Retrieve ERROR: With mandatory parameters only
    [Documentation]    Sends such Retrieve request which results with error response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

6.04 RSP: Retrieve ERROR: With optional parameters
    [Documentation]    Sends such Retrieve request which results with error response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

6.05 RSP: Update ERROR: With mandatory parameters only
    [Documentation]    Sends such Update request which results with error response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

6.06 RSP: Update ERROR: With optional parameters
    [Documentation]    Sends such Update request which results with error response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

6.07 RSP: Delete ERROR: With mandatory parameters only
    [Documentation]    Sends such Delete request which results with error response with mandatory
    ...    parameters only.
    [Tags]    not-implemented    exclude
    TODO

6.08 RSP: Delete ERROR: With optional parameters
    [Documentation]    Sends such Delete request which results with error response with
    ...    optional parameters set.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
Connect And Create The Tree
    [Documentation]    Create a tree that contain AE/ container / contentInstance in different layers
    ${iserver} =    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}    http
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr},"rn":"AE1"
    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr},"rn":"AE2"
    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr},"rn":"AE3"
    Create Resource    ${iserver}    InCSE1/AE1    ${rt_container}    "rn":"Container1"
    Create Resource    ${iserver}    InCSE1/AE1    ${rt_container}    "rn":"Container2"
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":150,"or":"http://hey/you","lbl":["underCSE"]
    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr},"rn":"Container3"
    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr},"rn":"Container4"
    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr},"rn":"Container5"
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":150,"or":"http://hey/you","lbl":["underAEContainer"]
    Create Resource    ${iserver}    InCSE1/AE1/Container1    ${rt_container}    ${attr},"rn":"Container6"
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":150,"or":"http://hey/you","lbl":["underCSEContainer"]
    Create Resource    ${iserver}    InCSE1/Container3    ${rt_container}    ${attr},"rn":"Container7"
    Create Resource    ${iserver}    InCSE1/Container3    ${rt_container}    ${attr},"rn":"Container8"
    Create Resource    ${iserver}    InCSE1/Container3    ${rt_container}    ${attr},"rn":"Container9"
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102","lbl":["contentInstanceUnderAEContainer"]
    Create Resource    ${iserver}    InCSE1/AE1/Container1    ${rt_contentInstance}    ${attr},"rn":"conIn1"
    Create Resource    ${iserver}    InCSE1/AE1/Container1    ${rt_contentInstance}    ${attr},"rn":"conIn2"
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102","lbl":["contentInstanceUnderContainerContainer"]
    Create Resource    ${iserver}    InCSE1/Container3    ${rt_contentInstance}    ${attr},"rn":"conIn3"
    Create Resource    ${iserver}    InCSE1/Container3    ${rt_contentInstance}    ${attr},"rn":"conIn4"
    Create Resource    ${iserver}    InCSE1/Container3    ${rt_contentInstance}    ${attr},"rn":"conIn5"
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102","lbl":["contentInstanceUnderContainer"]
    Create Resource    ${iserver}    InCSE1/Container4    ${rt_contentInstance}    ${attr},"rn":"conIn6"
    Create Resource    ${iserver}    InCSE1/Container4    ${rt_contentInstance}    ${attr},"rn":"conIn7"
    Create Resource    ${iserver}    InCSE1/Container4    ${rt_contentInstance}    ${attr},"rn":"conIn8"

TODO
    Fail    "Not implemented"
