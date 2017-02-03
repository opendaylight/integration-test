*** Settings ***
Documentation     Tests for Content Instance resource attributes
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

*** Test Cases ***
TODO Refactor test suite and implement TCs
    [Documentation]    Refactor this test suite and implement next TCs according to 000_ResourceAttributesNotes.txt03.
    ...    Example of changes is in 024_ResourceAttributesAE.robot
    [Tags]    not-implemented    exclude
    TODO

1.1 After Created, test whether all the mandatory attribtues are exist.
    [Documentation]    create 1 conIn test whether all the mandatory attribtues are exist
    ${attr} =    Set Variable    "rn":"Container1"
    ${r}=    Create Resource With Command    ${iserver}    InCSE1    ${rt_container}    rcn=3    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${attr} =    Set Variable    "con":"102CSS","rn":"conIn1"
    ${r} =    Create Resource With Command    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    rcn=3    ${attr}
    ${text} =    Text    ${r}
    Should Contain All Sub Strings    ${text}    "ri":    "rn":    "cs":    "lt":    "pi":
    ...    "con":    "ct":    "ty":4
    Should Not Contain    S{text}    "lbl"    "creator"    "or"

1.21 Missing content should return error
    [Documentation]    Missing content should return error
    ${attr} =    Set Variable
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    CONTENT    missing
    #===========================================================
    #    ContentInstance Optional Attribute Test (Allowed)
    #===========================================================
    #    create--> delete
    #    Cannot be updated
    # Optional attribute: [aa,at],contentInfo, ontologyRef, label, creator

2.11 ContentInfo (cnf) can be added when create
    [Documentation]    ContentInfo (cnf) can be added when create
    ${attr} =    Set Variable    "cnf": "1","con":"102CSS","rn":"conIn2"
    # create conIn under Container1
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}
    ${text} =    Check Create and Retrieve ContentInstance    ${r}
    Should Contain    ${text}    cnf

Delete the ContenInstance 2.1
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container1/conIn2

2.12 ContentInfo (cnf) cannot be updated
    [Documentation]    ContentInfo (cnf) cannot be updated
    ${attr} =    Set Variable    "cnf": "1"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

2.21 OntologyRef (or) can be added when create
    [Documentation]    OntologyRef (or) can be added when create
    ${attr} =    Set Variable    "or": "http://cisco.com","con":"102CSS","rn":"conIn2"
    # create conIn under Container1
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}
    ${text} =    Check Create and Retrieve ContentInstance    ${r}
    Should Contain    ${text}    or

Delete the ContenInstance 2.2
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container1/conIn2

2.22 OntologyRef (or) cannot be updated
    [Documentation]    OntologyRef (or) cannot be updated
    ${attr} =    Set Variable    "or": "1"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

2.31 labels[single] can be added when create
    [Documentation]    create conIn under Container1, labels[single] can be added when create
    ${attr} =    Set Variable    "lbl":["ds"],"con":"102CSS","rn":"conIn2"
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}
    ${text} =    Check Create and Retrieve ContentInstance    ${r}
    Should Contain    ${text}    lbl

Delete the ContenInstance 2.31
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container1/conIn2

2.32 labels (single) cannot be updated
    [Documentation]    update labels then expect error
    ${attr} =    Set Variable    "lbl":["1"]
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

2.33 labels (multiple) can be added when create
    [Documentation]    labels (multiple) can be added when create
    ${attr} =    Set Variable    "lbl":["http://cisco.com","dsds"],"con":"102CSS","rn":"conIn2"
    # create conIn under Container1
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}
    ${text} =    Check Create and Retrieve ContentInstance    ${r}
    Should Contain    ${text}    lbl

Delete the ContenInstance 2.33
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container1/conIn2

2.34 labels (multiple) cannot be updated
    [Documentation]    labels (multiple) cannot be updated
    ${attr} =    Set Variable    "lbl":["1"]
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content
    #=================================================================
    #    contentInstance Disturbing Attribute Test, Not Allowed Update
    #=================================================================
    # using non-valid attribtue to create then expext error

3.11 Mulitiple labels should return error
    [Documentation]    Mulitiple labels should return error
    ${attr} =    Set Variable    "con": "1", "lbl":["label1"],"lbl":["label2"]
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate    lbl

