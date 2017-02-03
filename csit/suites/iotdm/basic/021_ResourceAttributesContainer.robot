*** Settings ***
Documentation     Tests for Container resource attributes
Suite Setup       Start
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
TODO Refactor test suite and implement TCs
    [Documentation]    Refactor this test suite and implement next TCs according to 000_ResourceAttributesNotes.txt03.
    ...    Example of changes is in 024_ResourceAttributesAE.robot
    [Tags]    not-implemented    exclude
    TODO

1.1 After Created, test whether all the mandatory attribtues are exist.
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    #==================================================
    #    Container Mandatory Attribute Test
    #==================================================
    # For Creation, there are no mandatory input attribute
    ${attr} =    Set Variable    "rn":"Container1"
    ${r}=    Create Resource With Command    ${iserver}    InCSE1    ${rt_container}    rcn=3    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain All Sub Strings    ${text}    "ri":    "rn":    "cni"    "lt":    "pi":
    ...    "st":    "ct":    "ty":3    "cbs"
    Should Not Contain Any Sub Strings    ${text}    "lbl"    "creator"    "or"

2.11 maxNumberofInstance (mni) can be added when create
    [Documentation]    maxNumberofInstance (mni) can be added when create
    #==================================================
    #    Container Optional Attribute Test (Allowed)
    #==================================================
    #    create--> delete
    #    update(create)--> update(modified)-->update (delete)
    ${attr} =    Set Variable    "mni":3,"rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "mni"

Delete the Container2-2.1
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2

2.12 maxNumberofInstance (mni) can be added through update (0-1)
    [Documentation]    maxNumberofInstance (mni) can be added through update (0-1)
    ${attr} =    Set Variable    "mni":3
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain    ${text}    "mni"

2.13 maxNumberofInstance (mni) can be modified through update (1-1)
    [Documentation]    maxNumberofInstance (mni) can be modified through update (1-1)
    ${attr} =    Set Variable    "mni":5
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain    ${text}    "mni":5
    Should Not Contain    ${text}    "mni":3

2.14 if set to null, maxnumberofInstance (mni) can be deleted through delete(1-0)
    [Documentation]    if set to null, maxnumberofInstance (mni) can be deleted through delete(1-0)
    ${attr} =    Set Variable    "mni":null
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain    ${text}    "mni"

2.21 maxByteSize (mbs) can be added when create
    [Documentation]    maxByteSize (mbs) can be added when create
    ${attr} =    Set Variable    "mbs":20,"rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "mbs"

Delete the Container2-2.2
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2

2.22 maxByteSize (mbs) can be added through update (0-1)
    [Documentation]    maxByteSize (mbs) can be added through update (0-1)
    ${attr} =    Set Variable    "mbs":20
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain    ${text}    "mbs"

2.23 maxByteSize (mbs) can be modified through update (1-1)
    [Documentation]    maxByteSize (mbs) can be modified through update (1-1)
    ${attr} =    Set Variable    "mbs":25
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain    ${text}    "mbs":25
    Should Not Contain    ${text}    "mbs":20

2.24 if set to null, maxByteSize (mbs) can be deleted through delete(1-0)
    [Documentation]    if set to null, maxByteSize (mbs) can be deleted through delete(1-0)
    ${attr} =    Set Variable    "mbs":null
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain    ${text}    "mbs"

2.31 ontologyRef(or) can be added when create
    [Documentation]    ontologyRef(or) can be added when create
    ${attr} =    Set Variable    "or":"http://cisco.com","rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container2
    Should Contain    ${text}    "or"

Delete the Container2-2.3
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2

2.32 ontologyRef(or) can be added through update (0-1)
    [Documentation]    ontologyRef(or) can be added through update (0-1)
    ${attr} =    Set Variable    "or":"http://cisco.com"
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain    ${text}    "or"

2.33 ontologyRef(or) can be modified through update (1-1)
    [Documentation]    ontologyRef(or) can be modified through update (1-1)
    ${attr} =    Set Variable    "or":"http://iotdm.com"
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain    ${text}    "or":"http://iotdm.com"
    Should Not Contain    ${text}    "or":"http://cisco.com"

2.34 if set to null, ontologyRef(or) can be deleted through delete(1-0)
    [Documentation]    if set to null, ontologyRef(or) can be deleted through delete(1-0)
    ${attr} =    Set Variable    "or":null
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain    ${text}    "or"

