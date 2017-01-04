*** Settings ***
Documentation     Tests for Application Entity (AE) resource attributes
Suite Teardown    Kill The Tree    ${ODL_SYSTEM_IP}    InCSE1    admin    admin
Library           ../../../libraries/criotdm.py
Library           Collections

*** Variables ***
${httphost}       ${ODL_SYSTEM_IP}
${httpuser}       admin
${httppass}       admin
${rt_ae}          2
${rt_container}    3
${rt_contentInstance}    4

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable ${iserver}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}
    #==================================================
    #    AE Mandatory Attribute Test
    #==================================================
    # For Creation, there are only 2 mandatory attribute: App-ID(api), AE-ID(aei)

1.11 If include AE-ID should return error
    [Documentation]    when create AE, AE-ID should not be included
    ${attr} =    Set Variable    "aei":"ODL"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_ae}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    AE_ID

1.21 Missing App-ID should return error
    [Documentation]    when creete AE, Missing APP-ID should return error
    ${attr} =    Set Variable    "apn":"ODL"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_ae}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    APP_ID

1.3 After AE Created, test whether all the mandatory attribtues are exist.
    [Documentation]    mandatory attributes should be there after created
    ${attr} =    Set Variable    "api":"ODL","rr":true,"rn":"AE1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ri":    "rn":    "api":"ODL"
    Should Contain    ${text}    "aei":    "lt":    "pi":
    Should Contain    ${text}    "ct":    "rty":2
    Should Not Contain    S{text}    "lbl"    "apn"    "or"
    # 1.13    if Child Container updated, parent Last Modified time will be updated?
    # 1.14    if Child Container's child updated, parent Last Modified time will not be updated?
    # support rcn(support change URI in python library)
    #==================================================
    #    AE Optional Attribute Test (Allowed)
    #==================================================
    #    update(create)--> update(modified)-->update (delete)

2.11 appName can be created through update (0-1)
    [Documentation]    appName can be created through update (0-1)
    ${attr} =    Set Variable    "apn":"abcd"
    ${text} =    Update And Retrieve AE    ${attr}
    Should Contain    ${text}    "apn":"abcd"    "apn":"abcd" is not created

2.12 appName can be modified (1-1)
    [Documentation]    appName can be modified (1-1)
    ${attr} =    Set Variable    "apn":"dbac"
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    abcd
    Should Contain    ${text}    "apn":"dbac"    "apn":"dbac" is missing from tree

2.13 if set to null, appName should be deleted
    [Documentation]    if set to null, appName should be deleted
    ${attr} =    Set Variable    "apn":null
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    apn    apn should not exist
    Should Not Contain    ${text}    abcd    abcd should not exist
    Should Not Contain    ${text}    dbac    dbac should not exist

2.21 ontologyRef can be created through update (0-1)
    [Documentation]    ontologyRef can be created through update (0-1)
    ${attr} =    Set Variable    "or":"abcd"
    ${text} =    Update And Retrieve AE    ${attr}
    Should Contain    ${text}    "or":"abcd"    "or":"abcd" is missing from tree

2.22 ontologyRef can be modified (1-1)
    [Documentation]    ontologyRef can be modified (1-1)
    ${attr} =    Set Variable    "or":"dbac"
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    abcd    abcd should not exist
    Should Contain    ${text}    "or":"dbac"    "or":"abcd" is missing from tree

2.23 if set to null, ontologyRef should be deleted
    [Documentation]    if set to null, ontologyRef should be deleted
    ${attr} =    Set Variable    "or":null
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    or    or should not exist
    Should Not Contain    ${text}    abcd    abcd should not exist
    Should Not Contain    ${text}    dbac    dbac should not exist

2.31 labels can be created through update (0-1)
    [Documentation]    labels can be created through update (0-1)
    ${attr} =    Set Variable    "lbl":["label1"]
    ${text} =    Update And Retrieve AE    ${attr}
    Should Contain    ${text}    "lbl":["label1"]    "lbl":["label1"] is missing from tree

2.32 labels can be modified (1-1)
    [Documentation]    labels can be modified (1-1)
    ${attr} =    Set Variable    "lbl":["label2"]
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    label1    label1 should not exist
    Should Contain    ${text}    "lbl":["label2"]    "lbl":["label2"] is missing from tree

