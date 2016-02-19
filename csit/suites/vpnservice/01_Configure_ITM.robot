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
Library           ../../libraries/getOvsDpn.py    WITH NAME    dpn

*** Variables ***
${REST_CON}       /restconf/config
${VPN_CONFIG_DIR}    ${CURDIR}/../../variables/vpnservice
@{itm_created}    TZA
${REST_OPER}      /restconf/operational

*** Test Cases ***
Create and Verify VTEP -No Vlan
    Log    >>>>Creating VTEP with No Vlan<<<<
    ${Bridge-1}=    Set Variable    BR1
    ${Bridge-2}=    Set Variable    BR2
    Set Global Variable    ${Bridge-1}
    Set Global Variable    ${Bridge-2}
    ${Dpn_id_1}    Get Dpn Ids    ${mininet1_conn_id_1}
    ${Dpn_id_2}    Get Dpn Ids    ${mininet2_conn_id_1}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id":1    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id":2    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address":"2.2.2.2"    "ip-address": "${MININET}"
    ${body}    replace string    ${body}    "ip-address":"3.3.3.3"    "ip-address": "${MININET1}"
    ${body}    replace string    ${body}    "vlan-id":0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip":"0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    ${get}    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}
    ...    ${vlan}    ${Dpn_id_1}    ${MININET}    ${Dpn_id_2}    ${MININET1}
    Log    ${get}
    Log    >>>>Tunnel from DPN 1 to Dpn 2<<<<<
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${tunnel-1}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    log    ${tunnel-1}
    Set Global Variable    ${tunnel-1}
    Log    >>>>Tunnel from DPN 2 to Dpn 1<<<<<
    ${tunnel-2}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    log    ${tunnel-2}
    Set Global Variable    ${tunnel-2}
    ${tunnel-type}=    Set Variable    type: vxlan
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>OVS Validation in Switch 1 for Tunnel Created<<<<<
    ${check-1}    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${mininet1_conn_id_1}    ${MININET}
    ...    ${MININET1}    ${tunnel-1}    ${tunnel-type}
    Log    ${check-1}
    Log    >>>>OVS Validation in Switch 2 for Tunnel Created<<<<<
    ${check-2}    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${mininet2_conn_id_1}    ${MININET1}
    ...    ${MININET}    ${tunnel-2}    ${tunnel-type}
    Log    ${check-2}
    Log    >>>> Getting Network Topology Operational <<<<<<
    ${url-2}=    Set Variable    ${REST_OPER}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-1}    ${tunnel-2}    ${url-2}
    Log    ${resp}
    Log    >>>>Validating Interface 1 states<<<<
    ${data-1:2}    Wait Until Keyword Succeeds    40    10    Validate interface state    ${tunnel-1}    ${Dpn_id_1}
    Log    ${data-1:2}
    @{array-1}    Split String    ${data-1:2}    ,
    ${port-num-1}    Get from List    ${array-1}    0
    ${lower-layer-if-1}    Get From List    ${array-1}    1
    Log    >>>>Validating Interface 2 states<<<<
    ${data-2:1}    Wait Until Keyword Succeeds    40    10    Validate interface state    ${tunnel-2}    ${Dpn_id_2}
    Log    ${data-2:1}
    @{array-2}    Split String    ${data-2:1}    ,
    ${port-num-2}    Get from List    ${array-2}    0
    ${lower-layer-if-2}    Get From List    ${array-2}    1
    Log    >>>>>Verify Oper data base of Interface state<<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    Log    >>>>> Checking Entry in table 0 on OVS 1<<<<<
    ${check-3}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet1_conn_id_1}    ${Bridge-1}
    ...    ${port-num-1}
    Log    ${check-3}
    Log    >>>>> Checking Entry in table 0 on OVS \ 2<<<<<
    ${check-4}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet2_conn_id_1}    ${Bridge-2}
    ...    ${port-num-2}
    Log    ${check-4}
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-1}    ${lower-layer-if-2}
    Log    ${resp.content}

Delete and Verify VTEP -No Vlan
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${resp_1}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    10
    ${resp_2}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp_5.content}
    Should Be Equal As Strings    ${resp_5.status_code}    404
    ${resp_6}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp_6.content}
    Should Be Equal As Strings    ${resp_6.status_code}    404
    ${resp_7}    RequestsLibrary.Get    session    ${REST_CON}/ietf-interfaces:interfaces/interface/    headers=${ACCEPT_XML}
    log    ${resp_7.content}
    Should Be Equal As Strings    ${resp_7.status_code}    404
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet1_conn_id_1}    ${tunnel-1}
    Log    ${Ovs-del-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet2_conn_id_1}    ${tunnel-2}
    Log    ${Ovs-del-2}
    Log    >>>>>>> Getting Network Topology Config without Tunnels<<<<<<<
    ${url-2}=    Set variable    ${REST_OPER}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    5s    Get Network Topology without Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-1}    ${tunnel-2}    ${url-2}
    Log    ${resp}
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-1}
    Log    ${resp_8}
    ${resp_9}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-2}
    Log    ${resp_9}

