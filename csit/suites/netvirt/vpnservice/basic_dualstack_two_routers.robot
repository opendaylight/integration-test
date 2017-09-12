*** Settings ***
Documentation     Test suite to validate IPv6 vpnservice functionality in an Openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       NET1_2RT    NET2_2RT
@{SUBNETS4_RT2}    SUBNET1_IPV4_2RT    SUBNET2_IPV4_2RT
@{SUBNETS6_RT2}    SUBNET1_IPV6_2RT    SUBNET2_IPV6_2RT
@{SUBNETS4_CIDR}    10.1.1.0/24    20.1.1.0/24
@{SUBNETS6_CIDR}    2001:db8:0:2::/64    2001:db8:0:3::/64
@{PORT_LIST}      PORT11_2RT    PORT12_2RT    PORT21_2RT    PORT22_2RT
@{VM_INSTANCES_NET10}    VM11_2RT    VM21_2RT
@{VM_INSTANCES_NET20}    VM12_2RT    VM22_2RT
@{ROUTERS}        ROUTER4_2RT    ROUTER6_2RT
@{EXTRA_NW_IPV4}    40.1.1.2    50.1.1.2
@{EXTRA_NW_IPV6}    2001:db9:cafe:d::10    2001:db9:abcd:d::20
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24    2001:db9:cafe:d::/64    2001:db9:abcd:d::/64
${SECURITY_GROUP}    SG_2RT
${UPDATE_NETWORK}    UpdateNetwork
${UPDATE_SUBNET}    UpdateSubnet
${UPDATE_PORT}    UpdatePort

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    Update Network    ${NETWORKS[0]}    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    Show Network    ${NETWORKS[0]}
    Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    [Documentation]    Create subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS4_RT2[0]}    ${SUBNETS4_CIDR[0]}
    ${net1_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_IPV6_ADDR_POOL}
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS6_RT2[0]}    ${SUBNETS6_CIDR[0]}    ${net1_additional_args}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS4_RT2[1]}    ${SUBNETS4_CIDR[1]}
    ${net2_additional_args}=    Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET2_IPV6_ADDR_POOL}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS6_RT2[1]}    ${SUBNETS6_CIDR[1]}    ${net2_additional_args}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS4_RT2[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS4_RT2[1]}
    Should Contain    ${SUB_LIST}    ${SUBNETS6_RT2[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS6_RT2[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS4_RT2}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS6_RT2}
    Update SubNet    ${SUBNETS4_RT2[0]}    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    Show SubNet    ${SUBNETS4_RT2[0]}
    Should Contain    ${output}    ${UPDATE_SUBNET}

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}
    Create Router    ${ROUTERS[1]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    Should Contain    ${router_output}    ${ROUTERS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${ROUTERS}

Add Interfaces To Routers
    [Documentation]    Add Interfaces
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS4_RT2}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    \    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    : FOR    ${INTERFACE}    IN    @{SUBNETS6_RT2}
    \    Add Router Interface    ${ROUTERS[1]}    ${INTERFACE}
    \    ${interface_output} =    Show Router Interface    ${ROUTERS[1]}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    ${GW1_MAC_ADDR}    ${GW1_IP_ADDR} =    Get Gateway MAC And IP Address    ${ROUTERS[0]}
    Log    ${GW1_MAC_ADDR}
    Log    ${GW1_IP_ADDR}
    ${GW2_MAC_ADDR}    ${GW2_IP_ADDR} =    Get Gateway MAC And IP Address    ${ROUTERS[1]}
    Log    ${GW2_MAC_ADDR}
    Log    ${GW2_IP_ADDR}
    ${GW_MAC_ADDRS}=    Combine Lists    ${GW1_MAC_ADDR}    ${GW2_MAC_ADDR}
    Set Suite Variable    ${GW_MAC_ADDRS}
    ${GW_IP_ADDRS}=    Combine Lists    ${GW1_IP_ADDR}    ${GW2_IP_ADDR}
    Set Suite Variable    ${GW_IP_ADDRS}

Add Ssh V6 Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP6 packets for this suite
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    ${allowed_address_pairs_args}=    Set Variable    --allowed-address-pairs type=dict list=true ip_address=${EXTRA_NW_SUBNET[0]} ip_address=${EXTRA_NW_SUBNET[1]} ip_address=${EXTRA_NW_SUBNET[2]} ip_address=${EXTRA_NW_SUBNET[3]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}
    Update Port    ${PORT_LIST[0]}    additional_args=--name ${UPDATE_PORT}
    ${output} =    Show Port    ${UPDATE_PORT}
    Should Contain    ${output}    ${UPDATE_PORT}
    Update Port    ${UPDATE_PORT}    additional_args=--name ${PORT_LIST[0]}

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    ${VM_INSTANCES}=    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    Set Suite Variable    ${VM_INSTANCES}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS4_CIDR}
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS6_CIDR}
    Log    Collect VMs IPv4 addresses
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET10}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET20}
    ${VM_IPV4_NET10}    ${DHCPV4_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET10}
    ${VM_IPV4_NET20}    ${DHCPV4_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET20}
    Log    ${VM_IPV4_NET10}
    Log    ${VM_IPV4_NET20}
    Log    Collect VMs IPv6 addresses
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    2x    60s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${VM_INSTANCES_NET10}    ${NETWORKS}    ${SUBNETS6_CIDR[0]}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    2x    60s    Collect VM IPv6 SLAAC Addresses
    ...    true    ${VM_INSTANCES_NET20}    ${NETWORKS}    ${SUBNETS6_CIDR[1]}
    ${prefix_net10}=    Replace String    ${SUBNETS6_CIDR[0]}    ::/64    (:[a-f0-9]{,4}){,4}
    ${VM_IPV6_NET10}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net10}    ${VM_INSTANCES_NET10}
    ${prefix_net20}=    Replace String    ${SUBNETS6_CIDR[1]}    ::/64    (:[a-f0-9]{,4}){,4}
    ${VM_IPV6_NET20}=    Collect VM IPv6 SLAAC Addresses    false    ${prefix_net20}    ${VM_INSTANCES_NET20}
    Log    ${VM_IPV6_NET10}
    Log    ${VM_IPV6_NET20}
    ${VM_IPSV4}=    Combine Lists    ${VM_IPV4_NET10}    ${VM_IPV4_NET20}
    ${VM_IPSV6}=    Combine Lists    ${VM_IPV6_NET10}    ${VM_IPV6_NET20}
    Log Many    Obtained IPs    ${VM_IPSV4}
    Log Many    Obtained IPs    ${VM_IPSV6}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES_NET10}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPSV4}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{VM_INSTANCES}[${index}]    30s
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPSV6}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${VM_IPV4_NET10}
    Set Suite Variable    ${VM_IPV4_NET20}
    Set Suite Variable    ${VM_IPV6_NET10}
    Set Suite Variable    ${VM_IPV6_NET20}
    Set Suite Variable    ${VM_IPSV4}
    Set Suite Variable    ${VM_IPSV6}
    [Teardown]    Run Keywords    Show Debugs    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    ...    AND    Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV4_NET10[0]}    ping -I ${VM_IPV4_NET10[0]} -c 3 ${VM_IPV4_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[0]}    ping6 -I ${VM_IPV6_NET10[0]} -c 3 ${VM_IPV6_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IPV4_NET20[0]}    ping -I ${VM_IPV4_NET20[0]} -c 3 ${VM_IPV4_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IPV6_NET20[0]}    ping6 -I ${VM_IPV6_NET20[0]} -c 3 ${VM_IPV6_NET20[1]}
    Should Contain    ${output}    64 bytes

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath test across the networks using router for L3.
    Log    Verification of FIB Entries and Flow
    ${cn1_conn_id} =    Start Packet Capture on Node    ${OS_COMPUTE_1_IP}    file_Name=tcpDumpCN1
    ${cn2_conn_id} =    Start Packet Capture on Node    ${OS_COMPUTE_2_IP}    file_Name=tcpDumpCN2
    ${os_conn_id} =    Start Packet Capture on Node    ${OS_CONTROL_NODE_IP}    file_Name=tcpDumpOS
    ${vm_instances} =    Create List    @{VM_IPV4_NET10}    @{VM_IPV4_NET20}    @{VM_IPV6_NET10}    @{VM_IPV6_NET20}
    Log    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    : FOR    ${VM}    IN    ${vm_instances}
    \    Log    ${VM}
    \    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Entry On ODL    ${GW_MAC_ADDRS}
    Log    ${GW_MAC_ADDRS}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    Log    L3 Datapath test across the networks using router
    ${dst_ip_list} =    Create List    ${VM_IPV4_NET10[1]}    @{VM_IPV4_NET20}
    Log Many    Destination IPs list    ${dst_ip_list}
    Log Many    Source IP    ${VM_IPV4_NET10[1]}
    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IPV4_NET10[0]}    ${dst_ip_list}
    ${dst_ip_list} =    Create List    ${VM_IPV4_NET20[1]}    @{VM_IPV4_NET10}
    Log Many    Destination IPs list    ${dst_ip_list}
    Log Many    Source IP    ${VM_IPV4_NET20[0]}
    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IPV4_NET20[0]}    ${dst_ip_list}
    [Teardown]    Test Teardown With Tcpdump Stop    ${cn1_conn_id}    ${cn2_conn_id}    ${os_conn_id}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    [Documentation]    Add multiple extra routes and check data path before L3VPN creation
    Log    Adding extraroutes to VM
    : FOR    ${VM}    IN    @{VM_IPV4_NET10}
    \    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[0] netmask 255.255.255.0 up
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ${CONFIG_EXTRA_ROUTE_IP1}
    \    ${CONFIG_EXTRA_ROUTE_IP2} =    Catenate    sudo ifconfig eth0:2 @{EXTRA_NW_IPV4}[1] netmask 255.255.255.0 up
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ${CONFIG_EXTRA_ROUTE_IP2}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ip a
    ${EXT_RT1} =    Set Variable    destination=${EXTRA_NW_SUBNET[0]},gateway=${VM_IPV4_NET10[0]}
    ${EXT_RT2} =    Set Variable    destination=${EXTRA_NW_SUBNET[1]},gateway=${VM_IPV4_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT1}    ${RT_OPTIONS}    ${EXT_RT2}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    : FOR    ${VM}    IN    @{VM_IPV6_NET10}
    \    ${CONFIG_EXTRA_ROUTE_IP3} =    Catenate    sudo ip -6 addr add ${EXTRA_NW_IPV6[0]}/64 dev eth0
    \    Log    ${CONFIG_EXTRA_ROUTE_IP3}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ${CONFIG_EXTRA_ROUTE_IP3}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ip -6 a
    \    ${CONFIG_EXTRA_ROUTE_IP4} =    Catenate    sudo ip -6 addr add ${EXTRA_NW_IPV6[0]}/64 dev eth0
    \    Log    ${CONFIG_EXTRA_ROUTE_IP4}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP4}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[0]}    ip -6 a
    ${EXT_RT3} =    Set Variable    destination=${EXTRA_NW_SUBNET[2]},gateway=${VM_IPV6_NET10[0]}
    ${EXT_RT4} =    Set Variable    destination=${EXTRA_NW_SUBNET[3]},gateway=${VM_IPV6_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT3}    ${RT_OPTIONS}    ${EXT_RT4}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    Log    "Verify FIB table"
    ${vm_instances} =    Create List    @{EXTRA_NW_SUBNET}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    : FOR    ${EXTRA_NW_IP}    IN    @{EXTRA_NW_IPV4}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV4_NET10[0]}    ping -c 3 ${EXTRA_NW_IP}
    \    Should Contain    ${output}    64 bytes
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV4_NET10[1]}    ping -c 3 ${EXTRA_NW_IP}
    \    Should Contain    ${output}    64 bytes
    : FOR    ${EXTRA_NW_IP}    IN    @{EXTRA_NW_IPV6}
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[0]}    ping6 -c 3 ${EXTRA_NW_IP}
    \    Should Contain    ${output}    64 bytes
    \    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[1]}    ping6 -c 3 ${EXTRA_NW_IP}
    \    Should Contain    ${output}    64 bytes

