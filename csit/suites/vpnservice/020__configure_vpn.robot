*** Settings ***
Documentation       Test Suite for vpn instance

Library             OperatingSystem
Library             String
Library             RequestsLibrary
Variables           ../../variables/Variables.py
Library             Collections
Resource            CompareStream.robot

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Variables ***
${RESTS_DATA}             /rests/data/
@{vpn_inst_values}      testVpn1    1000:1    1000:1,2000:1    3000:1,4000:1
@{vm_int_values}        s1-eth1    l2vlan    openflow:1:1
@{vm_vpnint_values}     s1-eth1    testVpn1    10.0.0.1    12:f8:57:a8:b9:a1
${VPN_CONFIG_DIR}       ${CURDIR}/../../variables/vpnservice


*** Test Cases ***
Create VPN Instance
    [Documentation]    Creates VPN Instance through restconf
    [Tags]    post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance.json
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Post Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-instances/
    ...    data=${body}
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Post Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-instances/
    ...    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify VPN instance
    [Documentation]    Verifies the vpn instance is created
    [Tags]    get
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    ...    headers=${ACCEPT_XML}
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    FOR    ${value}    IN    @{vpn_inst_values}
        Should Contain    ${resp.content}    ${value}
    END

Create ietf vm interface
    [Documentation]    Creates ietf interface through the restconf
    [Tags]    post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vm_interface.json
    ${resp}    RequestsLibrary.Post Request    session    ${RESTS_DATA}ietf-interfaces:interfaces/    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify ietf vm interface
    [Documentation]    Verifies ietf interface created
    [Tags]    get
    ${resp}    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}ietf-interfaces:interfaces/interface/${vm_int_values[0]}/
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    FOR    ${value}    IN    @{vm_int_values}
        Should Contain    ${resp.content}    ${value}
    END

Create VPN interface
    [Documentation]    Creates vpn interface for the corresponding ietf interface
    [Tags]    post
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vm_vpninterface.json
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Post Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-interfaces/
    ...    data=${body}
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Post Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-interfaces/
    ...    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    204

Verify VPN interface
    [Documentation]    Verifies the vpn interface created
    [Tags]    get
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-interfaces/
    ...    headers=${ACCEPT_XML}
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-interfaces/
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    FOR    ${value}    IN    @{vm_vpnint_values}
        Should Contain    ${resp.content}    ${value}
    END

Verify FIB entry after create
    [Documentation]    Verifies the fib entry for the corresponding vpn interface
    [Tags]    get
    Wait Until Keyword Succeeds    5s    1s    Ensure The Fib Entry Is Present    ${vm_vpnint_values[2]}

Delete vm vpn interface
    [Documentation]    Deletes the vpn interface
    [Tags]    delete
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Delete Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-interfaces/
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Delete Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-interfaces/
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleteing vm vpn interface
    [Documentation]    Verifies vpn interface after delete
    [Tags]    verify after delete
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-interfaces/
    ...    headers=${ACCEPT_XML}
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-interfaces/
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete VPN Instance
    [Documentation]    Deletes the VPN Instance
    [Tags]    delete
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Delete Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Delete Requestt
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting the vpn instance
    [Documentation]    Verifies after deleting the vpn instance
    [Tags]    verfiy after delete
    CompareStream.Run_Keyword_If_Less_Than_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Post Request
    ...    session
    ...    ${RESTS_DATA}l3vpn:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    ...    headers=${ACCEPT_XML}
    CompareStream.Run_Keyword_If_At_Least_Magnesium
    ...    ${resp}
    ...    RequestsLibrary.Post Request
    ...    session
    ...    ${RESTS_DATA}l3vpn-instances-interfaces:vpn-instances/vpn-instance/${vpn_inst_values[0]}/
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete vm ietf interface
    [Documentation]    Deletes the ietf interface
    [Tags]    delete
    ${resp}    RequestsLibrary.Delete Request
    ...    session
    ...    ${RESTS_DATA}ietf-interfaces:interfaces/interface/${vm_int_values[0]}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting vm ietf interface
    [Documentation]    Verifies ietf interface after delete
    [Tags]    verify after delete
    ${resp}    RequestsLibrary.Get Request
    ...    session
    ...    ${RESTS_DATA}ietf-interfaces:interfaces/interface/${vm_int_values[0]}
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    404

Verify FIB entry after delete
    [Documentation]    Verifies the fib entry is deleted for the corresponding vpn interface
    [Tags]    get
    Wait Until Keyword Succeeds    5s    1s    Ensure The Fib Entry Is Removed    ${vm_vpnint_values[2]}


*** Keywords ***
Ensure The Fib Entry Is Present
    [Documentation]    Will succeed if the fib entry is present for the vpn
    [Arguments]    ${prefix}
    ${resp}    RequestsLibrary.Get Request
    ...    session
    ...    /rests/data/odl-fib:fibEntries?content=nonconfig
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${prefix}
    Should Contain    ${resp.content}    label

Ensure the Fib Entry Is Removed
    [Documentation]    Will succeed if the fib entry is removed for the vpn
    [Arguments]    ${prefix}
    ${resp}    RequestsLibrary.Get Request
    ...    session
    ...    /rests/data/odl-fib:fibEntries?content=nonconfig
    ...    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    ${prefix}