2.41 labels can be created through update (0-1)
    [Documentation]    labels can be created through update (0-1)
    ${attr} =    Set Variable    "lbl":["label1"]
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain All Sub Strings    ${text}    lbl    label1

2.42 labels can be modified (1-1)
    [Documentation]    labels can be modified (1-1)
    ${attr} =    Set Variable    "lbl":["label2"]
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain    ${text}    label1
    Should Contain All Sub Strings    ${text}    lbl    label2

2.43 if set to null, labels should be deleted(1-0)
    [Documentation]    if set to null, labels should be deleted(1-0)
    ${attr} =    Set Variable    "lbl":null
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain Any Sub Strings    ${text}    lbl    label1    label2

2.44 labels can be created through update (0-n)
    [Documentation]    labels can be created through update (0-n)
    ${attr} =    Set Variable    "lbl":["label3","label4","label5"]
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Contain All Sub Strings    ${text}    lbl    label3    label4    label5

2.45 labels can be modified (n-n)(across)
    [Documentation]    labels can be modified (n-n)(across)
    ${attr} =    Set Variable    "lbl":["label4","label5","label6"]
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain Any Sub Strings    ${text}    label1    label2    label3
    Should Contain All Sub Strings    ${text}    lbl    label4    label5    label6

2.46 labels can be modified (n-n)(not across)
    [Documentation]    labels can be modified (n-n)(not across)
    ${attr} =    Set Variable    "lbl":["label7","label8","label9"]
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain Any Sub Strings    ${text}    label1    label2    label3    label4    label5
    ...    label6
    Should Contain All Sub Strings    ${text}    lbl    label7    label8    label9

2.47 if set to null, labels should be deleted(n-0)
    [Documentation]    if set to null, labels should be deleted(n-0)
    ${attr} =    Set Variable    "lbl":null
    ${r} =    update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    InCSE1/Container1
    Should Not Contain Any Sub Strings    ${text}    label1    label2    label3    label4    label5
    ...    label6    label7    label8    label9    lbl
    #======================================================
    #    Container Disturbing Attribute Test, Not Allowed Update
    #======================================================
    # using non-valid attribtue to create then expext error

3.11 Mulitiple maxNrofInstance should return error
    [Documentation]    Mulitiple maxNrofInstance should return error
    ${attr} =    Set Variable    "mni":33,"mni":33
    ${error} =    Create Container Expect Cannot Create Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate key    mni

3.12 Mulitiple maxByteSize should return error
    [Documentation]    Mulitiple maxByteSize should return error
    ${attr} =    Set Variable    "mbs":44,"mbs":44
    ${error} =    Create Container Expect Cannot Create Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate key    mbs

3.13 Multiple creator should return error
    [Documentation]    Multiple creator should return error
    ${attr} =    Set Variable    "cr":null,"cr":null
    ${error} =    Create Container Expect Cannot Create Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate key    cr

3.14 Multiple ontologyRef should return error
    [Documentation]    Multiple ontologyRef should return error
    ${attr} =    Set Variable    "or":"http://cisco.com","or":"http://cisco.com"
    ${error} =    Create Container Expect Cannot Create Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate key    or

3.14 Multiple label attribute should return error(multiple array)
    [Documentation]    Multiple label attribute should return error(multiple array)
    ${attr} =    Set Variable    "lbl":["ODL1"], "lbl":["dsdsd"]
    ${error} =    Create Container Expect Cannot Create Error    ${attr}
    Should Contain All Sub Strings    ${error}    Duplicate key    lbl
    #    3.2 Input of Integer using String should return error    [Should checked by wenxin]
    #------------------------------------------------------
    # using non-valid attribute to update then expect error

3.31 resourceType cannot be update.
    [Documentation]    when update resourceType, expect error
    ${attr} =    Set Variable    "ty":2
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: ty"    Error response is not correct

3.32 resourceID cannot be update.
    [Documentation]    update resoureceID then expect error
    ${attr} =    Set Variable    "ri":"aaa"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: ri"    Error response is not correct

3.33 resouceName cannot be update.(write once)
    [Documentation]    update resourceName and expect error
    ${attr} =    Set Variable    "rn":"aaa"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"Resource Name cannot be updated: InCSE1/Container1/aaa"    Error response is not correct