Create and Verify VTEP-Vlan
    Log    >>>>Creating VTEP with No Vlan<<<<
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    ${vlan}=    Set Variable    100
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id":1    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id":2    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address":"2.2.2.2"    "ip-address": "${MININET}"
    ${body}    replace string    ${body}    "ip-address":"3.3.3.3"    "ip-address": "${MININET1}"
    ${body}    replace string    ${body}    "vlan-id":0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip":"0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${get}    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}
    ...    ${vlan}    ${Dpn_id_1}    ${MININET}    ${Dpn_id_2}    ${MININET1}
    Log    ${get}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    Log    >>>>Tunnel from DPN 1 to Dpn 2<<<<<
    ${tunnel-3}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    log    ${tunnel-3}
    Set Global Variable    ${tunnel-3}
    Log    >>>>Tunnel from DPN 2 to Dpn 1<<<<<
    ${tunnel-4}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    log    ${tunnel-4}
    Set Global Variable    ${tunnel-4}
    ${tunnel-type}=    Set Variable    type: vxlan
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>OVS Validation in Switch 1 for Tunnel Created<<<<<
    ${check-1}    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${mininet1_conn_id_1}    ${MININET}
    ...    ${MININET1}    ${tunnel-3}    ${tunnel-type}
    Log    ${check-1}
    Log    >>>>OVS Validation in Switch 2 for Tunnel Created<<<<<
    ${check-2}    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${mininet2_conn_id_1}    ${MININET1}
    ...    ${MININET}    ${tunnel-4}    ${tunnel-type}
    Log    ${check-2}
    Log    >>>>> Checking Network opertional Topology <<<<<<
    ${url-2}=    Set Variable    ${REST_CON}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-3}    ${tunnel-4}    ${url-2}
    Log    ${resp}
    Log    >>>>Validating Interface 1 states<<<<
    ${data-1:2}    Wait Until Keyword Succeeds    40    10    Validate interface state    ${tunnel-3}    ${Dpn_id_1}
    Log    ${data-1:2}
    @{array-1}    Split String    ${data-1:2}    ,
    ${port-num-1}    Get from List    ${array-1}    0
    ${lower-layer-if-1}    Get From List    ${array-1}    1
    Log    >>>>Validating Interface 2 states<<<<
    ${data-2:1}    Wait Until Keyword Succeeds    40    10    Validate interface state    ${tunnel-4}    ${Dpn_id_2}
    Log    ${data-1:2}
    @{array-2}    Split String    ${data-2:1}    ,
    ${port-num-2}    Get from List    ${array-2}    0
    ${lower-layer-if-2}    Get From List    ${array-2}    1
    Log    >>>>>Verify Oper data base of Interface state<<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-3}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-4}
    Log    >>>>> Checking Entry in table 0 on OVS 1<<<<<
    ${check-3}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet1_conn_id_1}    ${Bridge-1}
    ...    ${port-num-1}
    Log    ${check-3}
    Log    >>>>> Checking Entry in table 0 on OVS \ 2<<<<<
    ${check-4}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet2_conn_id_1}    ${Bridge-2}
    ...    ${port-num-2}
    Log    ${check-4}
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-2}    ${lower-layer-if-1}
    Log    ${resp.content}

Delete and Verify VTEP -Vlan
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${resp_1}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    10
    ${resp_2}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp_5.content}
    Should Be Equal As Strings    ${resp_5.status_code}    404
    ${resp_6}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp_6.content}
    Should Be Equal As Strings    ${resp_6.status_code}    404
    ${resp_7}    RequestsLibrary.Get    session    ${REST_CON}/ietf-interfaces:interfaces/interface/    headers=${ACCEPT_XML}
    log    ${resp_7.content}
    Should Be Equal As Strings    ${resp_7.status_code}    404
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet1_conn_id_1}    ${tunnel-3}
    Log    ${Ovs-del-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet2_conn_id_1}    ${tunnel-4}
    Log    ${Ovs-del-2}
    Log    >>>>>>> Getting Network Topology Config without Tunnels<<<<<<<
    ${url-2}=    Set variable    ${REST_OPER}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    5s    Get Network Topology without Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-3}    ${tunnel-4}    ${url-2}
    Log    ${resp}
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-3}
    Log    ${resp_8}
    ${resp_9}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-4}
    Log    ${resp_9}

