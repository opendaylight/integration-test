*** Settings ***
Suite Teardown    Kill The Tree    InCSE1    admin    admin
Library           ../../../libraries/criotdm.py
Library           Collections

*** Variables ***
${httphost}       ${CONTROLLER}
${httpuser}       admin
${httppass}       admin
${rt_ae}          2
${rt_container}    3
${rt_contentInstance}    4

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable ${iserver}
    #==================================================
    #    Container Mandatory Attribute Test
    #==================================================
    # mandatory attribute: content
    # cse
    #    |
    #    ---Container1
    #    |
    #    ----conIn1
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}

1.1 After Created, test whether all the mandatory attribtues are exist.
    [Documentation]    create 1 conIn test whether all the mandatory attribtues are exist
    ${attr} =    Set Variable
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    Container1
    ${container} =    Name    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${attr} =    Set Variable    "con":"102CSS"
    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}    conIn1
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ri":    "rn":    "cs":
    Should Contain    ${text}    "lt":    "pi":    "con":
    Should Contain    ${text}    "ct":    "rty":4
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
    ${attr} =    Set Variable    "cnf": "1","con":"102CSS"
    # create conIn under Container1
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}    conIn2
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
    ${attr} =    Set Variable    "or": "http://cisco.com","con":"102CSS"
    # create conIn under Container1
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}    conIn2
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
    ${attr} =    Set Variable    "lbl":["ds"],"con":"102CSS"
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}    conIn2
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
    ${attr} =    Set Variable    "lbl":["http://cisco.com","dsds"],"con":"102CSS"
    # create conIn under Container1
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}    conIn2
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
    Should Contain    ${error}    Duplicate    lbl

3.12 Multiple creator should return error
    [Documentation]    Multiple creator should return error
    ${attr} =    Set Variable    "con": "1", "cr":null, "cr":null
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain    ${error}    Duplicate    cr

3.13 Multiple contentInfo should return error
    [Documentation]    Multiple contentInfo should return error
    ${attr} =    Set Variable    "con": "1", "cnf":"1","cnf":"2"
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain    ${error}    Duplicate    cnf

3.14 Multiple ontologyRef should return error
    [Documentation]    Multiple ontologyRef should return error
    ${attr} =    Set Variable    "con": "1", "or":"http://cisco.com","or":"http://google.com"
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain    ${error}    Duplicate    or

3.15 Mulptiple content should return error
    [Documentation]    Mulptiple content should return error
    ${attr} =    Set Variable    "con": "1", "con":"2313"
    ${error} =    Cannot Craete ContentInstance Error    ${attr}
    Should Contain    ${error}    Duplicate    con
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
    ${attr} =    Set Variable    "ct": "343434T34322"
    ${error} =    Cannot Update ContentInstance Error    ${attr}
    Should Contain    ${error}    Not permitted to update content

3.26 lastmodifiedTime cannot be updated.
    [Documentation]    update lt then expect error
    ${attr} =    Set Variable    "lt": "434343T23232"
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
    #==================================================
    #    Functional Attribute Test
    #==================================================
    # Next step:
    # creator
    # contentSzie
    # contentInfo
    # content
    #==================================================
    #    Finish
    #==================================================

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
    ${con} =    Name    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${rr} =    Retrieve Resource    ${iserver}    ${con}
    ${text} =    Text    ${rr}
    [Return]    ${text}
