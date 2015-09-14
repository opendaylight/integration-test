*** Settings ***
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
    #    Delete Test
    #==================================================
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}

4.11 Delete AE without child resource
    [Documentation]    Create AE then delete it
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    ${ae} =    Location    ${r}
    Response Is Correct    ${r}
    #------------- Delete -----------------------------
    ${deleteRes} =    Delete Resource    ${iserver}    ${ae}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete AE that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${ae}
    Should Start with    ${error}    Cannot delete this resource [404]

4.12 Delete Container without child resource
    [Documentation]    create container then delete it
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    #------------- Delete -----------------------------
    ${deleteRes} =    Delete Resource    ${iserver}    ${container}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${container}
    Should Start with    ${error}    Cannot delete this resource [404]

4.13 Delete contentInstance under InCSE1/AE/container/
    [Documentation]    Delete contentInstance under InCSE1/AE/container/
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}    AE1
    ${ae} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con1
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}
    ${conIn} =    Location    ${r}
    Response Is Correct    ${r}
    #------------- Delete -----------------------------
    ${deleteRes} =    Delete Resource    ${iserver}    ${conIn}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${conIn}
    Should Start with    ${error}    Cannot delete this resource [404]

4.14 Delete contentInstance under InCSE1/Container/
    [Documentation]    Delete contentInstance under InCSE1/Container/
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    Con2
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}
    ${conIn} =    Location    ${r}
    Response Is Correct    ${r}
    #------------- Delete -----------------------------
    ${deleteRes} =    Delete Resource    ${iserver}    ${conIn}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${conIn}
    Should Start with    ${error}    Cannot delete this resource [404]

4.15 Delete contentIsntance under InCSE1/Container/container/
    [Documentation]    Delete contentIsntance under InCSE1/Container/container/
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1/Con2    ${rt_container}    ${attr}    Con3
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}
    ${conIn} =    Location    ${r}
    Response Is Correct    ${r}
    #------------- Delete -----------------------------
    ${deleteRes} =    Delete Resource    ${iserver}    ${conIn}
    ${status_code} =    Status Code    ${deleteRes}
    Should Be Equal As Integers    ${status_code}    200
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${conIn}
    Should Start with    ${error}    Cannot delete this resource [404]
    # ============== AE with child container ==================

4.21 Delete AE with 1 child Container
    [Documentation]    Delete the AE nmaed AE1 which contains Con1 in the above test
    ${r} =    Delete Resource    ${iserver}    InCSE1/AE1
    Response Is Correct    ${r}
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/AE1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve them -----------
    Cannot Retrieve Error    InCSE1/AE1
    Cannot Retrieve Error    InCSE1/AE1/Con1

4.22 Delete AE with 3 child Container
    [Documentation]    Delete AE with 3 child Container
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}    AE1
    ${ae} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con2
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con3
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con4
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    # ----------- Delete the parent AE --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/AE1
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200
    ${text} =    Text    ${r}
    LOG    ${text}
    ${json} =    Json    ${r}
    LOG    ${json}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/AE1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve them -----------
    Cannot Retrieve Error    InCSE1/AE1
    Cannot Retrieve Error    InCSE1/AE1/Con2
    Cannot Retrieve Error    InCSE1/AE1/Con3
    Cannot Retrieve Error    InCSE1/AE1/Con4

4.23 Delete AE with 1 child Container/1 contentInstance
    [Documentation]    Delete AE with 1 child Container/1 contentInstance
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}    AE1
    ${ae} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con2
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn1
    ${name} =    Location    ${r}
    Response Is Correct    ${r}
    # ----------- Delete the parent AE --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/AE1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/AE1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve all of them -----------
    Cannot Retrieve Error    InCSE1/AE1
    Cannot Retrieve Error    InCSE1/AE1/Con2
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn1

