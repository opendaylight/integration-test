*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Utils.robot
Resource          TemplatedRequests.robot
Resource          ../variables/Variables.robot
Library           Collections
Library           String
Library           OperatingSystem
Variables         ../variables/Variables.py

*** Variables ***
${VPN_INSTANCE_DELETE}    vpn1_instance_delete.json
${GETL3VPN}       GETL3vpn.json
${CREATE_RESP_CODE}    200
${CREATE_ID_DEFAULT}    "4ae8cd92-48ca-49b5-94e1-b2921a2661c7"
${CREATE_NAME_DEFAULT}    "vpn1"
${CREATE_ROUTER_DISTINGUISHER_DEFAULT}    ["2200:1"]
${CREATE_EXPORT_RT_DEFAULT}    ["3300:1","8800:1"]
${CREATE_IMPORT_RT_DEFAULT}    ["3300:1","8800:1"]
${CREATE_TENANT_ID_DEFAULT}    "6c53df3a-3456-11e5-a151-feff819cdc9f"
${VPN_CONFIG_DIR}    ${CURDIR}/../variables/vpnservice
&{ITM_DEFAULT_VAL}    tunneltype=vxlan    vlanid=0    prefix=1.1.1.1/24    gateway=0.0.0.0    dpnid1=1    portname1=BR1-eth1    ipaddress1=2.2.2.2    dpnid2=2    portname2= BR2-eth1   ipaddress2=3.3.3.3
${VAR_BASE}       ${CURDIR}/../variables/vpnservice/

*** Keywords ***
VPN Create L3VPN
    [Arguments]    ${vpn_instance}    &{Kwargs}
    [Documentation]    Create an L3VPN using the Json using the list of optional arguments received.
    @{KeysList}    Create List    CREATE_ID    CREATE_NAME    CREATE_ROUTER_DISTINGUISHER    CREATE_EXPORT_RT    CREATE_IMPORT_RT
    ...    CREATE_TENANT_ID
    ${body} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${vpn_instance}
    Log    Body:${body}
    Run Keyword If    ${Kwargs}    Log    ${Kwargs}
    ${CREATE_ID} =    Run Keyword If    ${Kwargs} != None    Pop From Dictionary    ${Kwargs}    ${KeysList[0]}    default=${CREATE_ID_DEFAULT}
    ${body} =    Replace String    ${body}    ${CREATE_ID_DEFAULT}    ${CREATE_ID}
    Log    ID:${CREATE_ID}
    ${CREATE_NAME} =    Run Keyword If    ${Kwargs} != None    Pop From Dictionary    ${Kwargs}    ${KeysList[1]}    default=${CREATE_NAME_DEFAULT}
    ${body} =    Replace String    ${body}    ${CREATE_NAME_DEFAULT}    ${CREATE_NAME}
    Log    NAME:${CREATE_NAME}
    ${CREATE_ROUTER_DISTINGUISHER} =    Run Keyword If    ${Kwargs} != None    Pop From Dictionary    ${Kwargs}    ${KeysList[2]}    default=${CREATE_ROUTER_DISTINGUISHER_DEFAULT}
    ${body} =    Replace String    ${body}    ${CREATE_ROUTER_DISTINGUISHER_DEFAULT}    ${CREATE_ROUTER_DISTINGUISHER}
    Log    ROUTER_DISTIGNSHER:${CREATE_ROUTER_DISTINGUISHER}
    ${CREATE_EXPORT_RT} =    Run Keyword If    ${Kwargs} != None    Pop From Dictionary    ${Kwargs}    ${KeysList[3]}    default=${CREATE_EXPORT_RT_DEFAULT}
    ${body} =    Replace String    ${body}    ${CREATE_EXPORT_RT_DEFAULT}    ${CREATE_EXPORT_RT}
    Log    EXPORT_RT:${CREATE_EXPORT_RT}
    ${CREATE_IMPORT_RT} =    Run Keyword If    ${Kwargs} != None    Pop From Dictionary    ${Kwargs}    ${KeysList[4]}    default=${CREATE_IMPORT_RT_DEFAULT}
    ${body} =    Replace String    ${body}    ${CREATE_IMPORT_RT_DEFAULT}    ${CREATE_IMPORT_RT}
    Log    IMPORT_RT:${CREATE_IMPORT_RT}
    ${CREATE_TENANT_ID} =    Run Keyword If    ${Kwargs} != None    Pop From Dictionary    ${Kwargs}    ${KeysList[5]}    default=${CREATE_TENANT_ID_DEFAULT}
    ${body} =    Replace String    ${body}    ${CREATE_TENANT_ID_DEFAULT}    ${CREATE_TENANT_ID}
    Log    TENANT_ID:${CREATE_TENANT_ID}
    Set Global Variable    ${GET_ID}    ${CREATE_ID}
    Log    ${body}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:createL3VPN    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}
    ${body1} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${GETL3VPN}
    ${body1} =    Replace String    ${body1}    ${CREATE_ID_DEFAULT}    ${CREATE_ID}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:getL3VPN    data=${body1}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}