3.34 parentID cannot be update.
    [Documentation]    update parentID and expect error
    ${attr} =    Set Variable    "pi":"aaa"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: pi"    Error response is not correct

3.35 createTime cannot be update.
    [Documentation]    update createTime and expect error
    ${attr} =    Set Variable    "ct":"aaa"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: ct"    Error response is not correct

3.36 curerntByteSize cannot be update --- Special, cannot be modified by the user
    [Documentation]    update currentByteSize and expect error
    ${attr} =    Set Variable    "cbs":123
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"cbs: read-only parameter"    Error response is not correct

3.37 currentNrofInstance cannot be updated --- Special, cannot be modified by the user
    [Documentation]    update cni and expect error
    ${attr} =    Set Variable    "cni":3
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"cni: read-only parameter"    Error response is not correct

3.38 LastMoifiedTime --- Special, cannot be modified by the user
    [Documentation]    update lt and expect error
    ${attr} =    Set Variable    "lt":"aaa"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: lt"    Error response is not correct

3.39 stateTag --- Special, cannot be modified by the user
    [Documentation]    update st and expect error
    ${attr} =    Set Variable    "st":3
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"st: read-only parameter"    Error response is not correct

3.310 creator -- cannot be modified
    [Documentation]    update cr and expect error
    ${attr} =    Set Variable    "cr":null
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CREATOR cannot be updated"    Error response is not correct

3.41 Using AE's M attribute to create
    [Documentation]    use AE attribtue to create Container then expect error
    ${attr} =    Set Variable    "api":"ODL","aei":"ODL"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: aei"    Error response is not correct

3.42 Using ContentInstance's M attribute to create
    [Documentation]    use contentInstance attribtue to create Container then expect error
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${error} =    Update Container Expect Cannot Update Error    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: con"    Error response is not correct
    #==================================================
    #    Functional Attribute Test
    #==================================================
    # 1. lastModifiedTime
    # 2. parentID
    # 3. stateTag
    # 4. currentNrOfInstances
    # 5. currentByteSize
    # 6. maxNrOfInstances
    # 7. maxByteSize
    # 8. creator
    # 9. contentSize
    # 10. childresource
    #-------------- 1.    lastModifiedTime    -----------

4.11 if updated seccessfully, last modified time must be modified.
    [Documentation]    if updated seccessfully, lastModifiedTime must be modified.
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container1
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "lbl":["aaa"]
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    ${r} =    Update Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${lt2} =    Last Modified Time    ${r}
    Should Not Be Equal    ${lt1}    ${lt2}

4.12 childResources create , parent's last modified time update
    [Documentation]    childResources create , parent's lastmodifiedTime update
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container1
    ${lt1} =    Last Modified Time    ${oldr}
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102","rn":"conIn1"
    ${r} =    Create Resource    ${iserver}    InCSE1/Container1    ${rt_contentInstance}    ${attr}
    ${lt2} =    Last Modified Time    ${r}
    Should Not Be Equal    ${lt1}    ${lt2}
    #-------------- 2 parentID ------------

