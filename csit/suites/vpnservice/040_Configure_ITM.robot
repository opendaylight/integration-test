*** Settings ***
Documentation     Test Suite for ITM
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../variables/Variables.py
Library           Collections
Resource          ../../libraries/Utils.robot
Library           re

*** Variables ***
${REST_CON}       /restconf/config
${VPN_CONFIG_DIR}    ${CURDIR}/../../variables/vpnservice
@{itm_created}    TZA    # zone name,prefix,vlan id,gateway,tunneltype,dpn_1,portname,dpn_2,portname,ip adress _1 , ipaddress_2
${REST_OPER}      /restconf/operational

*** Test Cases ***
Create and Verify VTEP -No Vlan
    Log    >>>>Creating VTEP with No Vlan<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/odl-interface-meta:bridge-ref-info/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${str1}    Get From List    ${resp_array}    1
    ${Dpn-1}    re.sub    ,    \    ${str1}
    Log    ${Dpn-1}
    @{resp_array}    Split String    ${result}    ,,
    ${Dpn-2}    Get From List    ${resp_array}    4
    Log    ${Dpn-2}
    ${dpn1-update}    Run    sed -i 's/"dpn-id":1/"dpn-id": ${Dpn-1}/g' ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${dpn2-update}    Run    sed -i 's/"dpn-id":2/"dpn-id": ${Dpn-2}/g' ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    Run Keyword If    "${resp.status_code}"==204    Log    Json posted successfully
    Log    >>>>> Resetting the Dpn Ids to \ 1 & 2<<<<<
    ${reset_1}    Run    sed -i 's/"dpn-id": ${Dpn-1}/"dpn-id":1/g' ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${reset_2}    Run    sed -i 's/"dpn-id": ${Dpn-2}/"dpn-id":2/g' ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    @{Itm-no-vlan}    Create List    TZA    10.183.254.0/24    0    ${Dpn-1}    s1-eth1
    ...    ${MININET}    ${Dpn-2}    s2-eth1    ${MININET1}    0.0.0.0    tunnel-type-vxlan
    : FOR    ${value}    IN    @{Itm-no-vlan}
    \    Should Contain    ${resp.content}    ${value}
    Sleep    3
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/s1/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${int1_name}    Get From List    ${resp_array}    1
    Log    ${int1_name}
    Should Be String    ${int1_name}
    Should Be True    '${int1_name}' =='s1'
    Log    Interface Name is ${int1_name}
    ${admin_status}    Get From List    ${resp_array}    3
    Log    ${admin_status}
    Should Be True    '${admin_status}' == 'up'
    Log    Admin status is UP
    ${Operational_status}    Get From List    ${resp_array}    4
    Log    ${Operational_status}
    Should Be True    '${Operational_status}' == 'up'
    Log    Operational status is UP
    Log    >>>>Validating Interface 2 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/s2/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${interface2_name}    Get From List    ${resp_array}    1
    Log    ${interface2_name}
    Should Be String    ${interface2_name}
    Should Be True    '${interface2_name}' =='s2'
    Log    Interface Name is ${interface2_name}
    ${admin_status}    Get From List    ${resp_array}    3
    Log    ${admin_status}
    Should Be True    '${admin_status}' == 'up'
    Log    Admin status is UP
    ${Operational_status}    Get From List    ${resp_array}    4
    Log    ${Operational_status}
    Should Be True    '${Operational_status}' == 'up'
    Log    Operational status is UP
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${Tunnel_Id_1}    Get Substring    ${result}    29    37
    Log    ${Tunnel_Id_1}
    Should Be String    ${Tunnel_Id_1}
    Log    >>>>Verify Tunnel Verify Tunnel Created between dpn 2 and dpn 1<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${Tunnel_Id_2}    Get Substring    ${result}    29    37
    Log    ${Tunnel_Id_2}
    Should Be String    ${Tunnel_Id_2}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${interface_name_1}    Get Substring    ${result}    1    8
    Log    ${interface_name_1}
    Log    >>>>Verify DPN Teps info 2<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${interface_name_2}    Get Substring    ${result}    1    8
    Log    ${interface_name_2}
    ${resp_1}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp_1.content}
    ${Line1}    Get Lines Containing String    ${Tunnel_Id_1}    ${resp_1.content}
    ${line2}    Get Lines Containing String    ${Tunnel_Id_2}    ${resp_1.content}
    Log    ${Line1}
    Log    ${Line1}
    Log    >>>>Verifying Operational data base<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}

