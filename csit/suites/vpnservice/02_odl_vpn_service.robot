*** Settings ***
Documentation     Test Suite for veirfication of ODL Neutron functions
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../libraries/Utils.robot
Variables         ../../variables/Variables.py
Variables         ../../variables/vpnservice/neutron_service.py
#Library           ../../libraries/Openstack.py    ${CONTROLLER}    WITH NAME    ops
Library           ../../libraries/VpnUtils.py    ${CONTROLLER}    WITH NAME    vpn


*** Variables ***
${BRIDGE1}    BR1
${BRIDGE2}    BR2
${GET_RESP_CODE}    200
@{vpn_values}     100:1
${REST_CON}       /restconf/config
${REST_OPER}      /restconf/operational



*** Test Cases ***
TC01 Verify TUNNEL creation
    [Documentation]   Verify Tunnel creation 
    [Tags]    Post 
    ${exp_result}    ConvertToInteger    0
    Log    "Get the dpn ids"
    ${resp}    vpn.Create Tunnel   srcip=${MININET}    dstip=${MININET1}    srcbr=${BRIDGE1}    dstbr=${BRIDGE2}
    Log    ${resp}
    Should Be Equal    ${resp}    ${exp_result}

TC02 Verify neutron network creation
    [Documentation]    Verify neutron network creation
    [Tags]    Post 
    ${exp_result}    ConvertToInteger    0
    Log    "Creating Network"
    ${res}    vpn.Create Network    ${NEUTRON_NETWORK1}
    Should Be Equal    ${res}    ${exp_result}
    ${res}    vpn.Create Network    ${NEUTRON_NETWORK2}
    Should Be Equal    ${res}    ${exp_result}
	
TC03 Verify fetching available network
    [Documentation]    Verify fetching available  network
    [Tags]    Get
    Log    "Fetching Network Inmformation"
    ${resp}    vpn.Get Networks
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}
   
TC04 Verify neutron subnet creation
    [Documentation]    Verify neutron subnet creation
    [Tags]    Post 
    ${exp_result}    ConvertToInteger    0
    ${result}      ConvertToInteger    1
    Log    "Creating the Subnet"
    ${res}    vpn.Create Subnet    ${NEUTRON_NETWORK1}    ${NEUTRON_SUBNET1}    ${NEUTRON_IPSUBNET1}
    ${res}    vpn.Create Subnet    ${NEUTRON_NETWORK2}    ${NEUTRON_SUBNET2}    ${NEUTRON_IPSUBNET2}
    Log    ${res}
    Should Be Equal    ${res}    ${exp_result}

TC05 Verify fetching available subnet
    [Documentation]    Verify fetching available subnet
    [Tags]    Get
    ${exp_result}    ConvertToInteger    0
    Log    "Fetching Subnet Information"
    ${resp}    vpn.Get Subnets
    Log    ${resp}
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC06 Verify neutron port creation 
    [Documentation]    Verify neutron port creation
    [Tags]    Post 
    ${exp_result}    ConvertToInteger    0
    Log    "Verify neutron port creation"
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK1}    ${NEUTRON_PORT1}    mac=${NEUTRON_PORT1_MAC}
    Log    ${res}
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK1}    ${NEUTRON_PORT2}    mac=${NEUTRON_PORT2_MAC}
    Log    ${res}
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK2}    ${NEUTRON_PORT3}    mac=${NEUTRON_PORT3_MAC}
    Log    ${res}
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK2}    ${NEUTRON_PORT4}    mac=${NEUTRON_PORT4_MAC}
    Log    ${res}
    Should Be Equal    ${res}    ${exp_result}

TC07 Verify fetching available ports
    [Documentation]    Verify fetching available ports
    [Tags]    Get 
    ${exp_result}    ConvertToInteger    0
    Log    "Verify fetching available ports"
    ${resp}    vpn.Get Ports
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC08 Verify vpn service creation 
    [Documentation]   Verify vpn service creation   
    [Tags]    Post
    ${exp_result}    ConvertToInteger    0
    Log    "Creating L3vpn"
    ${res}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Log    ${res}
    Should Not Be Equal    ${res}    ${exp_result}


