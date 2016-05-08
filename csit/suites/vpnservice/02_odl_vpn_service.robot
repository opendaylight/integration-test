*** Settings ***
Documentation     Test Suite for veirfication of ODL Neutron functions
Suite Setup       Pretest Setup
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           json
Variables         ../../variables/Variables.py
Variables         ../../variables/vpnservice/neutron_service.py
Variables         ../../variables/vpnservice/vpnservice_json.py
Resource          ../../libraries/Utils.robot
Library           re

*** Variables ***
${REST_OPR}       /restconf/operational/
${REST_CON}       /restconf/config
${VPN_CONFIG_DIR}    ${CURDIR}/../../variables/vpnservice
@{itm_created}    TZA
${REST_OPER}      /restconf/operational
${ODLREST}        /controller/nb/v2/neutron/
${vxlan_tunnel}    vxlan_tunnel.json
${ovs_restart}    sudo /etc/init.d/openvswitch-switch restart
${GET_RESP_CODE}    200
${REST_CON1}      /restconf/operations/
${REST_CON2}      /restconf/operations/neutronvpn:createL3VPN
${REST_CON}       /restconf/config

*** Test Cases ***
TC01 Create and Verify vxlan Tunnel
    Log    >>>>Creating VxLan Tunnel<<<<
    Create VxLan Tunnel
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_OPR}odl-interface-meta:bridge-ref-info/
    Log    ${resp.content}
    Log To Console    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/itm:transport-zones/
    Log    ${resp.content}
    Log To Console    ${resp.content}
    Log To Console    ${resp.status_code}

TC02 Verify neutron network creation
    [Documentation]    Verify neutron network creation
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    Log    "Creating Network"
    #${resp}    Post Json    session    ${ODLREST}networks/    data=${network_1}
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}networks    data=${network_1}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201
    #${resp}    Post Json    session    ${ODLREST}networks/    data=${network_2}
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}networks    data=${network_2}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201

TC03 Verify fetching available network
    [Documentation]    Verify fetching available  network
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get
    ${result}      ConvertToInteger    1
    Log    "Fetching Network Inmformation"

    ${resp}    RequestsLibrary.Get Request    session    ${ODLREST}networks/
    Log    ${resp.content}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}
  
TC04 Verify neutron subnet creation
    [Documentation]    Verify neutron subnet creation
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    ${result}      ConvertToInteger    1
    Log    "Creating the Subnet"
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}subnets/    data=${subnet_1}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}subnets/    data=${subnet_2}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201

TC05 Verify fetching available subnet
    [Documentation]    Verify fetching available subnet
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get
    Log    "Fetching Subnet Information"
    ${resp}    RequestsLibrary.Get Request    session    ${ODLREST}subnets/
    Log    ${resp.content}
    
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC06 Verify neutron port creation 
    [Documentation]    Verify neutron port creation
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    Log    "Verify neutron port creation"
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}ports/    data=${port_1}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}ports/    data=${port_2}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}ports/    data=${port_3}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${ODLREST}ports/    data=${port_4}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    201

TC07 Verify fetching available ports
    [Documentation]    Verify fetching available ports
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get 
    Log    "Verify fetching available ports"
    ${resp}    RequestsLibrary.Get Request    session    ${ODLREST}ports/
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC08 Verify vpn service creation 
    [Documentation]   Verify vpn service creation   
    [Tags]    Post
    Log To Console    "Creating L3vpn"
    ${l3vpndata}    json.dumps    ${l3vpn}
    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:createL3VPN/    data=${neutron_test_l3vpn}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    200

TC09 Verify/fetch vpn service from DB
    [Documentation]   Verify/fetch vpn service from DB   
    [Tags]    Get
    ${getl3vpndata}    json.dumps    ${get_delete_l3vpn}
    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:getL3VPN/    data=${getl3vpndata}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC10 Verify Associate network to vpn service and check from DB 
    [Documentation]   Verify Association of network to vpn service and check from DB   
    [Tags]    Associate
    Log To Console    "Associate network"
    ${netid1}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:associateNetworks    data=${ass_diss_conf_1}
    Log    ${netid1.content}
    Log    ${netid1.status_code}
    Should Be Equal As Strings    ${netid1.status_code}    ${GET_RESP_CODE}
    ${netid2}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:associateNetworks    data=${ass_diss_conf_2}
    Log    ${netid2.content}
    Log    ${netid2.status_code}
    Should Be Equal As Strings    ${netid2.status_code}    ${GET_RESP_CODE}

    Log To Console    "Check if vpn is updated after association of network"
    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:getL3VPN/    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Log To Console    ${resp}

    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/l3vpn:vpn-instances/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/odl-l3vpn:vpn-instance-to-vpn-id/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_OPER}/ietf-interfaces:interfaces-state/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/l3vpn:vpn-interfaces/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_OPER}/l3vpn:vpn-interfaces/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_OPER}/l3nexthop:l3nexthop/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/odl-fib:fibEntries/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_OPER}/odl-l3vpn:vpn-instance-op-data/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_OPER}/odl-l3vpn:prefix-to-interface/    headers=${ACCEPT_XML}
    Log    ${resp.content}