Delete and Verify VTEP -No Vlan
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/odl-interface-meta:bridge-ref-info/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${str1}    Get From List    ${resp_array}    1
    ${Dpn-1}    re.sub    ,    \    ${str1}
    Log    ${Dpn-1}
    @{resp_array}    Split String    ${result}    ,,
    ${Dpn-2}    Get From List    ${resp_array}    4
    Log    ${Dpn-2}
    ${resp_1}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    5
    ${resp_2}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_5.status_code}    200
    ${resp_6}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_6.status_code}    200

Create and Verify VTEP-Vlan
    Log    >>>>Creating VTEP with No Vlan<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/odl-interface-meta:bridge-ref-info/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${str1}    Get From List    ${resp_array}    1
    ${Dpn-1}    re.sub    ,    \    ${str1}
    Log    ${Dpn-1}
    @{resp_array}    Split String    ${result}    ,,
    ${Dpn-2}    Get From List    ${resp_array}    4
    Log    ${Dpn-2}
    ${dpn1-update}    Run    sed -i 's/"dpn-id":1/"dpn-id": ${Dpn-1}/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan.json
    ${dpn2-update}    Run    sed -i 's/"dpn-id":2/"dpn-id": ${Dpn-2}/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan.json
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_vlan.json
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    Run Keyword If    "${resp.status_code}"==204    Log    Json posted successfully
    Log    >>>>> Resetting the Dpn Ids to \ 1 & 2<<<<<
    ${reset_1}    Run    sed -i 's/"dpn-id": ${Dpn-1}/"dpn-id":1/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan.json
    ${reset_2}    Run    sed -i 's/"dpn-id": ${Dpn-2}/"dpn-id":2/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan.json
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    @{Itm-vlan}    Create List    TZA    10.183.254.0/24    100    ${Dpn-1}    s1-eth1
    ...    ${MININET}    ${Dpn-2}    s2-eth1    ${MININET1}    0.0.0.0    tunnel-type-vxlan
    : FOR    ${value}    IN    @{Itm-vlan}
    \    Should Contain    ${resp.content}    ${value}
    Sleep    3
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/s1/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${int1_name}    Get From List    ${resp_array}    1
    Log    ${int1_name}
    Should Be String    ${int1_name}
    Should Be True    '${int1_name}' =='s1'
    Log    Interface Name is ${int1_name}
    ${admin_status}    Get From List    ${resp_array}    3
    Log    ${admin_status}
    Should Be True    '${admin_status}' == 'up'
    Log    Admin status is UP
    ${Operational_status}    Get From List    ${resp_array}    4
    Log    ${Operational_status}
    Should Be True    '${Operational_status}' == 'up'
    Log    Operational status is UP
    Log    >>>>Validating Interface 2 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/s2/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${interface2_name}    Get From List    ${resp_array}    1
    Log    ${interface2_name}
    Should Be String    ${interface2_name}
    Should Be True    '${interface2_name}' =='s2'
    Log    Interface Name is ${interface2_name}
    ${admin_status}    Get From List    ${resp_array}    3
    Log    ${admin_status}
    Should Be True    '${admin_status}' == 'up'
    Log    Admin status is UP
    ${Operational_status}    Get From List    ${resp_array}    4
    Log    ${Operational_status}
    Should Be True    '${Operational_status}' == 'up'
    Log    Operational status is UP
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${Tunnel_Id_1}    Get Substring    ${result}    29    38
    Log    ${Tunnel_Id_1}
    Should Be String    ${Tunnel_Id_1}
    Log    >>>>Verify Tunnel Verify Tunnel Created between dpn 2 and dpn 1<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${Tunnel_Id_2}    Get Substring    ${result}    29    38
    Log    ${Tunnel_Id_2}
    Should Be String    ${Tunnel_Id_2}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    Log    >>>>Verify DPN Teps info 2<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${resp_1}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp_1.content}
    Log    >>>>Verifying Operational data base<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}

