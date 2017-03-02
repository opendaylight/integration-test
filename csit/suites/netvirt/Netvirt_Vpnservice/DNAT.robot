*** Settings ***
Documentation     Test suite for SNAT and DNAT functionality testing 
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       NET30    NET40    NET50    NET60
@{SUBNETS}        SUBNET30    SUBNET40    SUBNET50    SUBNET60
@{SUBNET_CIDR}    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24    60.1.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6    PORT7
...               PORT8    PORT9    PORT10
@{VM_INSTANCES_NET1}    VM1    VM2    VM3
@{VM_INSTANCES_NET2}    VM4    VM5    VM6    VM7
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2"]
${CREATE_IMPORT_RT}    ["2200:2"]
${EXT_NETWORK}    ext-net
${EXT_SUBNET}     ext-subnet
@{ROUTERS}        ROUTER_1    ROUTER_2
${PING_REGEXP}    , 0% packet loss
${Enable_SNAT}    --enable-snat
${Disable_SNAT}    --disable-snat
${SNAT_VERIFY_ENABLE}     "enable_snat": true
${SNAT_VERIFY_DISABLE}     "enable_snat": false
${ALLOCATION_POOL}    --allocation-pool start=12.12.12.2,end=12.12.12.254
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${FLOATING_IP_URL}     /restconf/config/neutron:neutron/floatingips/

*** Test Cases ***
TC00 Verify Setup
    [Documentation]    Verify if tunnels are present. If not then create new tunnel.
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Suite Variable    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET1}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[2]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}

TC01 Create external network and update router with enable SNAT
    [Documentation]    Verify_successful_creation_of_external_network_with_router_external_set_to TRUE
    Log    Create External Network
    Create Network    ${EXT_NETWORK}    --router:external=True --provider:network_type gre
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}     ${EXT_NETWORK}
    ${EXT_NET}     Create List     ${EXT_NETWORK}
    Set Global Variable    ${EXT_NET}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${EXT_NET}
    Log    Create External Subnet
    Create SubNet    ${EXT_NETWORK}    ${EXT_SUBNET}    ${ALLOCATION_POOL}    --gateway 12.12.12.1 12.12.12.0/24
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${EXT_SUBNET}
    ${EXT_SUB}     Create List     ${EXT_SUBNET}
    Set Global Variable    ${EXT_SUB}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${EXT_SUB}
    Log    Add Router Gateway
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Enable_SNAT}
    ${resp}    Show Router    ${ROUTERS[0]}     | grep external_gateway_info
    Should Contain    ${resp}    ${SNAT_VERIFY_ENABLE}
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ext_net_id} =    Get Net Id    ${EXT_NETWORK}    ${devstack_conn_id}
    ${ext_subnet_id} =    Get Subnet Id    ${EXT_SUBNET}    ${devstack_conn_id}
    Should Contain    ${resp}    ${ext_net_id}
    Should Contain    ${resp}    ${ext_subnet_id}
    Log    Flows before creating floating IP
    Dump Flows

TC02 update router with disable SNAT and delete external network
    [Documentation]    update router with disable SNAT and delete external network
    Log    Disabling SNAT
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Disable_SNAT}
    ${resp}    Show Router    ${ROUTERS[0]}
    Should Contain    ${resp}    ${SNAT_VERIFY_DISABLE}
    Log    Flows before creating floating IP
    Dump Flows
    Log    Clearing router gateway
    Delete Router Gateway    ${ROUTERS[0]}
    Log    Delete external subnet and net
    Delete SubNet    ${EXT_SUBNET}
    Delete Network    ${EXT_NETWORK}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${SUBNETWORK_URL}    ${EXT_SUB}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${NETWORK_URL}    ${EXT_NET}

