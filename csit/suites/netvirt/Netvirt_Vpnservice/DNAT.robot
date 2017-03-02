*** Settings ***
Documentation     Test suite for Tunnel Monitoring. More test cases to be added in subsequent patches.
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
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${EXT_NET}
    Log    Create External Subnet
    Create SubNet    ${EXT_NETWORK}    ${EXT_SUBNET}    ${ALLOCATION_POOL}    --gateway 12.12.12.1 12.12.12.0/24
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${EXT_SUBNET}
    ${EXT_SUB}     Create List     ${EXT_SUBNET}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${EXT_SUB}
    Log    Add Router Gateway
    Add Router Gateway    ${ROUTERS[0]}    ${EXT_NETWORK}    ${Enable_SNAT}
    ${resp}    Show Router    ${ROUTERS[0]}
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
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${SUBNETWORK_URL}    ${EXT_SUBNET}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${NETWORK_URL}    ${EXT_NETWORK}

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
    ${tenant_id}     Get Tenant ID From Network      ${EXT_NETWORK}
    ${ext_net_id}     Get Net ID      ${EXT_NETWORK}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${ext_net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${net_id}
    ${output}=    Get Fib Entries    session
    Log     ${output}
    Should Contain     ${output}    ${CREATE_RD}
    Log    Create Floating IP
    Create Floating IP     ${EXT_NETWORK}
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FLOATING_IP_URL}
    Log    ${resp.content}
    Should Contain     ${resp.content}    ${ext_net_id}
    Log    Flows before creating floating IP
    Dump Flows
    ${port_id}     Get Port Id     ${PORT_LIST[2]}
 
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
