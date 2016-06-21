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
@{itm_created}    TZA
${genius_config_dir}    ${CURDIR}/../../variables/genius
${Bridge-1}       BR1
${Bridge-2}       BR2

*** Test Cases ***
Create and Verify VTEP -No Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs without VLAN and Gateway configured in Json.
    Log    >>>>Creating VTEP with No Vlan<<<<
    ${Dpn_id_1}    Get Dpn Ids    ${mininet1_conn_id_1}
    ${Dpn_id_2}    Get Dpn Ids    ${mininet2_conn_id_1}
    Set Global Variable    ${Dpn_id_1}
    Set Global Variable    ${Dpn_id_2}
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    ${vlan}=    Set Variable    0
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${body}    set json    ${MININET}    ${MININET1}    ${vlan}    ${gateway-ip}    ${subnet}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    should be equal as strings    ${resp.status_code}    204
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
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
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
    ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${Dpn_id_1}    ${tunnel-1}
    Should Contain    ${resp.content}    ${Dpn_id_2}    ${tunnel-2}
    Log    >>>>> Checking Entry in table 0 on OVS 1<<<<<
    ${check-3}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet1_conn_id_1}    ${Bridge-1}
    ...    ${port-num-1}
    Log    ${check-3}
    Log    >>>>> Checking Entry in table 0 on OVS 2<<<<<
    ${check-4}    Wait Until Keyword Succeeds    40    10    Check Table0 Entry for 2 Dpn    ${mininet2_conn_id_1}    ${Bridge-2}
    ...    ${port-num-2}
    Log    ${check-4}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-1}    ${lower-layer-if-2}
    Log    ${resp.content}

Delete and Verify VTEP -No Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${resp_1}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    10
    ${resp_2}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    log    ${resp_4.content}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp_5.content}
    Should Be Equal As Strings    ${resp_5.status_code}    404
    ${resp_6}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp_6.content}
    Should Be Equal As Strings    ${resp_6.status_code}    404
    ${resp_7}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    log    ${resp_7.content}
    Run Keyword if    '${resp_7.content}'=='404'    Response is 404
    Run Keyword if    '${resp_7.content}'=='200'    Response is 200
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${CONFIG_TOPO_API}
    Log    ${resp_8}
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet1_conn_id_1}    ${tunnel-1}
    Log    ${Ovs-del-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet2_conn_id_1}    ${tunnel-2}
    Log    ${Ovs-del-2}
    Log    >>>>>>> Getting Network Topology Config without Tunnels<<<<<<<
    ${url-2}=    Set variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${url-2}
    Log    ${resp}
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-1}
    Log    ${resp_8}
    ${resp_9}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-2}
    Log    ${resp_9}

Create and Verify VTEP-Vlan
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and \ without Gateway configured in Json.
    Log    >>>>Creating VTEP with No Vlan<<<<
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    Log    ${subnet}
    ${vlan}=    Set Variable    100
    ${gateway-ip}=    Set Variable    0.0.0.0
    ${body}    set json    ${MININET}    ${MININET1}    ${vlan}    ${gateway-ip}    ${subnet}
    Log    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
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
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
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
    ${url_2}    set variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology with Tunnel    ${Bridge-1}    ${Bridge-2}
    ...    ${tunnel-3}    ${tunnel-4}    ${url_2}
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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-2}    ${lower-layer-if-1}

Delete and Verify VTEP -Vlan
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${resp_1}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    10
    ${resp_2}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    log    ${resp_4.content}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp_5.content}
    Should Be Equal As Strings    ${resp_5.status_code}    404
    ${resp_6}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp_6.content}
    Should Be Equal As Strings    ${resp_6.status_code}    404
    ${resp_7}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    log    ${resp_7.content}
    Run Keyword if    '${resp_7.content}'=='404'    Response is 404
    Run Keyword if    '${resp_7.content}'=='200'    Response is 200
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${CONFIG_TOPO_API}
    Log    ${resp_8}
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet1_conn_id_1}    ${tunnel-3}
    Log    ${Ovs-del-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet2_conn_id_1}    ${tunnel-4}
    Log    ${Ovs-del-2}
    Log    >>>>>>> Getting Network Topology Config without Tunnels<<<<<<<
    ${url-2}=    Set variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${url-2}
    Log    ${resp}
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-3}
    Log    ${resp_8}
    ${resp_9}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-4}
    Log    ${resp_9}

