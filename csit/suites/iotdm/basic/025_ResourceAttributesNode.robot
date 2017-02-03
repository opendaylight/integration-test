*** Settings ***
Documentation     Tests for Node resource attributes
Suite Teardown    Kill The Tree    ${ODL_SYSTEM_1_IP}    InCSE1    admin    admin
Resource          ../../../libraries/SubStrings.robot
Library           ../../../libraries/criotdm.py
Library           Collections

*** Variables ***
${httphost}       ${ODL_SYSTEM_1_IP}
${httpuser}       admin
${httppass}       admin
${rt_ae}          2
${rt_container}    3
${rt_contentInstance}    4
${rt_acp}         1
${rt_node}        14

*** Test Cases ***
Set Suite Variable
    [Documentation]    set a suite variable ${iserver}
    ${iserver} =    Connect To Iotdm    ${httphost}    ${httpuser}    ${httppass}    http
    Set Suite Variable    ${iserver}
    #==================================================
    #    Container Mandatory Attribute Test
    #==================================================
    # For Creation, there are no mandatory input attribute

TODO Refactor test suite and implement TCs
    [Documentation]    Refactor this test suite and implement next TCs according to 000_ResourceAttributesNotes.txt
    ...    Example of changes is in 024_ResourceAttributesAE.robot
    [Tags]    not-implemented
    TODO

1.1 After Created, test whether all the mandatory attribtues exist.
    [Documentation]    After Created, test whether all the mandatory attribtues exist.
    ${attr} =    Set Variable    "rn":"Container1"
    ${r}=    Create Resource With Command    ${iserver}    InCSE1    ${rt_container}    rcn=3    ${attr}
    ${container} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Convert To String    ${r.text}
    Should Contain All Sub Strings    ${text}    "ri":    "rn":    "cni"    "lt":    "pi":
    ...    "st":    "ct":    "ty":3    cbs"
    Should Not Contain Any Sub Strings    ${text}    "lbl"    "creator"    "or"

*** Keywords ***
TODO
    Fail    "Not implemented"
