*** Settings ***
Documentation     Test for layers AE/CONTAINER/CONTENTINSTANCE
Suite Teardown    Kill The Tree    ${CONTROLLER}    InCSE1    admin    admin
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
    #    AE Test
    #==================================================
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}

1.11 Valid Input for AE without name
    [Documentation]    Valid Input for AE without name
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    Response Is Correct    ${r}

1.12 Valid Input for AE with name
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}    ODL3
    Response Is Correct    ${r}

1.13 Invalid Input for AE with name Already Exist, should return error
    [Documentation]    Invalid Input for AE with name Already Exist, should return error
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_ae}
    ...    ${attr}    ODL3
    Should Start with    ${error}    Cannot create this resource [409]

1.14 Invalid Input for AE (AE cannot be created under AE)
    [Documentation]    Invalid Input for AE (AE cannot be created under AE), expect error
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/ODL3    ${rt_ae}
    ...    ${attr}    ODL4
    Should Start with    ${error}    Cannot create this resource [405]
    # -----------------    Update and Retrieve -------------

1.15 Valid Update AE's label
    [Documentation]    Valid Update AE's label
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/ODL3    2    ${attr}
    ${ae} =    Name    ${r}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    ${ae}
    ${Json} =    Text    ${r}
    Should Contain    ${Json}    "aaa"    "bbb"    "ccc"
    Should Contain    ${r.json()['lbl']}    aaa    bbb    ccc
    #==================================================
    #    Container Test
    #==================================================

2.11 Create Container under AE without name
    [Documentation]    Create Container under AE without name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    Connect And Create Resource    InCSE1/ODL3    ${rt_container}    ${attr}

2.12 Create Container under AE with name
    [Documentation]    Invalid Input for Container Under AE with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1/ODL3    ${rt_container}    ${attr}    containerUnderAE
    ${container} =    Name    ${r}
    Response Is Correct    ${r}
    # retrieve it
    ${result} =    Retrieve Resource    ${iserver}    ${container}
    ${text} =    Text    ${result}
    Should Contain    ${text}    "containerUnderAE"

2.13 Invalid Input for Container Under AE with name (Already exist)
    [Documentation]    Invalid Input for Container Under AE with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Connect And Create Resource    InCSE1/ODL3    ${rt_container}    ${attr}
    ...    containerUnderAE
    Should Start with    ${error}    Cannot create this resource [409]

2.14 Update Container Label
    [Documentation]    Update Label to ["aaa","bbb","ccc"]
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/ODL3/containerUnderAE    ${rt_container}    ${attr}
    ${container} =    Name    ${r}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    ${container}
    ${Json} =    Text    ${r}
    Should Contain    ${Json}    "aaa"    "bbb"    "ccc"
    Should Contain    ${r.json()['lbl']}    aaa    bbb    ccc
    #----------------------------------------------------------------------

2.21 Create Container under InCSE1 without name
    [Documentation]    Create Container under InCSE1 without name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    Response Is Correct    ${r}

2.22 Create Container under CSE with name
    [Documentation]    Create Container under CSE with name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    containerUnderCSE
    Response Is Correct    ${r}
    # retrieve it
    ${result} =    Retrieve Resource    ${iserver}    InCSE1/containerUnderCSE
    ${text} =    Text    ${result}
    Should Contain    ${text}    "contaienrUnderCSE"

2.23 Invalid Input for Container Under CSE with name (Already exist)
    [Documentation]    Invalid Input for Container Under CSE with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_container}
    ...    ${attr}    containerUnderCSE
    Should Start with    ${error}    Cannot create this resource [409]

2.24 Update Container Label
    [Documentation]    Update Container Label
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}    ${attr}
    ${container} =    Name    ${r}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    ${container}
    ${Json} =    Text    ${r}
    Should Contain    ${Json}    "aaa"    "bbb"    "ccc"
    Should Contain    ${r.json()['lbl']}    aaa    bbb    ccc
    #----------------------------------------------------------------------

2.31 Create Container under Container without name
    [Documentation]    Create Container under Container without name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}    ${attr}
    Response Is Correct    ${r}

2.32 Create Container under Container with name
    [Documentation]    Create Container under Container with name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}    ${attr}    containerUnderContainer
    ${container} =    Name    ${r}
    Response Is Correct    ${r}
    # retrieve it
    ${result} =    Retrieve Resource    ${iserver}    ${container}
    ${text} =    Text    ${result}
    Should Contain    ${text}    "containerUnderContainer"