Create VTEP - Vlan and Gateway
    [Documentation]    This testcase creates a Internal Transport Manager - ITM tunnel between 2 DPNs with VLAN and Gateway configured in Json.
    Log    >>>> Updating Json with prefix,dpn ids,ips <<<<
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    ${substr}0
    ${gateway-ip}    Catenate    ${substr}1
    Log    ${subnet}
    ${vlan}=    Set Variable    101
    ${json-file}=    Set Variable    Itm_creation_no_vlan.json
    ${body}    set json    ${MININET}    ${MININET1}    ${vlan}    ${gateway-ip}    ${subnet}
    Log    ${body}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_API}/itm:transport-zones/    data=${body}
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
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
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
    ${url-2}=    Set Variable    ${OPERATIONAL_API}/network-topology:network-topology/
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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/
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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/opendaylight-inventory:nodes/    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${lower-layer-if-2}    ${lower-layer-if-1}
    Log    ${resp.content}

Delete VTEP -Vlan and gateway
    [Documentation]    This Delete testcase , deletes the ITM tunnel created between 2 dpns.
    ${type}    set variable    odl-interface:tunnel-type-vxlan
    ${resp_1}    RequestsLibrary.Delete Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/
    Should Be Equal As Strings    ${resp_1.status_code}    200
    sleep    10
    ${resp_2}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}/    headers=${ACCEPT_XML}
    Log    ${resp_2.content}
    Should Be Equal As Strings    ${resp_2.status_code}    404
    ${resp_3}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_1}/${Dpn_id_2}/${type}/    headers=${ACCEPT_XML}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_3.status_code}    404
    ${resp_4}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${Dpn_id_2}/${Dpn_id_1}/${type}/    headers=${ACCEPT_XML}
    log    ${resp_4.content}
    Should Be Equal As Strings    ${resp_4.status_code}    404
    ${resp_5}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_1}/    headers=${ACCEPT_XML}
    Log    ${resp_5.content}
    Should Be Equal As Strings    ${resp_5.status_code}    404
    ${resp_6}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${Dpn_id_2}/    headers=${ACCEPT_XML}
    Log    ${resp_6.content}
    Should Be Equal As Strings    ${resp_6.status_code}    404
    ${resp_7}    RequestsLibrary.Get Request    session    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    log    ${resp_7.content}
    Run Keyword if    '${resp_7.content}'=='404'    Response is 404
    Run Keyword if    '${resp_7.content}'=='200'    Response is 200
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${CONFIG_TOPO_API}
    Log    ${resp_8}
    ${Ovs-del-1}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet1_conn_id_1}    ${tunnel-5}
    Log    ${Ovs-del-1}
    ${Ovs-del-2}    Wait Until Keyword Succeeds    40    10    OVS-Del    ${mininet2_conn_id_1}    ${tunnel-6}
    Log    ${Ovs-del-2}
    Log    >>>>>>> Getting Network Topology Config without Tunnels<<<<<<<
    ${url-2}=    Set variable    ${OPERATIONAL_API}/network-topology:network-topology/
    ${resp}    Wait Until Keyword Succeeds    40    10    Get Network Topology without Tunnel    ${url-2}
    Log    ${resp}
    ${resp_8}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-5}
    Log    ${resp_8}
    ${resp_9}    Wait Until Keyword Succeeds    40    10    Validate interface state Delete    ${tunnel-6}
    Log    ${resp_9}

*** Keywords ***
Get Dpn Ids
    [Arguments]    ${connection_id}
    [Documentation]    This keyword gets the DPN id of the switch after configuring bridges on it.It returns the captured DPN id.
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
    [Documentation]    This Keyword Gets the Tunnel /Interface name which has been created between 2 DPNS by passing source , destination DPN Ids along with the type of tunnel which is configured.
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/${type}/    headers=${ACCEPT_XML}
    Log    ${CONFIG_API}/itm-state:tunnel-list/internal-tunnel/${src}/${dst}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${src}    ${dst}    TUNNEL:
    ${result}    re.sub    <.*?>    ,    ${resp.content}
    Log    ${result}
    @{resp_array}    Split String    ${result}    ,,
    ${Tunnel}    Get From List    ${resp_array}    4
    Log    ${Tunnel}
    [Return]    ${Tunnel}

Validate interface state
    [Arguments]    ${tunnel}    ${dpid}
    [Documentation]    Validates the created Interface/Tunnel by \ checking its Operational status as UP/DOWN from the dump.
    Log    ${tunnel},${dpid}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/    headers=${ACCEPT_XML}
    Log    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
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
    [Documentation]    Checks the Table 0 entry in the OVS when flows are dumped in it.
    Switch Connection    ${connection_id}
    Log    ${connection_id}
    ${check}    Execute Command    sudo ovs-ofctl -O OpenFlow13 dump-flows ${Bridgename}
    Log    ${check}
    Should Contain    ${check}    in_port=${port-num1}
    [Return]    ${check}