Delete and Verify VTEP -Vlan
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/odl-interface-meta:bridge-ref-info/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${str1}    Get From List    ${resp_array}    1
    ${Dpn-1}    re.sub    ,    \    ${str1}
    Log    ${Dpn-1}
    @{resp_array}    Split String    ${result}    ,,
    ${Dpn-2}    Get From List    ${resp_array}    4
    Log    ${Dpn-2}
    ${resp_1}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    5
    ${resp_2}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_5.status_code}    200
    ${resp_6}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_6.status_code}    200

Create VTEP - Vlan and Gateway
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/odl-interface-meta:bridge-ref-info/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${str1}    Get From List    ${resp_array}    1
    ${Dpn-1}    re.sub    ,    \    ${str1}
    Log    ${Dpn-1}
    @{resp_array}    Split String    ${result}    ,,
    ${Dpn-2}    Get From List    ${resp_array}    4
    Log    ${Dpn-2}
    ${dpn1-update}    Run    sed -i 's/"dpn-id":1/"dpn-id": ${Dpn-1}/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan_gateway.json
    ${dpn2-update}    Run    sed -i 's/"dpn-id":2/"dpn-id": ${Dpn-2}/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan_gateway.json
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_vlan_gateway.json
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    Run Keyword If    "${resp.status_code}"==204    Log    Json posted successfully
    Log    >>>>> Resetting the Dpn Ids to \ 1 & 2<<<<<
    ${reset_1}    Run    sed -i 's/"dpn-id": ${Dpn-1}/"dpn-id":1/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan_gateway.json
    ${reset_2}    Run    sed -i 's/"dpn-id": ${Dpn-2}/"dpn-id":2/g' ${VPN_CONFIG_DIR}/Itm_creation_vlan_gateway.json
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    @{Itm-vlan-gateway}    Create List    TZA    10.183.254.0/24    101    ${Dpn-1}    s1-eth1
    ...    ${MININET}    ${Dpn-2}    s2-eth1    ${MININET1}    10.183.254.1    tunnel-type-vxlan
    : FOR    ${value}    IN    @{Itm-vlan-gateway}
    \    Should Contain    ${resp.content}    ${value}
    Sleep    3
    Log    >>>>Verify Tunnel Verify Tunnel Created between dpn 1 and dpn 2<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${Tunnel_Id_1}    Get Substring    ${result}    2    10
    Log    ${Tunnel_Id_1}
    Should Be String    ${Tunnel_Id_1}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    Log    >>>>Verify DPN Teps info 1<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    Log    >>>>Verify DPN Teps info 2<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    \    ${resp.content}
    Log    ${result}
    ${resp_1}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp_1.content}
    Log    >>>>Verifying Operational data base<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Log    >>>>Validating Interface states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/s1/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${interface1_name}    Get From List    ${resp_array}    1
    Log    ${interface1_name}
    Should Be True    '${interface1_name}' =='s1'
    Log    Interface Name is ${interface1_name}
    ${admin_status}    Get From List    ${resp_array}    3
    Log    ${admin_status}
    Should Be True    '${admin_status}' == 'up'
    Log    Admin status is UP
    ${Operational_status}    Get From List    ${resp_array}    4
    Log    ${Operational_status}
    Should Be True    '${Operational_status}' == 'up'
    Log    Operational status is UP
    Log    >>>>Verify Interface 2 state<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/s2/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${interface2_name}    Get From List    ${resp_array}    1
    Log    ${interface2_name}
    Should Be True    '${interface2_name}' =='s2'
    Log    Interface Name is ${interface2_name}
    ${admin_status}    Get From List    ${resp_array}    3
    Log    ${admin_status}
    Should Be True    '${admin_status}' == 'up'
    Log    Admin status is UP
    ${Operational_status}    Get From List    ${resp_array}    4
    Log    ${Operational_status}
    Should Be True    '${Operational_status}' == 'up'
    Log    Operational status is UP

Delete VTEP -Vlan and gateway
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/odl-interface-meta:bridge-ref-info/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${str1}    Get From List    ${resp_array}    1
    ${Dpn-1}    re.sub    ,    \    ${str1}
    Log    ${Dpn-1}
    @{resp_array}    Split String    ${result}    ,,
    ${Dpn-2}    Get From List    ${resp_array}    4
    Log    ${Dpn-2}
    ${resp_1}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    5
    ${resp_2}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_5.status_code}    200
    ${resp_6}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_6.status_code}    200