2.33 if set to null, labels should be deleted(1-0)
    [Documentation]    if set to null, labels should be deleted(1-0)
    ${attr} =    Set Variable    "lbl":null
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    lbl    lbl should not exist
    Should Not Contain    ${text}    label1    label1 should not exist
    Should Not Contain    ${text}    label2    label2 should not exist

2.34 labels can be created through update (0-n)
    [Documentation]    labels can be created through update (0-n)
    ${attr} =    Set Variable    "lbl":["label3","label4","label5"]
    ${text} =    Update And Retrieve AE    ${attr}
    Should Contain    ${text}    "lbl":["label3","label4","label5"]    "lbl":["label3","label4","label5"] is missing from tree

2.35 labels can be modified (n-n)(across)
    [Documentation]    labels can be modified (n-n)(across)
    ${attr} =    Set Variable    "lbl":["label4","label5","label6"]
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    label1    label1 should not exist
    Should Not Contain    ${text}    label2    label2 should not exist
    Should Not Contain    ${text}    label3    label3 should not exist
    Should Contain    ${text}    "lbl":["label4","label5","label6"]    "lbl":["label3","label4","label5"] is missing from tree

2.36 labels can be modified (n-n)(not across)
    [Documentation]    labels can be modified (n-n)(not across)
    ${attr} =    Set Variable    "lbl":["label7","label8","label9"]
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    label1    label1 should not exist
    Should Not Contain    ${text}    label2    label2 should not exist
    Should Not Contain    ${text}    label3    label3 should not exist
    Should Not Contain    ${text}    label4    label4 should not exist
    Should Not Contain    ${text}    label5    label5 should not exist
    Should Not Contain    ${text}    label6    label6 should not exist
    Should Contain    ${text}    "lbl":["label7","label8","label9"]    "lbl":["label7","label8","label9"] is missing from tree

2.37 if set to null, labels should be deleted(n-0)
    [Documentation]    if set to null, labels should be deleted(n-0)
    ${attr} =    Set Variable    "lbl":null
    ${text} =    Update And Retrieve AE    ${attr}
    Should Not Contain    ${text}    label1    label1 should not exist
    Should Not Contain    ${text}    label2    label2 should not exist
    Should Not Contain    ${text}    label3    label3 should not exist
    Should Not Contain    ${text}    label4    label4 should not exist
    Should Not Contain    ${text}    label5    label5 should not exist
    Should Not Contain    ${text}    label6    label6 should not exist
    Should Not Contain    ${text}    label7    label7 should not exist
    Should Not Contain    ${text}    label8    label8 should not exist
    Should Not Contain    ${text}    label9    label9 should not exist
    Should Not Contain    ${text}    lbl    lbl should not exist
    #======================================================
    #    AE Disturbing Attribute Test, Not Allowed Update
    #======================================================
    # using non-valid attribtue to create then expext error

3.11 Mulitiple App-ID should return error
    [Documentation]    Mulitiple App-ID should return error
    ${attr} =    Set Variable    "api":"ODL","api":"ODL2"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    Duplicate key    Error response is not correct
    Should Contain    ${error}    api    Error response is not correct

3.12 Mulitiple AE-ID should return error
    [Documentation]    Mulitiple AE-ID should return error
    ${attr} =    Set Variable    "api":"ODL","aei":"ODL1"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    AE_ID should be assigned by the system    Error response is not correct

3.13 Multiple app-name should return error
    [Documentation]    Multiple app-name should return error
    ${attr} =    Set Variable    "api":"ODL","apn":"ODL1","apn":"ODL1"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    Duplicate key    Error response is not correct
    Should Contain    ${error}    apn    Error response is not correct

3.14 Multiple label attribute should return error(multiple array)
    [Documentation]    Multiple label attribute should return error(multiple array)
    ${attr} =    Set Variable    "api":"ODL","lbl":["ODL1"], "lbl":["dsdsd"]
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    Duplicate key    Error response is not correct
    Should Contain    ${error}    lbl    Error response is not correct

3.15 Multiple ontologyRef attribute should return error
    [Documentation]    Multiple ontologyRef attribute should return error
    ${attr} =    Set Variable    "api":"ODL","or":"http://hey/you", "or":"http://hey/you"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    Duplicate key    Error response is not correct
    Should Contain    ${error}    or    Error response is not correct