Ovs Verification 2 Dpn
    [Arguments]    ${connection_id}    ${local}    ${remote-1}    ${tunnel}    ${tunnel-type}
    [Documentation]    Checks whether the created Interface is seen on OVS or not.
    Switch Connection    ${connection_id}
    Log    ${connection_id}
    ${check}    Execute Command    sudo ovs-vsctl show
    Log    ${check}
    Should Contain    ${check}    local_ip="${local}"    remote_ip="${remote-1}"    ${tunnel}
    Should Contain    ${check}    ${tunnel-type}
    [Return]    ${check}

Get ITM
    [Arguments]    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    ${MININET}    ${Dpn_id_2}
    ...    ${MININET1}
    [Documentation]    It returns the created ITM Transport zone with the passed values during the creation is done.
    Log    ${itm_created[0]},${subnet}, ${vlan}, ${Dpn_id_1},${MININET}, ${Dpn_id_2}, ${MININET1}
    ${resp_1}    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${itm_created[0]}    headers=${ACCEPT_XML}
    Log    ${resp_1.content}
    Should Be Equal As Strings    ${resp_1.status_code}    200
    @{Itm-no-vlan}    Create List    ${itm_created[0]}    ${subnet}    ${vlan}    ${Dpn_id_1}    BR1-eth1
    ...    ${MININET}    ${Dpn_id_2}    BR2-eth1    ${MININET1}
    : FOR    ${value}    IN    @{Itm-no-vlan}
    \    Should Contain    ${resp_1.content}    ${value}
    [Return]    ${resp_1.content}

Get Network Topology with Tunnel
    [Arguments]    ${Bridge-1}    ${Bridge-2}    ${tunnel-1}    ${tunnel-2}    ${url}
    [Documentation]    Returns the Network topology with Tunnel info in it.
    ${resp}    RequestsLibrary.Get Request    session    ${url}    headers=${ACCEPT_XML}
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
    [Arguments]    ${url}
    [Documentation]    Returns the Network Topology after Deleting of ITM transport zone is done , which wont be having any TUNNEL info in it.
    ${resp}    RequestsLibrary.Get Request    session    ${url}    headers=${ACCEPT_XML}
    Log    ${resp.content}
    Should be Equal as Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    TUNNEL:
    [Return]    ${resp.content}

Validate interface state Delete
    [Arguments]    ${tunnel}
    [Documentation]    Check for the Tunnel / Interface absence in OPERATIONAL data base of IETF interface after ITM transport zone is deleted.
    Log    ${tunnel}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/    headers=${ACCEPT_XML}
    Log    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/interface/${tunnel}/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    404
    Should not contain    ${resp.content}    ${tunnel}
    [Return]    ${resp.content}

set json
    [Arguments]    ${MININET}    ${MININET1}    ${vlan}    ${gateway-ip}    ${subnet}
    [Documentation]    Sets Json with the values passed for it.
    ${body}    OperatingSystem.Get File    ${genius_config_dir}/Itm_creation_no_vlan.json
    ${body}    replace string    ${body}    1.1.1.1    ${subnet}
    ${body}    replace string    ${body}    "dpn-id":1    "dpn-id": ${Dpn_id_1}
    ${body}    replace string    ${body}    "dpn-id":2    "dpn-id": ${Dpn_id_2}
    ${body}    replace string    ${body}    "ip-address":"2.2.2.2"    "ip-address": "${MININET}"
    ${body}    replace string    ${body}    "ip-address":"3.3.3.3"    "ip-address": "${MININET1}"
    ${body}    replace string    ${body}    "vlan-id":0    "vlan-id": ${vlan}
    ${body}    replace string    ${body}    "gateway-ip":"0.0.0.0"    "gateway-ip": "${gateway-ip}"
    Log    ${body}
    [Return]    ${body}    # returns complete json that has been updated

OVS-Del
    [Arguments]    ${connection-id}    ${tunnel}
    Log    ${tunnel}
    Switch Connection    ${connection-id}
    Log    ${connection-id}
    ${return}    Execute Command    sudo ovs-vsctl show
    Log    ${return}
    Should Not Contain    ${return}    ${tunnel}
    [Return]    ${return}