4.21 Check parentID(cse-container)
    [Documentation]    parentID should be InCSE1
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1
    ${CSEID} =    Resid    ${oldr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container1
    ${pi} =    Parent Id    ${r}
    Should Be Equal    /InCSE1/${CSEID}    ${pi}

4.22 Check parentID(cse-container-container)
    [Documentation]    parentID should be correct
    # CSE
    #    |--Contianer1
    #    |--Container2
    ${attr} =    Set Variable    "rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1/Container1    ${rt_container}    ${attr}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container1
    ${CSEID} =    Resid    ${oldr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container1/Container2
    ${pi} =    Parent Id    ${r}
    Should Be Equal    /InCSE1/${CSEID}    ${pi}

4.23 Check parentID(cse-AE-container)
    [Documentation]    parentID should be correct
    # CSE
    #    |--AE1
    #    |--Container2
    ${attr} =    Set Variable    "api":"ODL","apn":"ODL","rr":true,"rn":"AE1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    ${attr} =    Set Variable    "rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1/AE1    ${rt_container}    ${attr}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/AE1
    ${CSEID} =    Resid    ${oldr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/AE1/Container2
    ${pi} =    Parent Id    ${r}
    Should Be Equal    /InCSE1/${CSEID}    ${pi}

4.24 Check parentID(cse-AE-container-container)
    [Documentation]    parentID should be correct
    # CSE
    #    |--AE1
    #    |--Container2
    #    |--- Container3
    ${attr} =    Set Variable    "rn":"Container3"
    ${r}=    Create Resource    ${iserver}    InCSE1/AE1/Container2    ${rt_container}    ${attr}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/AE1/Container2
    ${CSEID} =    Resid    ${oldr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/AE1/Container2/Container3
    ${pi} =    Parent Id    ${r}
    Should Be Equal    /InCSE1/${CSEID}    ${pi}

Delete the test AE-4.2
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/AE1
    #--------------3. stateTag------------

4.31 stateTag (when create, check if 0)
    [Documentation]    when create, st should be 0
    # CSE
    #    |--Container2
    ${attr} =    Set Variable    "rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    ${container}
    ${st} =    State Tag    ${oldr}
    Should Be Equal As Integers    0    ${st}
    # 4.32 stateTag (when update expirationTime)
    # 4.33 stateTag (when update accessControlPolicyIDs)

4.34 stateTag (when update labels) + last modified time
    [Documentation]    st and lt should be changed
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "lbl":["label1"]
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    ${oldstall} =    Create List    ${oldst+1}    ${oldst+2}
    Should Contain    ${oldstall}    ${st}
    Should Not Be Equal    ${lt1}    ${lt2}
    # 4.35 stateTag (when update announceTo)
    # 4.36 stateTag (when update announceAttribute)

4.37 stateTag (when update MaxNrOfInstances) + last modified time
    [Documentation]    st and lt should be changed
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "mni":5
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    ${oldstall} =    Create List    ${oldst+1}    ${oldst+2}
    Should Contain    ${oldstall}    ${st}
    Should Not Be Equal    ${lt1}    ${lt2}

4.38 stateTag (when update MaxByteSize) + last modified time
    [Documentation]    st and lt should be changed
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "mbs":30
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    ${oldstall} =    Create List    ${oldst+1}    ${oldst+2}
    Should Contain    ${oldstall}    ${st}
    Should Not Be Equal    ${lt1}    ${lt2}
    # 4.39 stateTag (when update maxInstanceAge)
    # 4.310 stateTag (when update locationID)

4.311 stateTag (when update ontologyRef) + last modified time
    [Documentation]    st and lt should be changed
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "or":"http://google.com"
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    ${oldstall} =    Create List    ${oldst+1}    ${oldst+2}
    Should Contain    ${oldstall}    ${st}
    Should Not Be Equal    ${lt1}    ${lt2}

4.312 when create child container, stateTag will not increase + last modified time should change
    [Documentation]    when create child container, stateTag will not increase + lastModifiedTime should not change
    # CSE
    #    |--Contianer2
    #    |--Container3
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "lbl":["label1"],"rn":"Container3"
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    Should Be Equal As Integers    ${oldst}    ${st}
    Should Not Be Equal    ${lt1}    ${lt2}

4.313 * when create child contentInsntance, state should increase + last modified time should change
    [Documentation]    when create child contentInsntance, state should increase + lastModifiedTime shold not change
    # CSE
    #    |--Contianer2
    #    |--ContentInstance
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102"
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    ${oldstall} =    Create List    ${oldst+1}    ${oldst+2}
    Should Contain    ${oldstall}    ${st}
    Should Not Be Equal    ${lt1}    ${lt2}

4.314 stateTag should not be updated when update child container
    [Documentation]    stateTag should not be updated when update child container
    # CSE
    #    |--Contianer2
    #    |--Container3
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldst} =    State Tag    ${oldr}
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "lbl":["label45"]
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    Update Resource    ${iserver}    InCSE1/Container2/Container3    ${rt_container}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${lt2} =    Last Modified Time    ${r}
    ${st} =    State Tag    ${r}
    Should Be Equal As Integers    ${oldst}    ${st}
    Should Be Equal    ${lt1}    ${lt2}

Delete the Container2-4.3
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2
    #------------    4.    currentNrofInstance ------

4.41 when container create, cni should be 0
    [Documentation]    when container create, cni should be 0
    ${attr} =    Set Variable    "rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    ${container}
    ${cni} =    Current Number Of Instances    ${oldr}
    Should Be Equal As Integers    0    ${cni}

4.42 when conInstance create, parent container's cni should + 1
    [Documentation]    when conInstance create, parent container's cni should + 1.
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldcni} =    Current Number Of Instances    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102"
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${cni} =    Current Number Of Instances    ${r}
    Should Be Equal As Integers    ${oldcni+1}    ${cni}
    # Test again
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldcni} =    Current Number Of Instances    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102","rn":"contentIn1"
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${cni} =    Current Number Of Instances    ${r}
    Should Be Equal As Integers    ${oldcni+1}    ${cni}

4.43 when conInstance delete, parent container's cni should - 1
    [Documentation]    Delete the conIn created in 4.42, when conInstance delete, parent container's cni should - 1
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldcni} =    Current Number Of Instances    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102"
    Delete Resource    ${iserver}    InCSE1/Container2/contentIn1
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${cni} =    Current Number Of Instances    ${r}
    Should Be Equal As Integers    ${oldcni-1}    ${cni}

