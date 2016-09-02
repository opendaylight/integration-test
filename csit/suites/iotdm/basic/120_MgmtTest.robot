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
${rt_nod}        14
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
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    201
    ${text} =    Text    ${r}
    Should Contain    ${text}    "ri":    "rn":
    Should Contain    ${text}    "lt":    "pi":
    Should Contain    ${text}    "ct":    "rty":13
    Should Not Contain    S{text}    "lbl"    "creator"    "or"

1.3 MgmtObj cannot be created under Container
    [Documentation]    if created under a container, expect error
    ${attr} =    Set Variable    "rn":"Container1"
    ${r} =    Create Resource    ${iserver}    InCSE1    ${rt_container}    ${attr}
    ${container} =    Location    ${r}
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    ${container}    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource [405]

1.4 MgmtObj cannot be created if missing mandatory attribute -- mgmdDefinition
     [Documentation]    if missing mgd, return error
    ${attr} =    Set Variable    "vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

2.11 Firmware Mandatory Test -- version
    [Documentation]    if missing verison(vr), return error
    ${attr} =    Set Variable    "mgd":1001,"fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

2.12 Firmware Mandatory Test -- name
    [Documentation]    if missing firmwareName(fwnnam), return error
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","url":"120.120","ud": true,"uds": "uds"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

2.13 Firmware Mandatory Test -- URL
    [Documentation]    if missing URL(url), return error
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","ud": true,"uds": "uds"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

2.21 Update Firmware version, name, URL, update
    [Documentation]    all these attributed can be updated
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${firmware} =    Location    ${r}
    ${attr} =    Set Variable    "vr" : "version2","fwnnam":"firmware3","url":"1201.1201","ud": false
    ${r} =    update Resource    ${iserver}    ${firmware}    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    ${firmware}
    Should Contain    ${text}    "ud"    "vr"    "fwnnam"

2.22 updateStatus cannot be updated
    [documentation]    if update uds, should return error
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${firmware} =    Location    ${r}
    ${attr} =    Set Variable    "vr" : "version2","fwnnam":"firmware3","url":"1201.1201","ud": false,"uds": "uds2"
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${firmware}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

2.31 Retrieve Firmware
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "ud"    "vr"    "fwnnam"

2.41 Delete Firmware
    ${attr} =    Set Variable    "mgd":1001,"vr" : "version1","fwnnam":"firmware2","url":"120.120","ud": true,"uds": "uds"
    ${r} =    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${firmware} =    Location    ${r}
    ${r} =    delete Resource    ${iserver}    ${firmware}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200

3.10 Create Software mgmtObj
    [Documentation]    if all the mandatory attributes are there, should return success
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","swn":"software1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${r} =    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    Check Response and Retrieve Resource    ${r}

3.11 Software Mandatory Test -- version
    [Documentation]    if missing verison(vr), return error
    ${attr} =    Set Variable    "mgd":1002,"swn":"software1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

3.12 Software Mandatory Test -- name
    [Documentation]    if missing name(swn), return error
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

3.13 Software Mandatory Test -- url
    [Documentation]    if missing URL(url), return error
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","swn":"software1","in": true,"un": false, "ins":"installStatus"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

3.21 Update Software version, name, URL, install, uninstall
    [Documentation]    all these attributed can be updated
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","swn":"software1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${software} =    Location    ${r}
    ${attr} =    Set Variable    "vr":"version2","swn":"software2","url":"1201.1201","in": false,"un": true
    ${r} =    update Resource    ${iserver}    ${software}    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    ${software}
    Should Contain    ${text}    "vr"    "swn"    "url"

3.22 Cannot update installStatus
    [Documentation]    installStatus cannot be updated
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","swn":"software1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${software} =    Location    ${r}
    ${attr} =    Set Variable    "vr":"version2","swn":"software2","url":"1201.1201","in": false,"un": true, "ins":"installStatus"
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${software}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

3.31 Retrieve Software
    [Documentation]    retrieve software
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","swn":"software1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "un"    "vr"    "swn"

3.41 Delete Software
    [Documentation]    create a mgmtObj then delete it
    ${attr} =    Set Variable    "mgd":1002,"vr":"version1","swn":"software1","url":"120.120","in": true,"un": false, "ins":"installStatus"
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${software} =    Location    ${r}
    ${r} =    delete Resource    ${iserver}    ${software}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200

4.10 Create Memory mgmtObj
    [Documentation]    if all the mandatory attributes are there, should return success
    ${attr} =    Set Variable    "mgd":1003,"mma":1000,"mmt":2000
    ${r} =    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    Check Response and Retrieve Resource    ${r}