TC03 Verify floating IP provision and reachability from external network via neutron router through l3vpn
    [Documentation]    Verify floating IP provision and reachability from external network via neutron router through l3vpn
    Create Network    ${EXT_NETWORK}    --router:external=True --provider:network_type gre
    ${NET_LIST}    List Networks
    Should Contain    ${NET_LIST}     ${EXT_NETWORK}
    Create SubNet    ${EXT_NETWORK}    ${EXT_SUBNET}    ${ALLOCATION_POOL}    --gateway 12.12.12.1 12.12.12.0/24
    ${SUB_LIST}    List Subnets
    Should Contain    ${SUB_LIST}    ${EXT_SUBNET}
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Enable_SNAT}
    ${resp}    Show Router    ${ROUTERS[0]}
    Should Contain    ${resp}    ${SNAT_VERIFY_ENABLE}
    Log     FIB Entries
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Log    Flows before creating floating IP
    Dump Flows
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${ext_net_id}     Get Net ID      ${EXT_NETWORK}    ${devstack_conn_id}
    Set Global Variable     ${ext_net_id}
    ${tenant_id}     Get Tenant ID From Network     ${ext_net_id} 
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${ext_net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${ext_net_id}
    ${output}=    Get Fib Entries    session
    Log     ${output}
    ${rd}    Strip String     ${CREATE_RD}     characters=[]
    Log     ${rd}
    Should Contain     ${output}    ${rd}
    Log    Create Floating IP
    ${floating_ip_id}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Contain     ${resp.content}    ${ext_net_id}
    Should Contain     ${resp.content}    ${floating_ip_id}
    Log    Flows before creating floating IP
    Dump Flows
    Log     Associating Floating IP to Port
    Associate Floating IP To Port      ${floating_ip_id}      ${port_id2}
    Log    Show floating ip details
    ${floating_ip_add}    Get Floating IP Address     ${floating_ip_id}
    Log    ${floating_ip_add}
    Log    Get flow table
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Should Contain    ${output}    ${floating_ip_add}
    Log    Flows before creating floating IP
    Dump Flows
    Log    TO DO ADD PING FROM DCGW PART

TC04 Verify_floating_IP_de-provision_and_reachability_from_external_network_via_neutron_router_through_l3vpn
    [Documentation]    Verify_floating_IP_de-provision_and_reachability_from_external_network_via_neutron_router_through_l3vpn
    Log     Disassociate floating IP
    Dissociate Floating IP     ${floating_ip_id}      ${port_id2}
    Log    Deleting floating ip
    Delete Floating IP     ${floating_ip_id}
    Log    Verifying floating ip got removed from database
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${ext_net_id}
    Should Not Contain     ${resp.content}    ${floating_ip_id}
    Log    Flows after deleting floating IP
    Dump Flows
    Log    TO DO ADD PING FROM DCGW PART
    Log    Create Floating IP
    ${floating_ip_id2}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id2}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Contain     ${resp.content}    ${ext_net_id}
    Should Contain     ${resp.content}    ${floating_ip_id2}
    Log     Associating Floating IP to Port
    Associate Floating IP To Port      ${floating_ip_id2}      ${port_id2}
    Log    Show floating ip details
    ${floating_ip_add2}    Get Floating IP Address     ${floating_ip_id2}
    Set Global Variable    ${floating_ip_add2}
    Log    Get flow table
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Should Contain    ${output}    ${floating_ip_add2}
    Log    Flows before creating floating IP
    Dump Flows
    Log    TO DO ADD PING FROM DCGW PART

TC05 Verify_2_floating_IP_provision_distributed-across_2_neutron_ports_which_are_distributed_across_2_Vswitches
    [Documentation]     Verify_2_floating_IP_provision_distributed-across_2_neutron_ports_which_are_distributed_across_2_Vswitches
     Log    Create Floating IP
    ${floating_ip_id5}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id5}
    Verify Floating Ip Creation     ${floating_ip_id2}     session
    Verify Floating Ip Creation     ${floating_ip_id5}     session
#    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
#    Log    ${resp.content}
#    Should Contain     ${resp.content}    ${ext_net_id}
#    Should Contain     ${resp.content}    ${floating_ip_id2}
#    Should Contain     ${resp.content}    ${floating_ip_id5}
    Log     Associating Floating IP to Port
    Associate Floating IP To Port      ${floating_ip_id5}      ${port_id5}
    Log    Show floating ip details
    ${floating_ip_add5}    Get Floating IP Address     ${floating_ip_id5}
    Log    ${floating_ip_add5}
    Log    Get flow table
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Should Contain    ${output}    ${floating_ip_add5}
    Should Contain    ${output}    ${floating_ip_add2}
    Log    Flows before creating floating IP
    Dump Flows
    Log    TO DO ADD PING FROM DCGW PART