Delete the Container2-4.4
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2
    # -------------    5. currentByteSize    -----------

4.51 when container create, cbs should be 0
    [Documentation]    when container create, cbs should be 0
    ${attr} =    Set Variable    "rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    ${container}
    ${cbs} =    Current Byte Size    ${oldr}
    Should Be Equal As Integers    0    ${cbs}

4.52 when conInstance create, parent container's cbs should + cs
    [Documentation]    when conInstance create, parent container's cbs should + cs
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldcbs} =    Current Byte Size    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102CSS"
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${cbs} =    Current Byte Size    ${r}
    Should Be Equal As Integers    ${oldcbs+6}    ${cbs}
    # Test again
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldcbs} =    Current Byte Size    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"xxx%%!@","rn":"contentIn1"
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${cbs} =    Current Byte Size    ${r}
    Should Be Equal As Integers    ${oldcbs+7}    ${cbs}

4.53 when conInstance delete, parent container's cbs should - cs
    [Documentation]    Delete the conIn created in 4.52, when conInstance delete, parent container's cbs should - cs
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${oldcbs} =    Current Byte Size    ${oldr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102"
    Delete Resource    ${iserver}    InCSE1/Container2/contentIn1
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/Container2
    ${cbs} =    Current Byte Size    ${r}
    Should Be Equal As Integers    ${oldcbs-7}    ${cbs}

Delete the Container2-4.5
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2
    # -------------    6. maxNrOfInstances    ----------

4.61 if maxNrOfInstance = 1 , can create 1 contentInstance
    [Documentation]    if maxNrOfInstance = 1 , can create 1 contentInstance
    ${attr} =    Set Variable    "mni":1,"rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    ${container}
    ${mni} =    Max Number Of Instances    ${oldr}
    Should Be Equal As Integers    1    ${mni}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102CSS"
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}

4.62 if maxNrOfInstance = 1 , when create 2 contentInstance, the first one should be deleted
    [Documentation]    if maxNrOfInstance = 1 , cannot create 2 contentInstance
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102CSS"
    # cannot create 2
    ${rr} =    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    Check Response and Retrieve Resource    ${rr}
    ${rr} =    Retrieve resource    ${iserver}    InCSE1/Container2
    ${chr} =    Child Resource    ${rr}
    ${cbs} =    Current Byte Size    ${rr}
    ${cni} =    Current Number Of Instances    ${rr}
    Should Be Equal As Integers    ${cni}    1
    ${childNumber} =    Get Length    ${chr}
    Should Be Equal As Integers    ${childNumber}    1

4.63 if update to 3 , when create 4 or more contentInstance, the current number instance should be 3
    [Documentation]    if update to 3 , cannot create 4 contentInstance
    ${attr} =    Set Variable    "mni":3
    ${r}=    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102CSS"
    # create 3
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    #Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${rr}=    Retrieve resource    ${iserver}    InCSE1/Container2
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${mni} =    Max Number Of Instances    ${rr}
    ${chr} =    Child Resource    ${rr}
    Should Be Equal As Integers    ${mni}    3

4.64 what if alread have 4, then set mni to 1
    [Documentation]    if alread have 4, then set mni to 1, will delete 3 children
    ${attr} =    Set Variable    "mni":1
    ${r}=    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${rr}=    Retrieve resource    ${iserver}    InCSE1/Container2
    ${chr} =    Child Resource    ${rr}
    ${mni} =    Max Number Of Instances    ${rr}
    ${cni} =    Current Number Of Instances    ${rr}
    Should Be Equal As Integers    ${cni}    1

