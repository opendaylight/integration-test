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
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${json-file}=    Set Variable    Itm_creation_no_vlan.json
    Set Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}    ${subnet}    ${json-file}
    ...    ${gateway-ip}    ${vlan}
    Log    >>>> Json Update completed<<<<
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Run Keyword If    "${resp.status_code}"==204    Reset Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    Run Keyword If    "${resp.status_code}"!=204    Reset Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp.status_code}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    @{Itm-no-vlan}    Create List    TZA    ${subnet}    ${vlan}    ${Dpn-1}    BR1-eth1
    ...    ${MININET}    ${Dpn-2}    BR2-eth1    ${MININET1}    ${gateway-ip}    tunnel-type-vxlan
    : FOR    ${value}    IN    @{Itm-no-vlan}
    \    Should Contain    ${resp.content}    ${value}
    Sleep    3
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Dpn-2}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel-1}    Get From List    ${resp_array}    3
    Log    ${Tunnel-1}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Dpn-2}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel-2}    Get From List    ${resp_array}    3
    Log    ${Tunnel-2}
    Log    >>>>>OVS Validation in Switch 1 for Tunnel Created <<<<<
    Switch Connection    ${mininet1_conn_id_1}
    ${check-1}    Execute Command    sudo ovs-vsctl show
    Log    ${check-1}
    Should Contain    ${check-1}    ${MININET1}    ${MININET}    ${Tunnel-1}
    Log    >>>>>OVS Validation in Switch 2 for Tunnel Created <<<<<
    Switch Connection    ${mininet2_conn_id_1}
    ${check-2}    Execute Command    sudo ovs-vsctl show
    Log    ${check-2}
    Should Contain    ${check-2}    ${MININET}    ${MININET1}    ${Tunnel-2}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>Validating Interface 1 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/BR1/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    BR1    up    up
    Log    >>>>Validating Interface 2 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/BR2/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    BR2    up    up
    Log    >>>>>Verify Oper data base of Interface state<<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Tunnel-1}
    Should Contain    ${resp.content}    ${Dpn-2}    ${Tunnel-2}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
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
    Log    ${resp_3.content}e
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
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    ${vlan}=    Set Variable    100
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${json-file}=    Set Variable    Itm_creation_no_vlan.json
    Set Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}    ${subnet}    ${json-file}
    ...    ${gateway-ip}    ${vlan}
    Log    >>>> Json Update completed<<<<
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Run Keyword If    "${resp.status_code}"==204    Reset Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    Run Keyword If    "${resp.status_code}"!=204    Reset Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    @{Itm}    Create List    TZA    ${subnet}    ${vlan}    ${Dpn-1}    BR1-eth1
    ...    ${MININET}    ${Dpn-2}    BR2-eth1    ${MININET1}    ${gateway-ip}    tunnel-type-vxlan
    : FOR    ${value}    IN    @{Itm}
    \    Should Contain    ${resp.content}    ${value}
    Sleep    3
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Dpn-2}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel-1}    Get From List    ${resp_array}    3
    Log    ${Tunnel-1}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Dpn-2}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel-2}    Get From List    ${resp_array}    3
    Log    ${Tunnel-2}
    Log    >>>>>OVS Validation in Switch 1 for Tunnel Created <<<<<
    Switch Connection    ${mininet1_conn_id_1}
    ${check-1}    Execute Command    sudo ovs-vsctl show
    Log    ${check-1}
    Should Contain    ${check-1}    ${MININET1}    ${MININET}    ${Tunnel-1}
    Log    >>>>>OVS Validation in Switch 2 for Tunnel Created <<<<<
    Switch Connection    ${mininet2_conn_id_1}
    ${check-2}    Execute Command    sudo ovs-vsctl show
    Log    ${check-2}
    Should Contain    ${check-2}    ${MININET}    ${MININET1}    ${Tunnel-2}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>Validating Interface 1 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/BR1/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    BR1    up    up
    Log    >>>>Validating Interface 2 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/BR2/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    BR2    up    up
    Log    >>>>>Verify Oper data base of Interface state<<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Tunnel-1}
    Should Contain    ${resp.content}    ${Dpn-2}    ${Tunnel-2}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
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
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    ${gateway-ip}    Catenate    ${substr}1
    Log    ${subnet}
    ${vlan}=    Set Variable    101
    ${json-file}=    Set Variable    Itm_creation_no_vlan.json
    Set Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}    ${subnet}    ${json-file}
    ...    ${gateway-ip}    ${vlan}
    Log    >>>> Json Update completed<<<<
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Run Keyword If    "${resp.status_code}"==204    Reset Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    Run Keyword If    "${resp.status_code}"!=204    Reset Json_fields    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    @{Itm}    Create List    TZA    ${subnet}    ${gateway-ip}    ${Dpn-1}    BR1-eth1
    ...    ${MININET}    ${Dpn-2}    BR2-eth1    ${MININET1}    tunnel-type-vxlan    ${vlan}
    : FOR    ${value}    IN    @{Itm}
    \    Should Contain    ${resp.content}    ${value}
    Sleep    5
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-1}/${Dpn-2}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Dpn-2}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel-1}    Get From List    ${resp_array}    3
    Log    ${Tunnel-1}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn-2}/${Dpn-1}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Dpn-2}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel-2}    Get From List    ${resp_array}    3
    Log    ${Tunnel-2}
    Log    >>>>>OVS Validation in Switch 1 for Tunnel Created <<<<<
    Switch Connection    ${mininet1_conn_id_1}
    ${check-1}    Execute Command    sudo ovs-vsctl show
    Log    ${check-1}
    Should Contain    ${check-1}    ${MININET1}    ${MININET}    ${Tunnel-1}
    Log    >>>>>OVS Validation in Switch 2 for Tunnel Created <<<<<
    Switch Connection    ${mininet2_conn_id_1}
    ${check-2}    Execute Command    sudo ovs-vsctl show
    Log    ${check-2}
    Should Contain    ${check-2}    ${MININET}    ${MININET1}    ${Tunnel-2}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>Validating Interface 1 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/BR1/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    BR1    up    up
    Log    >>>>Validating Interface 2 states<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/BR2/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    BR2    up    up
    Log    >>>>>Verify Oper data base of Interface state<<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn-1}    ${Tunnel-1}
    Should Contain    ${resp.content}    ${Dpn-2}    ${Tunnel-2}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn-2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>Verifying Operational data base<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}

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