Create VTEP - Vlan and Gateway
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    ${gateway-ip}    Catenate    ${substr}1
    Log    ${subnet}
    ${vlan}=    Set Variable    101
    ${json-file}=    Set Variable    Itm_creation_no_vlan.json
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id":1    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id":2    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address":"2.2.2.2"    "ip-address": "${MININET}"
    ${body}    replace string    ${body}    "ip-address":"3.3.3.3"    "ip-address": "${MININET1}"
    ${body}    replace string    ${body}    "vlan-id":0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip":"0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    ${resp}    RequestsLibrary.Post    session    ${REST_CON}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    ${get}    Wait Until Keyword Succeeds    40    10    Get ITM    ${itm_created[0]}    ${subnet}
    ...    ${vlan}    ${Dpn_id_1}    ${MININET}    ${Dpn_id_2}    ${MININET1}
    Log    ${get}
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    Log    >>>>Tunnel from DPN 1 to Dpn 3<<<<<
    ${tunnel-5}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_1}    ${Dpn_id_2}
    ...    ${type}
    log    ${tunnel-5}
    Set Global Variable    ${tunnel-5}
    Log    >>>>Tunnel from DPN 2 to Dpn 1<<<<<
    ${tunnel-6}    Wait Until Keyword Succeeds    40    10    Get Tunnel    ${Dpn_id_2}    ${Dpn_id_1}
    ...    ${type}
    log    ${tunnel-6}
    Set Global Variable    ${tunnel-6}
    ${tunnel-type}=    Set Variable    type: vxlan
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    >>>>OVS Validation in Switch 1 for Tunnel Created<<<<<
    ${check-1}    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${mininet1_conn_id_1}    ${MININET}
    ...    ${MININET1}    ${tunnel-5}    ${tunnel-type}
    Log    ${check-1}
    Log    >>>>OVS Validation in Switch 2 for Tunnel Created<<<<<
    ${check-2}    Wait Until Keyword Succeeds    40    10    Ovs Verification 2 Dpn    ${mininet2_conn_id_1}    ${MININET1}
    ...    ${MININET}    ${tunnel-6}    ${tunnel-type}
    Log    ${check-2}
    Log    >>>>> Checking Network Topology Oper <<<<<<
    ${url-2}=    Set Variable    ${REST_OPER}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-5}    ${tunnel-6}    ${url-2}
    Log    ${resp}
    Log    >>>>Validating Interface 1 states<<<<
    ${data-1:2}    Wait Until Keyword Succeeds    40    10    Validate interface state    ${tunnel-5}    ${Dpn_id_1}
    Log    ${data-1:2}
    @{array-1}    Split String    ${data-1:2}    ,
    ${port-num-1}    Get from List    ${array-1}    0
    ${lower-layer-if-1}    Get From List    ${array-1}    1
    Log    >>>>Validating Interface 2 states<<<<
    ${data-2:1}    Wait Until Keyword Succeeds    40    10    Validate interface state    ${tunnel-6}    ${Dpn_id_2}
    Log    ${data-1:2}
    @{array-2}    Split String    ${data-2:1}    ,
    ${port-num-2}    Get from List    ${array-2}    0
    ${lower-layer-if-2}    Get From List    ${array-2}    1
    Log    >>>>>Verify Oper data base of Interface state<<<<<
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-5}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-6}
    Log    >>>>> Checking Entry in table 0 on OVS 1<<<<<
    ${check-3}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet1_conn_id_1}    ${Bridge-1}
    ...    ${port-num-1}
    Log    ${check-3}
    Log    >>>>> Checking Entry in table 0 on OVS \ 2<<<<<
    ${check-4}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet2_conn_id_1}    ${Bridge-2}
    ...    ${port-num-2}
    Log    ${check-4}
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-2}    ${lower-layer-if-1}
    Log    ${resp.content}

Delete VTEP -Vlan and gateway
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${resp_1}    RequestsLibrary.Delete    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    10
    ${resp_2}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp_5.content}
    Should Be Equal As Strings    ${resp_5.status_code}    404
    ${resp_6}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp_6.content}
    Should Be Equal As Strings    ${resp_6.status_code}    404
    ${resp_7}    RequestsLibrary.Get    session    ${REST_CON}/ietf-interfaces:interfaces/interface/    headers=${ACCEPT_XML}
    log    ${resp_7.content}
    Should Be Equal As Strings    ${resp_7.status_code}    404
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet1_conn_id_1}    ${tunnel-5}
    Log    ${Ovs-del-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet2_conn_id_1}    ${tunnel-6}
    Log    ${Ovs-del-2}
    Log    >>>>>>> Getting Network Topology Config without Tunnels<<<<<<<
    ${url-2}=    Set variable    ${REST_OPER}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    5s    Get Network Topology without Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-5}    ${tunnel-6}    ${url-2}
    Log    ${resp}
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-5}
    Log    ${resp_8}
    ${resp_9}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-6}
    Log    ${resp_9}