4.11 Memory Mandatory Test -- mma
    [Documentation]    if missing Memavailable(mma), return error
    ${attr} =    Set Variable    "mgd":1003,"mmt":2000
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

4.12 Memory Mandatory Test -- mmt
    [Documentation]    if missing memtotal(mmt), return error
    ${attr} =    Set Variable    "mgd":1003,"mma":1000
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

4.21 Update Memory mma, mmt
    [Documentation]    all these attributed can be updated
    ${attr} =    Set Variable    "mgd":1003,"mma":1000,"mmt":2000
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${memory} =    Location    ${r}
    ${attr} =    Set Variable    "mma":3000,"mmt":4000
    ${r} =    update Resource    ${iserver}    ${memory}    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    ${memory}
    Should Contain    ${text}    "mma"    "mmt"    "lt"

4.22 Cannot update mgmtdefinition
    [Documentation]    installStatus cannot be updated
    ${attr} =    Set Variable    "mgd":1003,"mma":1000,"mmt":2000
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${memory} =    Location    ${r}
    ${attr} =    Set Variable    "mgd":1003,"mma":2000,"mmt":4000
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${memory}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

4.31 Retrieve Memory
    [Documentation]    Retrieve memory mgmtObj sucsessfully
    ${attr} =    Set Variable    "mgd":1003,"mma":1000,"mmt":2000
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "mgd"    "mma"    "mmt"

4.41 Delete Memory
    [Documentation]    create a memory MgmtObj then delete it
    ${attr} =    Set Variable    "mgd":1003,"mma":1000,"mmt":2000
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${memory} =    Location    ${r}
    ${r} =    delete Resource    ${iserver}    ${memory}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200

5.10 Create AreaNwInfo mgmtObj
    [Documentation]    if all the mandatory attributes are there, should return success
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt","ldv":["1","2"]
    ${r} =    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    Check Response and Retrieve Resource    ${r}

5.11 AreaNwInfo Mandatory Test -- ant
    [Documentation]    if missing areaNwkType(ant), return error
    ${attr} =    Set Variable    "mgd":1004,"ldv":["1","2"]
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

5.12 AreaNwInfo Mandatory Test -- ldv
    [Documentation]    if missing listOfDevices(ldv), return error
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

5.21 Update AreaNwInfo ant, ldv
    [Documentation]    all these attributed can be updated
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt","ldv":["1","2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${areaNwInfo} =    Location    ${r}
    ${attr} =    Set Variable    "ant":"testAnt2","ldv":["12","22"]
    ${r} =    update Resource    ${iserver}    ${areaNwInfo}    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    ${areaNwInfo}
    Should Contain    ${text}    "lt"    "ant"    "ldv"

5.22 Cannot update mgmtdefinition
    [Documentation]    installStatus cannot be updated
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt","ldv":["1","2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${areaNwInfo} =    Location    ${r}
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt","ldv":["1","2"]
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${areaNwInfo}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

5.31 Retrieve AreaNwInfo
    [Documentation]    Retrieve areaNwInfo mgmtObj sucsessfully
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt","ldv":["1","2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "mgd"    "ant"    "ldv"

5.41 Delete AreaNwInfo
    [Documentation]    create a areaNwInfo MgmtObj then delete it
    ${attr} =    Set Variable    "mgd":1004,"ant":"testAnt","ldv":["1","2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${areaNwInfo} =    Location    ${r}
    ${r} =    delete Resource    ${iserver}    ${areaNwInfo}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200


6.10 Create AreaNwkDeviceInfo mgmtObj
    [Documentation]    if all the mandatory attributes are there, should return success
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "awi":"areaNwkId", "lnh":["neighbor1","neighbor2"],"sli":343
    ${r} =    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    Check Response and Retrieve Resource    ${r}

6.11 AreaNwkDeviceInfo Mandatory Test -- dvd
    [Documentation]    if missing devID(dvd), return error
    ${attr} =    Set Variable    "mgd":1005,"dvt":"devType", "awi":"areaNwkId", "lnh":["neighbor1","neighbor2"]
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

6.12 AreaNwkDeviceInfo Mandatory Test -- dvt
    [Documentation]    if missing devType(dvt), return error
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","awi":"areaNwkId", "lnh":["neighbor1","neighbor2"]
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

6.13 AreaNwkDeviceInfo Mandatory Test -- awi
    [Documentation]    if missing areaNwkID(awi), return error
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "lnh":["neighbor1","neighbor2"]
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

6.14 AreaNwkDeviceInfo Mandatory Test -- lnh
    [Documentation]    if missing listOfNeighbors(lnh), return error
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "awi":"areaNwkId"
    ${error} =    Run Keyword And Expect Error    *    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}
    ...    ${attr}
    Should Start with    ${error}    Cannot create this resource
    Should Contain    ${error}    missing

