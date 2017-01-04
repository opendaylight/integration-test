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

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable ${iserver}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}
    #==================================================
    #    Container Mandatory Attribute Test
    #==================================================
    # For Creation, there are no mandatory input attribute

1.0 Test whether default ACP exist
    Modify Headers Origin    ${iserver}    admin
    ${r} =    Retrieve Resource    ${iserver}    InCSE1/_defaultACP
    ${text} =    Text    ${r}
    LOG    ${text}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299

1.1 Create ACP without context, test whether all the reponse mandatory attribtues are exist.
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ct":    "lt":    "ty"
    Should Contain    ${text}    "ri":    "pi":

1.2 Create ACP with valid acip(ipv4)
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv4":["127.0.0.1"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp2"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ct":    "lt":    "ty"
    Should Contain    ${text}    "ri":    "pi":

1.3 Create ACP with invalid acip(ipv4)
    [Documentation]    input a invalid ipv4 address and expect error
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv4":["127.0.01"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp3"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_acp}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    not a valid Ipv4 address

1.4 Create ACP with valid acip(ipv6)
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv6":["2001:db8:0:0:0:ff00:42:8329"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp4"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ct":    "lt":    "ty"
    Should Contain    ${text}    "ri":    "pi":

1.5 Create ACP with invalid acip(ipv6)
    [Documentation]    input a invalid Ipv6 address and expect error
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv6":["2001:db8:0:0:0:ff00:42"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp3"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_acp}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    not a valid Ipv6 address

*** Keywords ***
Connect And Create Resource
    [Arguments]    ${targetURI}    ${resoutceType}    ${attr}    ${resourceName}=${EMPTY}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    ${r} =    Create Resource    ${iserver}    ${targetURI}    ${resoutceType}    ${attr}    ${resourceName}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201

Response Is Correct
    [Arguments]    ${r}
    ${text} =    Text    ${r}
    LOG    ${text}
    ${json} =    Json    ${r}
    LOG    ${json}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