3.12 Multiple creator should return error
    [Documentation]    Multiple creator should return error
    ${attr} =    Set Variable    "con": "1", "cr":null, "cr":null
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate    cr

3.13 Multiple contentInfo should return error
    [Documentation]    Multiple contentInfo should return error
    ${attr} =    Set Variable    "con": "1", "cnf":"1","cnf":"2"
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate    cnf

3.14 Multiple ontologyRef should return error
    [Documentation]    Multiple ontologyRef should return error
    ${attr} =    Set Variable    "con": "1", "or":"http://cisco.com","or":"http://google.com"
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate    or

3.15 Mulptiple content should return error
    [Documentation]    Mulptiple content should return error
    ${attr} =    Set Variable    "con": "1", "con":"2313"
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate    con
    #----------------All attributes cannot be updated----------

3.21 resourceType cannot be updated.
    [Documentation]    update resourceType and expect error
    ${attr} =    Set Variable    "rt": 3
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.22 resourceId cannot be updated.
    [Documentation]    update resourceId and expect error
    ${attr} =    Set Variable    "ri": "e4e43"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.23 resourceName cannot be updated.
    [Documentation]    update resourceName and expect error
    ${attr} =    Set Variable    "rn": "4343"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.24 parentId cannot be updated.
    [Documentation]    update parentID and expect error
    ${attr} =    Set Variable    "pi": "InCSE2/ERE"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.25 cretionTime cannot be updated.
    [Documentation]    update createTime and expect error
    ${attr} =    Set Variable    "ct": "20201210T123434"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.26 last modified time cannot be updated.
    [Documentation]    update lt then expect error
    ${attr} =    Set Variable    "lt": "20201210T123434"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.27 contentSize cannot be updated.
    [Documentation]    update contentSize then expect error
    ${attr} =    Set Variable    "cs": 232
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.28 content cannot be updated
    [Documentation]    update content then expect error
    ${attr} =    Set Variable    "con": "1"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

4.11 GetLatest Test
    [Documentation]    Set mni to 1 when creating a container, then continue creating <cin> "get latest" should always return the last created <cin>'s "con" value.
    ${attr} =    Set Variable    "mni":1,"rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${random} =    Evaluate    random.randint(0,50)    modules=random
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"${random}"
    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}
    ${latestCon} =    Get Latest    ${container}
    Should Be Equal As Strings    ${random}    ${latestCon}

4.12 GetLatest Loop 50 times Test
    [Documentation]    Just like 4.11, but do 50 times.
    ${attr} =    Set Variable    "mni":1,"rn":"Container3"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    : FOR    ${INDEX}    IN RANGE    1    100
    \    Latest Con Test    ${container}

Delete the test Container1
    [Documentation]    Delete the test Container1
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container1

*** Keywords ***
Cannot Update ContentInstance Error
    [Arguments]    ${attr}
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    InCSE1/Container1/conIn1    ${rt_contentInstance}
    ...    ${attr}
    Should Start with    ${error}    Cannot update this resource [405]
    [Return]    ${error}

Cannot Craete ContentInstance Error
    [Arguments]    ${attr}
    ${error} =    Run Keyword And Expect Error    *    create Resource    ${iserver}    InCSE1/Container1/conIn1    ${rt_contentInstance}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    [Return]    ${error}

Check Create and Retrieve ContentInstance
    [Arguments]    ${r}
    ${con} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${rr} =    Retrieve Resource    ${iserver}    ${con}
    ${text} =    Text    ${rr}
    [Return]    ${text}

Get Latest
    [Arguments]    ${resourceURI}
    ${latest} =    Retrieve Resource    ${iserver}    ${resourceURI}/latest
    ${con} =    Content    ${latest}
    [Return]    ${con}

Latest Con Test
    [Arguments]    ${resourceURI}
    ${random} =    Evaluate    random.randint(0,50)    modules=random
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"${random}"
    Create Resource    ${iserver}    ${resourceURI}    ${rt_contentInstance}    ${attr}
    ${latestCon} =    Get Latest    ${resourceURI}
    Should Be Equal As Strings    ${random}    ${latestCon}

TODO
    Fail    "Not implemented"
