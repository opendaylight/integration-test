*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           SSHLibrary
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CON}       /restconf/config/
@{vpn_inst_values}    testVpn1    1000:1    1000:1,2000:1    3000:1,4000:1
@{vm_int_values}    s1-eth1    l2vlan    openflow:1:1
@{vm_vpnint_values}    s1-eth1    testVpn1    10.0.0.1    12:f8:57:a8:b9:a1
${VPN_CONFIG_DIR}    ${CURDIR}/../../../variables/openstack/vpnservice
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
@{NET_10_VM_IPS}    10.1.1.3    10.1.1.4
@{NET_20_VM_IPS}    20.1.1.3    20.1.1.4
@{GATEWAY_IPS}    10.1.1.1    20.1.1.1
@{DHCP_IPS}       10.1.1.2    20.1.1.2
${ping_pass}    3 packets recieved
${ping_fail}    Network is unreachable


*** Test Cases ***
Verify Tunnel Creation
    [Documentation]    Checks that vxlan tunnels have been created properly.
    [Tags]    exclude
    Log    This test case is currently a noop, but work can be added here to validate if needed.    However, as the    suite Documentation notes, it's already assumed that the environment has been configured properly.    If    we do add work in this test case, we need to remove the "exclude" tag for it to run.    In fact, if this
    ...    test case is critical to run, and if it fails we would be dead in the water for the rest of the suite,    we should move it to Suite Setup so that nothing else will run and waste time in a broken environment.

Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}    --provider:network_type local
    Create Network    ${NETWORKS[1]}    --provider:network_type local
    List Networks

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    List Subnets

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}

Check OpenDaylight Neutron Ports
    [Documentation]    Checking OpenDaylight Neutron API for known ports
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Create Nova VMs
    [Documentation]    Create two subnets for previously created networks
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    [Tags]    exclude
    Log    This test will be added in the next patch

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath Test Across the networks using Router for L3.
    [Tags]    exclude
    Log    This test will be added in the next patch

Create L3VPN
    [Documentation]    Creates VPN Instance through restconf
    [Tags]    Post
	${tenantid}=    Get Tenant ID From Security Group
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance.json
	${body}    Replace String    ${body}    {tntid}    ${tenantid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:createL3VPN/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Associate Networks To L3VPN
    [Documentation]    Associate Networks To L3VPN.
    [Tags]    Post
    ${devstack_conn_id}=    Get ControlNode Connection
    ${networkid}=    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn1-network.json
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associateNetworks/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
    ${networkid}=    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn2-network.json
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associateNetworks/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Check VM accessibility across DPNs on same VPN
    [Documentation]    VM accessibility check Across the DPNs for same VPN
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_10_VM_IPS[1]}    ${ping_pass}
	${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova list    30s
    Log    ${output}


Check VM accessibility across VPNs
    [Documentation]    VM accessibility check Across the VPNs 
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[0]}    ${ping_fail} 

Exchange VPN Routes
    [Documentation]   Import/Export Routes between VPN
    [Tags]    Post
	${tenantid}=    Get Tenant ID From Security Group
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance_impex.json
	${body}    Replace String    ${body}    {tntid}    ${tenantid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:createL3VPN/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Check VM accessibility across VPNs within DPN1
    [Documentation]    VM accessibility check Across the VPNs within DPN's
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[0]}    ${ping_pass}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[0]}    ${NET_10_VM_IPS[0]}    ${ping_pass}

Check VM accessibility across VPNs within DPN2
    [Documentation]    VM accessibility check Across the VPNs within DPN's
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[1]}    ${NET_20_VM_IPS[1]}    ${ping_pass}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_20_VM_IPS[1]}    ${NET_10_VM_IPS[1]}    ${ping_pass}

Check VM accessibility across VPNs on other DPNs 
    [Documentation]    VM accessibility check Across VPNs on other DPNs
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[1]}    ${ping_pass}
    Check Ping From VM    ${NETWORKS[1]}    ${NET_10_VM_IPS[1]}    ${NET_20_VM_IPS[0]}    ${ping_pass}

Check VPN Route
    [Documentation]   TC4-Verify the subnet route is learnt for VPN1 and is shared across the other VPNs   
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Neutron Port
   [Documentation]  TC5- Deletion of Neutron Port for VPN1 
   Delete Port    ${PORT_LIST[0]}