TC06 Verify_full_topology(12FIP)_floating_IP_provision_distributed_across_12_neutron_ports_which_are_distributed_across_3_Vswitches
    [Documentation]     Verify_full_topology(12FIP)_floating_IP_provision_distributed
    Log    Create and associate Floating IP with port0
    ${floating_ip_id0}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id0}
    Log    ${port_id0}
    Associate Floating IP To Port    ${floating_ip_id0}    ${port_id0} 
    Log    Create and associate Floating IP with port1
    ${floating_ip_id1}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id1}
    Associate Floating IP To Port    ${floating_ip_id1}    ${port_id1}
    Log    Create and associate Floating IP with port3
    ${floating_ip_id3}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id3}
    Associate Floating IP To Port      ${floating_ip_id3}      ${port_id3}
    Log    Create and associate Floating IP with port4
    ${floating_ip_id4}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id4}
    Associate Floating IP To Port      ${floating_ip_id4}      ${port_id4}
    Log    Create and associate Floating IP with port6
    ${floating_ip_id6}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id6}
    Associate Floating IP To Port      ${floating_ip_id6}      ${port_id6}
    Log    Create and associate Floating IP with port7
    ${floating_ip_id7}     Create Floating IP     ${EXT_NETWORK}
    Set Global Variable    ${floating_ip_id7}
    Associate Floating IP To Port      ${floating_ip_id7}      ${port_id7}
    Log    Verifying all floating IPs
    : For    ${i}    IN RANGE    0     9
    \     Verify Floating Ip Creation     ${floating_ip_id${i}}    session
    ${floating_ip_list}     Create List
    Log    Get Floating Ip address
    : For    ${i}    IN RANGE    0     8  
    \     ${floating_ip_add}    Get Floating IP Address     ${floating_ip_id${i}}
    \     Append To List     ${floating_ip_list}     ${floating_ip_add}
    Set Global Variable    ${floating_ip_list}

TC07 Verify_de-provision_of_1_floating_IP_from_2_Floating_IPs_which_are_distributed_across_2_neutron_ports_across_2_Vswitches
    [Documentation]    Verify_de-provision_of_1_floating_IP_from_2_Floating_IPs_which_are_distributed_across_2_neutron_ports_across_2Switches
    Log    Disassociating and deleting floating IP from DPN1
    Dissociate Floating IP     ${floating_ip_id2}      ${port_id2}
    Delete Floating IP     ${floating_ip_id2}
    Log    Verifying floating ip got removed from database
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id2}
    Log    TO DO check ping fails to ${floating_ip_id2} but passes to ${floating_ip_id4} and ${floating_ip_id5}

TC08 Verify_disassociation_of_external_network_from_L3VPN_where_FIP_already_provisioned_in_the_network
    [Documentation]    Verify_disassociation_of_external_network_from_L3VPN_where_FIP_already_provisioned_in_the_network
    Log    Get Fib Tables and Flow Dumps
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Dump Flows
    Log    Disassociating the external network from the L3VPN
    Dissociate L3VPN From Networks    networkid=${ext_net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${ext_net_id}
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Dump Flows
    Log    TO DO chack Ping to floating IPs fails
    Log    Associating the external network again to the L3VPN
    Associate L3VPN To Network    networkid=${ext_net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${ext_net_id}
    ${output}=    Get Fib Entries    session
    Log     ${output}

TC09 Verify_disassociation_of_subnet(which_has_FIP_is_assigned)_from_router
    [Documentation]    Verify_disassociation_of_subnet(which_has_FIP_is_assigned)_from_router
    Log    Deleting the Floating IPs
    Delete Floating IP     ${floating_ip_id0}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id0}
    Delete Floating IP     ${floating_ip_id1}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id1}
    Delete Floating IP     ${floating_ip_id2}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id2}
    Delete Floating IP     ${floating_ip_id3}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id3}
    Delete Floating IP     ${floating_ip_id4}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id4}
    Delete Floating IP     ${floating_ip_id5}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id5}
    Delete Floating IP     ${floating_ip_id6}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id6}
    Delete Floating IP     ${floating_ip_id7}
    ${resp}    RequestsLibrary.Get Request    session    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Not Contain     ${resp.content}    ${floating_ip_id7}
    Log    TO DO check no ping to all these deleted floating IP
    Log    Clearing the Gateway
    Delete Router Gateway    ${ROUTERS[0]}
    Dump Flows
    Log    Disassociating subnets from router
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    Log    Deleting L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Delete SubNet    ${EXT_SUBNET}
    Delete Network    ${EXT_NETWORK}
 