3.21 Using Container's M attribute to create
    [Documentation]    Using Container's M attribute to create
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    CONTENT(pc) attribute not recognized: mni

3.22 Using ContentInstance's M attribute to create
    [Documentation]    Using ContentInstance's M attribute to create
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    CONTENT(pc) attribute not recognized: con
    #------------------------------------------------------
    # using non-valid attribute to update then expect error

3.31 resourceType cannot be update.
    [Documentation]    when update resourceType expext error
    ${attr} =    Set Variable    "ty":3
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: ty"    Error response is not correct

3.32 resoureceID cannot be update.
    [Documentation]    when update resourceId expect error
    ${attr} =    Set Variable    "ri":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: ri"    Error response is not correct

3.33 resouceNme cannot be update.(write once)
    [Documentation]    when update resourceName expect error
    ${attr} =    Set Variable    "rn":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"Resource Name cannot be updated: InCSE1/AE1/aaa"    Error response is not correct

3.34 parentID cannot be update.
    [Documentation]    when update parentID expect error
    ${attr} =    Set Variable    "pi":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: pi"    Error response is not correct

3.35 createTime cannot be update.
    [Documentation]    when update createTime expect error
    ${attr} =    Set Variable    "ct":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: ct"    Error response is not correct

3.36 app-id cannot be update
    [Documentation]    when update app-id expect error
    ${attr} =    Set Variable    "api":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"APP_ID cannot be updated"    Error response is not correct

3.37 ae-id cannot be updated
    [Documentation]    when update ae-id epxect error
    ${attr} =    Set Variable    "aei":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) AE_ID should be assigned by the system, please do not include aei"    Error response is not correct

3.38 LastMoifiedTime --- Special, cannot be modified by the user
    [Documentation]    LastMoifiedTime --- Special, cannot be modified by the user
    ${attr} =    Set Variable    "lt":"aaa"
    ${error} =    Cannot Update AE Error And Check Response Code    ${attr}
    Should Contain    ${error}    "error":"CONTENT(pc) attribute not recognized: lt"    Error response is not correct
    #==================================================
    #    Functional Attribute Test
    #==================================================
    # 1. lastModifiedTime
    # 2. parentID

4.1 if updated seccessfully, last modified time must be modified.
    [Documentation]    if updated seccessfully, lastModifiedTime must be modified.
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1/AE1
    ${lt1} =    Last Modified Time    ${oldr}
    ${attr} =    Set Variable    "lbl":["aaa"]
    Sleep    1s
    # We know Beryllium is going to be get rid of all sleep.
    # But as lastModifiedTime has precision in seconds,
    # we need to wait 1 second to see different value on update.
    ${r} =    update Resource    ${iserver}    InCSE1/AE1    ${rt_ae}    ${attr}
    ${lt2} =    last modified time    ${r}
    Should Not Be Equal    ${lt1}    ${lt2}

4.2 Check parentID
    [Documentation]    check parentID whether it is correct
    ${oldr} =    Retrieve Resource    ${iserver}    InCSE1
    ${CSEID} =    Set Variable    ${oldr.json()['m2m:cb']['ri']}
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/AE1
    Should Be Equal    /InCSE1/${oldr.json()['m2m:cb']['ri']}    ${r.json()['m2m:ae']['pi']}
    #==================================================
    #    Finish
    #==================================================

*** Keywords ***
Update And Retrieve AE
    [Arguments]    ${attr}
    ${r} =    update Resource    ${iserver}    InCSE1/AE1    ${rt_ae}    ${attr}
    ${text} =    Text    ${r}
    LOG    ${text}
    ${rr} =    Retrieve Resource    ${iserver}    InCSE1/AE1
    ${text} =    Text    ${rr}
    LOG    ${text}
    [Return]    ${text}

Cannot Update AE Error And Check Response Code
    [Arguments]    ${attr}
    ${error} =    Run Keyword And Expect Error    *    Update Resource    ${iserver}    InCSE1/AE1    ${rt_ae}
    ...    ${attr}
    Should Start with    ${error}    Cannot update this resource [400]
    [Return]    ${error}
