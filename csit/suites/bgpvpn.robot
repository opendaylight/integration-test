
#Script header:
#       $Id: Neutron based BGP VPN Orchestration
#Name:
#       Neutron based BGP VPN Orchestration 
#Purpose :
#       Verify Neutron based BGP VPN Orchestration
#Author:
#       Ravi Ranjan ---(ravi.ranjan3@tcs.com)
#Maintainer:
#       Ravi Ranjan --(ravi.ranjan3@tcs.com)
#
#References:
#	http://docs.openstack.org/developer/networking-bgpvpn
#
#Description:
#	Tests OF BGPVPN create/update/delete/Associte network/router via Openstack CLI
#
#Known Bugs:
#
#Script status:
#       progress
#
# End of Header
#=============================================================================================================

*** Settings ***
Documentation      Test Suite for Basic BGPVPN

Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup Tests
Suite Teardown    Basic BgpVpn Suite Teardown
Resource          ../libraries/OpenStackOperations.robot
Resource          ../libraries/DevstackUtils.robot
Resource          ../libraries/SetupUtils.robot
Resource          ../variables/Variables.robot
*** Variables ***
${BgpVpnUrl}      /restconf/config/neutron:neutron/bgpvpns/
${VpnName}        Vpn1
@{NETWORKS}       NetWork1    NetWork2
@{SUBNETS}        SubNet1    SubNet2
@{SUBNET_CIDR}    10.10.10.0/24    20.20.20.0/24
${RtrName}        ROUTER1
*** Testcases ***

Verify Bgpvpn creation via Neutron Api
    [Documentation]    Create a BGPVPN with only RD value
    Log    Create a Bgpvpn via Neutron Api
    ${Additional_Args}    Set Variable    --route-distinguishers 100:1
    OpenStackOperations.Create BgpVpn    ${VpnName}    ${Additional_Args}
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl} 
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${VpnName}    


Verify bgpvpn config update via Neutron Api
    [Documentation]    Verify config update of previously created bgpvpn with import and export values
    Log    Update config with import and export value
    ${Additional_Args}    Set Variable    --export-targets 200:10 --import-targets 200:10
    OpenStackOperations.Update BgpVpn    ${VpnName}    ${Additional_Args}
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl}
    Log    ${resp.content}
    Should Contain    ${resp.content}    200:10

Verify the association of networks to VPN
    [Documentation]    Create a Network with subnet and Verify association to previously created bgpvpn
    Log    Create a network with subnet
    OpenStackOperations.Create Network    ${NETWORKS[0]}
    OpenStackOperations.Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Log    Associate the network to VPN
    OpenStackOperations.Bgpvpn Network Associate    ${VpnName}    ${NETWORKS[0]}
    ${devstack_conn_id} =    Get ControlNode Connection
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${net_id}
 

Verify Dis-association of network from the VPN instance
    [Documentation]    Disassociate the previously associated network from the bgpvpn
    Log    Get the network association ID
    ${AssociationId}    OpenStackOperations.Get Bgpvpn Network Association Id    ${VpnName}    ${NETWORKS[0]}
    Log    verify disassociation of network from VPN
    OpenStackOperations.Bgpvpn Network Disassociate    ${VpnName}    ${AssociationId}
    ${devstack_conn_id} =    Get ControlNode Connection
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${net_id}


Verify the association of router to VPN
    [Documentation]    Create a Router and Verify association to previously created bgpvpn
    Log    Create a router with network and subnet
    OpenStackOperations.Create Network    ${NETWORKS[1]}
    OpenStackOperations.Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    OpenStackOperations.Create Router    ${RtrName}
    OpenStackOperations.Add Router Interface    ${RtrName}    ${SUBNETS[1]}
    Log    Associate the router to bgpvpn
    OpenStackOperations.Bgpvpn Router Associate    ${VpnName}    ${RtrName}
    ${devstack_conn_id} =    Get ControlNode Connection
    ${RouterId} =    Get Router Id    ${RtrName}    ${devstack_conn_id}
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${RouterId}

Verify the Dis-association of neutron router from VPN
    [Documentation]    Disassociate the neutron router previously associated to bgpvpn
    Log    Get the router association ID
    ${AssociationId}    OpenStackOperations.Get Bgpvpn Router Association Id    ${VpnName}    ${RtrName}
    Log  Verify disassociation of router from bgpvpn
    OpenStackOperations.Bgpvpn Router Disassociate    ${VpnName}    ${AssociationId}
    ${devstack_conn_id} =    Get ControlNode Connection
    ${RouterId} =    Get Router Id    ${RtrName}    ${devstack_conn_id}
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${RouterId}

Verify bgpvpn deletion via Neutron Api
    [Documentation]    Delete previously created bgpvpn with id/name
    Log    Delete previously created bgpvpn
    OpenStackOperations.Delete Bgpvpn    ${VpnName}   
    ${resp}    RequestsLibrary.Get    session    ${BgpVpnUrl}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${VpnName}    

*** Keywords ***
Basic BgpVpn Suite Teardown
    OpenStackOperations.Remove Interface    ${RtrName}    ${SUBNETS[1]}
    OpenStackOperations.Delete SubNet    ${SUBNETS[0]}
    OpenStackOperations.Delete SubNet    ${SUBNETS[1]}
    OpenStackOperations.Delete Network    ${NETWORKS[0]}
    OpenStackOperations.Delete Network    ${NETWORKS[1]}
    OpenStackOperations.Delete Router    ${RtrName}
    Close All Connections