TC11 Verify Dissociate Network from VPN instance
    [Documentation]   Dissociate Network from VPN instance 
    [Tags]    Dissociate
    ${netid1}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:dissociateNetworks    data=${ass_diss}
    Log    ${netid1.content}
    Log    ${netid1.status_code}
    Should Be Equal As Strings    ${netid1.status_code}    ${GET_RESP_CODE}

    Log To Console    "Check if vpn is updated after dissociation of network"
    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:getL3VPN/    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Log    ${resp}

TC12 Verify Deletion of vpn instance
    [Documentation]   Delete VPN instance 
    [Tags]    Delete
    Log    "Deleting vpn instance"  
    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:deleteL3VPN    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON1}/neutronvpn:getL3VPN/    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Log    ${resp.status_code}
    #Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC13 Verify neutron Port Deletion
    [Documentation]    Verify neutron Port Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Verify neutron port deletion"
    Log To Console    ${test_neutron_port1} 
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}ports/${test_neutron_port1}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log To Console    ${test_neutron_port2} 
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}ports/${test_neutron_port2}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log To Console    ${test_neutron_port3} 
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}ports/${test_neutron_port3}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}ports/${test_neutron_port4}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204

TC14 Verify neutron Subnet Deletion
    [Documentation]    Verify neutron Subnet Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Creating the Subnet"
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}subnets/${test_neutron_subnet1}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}subnets/${test_neutron_subnet2}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204

TC15 Verify neutron network Deletion
    [Documentation]    Verify neutron network Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Netowrk"
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}networks/${test_neutron_network1}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Delete Request    session    ${ODLREST}networks/${test_neutron_network2}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204

TC16 Delete and Verify Vxlan Tunnel
    Delete All VxLan Tunnels


*** Keywords ***
Pretest Setup
    [Documentation]    Test Case Pre Setup
    Log To Console    "Running Test case level Pretest Setup"
    ${resp}    Log    ***********************************Pretest Setup ********************************
    ${resp}    Create Session    session    http://${CONTROLLER}:${PORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}    Create Session    odlsession    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Create VxLan Tunnel
    Set Json fields    ${vxlan_tunnel}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${vxlan_tunnel}
    ${resp}    RequestsLibrary.Post Request    odlsession    ${REST_CON}/itm:transport-zones/    data=${body}
    ${res}    Sleep    3
    Log    ${resp.content}
    Log To Console    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/itm:transport-zones/
    Log    ${resp.content}
    Log To Console    ${resp.content}
    Reset Json fields    ${vxlan_tunnel}
    Should Be Equal As Strings    ${resp.status_code}    200

Reset Json fields
    [Arguments]    ${json-file}
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    SEPARATOR=    ${substr}0    \\    /24
    Log To Console    ${subnet}
    ${reset-dpn1-ip}    run    sed -i 's/"ip-address": "${MININET}"/"ip-address": "2.2.2.2"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${reset-dpn2-ip}    run    sed -i 's/"ip-address": "${MININET1}"/"ip-address": "3.3.3.3"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${prefix-reset}    run    sed -i 's/${subnet}/1.1.1.1/g' \ ${VPN_CONFIG_DIR}/${json-file}

Set Json fields
    [Arguments]    ${json-file}
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    SEPARATOR=    ${substr}0    \\    /24
    Log To Console    ${subnet}
    ${prefix-add}    Run    sed -i 's/"prefix": "1.1.1.1"/"prefix": "${subnet}"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${dpn1-ip-add}    Run    sed -i 's/"ip-address": "2.2.2.2"/"ip-address": "${MININET}"/g' ${VPN_CONFIG_DIR}/${json-file}
    ${dpn2-ip-add}    Run    sed -i 's/"ip-address": "3.3.3.3"/"ip-address": "${MININET1}"/g' ${VPN_CONFIG_DIR}/${json-file}

Delete All VxLan Tunnels
    ${resp}    RequestsLibrary.Delete Request    odlsession    ${REST_CON}/itm:transport-zones/
    Log    ${resp.content}
    Log To Console    ${resp.content}
    Log To Console    ${resp.status_code}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${REST_CON}/itm:transport-zones/
    Log    ${resp.content}
    Log To Console    ${resp.content}
    Log To Console    ${resp.status_code}