Delete Extra Route
    [Documentation]    Delete the extra routes
    : FOR    ${router}    IN    @{ROUTERS}
    \    Update Router    ${router}    ${RT_CLEAR}
    \    Show Router    ${router}    -D

Delete And Recreate Extra Route
    [Documentation]    Recreate IPv4 and IPv6 extra routes and check data path before L3VPN creation
    Log    "Adding extra route to VM"
    ${CONFIG_EXTRA_ROUTE_IPV4}=    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV4_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IPV4}
    ${EXT_RT_IPv4} =    Set Variable    destination=${EXTRA_NW_SUBNET[0]},gateway=${VM_IPV4_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT_IPV4}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV4_NET10[1]}    ping -c 3 @{EXTRA_NW_IPV4}[0]
    Should Contain    ${output}    64 bytes
    ${CONFIG_EXTRA_ROUTE_IPV6} =    Catenate    sudo ip -6 addr add ${EXTRA_NW_IPV6[0]}/64 dev eth0
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[1]}    ${CONFIG_EXTRA_ROUTE_IPV6}
    ${EXT_RT2} =    Set Variable    destination=${EXTRA_NW_SUBNET[2]},gateway=${VM_IPV6_NET10[1]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT2}
    Update Router    @{ROUTERS}[1]    ${cmd}
    Show Router    @{ROUTERS}[1]    -D
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IPV6_NET10[1]}    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    Should Contain    ${output}    64 bytes
    # clear off extra-routes before the next set of tests
    : FOR    ${rt}    IN    @{ROUTERS}
    \    Run Keywords    Update Router    ${rt}    ${RT_CLEAR}
    \    AND    Show Router    ${rt}    -D
    \    AND    Get Test Teardown Debugs
    [Teardown]

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN
    : FOR    ${rt}    IN    @{ROUTERS}
    \    ${rt_id} =    Get Router Id    ${rt}    ${devstack_conn_id}
    \    Associate VPN to Router    routerid=${rt}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${rt_id}

