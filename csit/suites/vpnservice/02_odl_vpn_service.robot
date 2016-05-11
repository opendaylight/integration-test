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
${VPN_CONFIG_DIR}    ${CURDIR}/../../variables/vpnservice
@{itm_created}    TZA
${vxlan_tunnel}    vxlan_tunnel.json
${ovs_restart}    sudo /etc/init.d/openvswitch-switch restart
${RESTCONF_OPERATIONS_URI}      /restconf/operations/

*** Test Cases ***
TC01 Create and Verify vxlan Tunnel
    [Documentation]    Create Vxlan Tunnel
    [Tags]    Post
    Log    Creating VxLan Tunnel
    Create VxLan Tunnel
    ${resp}    RequestsLibrary.Get Request    odlsession    ${OPERATIONAL_API}/odl-interface-meta:bridge-ref-info/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/itm:transport-zones/
    Log    ${resp.content}

TC02 Verify neutron network creation
    [Documentation]    Verify neutron network creation
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    Log    "Creating Network"
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}networks    data=${network_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}networks    data=${network_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

TC03 Verify fetching available network
    [Documentation]    Verify fetching available  network
    [Tags]    Get
    ${exp_result}    ConvertToInteger    0
    ${result}      ConvertToInteger    1
    Log    "Fetching Network Inmformation"
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NB_API}networks/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

TC04 Verify neutron subnet creation
    [Documentation]    Verify neutron subnet creation
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    ${result}      ConvertToInteger    1
    Log    "Creating the Subnet"
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}subnets/    data=${subnet_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}subnets/    data=${subnet_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

TC05 Verify fetching available subnet
    [Documentation]    Verify fetching available subnet
    [Tags]    Get
    ${exp_result}    ConvertToInteger    0
    Log    "Fetching Subnet Information"
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NB_API}subnets/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

TC06 Verify neutron port creation
    [Documentation]    Verify neutron port creation
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    Log    "Verify neutron port creation"
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}ports/    data=${port_1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}ports/    data=${port_2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}ports/    data=${port_3}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}ports/    data=${port_4}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

TC07 Verify fetching available ports
    [Documentation]    Verify fetching available ports
    [Tags]    Get
    ${exp_result}    ConvertToInteger    0
    Log    "Verify fetching available ports"
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NB_API}ports/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

TC08 Verify vpn service creation
    [Documentation]   Verify vpn service creation
    [Tags]    Post
    Log    "Creating L3vpn"
    ${l3vpndata}    json.dumps    ${l3vpn}
    ${resp}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:createL3VPN/    data=${neutron_test_l3vpn}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

TC09 Verify/fetch vpn service from DB
    [Documentation]   Verify/fetch vpn service from DB
    [Tags]    Get
    ${getl3vpndata}    json.dumps    ${get_delete_l3vpn}
    ${resp}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:getL3VPN/    data=${getl3vpndata}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

TC10 Verify Associate network to vpn service and check from DB
    [Documentation]   Verify Association of network to vpn service and check from DB
    [Tags]    Associate
    Log    "Associate network"
    ${netid1}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:associateNetworks    data=${ass_diss_conf_1}
    Log    ${netid1.content}
    Should Be Equal As Strings    ${netid1.status_code}    200
    ${netid2}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:associateNetworks    data=${ass_diss_conf_2}
    Log    ${netid2.content}
    Should Be Equal As Strings    ${netid2.status_code}    200

    Log    "Getting the associated L3VPN details"
    ${resp}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:getL3VPN/    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Log    ${resp}

    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/l3vpn:vpn-instances/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/odl-l3vpn:vpn-instance-to-vpn-id/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/ietf-interfaces:interfaces/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${OPERATIONAL_API}/ietf-interfaces:interfaces-state/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/l3vpn:vpn-interfaces/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${OPERATIONAL_API}/l3vpn:vpn-interfaces/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${OPERATIONAL_API}/l3nexthop:l3nexthop/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/odl-fib:fibEntries/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${OPERATIONAL_API}/odl-l3vpn:vpn-instance-op-data/    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${OPERATIONAL_API}/odl-l3vpn:prefix-to-interface/    headers=${ACCEPT_XML}
    Log    ${resp.content}

TC11 Verify Dissociate Network from VPN instance
    [Documentation]   Dissociate Network from VPN instance
    [Tags]    Dissociate
    ${netid1}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:dissociateNetworks    data=${ass_diss}
    Log    ${netid1.content}
    Should Be Equal As Strings    ${netid1.status_code}    200
    Log    "Check if vpn is updated after dissociation of network"
    ${resp}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:getL3VPN/    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Log    ${resp}

TC12 Verify Deletion of vpn instance
    [Documentation]   Delete VPN instance
    [Tags]    Delete
    Log    "Deleting vpn instance"
    ${resp}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:deleteL3VPN    data=${get_delete_l3vpn}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

    ${resp}    RequestsLibrary.Post Request    odlsession    ${RESTCONF_OPERATIONS_URI}/neutronvpn:getL3VPN/    data=${get_delete_l3vpn}
    Log    ${resp.content}

TC13 Verify neutron Port Deletion
    [Documentation]    Verify neutron Port Deletion
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Verify neutron port deletion"
    Log    ${test_neutron_port1}
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}ports/${test_neutron_port1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log    ${test_neutron_port2}
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}ports/${test_neutron_port2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    Log    ${test_neutron_port3}
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}ports/${test_neutron_port3}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}ports/${test_neutron_port4}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

TC14 Verify neutron Subnet Deletion
    [Documentation]    Verify neutron Subnet Deletion
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Creating the Subnet"
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}subnets/${test_neutron_subnet1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}subnets/${test_neutron_subnet2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

TC15 Verify neutron network Deletion
    [Documentation]    Verify neutron network Deletion
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Delete Netowrk"
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}networks/${test_neutron_network1}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Delete Request    session    ${NEUTRON_NB_API}networks/${test_neutron_network2}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

TC16 Delete and Verify Vxlan Tunnel
    [Documentation]    Verify Vxlan Tunnel Deletion
    [Tags]    Delete
    Delete All VxLan Tunnels

*** Keywords ***
Pretest Setup
    [Documentation]    Test Case Pre Setup
    Log    "Running Test case level Pretest Setup"
    ${resp}    Log    ***********************************Pretest Setup ********************************
    ${resp}    Create Session    session    http://${CONTROLLER}:${PORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}    Create Session    odlsession    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Create VxLan Tunnel
    ${body}    Set Json fields    ${vxlan_tunnel}
    Log    ${body}
    ${resp}    RequestsLibrary.Post Request    odlsession    ${CONFIG_API}/itm:transport-zones/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/itm:transport-zones/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Set Json fields
    [Arguments]    ${json-file}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/${json-file}
    Log    ${body}
    ${substr}    Should Match Regexp    ${MININET}    [0-9]\{1,3}\.[0-9]\{1,3}\.[0-9]\{1,3}\.
    ${subnet}    Catenate    SEPARATOR=    ${substr}0    \\    /24
    Log    ${subnet}
    ${body}    replace string    ${body}     "ip-address": "2.2.2.2"    "ip-address": "${MININET}"
    ${body}    replace string    ${body}     "ip-address": "3.3.3.3"     "ip-address": "${MININET1}"
    ${body}    replace string    ${body}      1.1.1.1    ${subnet}
    Log    ${body}
    [Return]    ${body}

Delete All VxLan Tunnels
    ${resp}    RequestsLibrary.Delete Request    odlsession    ${CONFIG_API}/itm:transport-zones/
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    odlsession    ${CONFIG_API}/itm:transport-zones/
    Log    ${resp.content}