2.33 Invalid Input for Container Under Container with name (Already exist)
    [Documentation]    Invalid Input for Container Under Container with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}
    ...    ${attr}    containerUnderContainer
    Should Start with    ${error}    Cannot create this resource [409]

2.34 Update Container Label
    [Documentation]    Update Container Label to ["aaa","bbb","ccc"]
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/containerUnderCSE/containerUnderContainer    ${rt_container}    ${attr}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/containerUnderCSE/containerUnderContainer
    ${Json} =    Text    ${r}
    Should Contain    ${Json}    "aaa"    "bbb"    "ccc"
    Should Contain    ${r.json()['lbl']}    aaa    bbb    ccc

2.41 Invalid Input for AE under container withoutname(mess up layer)
    [Documentation]    Invalid Input for AE under container withoutname(mess up layer)
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_ae}
    ...    ${attr}    ODL4
    Should Start with    ${error}    Cannot create this resource [405]
    Should Contain    ${error}    Cannot create AE under this resource type: 3
    #==================================================
    #    ContentInstance Test
    #==================================================

3.11 Valid contentInstance under CSEBase/container without name
    [Documentation]    Valid contentInstance under CSEBase/container without name
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_contentInstance}    ${attr}
    Response Is Correct    ${r}

3.12 Valid contentInstance under CSEBase/container with name
    [Documentation]    Valid contentInstance under CSEBase/container with name
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_contentInstance}    ${attr}    conIn1
    Response Is Correct    ${r}

3.13 Invalid contentInstance under CSEBase
    [Documentation]    Invalid contentInstance under CSEBase
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_contentInstance}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]
    Should Contain    ${error}    Cannot create ContentInstance under this resource type: 5

3.14 Invalid contentInstance under AE
    [Documentation]    Invalid contentInstance under AE
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/ODL3    ${rt_contentInstance}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]
    Should Contain    ${error}    Cannot create ContentInstance under this resource type: 2

3.15 Invalid contentInstance under contentInstance
    [Documentation]    Invalid contentInstance under contentInstance
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE/conIn1    ${rt_contentInstance}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]
    Should Contain    ${error}    Cannot create ContentInstance under this resource type: 4

3.16 Invalid AE under contentInstance
    [Documentation]    Invalid AE under contentInstance
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE/conIn1    ${rt_ae}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]
    Should Contain    ${error}    Cannot create AE under this resource type: 4

3.17 Invalid container under contentInstance
    [Documentation]    Invalid container under contentInstance
    ${attr} =    Set Variable    "cr":null,"lbl":["aaa","bbb","ccc"]
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE/conIn1    ${rt_container}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]
    Should Contain    ${error}    Cannot create Container under this resource type: 4
    #==================================================
    #    Delete Test
    #==================================================

4.11 Delete AE without child resource
    [Documentation]    Delete AE without child resource
    ${attr} =    Set Variable    "aei":"ODL","api":"jb","apn":"jb2","or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    ${ae} =    Name    ${r}
    Response Is Correct    ${r}
    ${deleteRes} =    Delete Resource    ${iserver}    ${ae}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete AE that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${ae}
    Should Start with    ${error}    Cannot delete this resource [404]

4.12 Delete Container without child resource
    [Documentation]    Delete Container without child resource
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1/ODL3    ${rt_container}    ${attr}
    ${container} =    Name    ${r}
    Response Is Correct    ${r}
    ${deleteRes} =    Delete Resource    ${iserver}    ${container}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${container}
    Should Start with    ${error}    Cannot delete this resource [404]

Delete the Container Under CSEBase
    [Documentation]    Delete the Container and AE Under CSEBase
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/containerUnderCSE
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/ODL3

*** Keywords ***
Connect And Create Resource
    [Arguments]    ${targetURI}    ${resoutceType}    ${attr}    ${resourceName}=${EMPTY}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    ${r} =    Create Resource    ${iserver}    ${targetURI}    ${resoutceType}    ${attr}    ${resourceName}
    ${container} =    Name    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201

Response Is Correct
    [Arguments]    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
    ${text} =    Text    ${r}
    LOG    ${text}
    ${json} =    Json    ${r}
    LOG    ${json}