*** Keywords ***
Reset Json_fields
    [Arguments]    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    ${reset_1}    Run    sed -i 's/"dpn-id": ${Dpn-1}/"dpn-id":1/g' ${VPN_CONFIG_DIR}/${json-file}
    ${reset_2}    Run    sed -i 's/"dpn-id": ${Dpn-2}/"dpn-id":2/g' ${VPN_CONFIG_DIR}/${json-file}
    ${reset-dpn1-ip}    run    sed -i 's/"ip-address": "${MININET}"/"ip-address":"2.2.2.2"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${reset-dpn2-ip}    run    sed -i 's/"ip-address": "${MININET1}"/"ip-address":"3.3.3.3"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${prefix-reset}    run    sed -i 's/${subnet}/1.1.1.1/g' \ ${VPN_CONFIG_DIR}/${json-file}
    ${vlan-reset}    Run    sed -i 's/"vlan-id": ${vlan}/"vlan-id":0/g' \ ${VPN_CONFIG_DIR}/${json-file}
    ${gateway-reset}    Run    sed -i 's/"gateway-ip": "${gateway-ip}"/"gateway-ip":"0.0.0.0"/g' \ ${VPN_CONFIG_DIR}/${json-file}

Set Json _fields
    [Arguments]    ${Dpn-1}    ${Dpn-2}    ${MININET}    ${MININET1}
    ...    ${subnet}    ${json-file}    ${gateway-ip}    ${vlan}
    ${prefix-add}    Run    sed -i \ 's/1.1.1.1/${subnet}/g' ${VPN_CONFIG_DIR}/${json-file}
    ${dpn1-update}    Run    sed -i 's/"dpn-id":1/"dpn-id": ${Dpn-1}/g' ${VPN_CONFIG_DIR}/${json-file}
    ${dpn2-update}    Run    sed -i 's/"dpn-id":2/"dpn-id": ${Dpn-2}/g' ${VPN_CONFIG_DIR}/${json-file}
    ${dpn1-ip-add}    Run    sed -i 's/"ip-address":"2.2.2.2"/"ip-address": "${MININET}"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${dpn2-ip-add}    Run    sed -i 's/"ip-address":"3.3.3.3"/"ip-address": "${MININET1}"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${vlan-id}    Run    sed -i 's/"vlan-id":0/"vlan-id": ${vlan}/g' \ ${VPN_CONFIG_DIR}/${json-file}
    ${gateway}    Run    sed -i 's/"gateway-ip":"0.0.0.0"/"gateway-ip": "${gateway-ip}"/g' \ ${VPN_CONFIG_DIR}/${json-file}