Check VPN Route
    [Documentation]   TC5-Verify the subnet route for route Withdrawl after deletion for neutron port on VPN1
    [Tags]    exclude
    Log    This test will be added in the next patch

Create L3VPN for VPN3
    [Documentation]    TC6-Creates VPN3 Instance through restconf
    [Tags]    Post
	${tenantid}=    Get Tenant ID From Security Group
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/vpn_instance_vpn3_impex.json
	${body}    Replace String    ${body}    {tntid}    ${tenantid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:createL3VPN/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204

Associate Networks To L3VPN for VPN3
    [Documentation]    TC6-Associate Networks To L3VPN for VPN3
    [Tags]    Post
    ${devstack_conn_id}=    Get ControlNode Connection
    ${networkid}=    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn3-network.json
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associateNetworks/    data=${body}
    Log    ${resp.content}
	Should Be Equal As Strings    ${resp.status_code}    204
    ${networkid}=    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn3-network.json
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associateNetworks/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    204
	
Check reachability between networks in VPN3
    [Documentation]   TC6-Check reachability between networks in VPN3
    [Tags]    exclude
    Log    This test will be added in the next patch
 
Dissociate Networks To L3VPN for VPN3
    [Documentation]   TC7-Dissociate VPN3 from network2
    [Tags]    exclude
    ${devstack_conn_id}=    Get ControlNode Connection
    ${networkid}=    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn3-network.json
    ${body}    Replace String    ${body}    {netid}    ${networkid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:dissociateNetworks/    data=${body}
    Log    ${resp.content}
	Should Be Equal As Strings    ${resp.status_code}    204

Check reachability between networks in VPN3
    [Documentation]   TC7-Check reachability between network1 and network2 in VPN3
    [Tags]    exclude
    Log    This test will be added in the next patch
	
Create Router
    [Documentation]    TC8-Create Router
    Create Router    ${ROUTERS[0]}

Add Interfaces To Router
    [Documentation]    TC8-assocaitte 2 interfaces to router
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}

Associtate VPN To Router
    [Documentation]   TC9-Associate VPN1 and VPN2 to Router1
    [Tags]    exclude
    ${devstack_conn_id}=    Get ControlNode Connection
    ${routerid}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn1-router.json
    ${body}    Replace String    ${body}    {rtrid}    ${routerid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associaterouters/    data=${body}
    Log    ${resp.content}
	Should Be Equal As Strings    ${resp.status_code}    204
    ${routerid}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    ${body}    OperatingSystem.Get File    ${VPN_CONFIG_DIR}/testVpn2-router.json
    ${body}    Replace String    ${body}    {rtrid}    ${routerid}
    ${resp}    RequestsLibrary.Post Request    session    ${REST_CON}neutronvpn:associaterouters/    data=${body}
    Log    ${resp.content}
	Should Be Equal As Strings    ${resp.status_code}    204

Check VM accessibility across VPNs
    [Documentation]    TC9-VM accessibility check Across the VPNs 
    Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[0]}    ${ping_pass} 
	Check Ping From VM    ${NETWORKS[0]}    ${NET_10_VM_IPS[0]}    ${NET_20_VM_IPS[1]}    ${ping_pass} 
	
Restart VM and verify flow reprogramming	
    [Documentation] TC10-Restart one VM from VPN1 and VPN2
    Restart VM    ${VM_INSTANCES[0]}
	Restart VM    ${VM_INSTANCES[1]}

Verify Dumpflow
    [Documentation] TC10-verify that the flows are reprogrammed on restarting one VM from VPN1 and VPN2
	[Tags]    exclude
	Log    This test will be added in the next patch
	
Verify VM rechability after restart
    [Documentation] TC10-Check VMs are reachable once after they are up
	[Tags]    exclude
	Log    This test will be added in the next patch

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}

Create L3VPN
    [Documentation]    Create L3VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Associate Networks To L3VPN
    [Documentation]    Associate Networks To L3VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

Delete Neutron Ports
    [Documentation]    Delete Neutron Ports in the given Port List.
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete SubNet    ${Port}

Delete Sub Networks
    [Documentation]    Delete Sub Nets in the given Subnet List.
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

Delete Networks
    [Documentation]    Delete Networks in the given Net List
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions
