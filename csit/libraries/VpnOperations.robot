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
&{ITM_CREATE_DEFAULT}    tunneltype=vxlan    vlanid=0    prefix=1.1.1.1/24    gateway=0.0.0.0    dpnid1=1    portname1=BR1-eth1    ipaddress1=2.2.2.2
...               dpnid2=2    portname2= BR2-eth1    ipaddress2=3.3.3.3
&{L3VPN_CREATE_DEFAULT}    vpnid=4ae8cd92-48ca-49b5-94e1-b2921a261111    name=vpn1    rd=["2200:1"]    exportrt=["2200:1","8800:1"]    importrt=["2200:1","8800:1"]    tenantid=6c53df3a-3456-11e5-a151-feff819cdc9f
${VAR_BASE}       ${CURDIR}/../variables/vpnservice/

*** Keywords ***
VPN Create L3VPN
    [Arguments]    &{Kwargs}
    [Documentation]    Create an L3VPN using the Json using the list of optional arguments received.
    &{L3vpn_create_actual_val} =    Collections.Copy_Dictionary    ${L3VPN_CREATE_DEFAULT}
    Collections.Set_To_Dictionary    ${L3vpn_create_actual_val}    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/l3vpn_create    mapping=${L3vpn_create_actual_val}    session=session

VPN Get L3VPN
    [Arguments]    &{Kwargs}
    [Documentation]    Will return detailed list of the L3VPN_ID received
    ${resp} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/get_l3vpn    mapping=${Kwargs}    session=session
    Log    ${resp}
    [Return]    ${resp}

Associate L3VPN To Network
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/assoc_l3vpn    mapping=${Kwargs}    session=session

Dissociate L3VPN From Networks
    [Arguments]    &{Kwargs}
    [Documentation]    Disssociate the already associated networks from L3VPN
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/dissoc_l3vpn    mapping=${Kwargs}    session=session

Associate VPN to Router
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a router-id received as argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/assoc_router_l3vpn    mapping=${Kwargs}    session=session

Dissociate VPN to Router
    [Arguments]    &{Kwargs}
    [Documentation]    Dissociate the already associated routers from L3VPN
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/dissoc_router_l3vpn    mapping=${Kwargs}    session=session

VPN Delete L3VPN
    [Arguments]    &{Kwargs}
    [Documentation]    Delete the created L3VPN
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/l3vpn_delete    mapping=${Kwargs}    session=session

ITM Create Tunnel
    [Arguments]    &{Kwargs}
    [Documentation]    Creates Tunnel between the two DPNs received in the dictionary argument
    &{Itm_actual_val} =    Collections.Copy_Dictionary    ${ITM_CREATE_DEFAULT}
    Collections.Set_To_Dictionary    ${Itm_actual_val}    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/itm_create    mapping=${Itm_actual_val}    session=session

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
