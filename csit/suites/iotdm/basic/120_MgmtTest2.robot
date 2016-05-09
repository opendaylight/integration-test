*** Settings ***
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
${rt_acp}         1
${rt_nod}         14
${rt_mgo}         13

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable ${iserver}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}
    #==================================================
    #    Container Mandatory Attribute Test
    #==================================================
    # For Creation, there are no mandatory input attribute

1.1 create a node
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    ${attr} =    Set Variable    "ni":"dsds","rn":"InNode1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_nod}    ${attr}
    ${node} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ri":    "rn":
    Should Contain    ${text}    "lt":    "pi":
    Should Contain    ${text}    "ct":    "rty":14
    Should Not Contain    S{text}    "lbl"    "creator"    "or"

1.2 After Created, test whether all the mandatory attribtues are exist.
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    ${attr} =    Set Variable    "mgd":"1001","vr" : "version1","fwnnam":"firmware2","url":true,"ud": "true","uds": "uds"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ri":    "rn":
    Should Contain    ${text}    "lt":    "pi":
    Should Contain    ${text}    "ct":    "rty":13
    Should Not Contain    S{text}    "lbl"    "creator"    "or"