VPN Get L3VPN
    [Arguments]    ${GET_L3VPN_ID}
    [Documentation]    Will return detailed list of the L3VPN_ID received
    ${body1} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${GETL3VPN}
    ${body1} =    Replace String    ${body1}    ${CREATE_ID_DEFAULT}    ${GET_L3VPN_ID}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:getL3VPN    data=${body1}
    Log    ${resp}
    Log    BODY:${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}
    [Return]    ${resp.content}

Associate L3VPN To Network
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    ${resp} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/assoc_l3vpn    mapping=${Kwargs}    session=session
    Log    ${resp}
    Get L3VPN Association

Dissociate L3VPN From Networks
    [Arguments]    &{Kwargs}
    [Documentation]    Disssociate the already associated networks from L3VPN
    ${resp} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/dissoc_l3vpn    mapping=${Kwargs}    session=session
    Log    ${resp}
    Get L3VPN Association

Get L3VPN Association
    [Documentation]    Will return detailed list of L3VPN created and associated networks
    ${resp} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/get_l3vpn    mapping={"getid":${GET_ID}}    session=session
    Log    ${resp}
    [Return]    ${resp}

Associate VPN to Router
    [Arguments]    ${ROUTER}    ${VPN_INSTANCE_NAME}
    [Documentation]    Associate the created L3VPN to a router-id received as argument
    ${body} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_router.json
    ${body} =    Replace String    ${body}    VPN_ID    ${VPN_INSTANCE_NAME}
    ${body} =    Replace String    ${body}    ROUTER_ID    ${ROUTER}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:associateRouter    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}
    ${body1} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${GETL3VPN}
    ${body1} =    Replace String    ${body1}    ${CREATE_ID_DEFAULT}    ${GET_ID}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:getL3VPN    data=${body1}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}

Dissociate VPN to Router
    [Arguments]    ${ROUTER}    ${VPN_INSTANCE_NAME}
    [Documentation]    Dissociate the already associated routers from L3VPN
    ${body} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_router.json
    ${body} =    Replace String    ${body}    VPN_ID    ${VPN_INSTANCE_NAME}
    ${body} =    Replace String    ${body}    ROUTER_ID    ${ROUTER}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:dissociateRouter    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}
    ${body1} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${GETL3VPN}
    ${body1} =    Replace String    ${body1}    ${CREATE_ID_DEFAULT}    ${GET_ID}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:getL3VPN    data=${body1}
    Log    ${resp}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}

VPN Delete L3VPN
    [Arguments]    ${DEL_L3VPN_ID}
    [Documentation]    Delete the created L3VPN
    ${body1} =    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${VPN_INSTANCE_DELETE}
    Log    ${body1}
    ${body1} =    Replace String    ${body1}    ${CREATE_ID_DEFAULT}    ${DEL_L3VPN_ID}
    ${resp} =    RequestsLibrary.Post Request    session    ${OPERATIONS_API}/neutronvpn:deleteL3VPN    ${body1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${CREATE_RESP_CODE}

ITM Create Tunnel
    [Arguments]    &{Kwargs}
    &{Itm_actual_val} =    Collections.Copy_Dictionary    ${ITM_DEFAULT_VAL}
    Collections.Set_To_Dictionary    ${Itm_actual_val}    &{Kwargs}
    [Documentation]    Creates Tunnel between the two DPNs received in the dictionary argument
    ${resp} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/itm_create    mapping=${Itm_actual_val}    session=session
    Log    ${resp}

ITM Get Tunnels
    [Documentation]    Get all Tunnels and return the contents
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:transport-zones/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

ITM Delete Tunnel
    [Arguments]    ${zone-name}
    [Documentation]    Delete Tunnels created under the transport-zone
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${zone-name}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}