*** Keywords ***
Start Suite
    [Documentation]    Run before the suite execution
    DevstackUtils.Devstack Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Log    Create two networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    Create Network    ${network}
    #    Create Network    ${NETWORKS[0]}
    #    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    : FOR    ${network}    IN    @{NETWORKS}
    \    Should Contain    ${NET_LIST}    ${network}
    #    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    #    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    Create SubNet    ${NETWORKS[3]}    ${SUBNETS[3]}    ${SUBNET_CIDR[3]}
    ${SUB_LIST}    List Subnets
    : FOR    ${subnet}    IN    @{SUBNETS}
    \    Should Contain    ${SUB_LIST}    ${subnet}
    #    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    #    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Neutron Security Group Create    sg-vpnservice1
    Neutron Security Group Rule Create    sg-vpnservice1    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice1    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[2]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[3]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[4]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[5]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[6]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[7]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[8]}    sg=sg-vpnservice1
    Create Port    ${NETWORKS[3]}    ${PORT_LIST[9]}    sg=sg-vpnservice1
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${port_id0}     Get Port Id     ${PORT_LIST[0]}    ${devstack_conn_id}
    ${port_id1}     Get Port Id     ${PORT_LIST[1]}    ${devstack_conn_id}
    ${port_id2}     Get Port Id     ${PORT_LIST[2]}    ${devstack_conn_id}
    ${port_id3}     Get Port Id     ${PORT_LIST[3]}    ${devstack_conn_id}
    ${port_id4}     Get Port Id     ${PORT_LIST[4]}    ${devstack_conn_id}
    ${port_id5}     Get Port Id     ${PORT_LIST[5]}    ${devstack_conn_id} 
    ${port_id6}     Get Port Id     ${PORT_LIST[6]}    ${devstack_conn_id}
    ${port_id7}     Get Port Id     ${PORT_LIST[7]}    ${devstack_conn_id}
    ${port_id8}     Get Port Id     ${PORT_LIST[8]}    ${devstack_conn_id}
    Set Global Variable     ${port_id0}
    Set Global Variable     ${port_id1}
    Set Global Variable     ${port_id2}
    Set Global Variable     ${port_id3}
    Set Global Variable     ${port_id4}
    Set Global Variable     ${port_id5}
    Set Global Variable     ${port_id6}
    Set Global Variable     ${port_id7}
    Set Global Variable     ${port_id8}
#    ${port_id_list}    Create List
#    : FOR    ${i}    IN RANGE    0     8
#    \     ${port_id}     Get Port Id     ${PORT_LIST[${i}]}    ${devstack_conn_id}
#    \     Append To List     ${port_id_list}     ${port_id}
#    \     Set Global Variable     ${port_id${i}}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET1[2]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_INSTANCES_NET2[2]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice1
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_INSTANCES_NET2[3]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice1
    Log    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NEUTRON_ROUTERS_API}    ${router_list}
    Log    Add Interfaces to router
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[1]}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${VM_IP_NET1}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnet and networks
    Delete Router Gateway    ${ROUTERS[0]}
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[0]}
    Remove Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    Delete Router    ${ROUTERS[0]}
    Log    Delete the VM instances
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    Delete neutron ports
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    Log    Delete subnets
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    Log    Delete networks
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

Verify Floating Ip Creation
    [Arguments]     ${id}    ${session} 
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Contain     ${resp.content}    ${ext_net_id}
    Should Contain     ${resp.content}    ${id}

Dump Flows
    [Documentation]    Dump flows of both DPN
    ${flow_output_1}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output_1}
    ${flow_output_2}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output_2}

Get Fib Entries
    [Arguments]    ${session}
    [Documentation]    Get Fib table entries from ODL
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
    Log    ${resp.content}
    [Return]    ${resp.content}