4.24 Delete AE with 1 child Container/3 contentInsntace
    [Documentation]    Delete AE with 1 child Container/3 contentInsntace
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}    AE1
    ${ae} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con2
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn1
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn2
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn3
    Response Is Correct    ${r}
    # ----------- Delete the parent AE --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/AE1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/AE1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve all of them -----------
    Cannot Retrieve Error    InCSE1/AE1
    Cannot Retrieve Error    InCSE1/AE1/Con2
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn1
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn2
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn3

4.25 Delete AE with 3 child Container/9 contentInstance
    [Documentation]    Delete AE with 3 child Container/9 contentInstance
    ${attr} =    Set Variable    "api":"jb","apn":"jb2","or":"http://hey/you","rr":true
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}    AE1
    ${ae} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con1
    ${container1} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con2
    ${container2} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${ae}    ${rt_container}    ${attr}    Con3
    ${container3} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    : FOR    ${conName}    IN    conIn1    conIn2    conIn3
    \    ${r} =    Create Resource    ${iserver}    ${container1}    ${rt_contentInstance}    ${attr}
    \    ...    ${conName}
    \    Response Is Correct    ${r}
    : FOR    ${conName}    IN    conIn1    conIn2    conIn3
    \    ${r} =    Create Resource    ${iserver}    ${container2}    ${rt_contentInstance}    ${attr}
    \    ...    ${conName}
    \    Response Is Correct    ${r}
    : FOR    ${conName}    IN    conIn1    conIn2    conIn3
    \    ${r} =    Create Resource    ${iserver}    ${container3}    ${rt_contentInstance}    ${attr}
    \    ...    ${conName}
    \    Response Is Correct    ${r}
    # ----------- Delete the parent AE --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/AE1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/AE1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve them -----------
    Cannot Retrieve Error    InCSE1/AE1
    Cannot Retrieve Error    InCSE1/AE1/Con1
    Cannot Retrieve Error    InCSE1/AE1/Con2
    Cannot Retrieve Error    InCSE1/AE1/Con3
    Cannot Retrieve Error    InCSE1/AE1/Con1/conIn1
    Cannot Retrieve Error    InCSE1/AE1/Con1/conIn2
    Cannot Retrieve Error    InCSE1/AE1/Con1/conIn3
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn1
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn2
    Cannot Retrieve Error    InCSE1/AE1/Con2/conIn3
    Cannot Retrieve Error    InCSE1/AE1/Con3/conIn1
    Cannot Retrieve Error    InCSE1/AE1/Con3/conIn2
    Cannot Retrieve Error    InCSE1/AE1/Con3/conIn3
    # ================ Container with child container ==================

4.31 Delete Container with 1 child Container
    [Documentation]    Delete the Container nmaed Con2 which contains Con3 in the above test
    ${r} =    Delete Resource    ${iserver}    InCSE1/Con2
    Response Is Correct    ${r}
    # Delete container that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/Con2
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve them -----------
    Cannot Retrieve Error    InCSE1/Con2
    Cannot Retrieve Error    InCSE1/Con2/Con3

4.32 Delete Container with 3 child Container
    [Documentation]    Delete Container with 3 child Container
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    ConTop1
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_container}    ${attr}    Con1
    ${container1} =    Location    ${r}
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_container}    ${attr}    Con2
    ${container2} =    Location    ${r}
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_container}    ${attr}    Con3
    ${container3} =    Location    ${r}
    Response Is Correct    ${r}
    # ----------- Delete the parent Container --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/ConTop1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/Contop1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve them -----------
    Cannot Retrieve Error    InCSE1/Contop1
    Cannot Retrieve Error    InCSE1/Contop1/Con1
    Cannot Retrieve Error    InCSE1/Contop1/Con2
    Cannot Retrieve Error    InCSE1/Contop1/Con3

4.33 Delete Container with 1 child Container/1 contentInstance
    [Documentation]    Delete Container with 1 child Container/1 contentInstance
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    Con1
    ${con} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${con}    ${rt_container}    ${attr}    Con2
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn1
    ${name} =    Location    ${r}
    Response Is Correct    ${r}
    # ----------- Delete the parent Container --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/Con1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/Con1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve all of them -----------
    Cannot Retrieve Error    InCSE1/Con1
    Cannot Retrieve Error    InCSE1/Con1/Con2
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn1