Delete the Container2-4.6
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2
    # -------------    7. maxByteSize -------

4.71 if maxByteSize = 5 , can create contentInstance with contentSize 5
    [Documentation]    if maxByteSize = 5 , can create contentInstance with contentSize 5
    ${attr} =    Set Variable    "mbs":5,"rn":"Container2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    ${oldr} =    Retrieve Resource    ${iserver}    ${container}
    ${mbs} =    Max Byte Size    ${oldr}
    Should Be Equal As Integers    5    ${mbs}

4.72 if maxByteSize = 5 , cannot create contentInstance with contenSize 8
    [Documentation]    if maxByteSize = 5 , cannot create contentInstance with contenSize 8
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102C120c"
    # cannot create 2
    ${error} =    Run Keyword And Expect Error    Cannot create this resource [400]*    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}
    ...    ${attr}

4.73 if update to 20 , cannot create another contentInstance
    [Documentation]    if update to 20 , cannot create another contentInstance
    ${attr} =    Set Variable    "mbs":20
    ${r}=    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102CS"
    # create 4 cin
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    Create Resource    ${iserver}    InCSE1/Container2    ${rt_contentInstance}    ${attr}
    ${rr}=    Retrieve resource    ${iserver}    InCSE1/Container2
    ${cbs} =    Current Byte Size    ${rr}
    ${chr} =    Child Resource    ${rr}
    ${cni} =    Current Number Of Instances    ${rr}
    Should Be Equal As Integers    ${cni}    4
    ${childNumber} =    Get Length    ${chr}
    Should Be Equal As Integers    ${childNumber}    4

4.74 if alread have 20, then set mbs to 5，will delete contentInstance until mbs less than 5.
    [Documentation]    what if alread have 20, then set mbs to 5, will delete contentInstance until mbs less than 5.
    ${attr} =    Set Variable    "mbs":5
    ${r}=    Update Resource    ${iserver}    InCSE1/Container2    ${rt_container}    ${attr}
    ${rr}=    Retrieve resource    ${iserver}    InCSE1/Container2
    ${chr} =    Child Resource    ${rr}
    ${cbs} =    Current Byte Size    ${rr}
    ${cni} =    Current Number Of Instances    ${rr}
    Should Be Equal As Integers    ${cni}    1
    ${childNumber} =    Get Length    ${chr}
    Should Be Equal As Integers    ${childNumber}    1

Delete the Container2-4.7
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container2

4.81 creator -- value must be null
    [Documentation]    creator -- value must be null
    ${attr} =    Set Variable    "cr":"VALUE"
    ${error} =    Run Keyword And Expect Error    Cannot create this resource [400]*    Create Resource    ${iserver}    InCSE1/Container1    ${rt_container}
    ...    ${attr}
    Should Contain All Sub Strings    ${error}    error    cr
    #==================================================
    #    Finish
    #==================================================

Delete the test Container1
    [Documentation]    Delete the test Container1
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/Container1

*** Keywords ***
Check Response and Retrieve Resource
    [Arguments]    ${r}
    ${con} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
    ${rr} =    Retrieve Resource    ${iserver}    ${con}
    ${text} =    Text    ${rr}
    [Return]    ${text}

Check Response and Retrieve Resource For Update
    [Arguments]    ${r}    ${location}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
    ${rr} =    Retrieve Resource    ${iserver}    ${location}
    ${text} =    Text    ${rr}
    [Return]    ${text}

Create Container Expect Cannot Create Error
    [Arguments]    ${attr}
    [Documentation]    create Container Under InCSE1 and expect error
    ${error} =    Run Keyword And Expect Error    Cannot create this resource [400]*    Create Resource    ${iserver}    InCSE1    ${rt_container}
    ...    ${attr}
    [Return]    ${error}

Update Container Expect Cannot Update Error
    [Arguments]    ${attr}
    [Documentation]    update Container Under InCSE1 and expect error
    ${error} =    Run Keyword And Expect Error    Cannot update this resource [400]*    Update Resource    ${iserver}    InCSE1/Container1    ${rt_container}
    ...    ${attr}
    [Return]    ${error}

Start
    [Documentation]    Set up suite
    ${iserver} =    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}    http
    Set Suite Variable    ${iserver}

TODO
    Fail    "Not implemented"
