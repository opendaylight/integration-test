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
${rt_acp}    1

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
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["Test_AE_ID","222"],"acop":3},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["admin","222"],"acop":63},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp1"
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
    [documentation]    input a invalid ipv4 address and expect error
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv4":["127.0.01"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp3"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
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
    [documentation]    input a invalid Ipv6 address and expect error
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35,"acco":[{"acip":{"ipv6":["2001:db8:0:0:0:ff00:42"]}}]},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp3"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    not a valid Ipv6 address

1.6 ACP can be created under AE
    [documentation]    create an AE named AE1, then create ACP under that AE1.
    ${attr} =    Set Variable    "api":"ODL","rr":true,"rn":"AE1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_ae}    ${attr}
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp5"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201

1.7 ACP cannot be created under Container
    [documentation]    create a Contianer named Con1, cannot create ACP under that Con1.
    ${attr} =    Set Variable    "rn":"Con1"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["111","222"],"acop":35},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["111","222"],"acop":7},{"acor" : ["111","222"],"acop":9}]},"rn":"Acp6"
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/Con1    ${rt_acp}    ${attr}
    Should Contain    ${error}    Cannot create AccessControlPolicy under this resource type

2.1 Check the originator funtion - the * A
    [documentation]    AAcp allows any orginator to create/update resource
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["*"],"acop":3},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["admin","222"],"acop":63},{"acor" : ["TestAE","222"],"acop":1}]},"rn":"AAcp"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${attr} =    Set Variable    "rn":"ContainerFromA","acpi":["InCSE1/AAcp"]
    Modify Headers Origin    ${iserver}    TestAE111
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201

2.2 Check the originator funtion - the * B
    [documentation]    AAcp allows any orginator to create/update resource
    ${attr} =    Set Variable    "rn":"ContainerFromB","acpi":["InCSE1/AAcp"]
    Modify Headers Origin    ${iserver}    TestAE222
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201

2.3 Cannot create resource if the originator is not allowed
    [documentation]    Acp1 does not allow TestAE222 to create/update resource
    ${attr} =    Set Variable    "rn":"ContainerFromB2","acpi":["InCSE1/Acp1"]
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    Originator

2.4 Cannot delete resource if the originator is not allowed
    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["TestAE"],"acop":15},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["admin","222"],"acop":63},{"acor" : ["111","222"],"acop":9}]},"rn":"BAcp"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    ${attr} =    Set Variable    "rn":"ContainerFromTestAE","acpi":["InCSE1/BAcp"]
    Modify Headers Origin    ${iserver}    TestAE
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${con} =    Location    ${r}
    Modify Headers Origin    ${iserver}    TestAE111
    ${error}=    Run Keyword And Expect Error    *    Delete Resource    ${iserver}    ${con}
    Should Start with    ${error}    Cannot delete this resource [400]
    Should Contain    ${error}    Originator

2.5 Cannot create the resource if the operation number does not contain code 1
    [documentation]    If ACP operation is even, cannot create a new resource
     ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["TestAE2"],"acop":16},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["admin","222"],"acop":63},{"acor" : ["111","222"],"acop":9}]},"rn":"CAcp"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    Modify Headers Origin    ${iserver}    TestAE2
    ${attr} =    Set Variable    "rn":"ContainerFromTestAE2","acpi":["InCSE1/CAcp"]
    ${error}=    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    Should Start with    ${error}    Cannot create this resource [400]
    Should Contain    ${error}    Operation

2.6 Cannot retrieve the resource if the operation is not allowed
     ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["TestAE2"],"acop":1},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["admin","222"],"acop":63},{"acor" : ["111","222"],"acop":9}]},"rn":"DAcp"
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_acp}    ${attr}
    Modify Headers Origin    ${iserver}    TestAE2
    ${attr} =    Set Variable    "rn":"ContainerFromTestAE2","acpi":["InCSE1/DAcp"]
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${error}=    Run Keyword And Expect Error    *    Retrieve Resource    ${iserver}    InCSE1/ContainerFromTestAE2
    Should Start with    ${error}    Cannot retrieve this resource [400]
    Should Contain    ${error}    Operation

2.7 Cannot update the resource if the operation is not allowed
    ${attr} =    Set Variable    "or":"oror1"
    ${error}=    Run Keyword And Expect Error    *     update Resource    ${iserver}    InCSE1/ContainerFromTestAE2    ${rt_container}    ${attr}
    Should Start with    ${error}    Cannot update this resource [400]
    Should Contain    ${error}    Operation

2.8 Cannot delete the resource if the operation is not allowed
    ${error}=    Run Keyword And Expect Error    *     delete Resource    ${iserver}    InCSE1/ContainerFromTestAE2
    Should Start with    ${error}    Cannot delete this resource [400]
    Should Contain    ${error}    Operation

3.1 If create a child resource does not contain acpid, using the parentACPid (layer1)
    [documentation]    create a Container under test 2.6, then the child cannot be deleted
    ${attr} =    Set Variable    "rn":"ContainerSon"
    ${r}=    Create Resource    ${iserver}    InCSE1/ContainerFromTestAE2    ${rt_container}    ${attr}
    ${error}=    Run Keyword And Expect Error    *     delete Resource    ${iserver}    InCSE1/ContainerFromTestAE2/ContainerSon
    Should Start with    ${error}    Cannot delete this resource [400]
    Should Contain    ${error}    Operation

3.2 If create a child resource does not contain acpid, using the parent's parent acpid if parent does not contain ACPid (layer2)
    [documentation]    create a Container under test 3.1, then the child cannot be deleted
    ${attr} =    Set Variable    "rn":"ContainerSon"
    ${r}=    Create Resource    ${iserver}    InCSE1/ContainerFromTestAE2/ContainerSon    ${rt_container}    ${attr}
    ${error}=    Run Keyword And Expect Error    *     delete Resource    ${iserver}    InCSE1/ContainerFromTestAE2/ContainerSon/ContainerSon
    Should Start with    ${error}    Cannot delete this resource [400]
    Should Contain    ${error}    Operation

3.3 Check the default ACP selfPrivilege function - acor
    ${error}=    Run Keyword And Expect Error    *     delete Resource    ${iserver}    InCSE1/_defaultACP
    Should Start with    ${error}    Cannot delete this resource [400]
    Should Contain    ${error}    Originator

3.4 Check the selfPrivilege function : delete
    [documentation]    For AAcp, Origin admin can do anything, origin TestAE can only do create
    Modify Headers Origin    ${iserver}    TestAE
    ${error}=    Run Keyword And Expect Error    *     delete Resource    ${iserver}    InCSE1/AAcp
    Should Start with    ${error}    Cannot delete this resource [400]
    Should Contain    ${error}    Operation
    Modify Headers Origin    ${iserver}    admin
    ${r}=    Delete Resource    ${iserver}    InCSE1/AAcp
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299

3.5 Check the selfPrivilege function - update

    ${attr} =    Set Variable    "pv":{"acr":[{"acor" : ["TestAE2"],"acop":1},{"acor" : ["111","222"],"acop":35}]},"pvs":{"acr":[{"acor" : ["admin","222"],"acop":63},{"acor" : ["111","dddd"],"acop":9}]}
    Modify Headers Origin    ${iserver}    111
    ${error}=    Run Keyword And Expect Error    *     update Resource    ${iserver}    InCSE1/BAcp    ${rt_acp}    ${attr}
    Should Start with    ${error}    Cannot update this resource [400]
    Should Contain    ${error}    Operation
    Modify Headers Origin    ${iserver}    admin
    ${r}=    Update Resource    ${iserver}    InCSE1/BAcp    ${rt_acp}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299

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