6.21 Update AreaNwkDeviceInfo dvd,dvt,awi,lnh
    [Documentation]    all these attributed can be updated
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "awi":"areaNwkId", "lnh":["neighbor1","neighbor2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${AreaNwkDeviceInfo} =    Location    ${r}
    ${attr} =    Set Variable    "awi":"areaNwkId2", "lnh":["neighbor3","neighbor4"], "sld":423
    ${r} =    update Resource    ${iserver}    ${AreaNwkDeviceInfo}    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource For Update    ${r}    ${AreaNwkDeviceInfo}
    Should Contain    ${text}    "awi"    "sld"    "lnh"

6.22 Cannot update mgmtdefinition
    [Documentation]    installStatus cannot be updated
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "awi":"areaNwkId", "lnh":["neighbor1","neighbor2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${AreaNwkDeviceInfo} =    Location    ${r}
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID2","dvt":"devType2"
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${AreaNwkDeviceInfo}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

6.31 Retrieve AreaNwkDeviceInfo
    [Documentation]    Retrieve AreaNwkDeviceInfo mgmtObj sucsessfully
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "awi":"areaNwkId", "lnh":["neighbor1","neighbor2"],"sld":323
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "dvd"    "dvt"    "sld"

6.41 Delete AreaNwkDeviceInfo
    [Documentation]    create a AreaNwkDeviceInfo MgmtObj then delete it
    ${attr} =    Set Variable    "mgd":1005,"dvd":"devID","dvt":"devType", "awi":"areaNwkId", "lnh":["neighbor1","neighbor2"]
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${AreaNwkDeviceInfo} =    Location    ${r}
    ${r} =    delete Resource    ${iserver}    ${AreaNwkDeviceInfo}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200

7.10 Create Battery mgmtObj
    [Documentation]    if all the mandatory attributes are there, should return success
    ${attr} =    Set Variable    "mgd":1006,"btl":11112,"bts":231231
    ${r} =    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    Check Response and Retrieve Resource    ${r}

7.21 Cannot update btl
    [Documentation]    batterylevel(btl) cannot be updated
    ${attr} =    Set Variable    "mgd":1006,"btl":11112,"bts":231231
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${Battery} =    Location    ${r}
    ${attr} =    Set Variable    "btl":11112
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${Battery}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

7.22 Cannot update bts
    [Documentation]    batterystatus(bts) cannot be updated
    ${attr} =    Set Variable    "mgd":1006,"btl":11112,"bts":231231
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${Battery} =    Location    ${r}
    ${attr} =    Set Variable    "bts":11112
    ${error} =    Run Keyword And Expect Error    *    update Resource    ${iserver}    ${Battery}    ${rt_mgo}    ${attr}
    Should Start with    ${error}    Cannot update this resource

7.31 Retrieve Battery
    [Documentation]    Retrieve Battery mgmtObj sucsessfully
    ${attr} =    Set Variable    "mgd":1006,"btl":11112,"bts":231231
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${text} =    Check Response and Retrieve Resource    ${r}
    Should Contain    ${text}    "btl"    "bts"    "mgd"

7.41 Delete Battery
    [Documentation]    create a Battery MgmtObj then delete it
    ${attr} =    Set Variable    "mgd":1006,"btl":11112,"bts":231231
    ${r}=    Create Resource    ${iserver}    InCSE1/InNode1    ${rt_mgo}    ${attr}
    ${Battery} =    Location    ${r}
    ${r} =    delete Resource    ${iserver}    ${Battery}
    ${status_code} =    Status Code    ${r}
    Should Be Equal As Integers    ${status_code}    200

*** Keywords ***
Check Response and Retrieve Resource
    [Arguments]    ${r}
    ${con} =    Location    ${r}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
    ${rr} =    Retrieve Resource    ${iserver}    ${con}
    ${text} =    Text    ${rr}
    [Return]    ${text}

Check Response and Retrieve Resource For Update
    [Arguments]    ${r}    ${location}
    ${status_code} =    Status Code    ${r}
    Should Be True    199 < ${status_code} < 299
    ${rr} =    Retrieve Resource    ${iserver}    ${location}
    ${text} =    Text    ${rr}
    [Return]    ${text}