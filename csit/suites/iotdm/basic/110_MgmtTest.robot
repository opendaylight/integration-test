*** Settings ***
Documentation     Test suite for Mgmt Object
Suite Setup       Create Session    session    http://${CONTROLLER}:${PORT}    auth=${AUTH}    headers=${HEADERS_CSE}
Suite Teardown    Kill The Tree    ${CONTROLLER}    InCSE1    admin    admin
Library           RequestsLibrary
Library           OperatingSystem
Library           ../../../libraries/criotdm.py
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${POST_CSE}       ${CURDIR}/../../../variables/iotdm/setCSE.json
${POST_MGMTOBJ}    ${CURDIR}/../../../variables/iotdm/setMgmtObject.json
${httphost}       ${ODL_SYSTEM_IP}
${httpuser}       admin
${httppass}       admin
${rt_nod}         14

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable ${iserver}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}
    #==================================================
    #    Container Mandatory Attribute Test
    #==================================================
    # For Creation, there are no mandatory input attribute

1.1 Provision CSE
    ${body}    OperatingSystem.Get File    ${POST_CSE}
    ${resp}    RequestsLibrary.Post Request    session    ${POST_CSE_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

1.2 create a node
    [Documentation]    After Created, test whether all the mandatory attribtues are exist.
    ${attr} =    Set Variable    "ni":"dsds","rn":"mockNode"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_nod}    ${attr}
    ${node} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ri":    "rn":
    Should Contain    ${text}    "lt":    "pi":
    Should Contain    ${text}    "ct":    "rty":14
    Should Not Contain    S{text}    "lbl"    "creator"    "or"

1.3 Check MAndatory Parameters for Firmware as Mgmt Object
    ${body}    OperatingSystem.Get File    ${POST_MGMTOBJ}
    Create Session    session1    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS1}
    ${resp}    RequestsLibrary.Post Request    session1    ${POST_MGMTOBJECT_URI}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