Verify L3VPN Datapath With Router Association
    [Documentation]    Datapath test across the networks using L3VPN with router association.
    Log    Verify VPN interfaces, FIB entries and Flow table
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${VPN_IFACES_URL}    ${VM_INSTANCES}
    ${RD} =    Strip String    ${RDS[0]}    characters="[]
    Log    ${RD}
    Wait Until Keyword Succeeds    60s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${VM_INSTANCES}
    Wait Until Keyword Succeeds    60s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_INSTANCES}
    Wait Until Keyword Succeeds    60s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${VM_INSTANCES}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Entry On ODL    ${GW_MAC_ADDRS}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    Log    Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{VM_IPV4_NET10}[1]    @{VM_IPV4_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{VM_IPV4_NET10}[0]    ${dst_ip_list}
    Log    Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{VM_IPV4_NET20}[1]    @{VM_IPV4_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{VM_IPV4_NET20}[0]    ${dst_ip_list}

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN
    : FOR    ${rt}    IN    @{ROUTERS}
    \    ${rt}=    Get Router Id    ${rt}    ${devstack_conn_id}
    \    Dissociate VPN to Router    routerid=${rt}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${rt}

Delete Router And Router Interfaces With L3VPN
    [Documentation]    Delete Router and Interface to the subnets with L3VPN associate
    # Asscoiate router with L3VPN
    : FOR    ${rt}    IN    @{ROUTERS}
    \    ${rt_id}=    Get Router Id    ${rt}    ${devstack_conn_id}
    \    Associate VPN to Router    routerid=${rt_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${rt_id}
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS4_RT2}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    \    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    : FOR    ${INTERFACE}    IN    @{SUBNETS6_RT2}
    \    Remove Interface    ${ROUTERS[1]}    ${INTERFACE}
    \    ${interface_output} =    Show Router Interface    ${ROUTERS[1]}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    : FOR    ${rt}    IN    @{ROUTERS}
    \    Delete Router    ${rt}
    \    ${router_output} =    List Router
    \    Log    ${router_output}
    \    Should Not Contain    ${router_output}    ${rt}
    \    ${router_list} =    Create List    ${rt}
    \    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    \    # Verify Router Entry removed from L3VPN
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${rt}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network1_id}
    Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network2_id}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network1_id}
    Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network2_id}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${RDS[0]}    exportrt=${RDS[0]}    importrt=${RDS[0]}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[1]}    rd=${RDS[1]}    exportrt=${RDS[1]}    importrt=${RDS[1]}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[2]}    name=${VPN_NAME[2]}    rd=${RDS[2]}    exportrt=${RDS[2]}    importrt=${RDS[2]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[2]}

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[2]}