*** Keywords ***
Get Dpn Ids
    [Arguments]    ${connection_id}
    Switch connection    ${connection_id}
    ${cmd}    set Variable    sudo ovs-vsctl show | grep Bridge | awk -F "\\"" '{print $2}'
    ${Bridgename1}    Execute command    ${cmd}
    log    ${Bridgename1}
    ${output1}    Execute command    sudo ovs-ofctl show -O Openflow13 ${Bridgename1} | head -1 | awk -F "dpid:" '{ print $2 }'
    log    ${output1}
    ${Dpn_id}    Execute command    echo \$\(\(16\#${output1}\)\)
    log    ${Dpn_id}
    [Return]    ${Dpn_id}

Get Tunnel
    [Arguments]    ${src}    ${dst}    ${type}
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/    headers=${ACCEPT_XML}
    Log    ${REST_CON}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${src}    ${dst}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel}    Get From List    ${resp_array}    4
    Log    ${Tunnel}
    [Return]    ${Tunnel}

Validate interface state
    [Arguments]    ${tunnel}    ${dpid}
    Log    ${tunnel},${dpid}
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/${tunnel}/    headers=${ACCEPT_XML}
    Log    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should not contain    ${resp.content}    down
    Should Contain    ${resp.content}    ${tunnel}    up    up
    ${result-1}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result-1}
    ${lower_layer_if}    Should Match Regexp    ${result-1}    openflow:${dpid}:[0-9]+
    log    ${lower_layer_if}
    @{resp_array}    Split String    ${lower_layer_if}    :
    ${port-num}    Get From List    ${resp_array}    2
    Log    ${port-num}
    [Return]    ${port-num},${lower_layer_if}

Check Table0 Entry for 2 Dpn
    [Arguments]    ${connection_id}    ${Bridgename}    ${port-num1}
    Switch Connection    ${connection_id}
    Log    ${connection_id}
    ${check}    Execute Command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridgename}
    Log    ${check}
    Should Contain    ${check}    in_port=${port-num1}
    [Return]    ${check}

Ovs Verification 2 Dpn
    [Arguments]    ${connection_id}    ${local}    ${remote-1}    ${tunnel}    ${tunnel-type}
    Switch Connection    ${connection_id}
    Log    ${connection_id}
    ${check}    Execute Command    sudo ovs-vsctl show
    Log    ${check}
    Should Contain    ${check}    local_ip="${local}"    remote_ip="${remote-1}"    ${tunnel}
    Should Contain    ${check}    ${tunnel-type}
    [Return]    ${check}

OVS-Del
    [Arguments]    ${connection-id}    ${tunnel}
    Log    ${tunnel}
    Switch Connection    ${connection-id}
    Log    ${connection-id}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    [Return]    ${return}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${MININET}    ${Dpn_id_2}
    ...    ${MININET1}
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${MININET}, ${Dpn_id_2}, ${MININET1}
    ${resp_1}    RequestsLibrary.Get    session    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}    headers=${ACCEPT_XML}
    Log    ${REST_CON}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Log    ${resp_1.content}
    Should Be Equal As Strings    ${resp_1.status_code}    200
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    BR1-eth1
    ...    ${MININET}    ${Dpn_id_2}    BR2-eth1    ${MININET1}
    : FOR    ${value}    IN    @{Itm-no-vlan}
    \    Should Contain    ${resp_1.content}    ${value}
    [Return]    ${resp_1.content}

Get Network Topology with Tunnel
    [Arguments]    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}    ${tunnel-2}    ${url}
    ${resp}    RequestsLibrary.Get    session    ${url}    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should be Equal as Strings    ${resp.status_code}    200
    Log    ${resp.content}
    ${result-1}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result-1}
    @{bridges}    Create List    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}    ${tunnel-2}
    : FOR    ${value}    IN    @{bridges}
    \    Should Contain    ${resp.content}    ${value}
    [Return]    ${result-1}

Get Network Topology without Tunnel
    [Arguments]    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}    ${tunnel-2}    ${url}
    ${resp}    RequestsLibrary.Get    session    ${url}    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should be Equal as Strings    ${resp.status_code}    200
    Log    ${resp.content}
    ${result-1}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result-1}
    @{tunnels}    Create List    ${tunnel-1}    ${tunnel-2}
    : FOR    ${value}    IN    @{tunnels}
    \    Should Not Contain    ${resp.content}    ${value}
    [Return]    ${result-1}

Validate interface state Delete
    [Arguments]    ${tunnel}
    Log    ${tunnel}
    ${resp}    RequestsLibrary.Get    session    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/${tunnel}/    headers=${ACCEPT_XML}
    Log    ${REST_OPER}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404
    Should not contain    ${resp.content}    ${tunnel}
    [Return]    ${resp.content}