4.34 Delete Container with 1 child Container/3 contentInsntace
    [Documentation]    Delete Container with 1 child Container/3 contentInsntace
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    Con1
    ${con} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    ${con}    ${rt_container}    ${attr}    Con2
    ${container} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn1
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn2
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}    conIn3
    Response Is Correct    ${r}
    # ----------- Delete the parent Container --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/Con1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/Con1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve all of them -----------
    Cannot Retrieve Error    InCSE1/Con1
    Cannot Retrieve Error    InCSE1/Con1/Con1/conIn2
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn1
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn2
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn3

4.35 Delete Container with 3 child Container/9 contentInstance
    [Documentation]    Delete Container with 3 child Container/9 contentInstance
    ${attr} =    Set Variable    "cr":null,"mni":5,"mbs":15,"or":"http://hey/you"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}    Con1
    ${con} =    Location    ${r}
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${con}    ${rt_container}    ${attr}    Con2
    ${container1} =    Location    ${r}
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${con}    ${rt_container}    ${attr}    Con3
    ${container2} =    Location    ${r}
    Response Is Correct    ${r}
    ${r} =    Create Resource    ${iserver}    ${con}    ${rt_container}    ${attr}    Con4
    ${container3} =    Location    ${r}
    Response Is Correct    ${r}
    ${attr} =    Set Variable    "cnf": "1","or": "http://hey/you","con":"101"
    : FOR    ${conName}    IN    conIn1    conIn2    conIn3
    \    ${r} =    Create Resource    ${iserver}    ${container1}    ${rt_contentInstance}    ${attr}
    \    ...    ${conName}
    \    Response Is Correct    ${r}
    : FOR    ${conName}    IN    conIn1    conIn2    conIn3
    \    ${r} =    Create Resource    ${iserver}    ${container2}    ${rt_contentInstance}    ${attr}
    \    ...    ${conName}
    \    Response Is Correct    ${r}
    : FOR    ${conName}    IN    conIn1    conIn2    conIn3
    \    ${r} =    Create Resource    ${iserver}    ${container3}    ${rt_contentInstance}    ${attr}
    \    ...    ${conName}
    \    Response Is Correct    ${r}
    # ----------- Delete the parent Container --------------
    ${r} =    Delete Resource    ${iserver}    InCSE1/Con1
    Response Is Correct    ${r}
    # Delete the resource that does not exist/has been deleted should return error
    ${error} =    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    InCSE1/Con1
    Should Start with    ${error}    Cannot delete this resource [404]
    #----------- Make sure cannot retrieve them -----------
    Cannot Retrieve Error    InCSE1/Con1
    Cannot Retrieve Error    InCSE1/Con1/Con2
    Cannot Retrieve Error    InCSE1/Con1/Con3
    Cannot Retrieve Error    InCSE1/Con1/Con4
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn1
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn2
    Cannot Retrieve Error    InCSE1/Con1/Con2/conIn3
    Cannot Retrieve Error    InCSE1/Con1/Con3/conIn1
    Cannot Retrieve Error    InCSE1/Con1/Con3/conIn2
    Cannot Retrieve Error    InCSE1/Con1/Con3/conIn3
    Cannot Retrieve Error    InCSE1/Con1/Con4/conIn1
    Cannot Retrieve Error    InCSE1/Con1/Con4/conIn2
    Cannot Retrieve Error    InCSE1/Con1/Con4/conIn3

*** Keywords ***
Response Is Correct
    [Arguments]    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
    ${text} =    Text    ${r}
    LOG    ${text}
    ${json} =    Json    ${r}
    LOG    ${json}

Cannot Retrieve Error
    [Arguments]    ${uri}
    ${error} =    Run Keyword And Expect Error    *    Retrieve Resource    ${iserver}    ${uri}
    Should Start with    ${error}    Cannot retrieve this resource [404]
