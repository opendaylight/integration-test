*** Settings ***
Documentation     Test for hierarchy of resources: AE/CONTAINER/CONTENTINSTANCE
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
1.11 Valid Input for AE without name
    [Documentation]    Valid Input for AE without name
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    Response Is Correct    ${r}

1.12 Valid Input for AE with name
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true,"rn":"ODL3"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    Response Is Correct    ${r}

1.13 Invalid Input for AE with name Already Exist, should return error
    [Documentation]    Invalid Input for AE with name Already Exist, should return error
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true,"rn":"ODL3"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_ae}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [409]

1.14 Invalid Input for AE (AE cannot be created under AE)
    [Documentation]    Invalid Input for AE (AE cannot be created under AE), expect error
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true,"rn":"ODL4"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/ODL3    ${rt_ae}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]
    # -----------------    Update and Retrieve -------------

1.15 Valid Update AE's label
    [Documentation]    Valid Update AE's label
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/ODL3    ${rt_ae}    ${attr}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/ODL3
    Should Contain All Sub Strings    ${r.text}    "aaa"    "bbb"    "ccc"
    #==================================================
    #    Container Test
    #==================================================

2.11 Create Container without name under AE
    [Documentation]    Create Container under AE without name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    Connect And Create Resource    InCSE1/ODL3    ${rt_container}    ${attr}

2.12 Create Container with name under AE
    [Documentation]    Create Container Under AE with name containerUnderAE and retrieve it to check if it is created
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you","rn":"containerUnderAE"
    ${r} =    Create Resource    ${iserver}    /InCSE1/ODL3    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    # retrieve it
    ${result} =    Retrieve Resource    ${iserver}    ${container}
    Should Contain    ${result.text}    containerUnderAE

2.13 Invalid Input for Container Under AE with name (Already exist)
    [Documentation]    Invalid Input for Container Under AE with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you","rn":"containerUnderAE"
    ${error} =    Run Keyword And Expect Error    *    Connect And Create Resource    InCSE1/ODL3    ${rt_container}    ${attr}
    Should Start with    ${error}    Cannot create this resource [409]

2.14 Update Container Label
    [Documentation]    Update Label to ["aaa","bbb","ccc"]
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/ODL3/containerUnderAE    ${rt_container}    ${attr}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/ODL3/containerUnderAE
    Should Contain All Sub Strings    ${r.text}    "aaa"    "bbb"    "ccc"
    #----------------------------------------------------------------------

2.21 Create Container under InCSE1 without name
    [Documentation]    Create Container under InCSE1 without name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    Response Is Correct    ${r}

2.22 Create Container under CSE with name
    [Documentation]    Create Container under CSE with name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you","rn":"containerUnderCSE"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    Response Is Correct    ${r}
    # retrieve it
    ${result} =    Retrieve Resource    ${iserver}    InCSE1/containerUnderCSE
    Should Contain    ${result.text}    containerUnderCSE

2.23 Invalid Input for Container Under CSE with name (Already exist)
    [Documentation]    Invalid Input for Container Under CSE with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you","rn":"containerUnderCSE"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_container}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [409]

2.24 Update Container Label
    [Documentation]    Update Container Label
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}    ${attr}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/containerUnderCSE
    Should Contain All Sub Strings    ${r.text}    "aaa"    "bbb"    "ccc"
    #----------------------------------------------------------------------

2.31 Create Container under Container without name
    [Documentation]    Create Container under Container without name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}    ${attr}
    Response Is Correct    ${r}

2.32 Create Container under Container with name
    [Documentation]    Create Container under Container with name
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you","rn":"containerUnderContainer"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    # retrieve it
    ${result} =    Retrieve Resource    ${iserver}    ${container}
    Should Contain    ${result.text}    containerUnderContainer

2.33 Invalid Input for Container Under Container with name (Already exist)
    [Documentation]    Invalid Input for Container Under Container with name (Already exist)
    ${attr} =    Set Variable    "cr":null,"mni":1,"mbs":15,"or":"http://hey/you","rn":"containerUnderContainer"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_container}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [409]

2.34 Update Container Label
    [Documentation]    Update Container Label to ["aaa","bbb","ccc"]
    ${attr} =    Set Variable    "lbl":["aaa","bbb","ccc"]
    ${r} =    Update Resource    ${iserver}    InCSE1/containerUnderCSE/containerUnderContainer    ${rt_container}    ${attr}
    Response Is Correct    ${r}
    # Retrieve and test the lbl
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/containerUnderCSE/containerUnderContainer
    Should Contain All Sub Strings    ${r.text}    "aaa"    "bbb"    "ccc"

2.41 Invalid Input for AE under container with name(mess up layer)
    [Documentation]    Invalid Input for AE under container withoutname(mess up layer)
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true,"rn":"ODL4"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_ae}
    ...    ${attr}
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
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"102","rn":"conIn1"
    ${r} =    Create Resource    ${iserver}    InCSE1/containerUnderCSE    ${rt_contentInstance}    ${attr}
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
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
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
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    ${ae} =    Location    ${r}
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
    ${container} =    Location    ${r}
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
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    ${deleteRes} =    Delete Resource    ${iserver}    InCSE1/ODL3
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200

*** Keywords ***
Connect And Create Resource
    [Arguments]    ${targetURI}    ${resoutceType}    ${attr}
    ${iserver} =    Connect To Iotdm    ${ODL_SYSTEM_1_IP}    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}    http
    ${r} =    Create Resource    ${iserver}    ${targetURI}    ${resoutceType}    ${attr}
    ${container} =    Resid    ${r}
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