TC09 Verify/fetch vpn service from DB
    [Documentation]   Verify/fetch vpn service from DB
    [Tags]    Get
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log To Console    "L3vpn created is found  in DB"
    : FOR    ${value}    IN    @{vpn_values}
    \    Should Contain    ${resp}    ${value}
    Log To Console    "L3vpn details are found in DB"


TC10 Verify Associate network to vpn service and check from DB 
    [Documentation]   Verify Association of network to vpn service and check from DB   
    [Tags]    Associate
    Log    "Associate network"
    ${netid2}    vpn.Associate Network    ${NEUTRON_NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NEUTRON_NETWORK2}   ${L3VPN}
    Log    ${netid2}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}

    Log    "check if uuid of associated network is found in DB"
    Should Contain    ${resp}    ${netid2}
    Log    "Associated network found in DB"
    Should Contain    ${resp}    ${netid3}



TC12 Verify Dissociate Network from VPN instance
    [Documentation]   Dissociate Network from VPN instance 
    [Tags]    Dissociate
    ${netid2}    vpn.Dissociate Network    ${NEUTRON_NETWORK1}   ${L3VPN}
    Log    ${netid2}
    ${netid3}    vpn.Dissociate Network    ${NEUTRON_NETWORK2}   ${L3VPN}
    Log    ${netid3}
    Log    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log    ${resp}
    Log    "check if uuid of dissociated network is not found in DB"
    Should Not Contain    ${resp}    ${netid2}
    Should Not Contain    ${resp}    ${netid3}
    Log    "dissociated network not found in DB"

TC13 Verify Deletion of vpn instance
    [Documentation]   Delete VPN instance 
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "Deleting vpn instance"  
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    "vpn instance deleted"  
    Log    ${resp}
    Should Be Equal    ${resp}    ${exp_result}

TC14 Verify neutron Port Deletion
    [Documentation]    Verify neutron Port Deletion
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Delete Netowrk"
    ${res1}    vpn.Delete Port    ${NEUTRON_PORT1}
    ${res2}    vpn.Delete Port    ${NEUTRON_PORT2}
    ${res3}    vpn.Delete Port    ${NEUTRON_PORT3}
    ${res4}    vpn.Delete Port    ${NEUTRON_PORT4}
    Log    ${res1}
    Log    ${res2}
    Log    ${res3}
    Log    ${res4}
    Should Be Equal    ${res1}    ${exp_result}
    Should Be Equal    ${res2}    ${exp_result}
    Should Be Equal    ${res3}    ${exp_result}
    Should Be Equal    ${res4}    ${exp_result}
    Log    "Get available ports"
    ${resp}    vpn.Get Ports
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC15 Verify neutron Subnet Deletion
    [Documentation]    Verify neutron Subnet Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Subnet Netowrk"
    ${res1}    vpn.Delete Subnet    ${NEUTRON_SUBNET1}
    ${res2}    vpn.Delete Subnet    ${NEUTRON_SUBNET2}
    Log    ${res1}
    Log    ${res2}
    Should Be Equal    ${res1}    ${exp_result}
    Should Be Equal    ${res2}    ${exp_result}
    Log    "Get available Subnets"
    ${resp}    vpn.Get Subnets
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC16 Verify neutron network Deletion
    [Documentation]    Verify neutron network Deletion
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Delete Netowrk"
    ${res}    vpn.Delete Net    ${NEUTRON_NETWORK1}
    ${res}    vpn.Delete Net    ${NEUTRON_NETWORK2}
    Log    ${res}
    Should Be Equal    ${res}    ${exp_result}
    Log    "Get available Networks"
    ${resp}    vpn.Get Networks
    Log    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC17 Verify fetching TUNNELS
    [Documentation]   Verify fetching Tunnels 
    [Tags]    Get
    ${exp_result}    ConvertToInteger   200 
    Log    "Fetching the tunnels"
    ${resp}    vpn.Get All Tunnels
    Log    ${resp}
    Should Be Equal    ${resp.status_code}    ${exp_result}

TC18 Verify TUNNEL deletion
    [Documentation]   Verify Tunnel deletion
    [Tags]    Delete
    ${exp_result}    ConvertToInteger    0
    Log    "Deleting the tunnel"
    ${resp}    vpn.Delete All Tunnels
    Log    ${resp}
    Should Be Equal    ${resp}    ${exp_result}
