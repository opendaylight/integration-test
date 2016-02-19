*** Settings ***
Documentation     Test Suite for veirfication of ODL Neutron functions

Library           OperatingSystem
Library           Collections
Library           SSHLibrary
Variables         ../../variables/Variables.py
Variables         ../../variables/vpnservice/neutron_service.py
#Library           ../../libraries/Openstack.py    ${CONTROLLER}    WITH NAME    ops
Library           ../../libraries/VpnUtils.py    ${CONTROLLER}    WITH NAME    vpn


*** Variables ***
${BRIDGE1}    BR1
${BRIDGE2}    BR2

${GET_RESP_CODE}    200
${REST_CON1}      /restconf/operations/
${REST_CON2}      /restconf/operations/neutronvpn:createL3VPN
${CONF}           /restconf/config/ebgp:bgp/
${REST_CON3}      /restconf/config/neutron:neutron/routers/
@{vpn_values}     100:1
${REST_CON5}      /restconf/config/l3vpn:vpn-instances/
${LOG_FILE}      log.txt


*** Test Cases ***
TC01 Verify TUNNEL creation
    [Documentation]   Verify Tunnel creation 
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    Log    "Get the dpn ids"
    ${resp}    vpn.Create Tunnel   srcip=${MININET}    dstip=${MININET1}    srcbr=${BRIDGE1}    dstbr=${BRIDGE2}
    Log To Console    ${resp}
    Should Be Equal    ${resp}    ${exp_result}

TC02 Verify neutron network creation
    [Documentation]    Verify neutron network creation
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    Log    "Creating Network"
    ${res}    vpn.Create Network    ${NEUTRON_NETWORK1}
    Should Be Equal    ${res}    ${exp_result}
    ${res}    vpn.Create Network    ${NEUTRON_NETWORK2}
    Should Be Equal    ${res}    ${exp_result}
	
TC03 Verify fetching available network
    [Documentation]    Verify fetching available  network
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get
    ${result}      ConvertToInteger    1
    Log    "Fetching Network Inmformation"
    ${resp}    vpn.Get Networks
    Log To Console    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}
   
TC04 Verify neutron subnet creation
    [Documentation]    Verify neutron subnet creation
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    ${result}      ConvertToInteger    1
    Log    "Creating the Subnet"
    ${res}    vpn.Create Subnet    ${NEUTRON_NETWORK1}    ${NEUTRON_SUBNET1}    ${NEUTRON_IPSUBNET1}
    ${res}    vpn.Create Subnet    ${NEUTRON_NETWORK2}    ${NEUTRON_SUBNET2}    ${NEUTRON_IPSUBNET2}
    Log To Console    ${res}
    Should Be Equal    ${res}    ${exp_result}

TC05 Verify fetching available subnet
    [Documentation]    Verify fetching available subnet
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get
    Log    "Fetching Subnet Information"
    ${resp}    vpn.Get Subnets
    Log To Console    ${resp}
    Log To Console    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC06 Verify neutron port creation 
    [Documentation]    Verify neutron port creation
    ${exp_result}    ConvertToInteger    0
    [Tags]    Post 
    Log    "Verify neutron port creation"
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK1}    ${NEUTRON_PORT1}    mac=${NEUTRON_PORT1_MAC}
    Log To Console    ${res}
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK1}    ${NEUTRON_PORT2}    mac=${NEUTRON_PORT2_MAC}
    Log To Console    ${res}
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK2}    ${NEUTRON_PORT3}    mac=${NEUTRON_PORT3_MAC}
    Log To Console    ${res}
    ${res}    vpn.Create Port    ${NEUTRON_NETWORK2}    ${NEUTRON_PORT4}    mac=${NEUTRON_PORT4_MAC}
    Log To Console    ${res}
    Should Be Equal    ${res}    ${exp_result}

TC07 Verify fetching available ports
    [Documentation]    Verify fetching available ports
    ${exp_result}    ConvertToInteger    0
    [Tags]    Get 
    Log    "Verify fetching available ports"
    ${resp}    vpn.Get Ports
    Log To Console    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    ${GET_RESP_CODE}

TC08 Verify vpn service creation 
    [Documentation]   Verify vpn service creation   
    [Tags]    Post
    Log To Console    "Creating L3vpn"
    ${result}    vpn.Create L3vpn    ${L3VPN}    ${RD}    ${IMPORT_RT}    ${EXPORT_RT}
    Log    ${result}

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
    Log To Console    "Associate network"
    ${netid2}    vpn.Associate Network    ${NEUTRON_NETWORK1}   ${L3VPN}
    ${netid3}    vpn.Associate Network    ${NEUTRON_NETWORK2}   ${L3VPN}
    Log To Console    ${netid2}
    Log To Console    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log To Console    ${resp}

    Log To Console    "check if uuid of associated network is found in DB"
    Should Contain    ${resp}    ${netid2}
    Should Contain    ${resp}    ${netid3}
    Log To Console    "Associated network found in DB"


