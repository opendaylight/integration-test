*** Settings ***
Suite Setup       Connect And Create The Tree
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
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}
    #==================================================
    #    ResultContent(rcn) Test
    #==================================================

1.1 rcn is legal in create
    [Documentation]    rcn=1, 2, 3, 0 is legal
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    : FOR    ${rcn}    IN    \    1    2    3
    ...    0
    \    ${r} =    Create Resource With Command    ${iserver}    InCSE1    ${rt_ae}    rcn=${rcn}
    \    ...    ${attr}

1.2 rcn is illegal in create
    [Documentation]    rcn=4, 5, 6, 7 is illegal
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    : FOR    ${rcn}    IN    4    5    6    7
    \    ${error} =    Run Keyword And Expect Error    *    Create Resource With Command    ${iserver}    InCSE1
    \    ...    ${rt_ae}    rcn=${rcn}    ${attr}
    \    Should Start with    ${error}    Cannot create this resource [400]
    \    Should Contain    ${error}    rcn

2.1 rcn is legal in update
    [Documentation]    rcn=1, 0/ null is legal
    ${attr} =    Set Variable    "or":"http://hey/you"
    : FOR    ${rcn}    IN    \    0    1    5
    ...    6
    \    ${r} =    Update Resource With Command    ${iserver}    InCSE1/AE1    ${rt_ae}    rcn=${rcn}
    \    ...    ${attr}

2.2 rcn is illegal in update
    [Documentation]    rcn=2, 3, 7 is illegal
    ${attr} =    Set Variable    "or":"http://hey/you"
    : FOR    ${rcn}    IN    2    3    4    7
    \    ${error} =    Run Keyword And Expect Error    *    Update Resource With Command    ${iserver}    InCSE1/AE1
    \    ...    ${rt_ae}    rcn=${rcn}    ${attr}
    \    Should Start with    ${error}    Cannot update this resource [400]
    \    Should Contain    ${error}    rcn

3.1 rcn is legal in retrieve
    [Documentation]    rcn=1, 4, 5, 6 null is legal
    : FOR    ${rcn}    IN    \    1    4    5
    ...    6
    \    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=${rcn}
    # when rcn=7 can be retrieved

3.2 rcn is illegal in retrieve
    [Documentation]    rcn=0, 2, 3 is illegal
    : FOR    ${rcn}    IN    0    2    3
    \    ${error} =    Run Keyword And Expect Error    *    Retrieve Resource With Command    ${iserver}    InCSE1/AE1
    \    ...    rcn=${rcn}
    \    Should Start with    ${error}    Cannot retrieve this resource [400]
    \    Should Contain    ${error}    rcn

4.2 rcn is illegal in delete
    [Documentation]    rcn=2, 3, 4, 5, 6, 7 is illegal
    ${attr} =    Set Variable    "or":"http://hey/you"
    : FOR    ${rcn}    IN    2    3    4    7
    \    ${error} =    Run Keyword And Expect Error    *    Delete Resource With Command    ${iserver}    InCSE1/AE1
    \    ...    rcn=${rcn}
    \    Should Start with    ${error}    Cannot delete this resource [400]
    \    Should Contain    ${error}    rcn

Delete the tree
    Kill The Tree    ${ODL_SYSTEM_IP}    InCSE1    admin    admin
    #==================================================
    #    FilterCriteria Test
    #==================================================

Create the tree
    Connect And Create The Tree

1. createdBefore
    ${cty} =    Get Time    year
    ${ctm} =    Get Time    month
    ${ctd} =    Get Time    day
    ${cth} =    Get Time    hour
    ${ctmin} =    Get Time    min
    ${ctsec} =    Get Time    sec
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&crb=${cty}${ctm}${ctd}T${cth}${ctmin}${ctsec}
    ${count} =    Get Length    ${r.json()['m2m:ae']['ch']}
    Should Be Equal As Integers    ${count}    2

2. createdAfter
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&cra=20150612T033748
    ${count} =    Get Length    ${r.json()['m2m:ae']['ch']}
    Should Be Equal As Integers    ${count}    2

3. modifiedSince
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&ms=20150612T033748
    ${count} =    Get Length    ${r.json()['m2m:ae']['ch']}
    Should Be Equal As Integers    ${count}    2

4. unmodifiedSince
    ${cty} =    Get Time    year
    ${ctm} =    Get Time    month
    ${ctd} =    Get Time    day
    ${cth} =    Get Time    hour
    ${ctmin} =    Get Time    min
    ${ctsec} =    Get Time    sec
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/AE1    rcn=4&us=${cty}${ctm}${ctd}T${cth}${ctmin}${ctsec}
    ${count} =    Get Length    ${r.json()['m2m:ae']['ch']}
    Should Be Equal As Integers    ${count}    2

5. stateTagSmaller
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/Container3    rcn=4&sts=3
    ${count} =    Get Length    ${r.json()['ch']}
    Should Be Equal As Integers    ${count}    5

6. stateTagBigger
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/Container3    rcn=4&stb=1
    ${count} =    Get Length    ${r.json()['m2m:cnt']['ch']}
    Should Be Equal As Integers    ${count}    2
    # 7. expireBefore
    # 8. expireAfter

9. labels
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1/Container3    rcn=4&sts=3&lbl=contentInstanceUnderContainerContainer
    ${count} =    Get Length    ${r.json()['ch']}
    Should Be Equal As Integers    ${count}    2
    # 2 labels test

10. resourceType
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    rcn=4&rty=3
    ${count} =    Get Length    ${r.json()['ch']}
    Should Be Equal As Integers    ${count}    3

11. sizeAbove
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    rcn=4&rty=3&sza=5
    ${count} =    Get Length    ${r.json()['ch']}
    Should Be Equal As Integers    ${count}    2

12. sizeBelow
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    rcn=4&rty=3&szb=5
    ${count} =    Get Length    ${r.json()['ch']}
    Should Be Equal As Integers    ${count}    1

2.1 And Test - labels
    ${r} =    Retrieve Resource With Command    ${iserver}    InCSE1    fu=1&rcn=4&sts=4&lbl=contentInstanceUnderContainerContainer&lbl=underCSE
    ${count} =    Get Length    ${r.json()}
    Should Be Equal As Integers    ${count}    6

*** Keywords ***
Connect And Create The Tree
    [Documentation]    Create a tree that contain AE/ container / contentInstance in different layers
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
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