*** Keywords ***
Test Teardown With Tcpdump Stop
    [Arguments]    ${cn1_conn_id}    ${cn2_conn_id}    ${os_conn_id}
    Stop Packet Capture on Node    ${cn1_conn_id}
    Stop Packet Capture on Node    ${cn2_conn_id}
    Stop Packet Capture on Node    ${os_conn_id}
    Get Test Teardown Debugs

Get Gateway MAC And IP Address
    [Arguments]    ${router_Name}
    [Documentation]    Get Gateway mac and IP Address
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-port-list ${router_Name}    30s
    @{MacAddr-list} =    Get Regexp Matches    ${output}    ${MAC_REGEX}
    @{IpAddr-list} =    Get Regexp Matches    ${output}    ${IP6_REGEX}
    [Return]    ${MacAddr-list}    ${IpAddr-list}

Verify GWMAC Flow Entry On Flow Table
    [Arguments]    ${cnIp}
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${group_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    Log    ${group_output}
    Should Contain    ${flow_output}    table=${DISPATCHER_TABLE}
    ${dispatcher_table} =    Get Lines Containing String    ${flow_output}    table=${DISPATCHER_TABLE}
    Log    ${dispatcher_table}
    Should Contain    ${dispatcher_table}    goto_table:${GWMAC_TABLE}
    Should Not Contain    ${dispatcher_table}    goto_table:${ARP_RESPONSE_TABLE}
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    Log    ${gwmac_table}
    #Verify GWMAC address present in table 19
    : FOR    ${macAdd}    IN    @{GW_MAC_ADDRS}
    \    Should Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
    #verify Miss entry
    Should Contain    ${gwmac_table}    actions=resubmit(,17)
    #arp request and response
    Should Match Regexp    ${gwmac_table}    ${ARP_RESPONSE_REGEX}
    ${match} =    Should Match Regexp    ${gwmac_table}    ${ARP_REQUEST_REGEX}
    ${groupID} =    Split String    ${match}    separator=:
    Log    groupID
    Should Contain    ${flow_output}    table=${IPV6_TABLE}
    ${icmp_ipv6_flows} =    Get Lines Containing String    ${flow_output}    icmp_type=135
    Log    ${icmp_ipv6_flows}
    : FOR    ${ip_addr}    IN    @{GWIP_ADDRS}
    \    ${rule} =    Set Variable    icmp_type=135,icmp_code=0,nd_target=${ip_addr} actions=CONTROLLER:65535
    \    Should Match Regexp    ${icmp_ipv6_flows}    ${rule}