TC11 Verify end to end data path within same network and from one network to the other
    [Documentation]   Verify end to end data path within same network and from one network to the other
    [Tags]    Datapath
    ${resp}    Sleep    ${DELAY_BEFORE_PING}
    :FOR    ${index}    IN RANGE    7
    \    ${output}    vpn.Remotevmexec    ${MININET}    ${PING_NS2}
    \    Log To Console    ${output}
    \    Log    ${output}
    \    ${output}    vpn.Remotevmexec    ${MININET}    ${PING_NS3}
    \    Log To Console    ${output}
    \    Log    ${output}
    \    ${output}    vpn.Remotevmexec    ${MININET}    ${PING_NS4}
    \    Log To Console    ${output}
    \    Log    ${output}
    ${output}    vpn.Remotevmexec    ${MININET}    ${PING_NS2}
    Log To Console    ${output}
    Log    ${output}
    Should Match Regexp    ${output}    ${PING_REGEX}
    ${output}    vpn.Remotevmexec    ${MININET}    ${PING_NS3}
    Log To Console    ${output}
    Log    ${output}
    Should Match Regexp    ${output}    ${PING_REGEX}
    ${output}    vpn.Remotevmexec    ${MININET}    ${PING_NS4}
    Log To Console    ${output}
    Log    ${output}
    Should Match Regexp    ${output}    ${PING_REGEX}


TC12 Verify Dissociate Network from VPN instance
    [Documentation]   Dissociate Network from VPN instance 
    [Tags]    Dissociate
    ${netid2}    vpn.Dissociate Network    ${NEUTRON_NETWORK1}   ${L3VPN}
    Log To Console    ${netid2}
    ${netid3}    vpn.Dissociate Network    ${NEUTRON_NETWORK2}   ${L3VPN}
    Log To Console    ${netid3}
    Log To Console    "Check if vpn is updated after association of network"
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Log To Console    ${resp}
    Log To Console    "check if uuid of dissociated network is not found in DB"
    Should Not Contain    ${resp}    ${netid3}
    Log To Console    "dissociated network not found in DB"

TC13 Verify Deletion of vpn instance
    [Documentation]   Delete VPN instance 
    [Tags]    Delete
    ${resp}    vpn.GetL3vpn    ${L3VPN}
    Should Contain    ${resp}    ${L3VPN}
    Log    "Deleting vpn instance"  
    ${resp}    vpn.DeleteL3vpn    ${L3VPN}
    Log    "vpn instance deleted"  

TC14 Verify neutron Port Deletion
    [Documentation]    Verify neutron Port Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Netowrk"
    ${res}    vpn.Delete Port    ${NEUTRON_PORT1}
    ${res}    vpn.Delete Port    ${NEUTRON_PORT2}
    ${res}    vpn.Delete Port    ${NEUTRON_PORT3}
    ${res}    vpn.Delete Port    ${NEUTRON_PORT4}
    Log To Console    ${res}
    Should Be Equal    ${res}    ${exp_result}
    Log    "Get available ports"
    ${resp}    vpn.Get Ports
    Log To Console    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC15 Verify neutron Subnet Deletion
    [Documentation]    Verify neutron Subnet Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Subnet Netowrk"
    ${res}    vpn.Delete Subnet    ${NEUTRON_SUBNET1}
    ${res}    vpn.Delete Subnet    ${NEUTRON_SUBNET2}
    Log To Console    ${res}
    Should Be Equal    ${res}    ${exp_result}
    Log    "Get available Subnets"
    ${resp}    vpn.Get Subnets
    Log To Console    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC16 Verify neutron network Deletion
    [Documentation]    Verify neutron network Deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Delete Netowrk"
    ${res}    vpn.Delete Net    ${NEUTRON_NETWORK1}
    ${res}    vpn.Delete Net    ${NEUTRON_NETWORK2}
    Log To Console    ${res}
    Should Be Equal    ${res}    ${exp_result}
    Log    "Get available Networks"
    ${resp}    vpn.Get Networks
    Log To Console    ${resp}
    Log    ${resp.content}
    Log    ${resp.status_code}

TC17 Verify fetching TUNNELS
    [Documentation]   Verify fetching Tunnels 
    ${exp_result}    ConvertToInteger   200 
    [Tags]    Get
    Log    "Fetching the tunnels"
    ${resp}    vpn.Get All Tunnels
    Log To Console    ${resp}
    Should Be Equal    ${resp.status_code}    ${exp_result}

TC18 Verify TUNNEL deletion
    [Documentation]   Verify Tunnel deletion
    ${exp_result}    ConvertToInteger    0
    [Tags]    Delete
    Log    "Deleting the tunnel"
    ${resp}    vpn.Delete All Tunnels
    Log To Console    ${resp}
    Should Be Equal    ${resp}    ${exp_result}


*** Keywords ***
Open Connection And Log In Server And Run Script
    [Arguments]    ${HOST}    ${USERNAME}    ${PASSWORD}    ${scriptname}
    ${connection_handle}=    SSHLibrary.Open Connection    ${HOST}
    Set Client Configuration    prompt=>
    SSHLibrary.Login    ${USERNAME}    ${PASSWORD}
    ${scriptcmd}=    Catenate    SEPARATOR=    /home/mininet/integration/test/csit/scripts/    ${scriptname}
    SSHLibrary.Write    ${scriptcmd}
    Set Client Configuration    prompt=>
    Log To Console    ${scriptcmd}
    ${output}=    SSHLibrary.Read Until Prompt
    Close Connection
    [Return]    ${output}


