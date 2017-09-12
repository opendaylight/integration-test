*** Settings ***
Documentation     Test suite to validate IPv6 vpnservice functionality in an Openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       VpnOperations.Basic Suite Setup
Suite Teardown    VpnOperations.Basic Vpnservice Suite Cleanup
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
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
${SECURITY_GROUP}    vpn_sg
@{NETWORKS}       vpn_net_1    vpn_net_2
@{SUBNETS4}       vpn_net_ipv4_1    vpn_net_ipv4_2
@{SUBNETS6}       vpn_net_ipv6_1    vpn_net_ipv6_2
@{SUBNETS4_CIDR}    10.1.1.0/24    20.1.1.0/24
@{SUBNETS6_CIDR}    2001:db8:0:2::/64    2001:db8:0:3::/64
@{PORTS}          vpn_port_1    vpn_port_2    vpn_port_3    vpn_port_4
@{ROUTERS}        vpn_router
@{NET_1_VM_INSTANCES}    vpn_net_1_vm_1    vpn_net_1_vm_2
@{NET_2_VM_INSTANCES}    vpn_net_2_vm_1    vpn_net_2_vm_2
@{EXTRA_NW_IPV4}    71.1.1.2    72.1.1.2
@{EXTRA_NW_IPV6}    3001:db9:cafe:d::10    3001:db9:abcd:d::20
@{EXTRA_NW_SUBNET}    71.1.1.0/24    72.1.1.0/24    3001:db9:cafe:d::/64    3001:db9:abcd:d::/64
${UPDATE_NETWORK}    UpdateNetwork
${UPDATE_SUBNET}    UpdateSubnet
${UPDATE_PORT}    UpdatePort
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261661    4ae8cd92-48ca-49b5-94e1-b2921a261662    4ae8cd92-48ca-49b5-94e1-b2921a261663
@{VPN_NAME}       vpn6_1    vpn6_2    vpn6_3
@{RDS}            ["2206:2"]    ["2306:2"]    ["2406:2"]

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create two networks
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    ${NET_LIST}    OpenStackOperations.List Networks
    BuiltIn.Should Contain    ${NET_LIST}    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${NET_LIST}    @{NETWORKS}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    [Documentation]    Create subnets for previously created networks
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS4}[0]    @{SUBNETS4_CIDR}[0]
    ${net1_additional_args}=    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_IPV6_ADDR_POOL}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS6}[0]    @{SUBNETS6_CIDR}[0]    ${net1_additional_args}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS4}[1]    @{SUBNETS4_CIDR}[1]
    ${net2_additional_args}=    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET2_IPV6_ADDR_POOL}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS6}[1]    @{SUBNETS6_CIDR}[1]    ${net2_additional_args}
    ${SUB_LIST}    OpenStackOperations.List Subnets
    BuiltIn.Should Contain    ${SUB_LIST}    @{SUBNETS4}[0]
    BuiltIn.Should Contain    ${SUB_LIST}    @{SUBNETS4}[1]
    BuiltIn.Should Contain    ${SUB_LIST}    @{SUBNETS6}[0]
    BuiltIn.Should Contain    ${SUB_LIST}    @{SUBNETS6}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS4}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS6}
    OpenStackOperations.Update SubNet    @{SUBNETS4}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS4}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}

Create Routers
    [Documentation]    Create Router
    OpenStackOperations.Create Router    ${ROUTERS[0]}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${ROUTERS}
    : FOR    ${PORT}    IN    @{SUBNETS4}
    \    OpenStackOperations.Add Router Interface    ${ROUTERS[0]}    ${PORT}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTERS[0]}
    ${GW1_MAC_ADDRS}    ${GW_IPV4_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTERS[0]}
    : FOR    ${PORT}    IN    @{SUBNETS6}
    \    OpenStackOperations.Add Router Interface    ${ROUTERS[0]}    ${PORT}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTERS[0]}
    ${GW2_MAC_ADDRS}    ${GW_IPV6_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTERS[0]}    ${IP6_REGEX}
    ${GW_MAC_ADDRS} =    BuiltIn.Create List    @{GW1_MAC_ADDRS}    @{GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW1_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_IPV4_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_IPV6_ADDRS}

Create Allow All Security Group IPv4+IPv6
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}    IPv4
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    ${allowed_address_pairs_args}=    BuiltIn.Set Variable    --allowed-address ip-address=${EXTRA_NW_SUBNET[0]} --allowed-address ip-address=${EXTRA_NW_SUBNET[1]} --allowed-address ip-address=${EXTRA_NW_SUBNET[2]} --allowed-address ip-address=${EXTRA_NW_SUBNET[3]}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORTS}
    ${PORTS_MACADDR} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    BuiltIn.Set Suite Variable    ${PORTS_MACADDR}
    OpenStackOperations.Update Port    @{PORTS}[0]    additional_args=--name ${UPDATE_PORT}
    ${output} =    Show Port    ${UPDATE_PORT}
    BuiltIn.Should Contain    ${output}    ${UPDATE_PORT}
    OpenStackOperations.Update Port    ${UPDATE_PORT}    additional_args=--name @{PORTS}[0]

Create Nova VMs
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    ${NET_1_VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    ${NET_1_VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    ${NET_2_VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    ${NET_2_VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    ${VM_INSTANCES}=    BuiltIn.Create List    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    BuiltIn.Set Suite Variable    ${VM_INSTANCES}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS4_CIDR}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS6_CIDR}
    BuiltIn.Log    Collect VMs IPv4 addresses
    @{NET_1_VM_IPV4}    ${NET_1_DHCP_IPV4} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    @{NET_2_VM_IPV4}    ${NET_2_DHCP_IPV4} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_INSTANCES}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IPV4}    None
    BuiltIn.Log    Collect VMs IPv6 addresses
    ${prefix_net10}=    String.Replace String    @{SUBNETS6_CIDR}[0]    ::/64    (:[a-f0-9]{,4}){,4}
    ${prefix_net20}=    String.Replace String    @{SUBNETS6_CIDR}[1]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    2x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${NET_1_VM_INSTANCES}    network=@{NETWORKS}[0]    subnet=${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    2x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${NET_2_VM_INSTANCES}    network=@{NETWORKS}[1]    subnet=${prefix_net20}
    ${NET_1_VM_IPV6}=    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_1_VM_INSTANCES}    network=@{NETWORKS}[0]    subnet=${prefix_net10}
    ${NET_2_VM_IPV6}=    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_2_VM_INSTANCES}    network=@{NETWORKS}[1]    subnet=${prefix_net20}
    ${LOOP_COUNT}    Get Length    ${NET_1_VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    @{NET_1_VM_IPV6}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{NET_1_VM_INSTANCES}[${index}]    30s
    \    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    @{NET_2_VM_IPV6}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{NET_2_VM_INSTANCES}[${index}]    30s
    BuiltIn.Set Suite Variable    ${NET_1_VM_IPV4}
    BuiltIn.Set Suite Variable    ${NET_2_VM_IPV4}
    BuiltIn.Set Suite Variable    ${NET_1_VM_IPV6}
    BuiltIn.Set Suite Variable    ${NET_2_VM_IPV6}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ping -I ${NET_1_VM_IPV4[0]} -c 3 ${NET_1_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ping6 -I ${NET_1_VM_IPV6[0]} -c 3 ${NET_1_VM_IPV6[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ping -I ${NET_2_VM_IPV4[0]} -c 3 ${NET_2_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ping6 -I ${NET_2_VM_IPV6[0]} -c 3 ${NET_2_VM_IPV6[1]}
    BuiltIn.Should Contain    ${output}    64 bytes

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath test across the networks using router for L3.
    BuiltIn.Log    Verification of FIB Entries and Flow
    ${cn1_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_COMPUTE_1_IP}    file_Name=tcpDumpCN1
    ${cn2_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_COMPUTE_2_IP}    file_Name=tcpDumpCN2
    ${os_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_CONTROL_NODE_IP}    file_Name=tcpDumpOS
    ${vm_instances} =    BuiltIn.Create List    @{NET_1_VM_IPV4}    @{NET_2_VM_IPV4}    @{NET_1_VM_IPV6}    @{NET_2_VM_IPV6}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    : FOR    ${VM}    IN    ${vm_instances}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW_MAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    L3 Datapath test across the networks using router
    ${dst_ipv4_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV4[1]}    @{NET_2_VM_IPV4}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv4_list1}
    BuiltIn.Log Many    Source IP    ${NET_1_VM_IPV4[1]}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${dst_ipv4_list1}
    ${dst_ipv4_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV4[1]}    @{NET_1_VM_IPV4}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv4_list2}
    BuiltIn.Log Many    Source IP    ${NET_2_VM_IPV4[0]}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ${dst_ipv4_list2}
    ${dst_ipv6_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV6[1]}    @{NET_2_VM_IPV6}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv6_list1}
    BuiltIn.Log Many    Source IP    ${NET_1_VM_IPV6[1]}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ${dst_ipv6_list1}
    ${dst_ipv6_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV6[1]}    @{NET_1_VM_IPV6}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv6_list2}
    BuiltIn.Log Many    Source IP    ${NET_2_VM_IPV6[0]}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ${dst_ipv6_list2}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${cn1_conn_id}    ${cn2_conn_id}    ${os_conn_id}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    [Documentation]    Add multiple extra routes and check data path before L3VPN creation
    BuiltIn.Log    Adding extraroutes to VM
    : FOR    ${VM}    IN    @{NET_1_VM_IPV4}
    \    ${CONFIG_EXTRA_ROUTE_IP1} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[0] netmask 255.255.255.0 up
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ${CONFIG_EXTRA_ROUTE_IP1}
    \    ${CONFIG_EXTRA_ROUTE_IP2} =    BuiltIn.Catenate    sudo ifconfig eth0:2 @{EXTRA_NW_IPV4}[1] netmask 255.255.255.0 up
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ${CONFIG_EXTRA_ROUTE_IP2}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ip a
    ${ext_rt1} =    BuiltIn.Set Variable    destination=${EXTRA_NW_SUBNET[0]},gateway=${NET_1_VM_IPV4[0]}
    ${ext_rt2} =    BuiltIn.Set Variable    destination=${EXTRA_NW_SUBNET[1]},gateway=${NET_1_VM_IPV4[0]}
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt1}    ${RT_OPTIONS}    ${ext_rt2}
    OpenStackOperations.Update Router    @{ROUTERS}[0]    ${cmd}
    OpenStackOperations.Show Router    @{ROUTERS}[0]    -D
    : FOR    ${VM}    IN    @{NET_1_VM_IPV6}
    \    ${CONFIG_EXTRA_ROUTE_IP3} =    BuiltIn.Catenate    sudo ip -6 addr add ${EXTRA_NW_IPV6[0]}/64 dev eth0
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ${CONFIG_EXTRA_ROUTE_IP3}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM}    ip -6 a
    \    ${CONFIG_EXTRA_ROUTE_IP4} =    BuiltIn.Catenate    sudo ip -6 addr add ${EXTRA_NW_IPV6[0]}/64 dev eth0
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ${CONFIG_EXTRA_ROUTE_IP4}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ip -6 a
    ${ext_rt3} =    BuiltIn.Set Variable    destination=${EXTRA_NW_SUBNET[2]},gateway=${NET_1_VM_IPV6[0]}
    ${ext_rt4} =    BuiltIn.Set Variable    destination=${EXTRA_NW_SUBNET[3]},gateway=${NET_1_VM_IPV6[0]}
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt3}    ${RT_OPTIONS}    ${ext_rt4}
    OpenStackOperations.Update Router    @{ROUTERS}[0]    ${cmd}
    OpenStackOperations.Show Router    @{ROUTERS}[0]    -D
    BuiltIn.Log    "Verify FIB table"
    ${vm_instances} =    BuiltIn.Create List    @{EXTRA_NW_SUBNET}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    : FOR    ${EXTRA_NW_IP}    IN    @{EXTRA_NW_IPV4}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ping -c 3 ${EXTRA_NW_IP}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[1]}    ping -c 3 ${EXTRA_NW_IP}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    : FOR    ${EXTRA_NW_IP}    IN    @{EXTRA_NW_IPV6}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ping6 -c 3 ${EXTRA_NW_IP}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[1]}    ping6 -c 3 ${EXTRA_NW_IP}
    \    BuiltIn.Should Contain    ${output}    64 bytes

Delete And Recreate Extra Route
    [Documentation]    Delete IPv4 and IPv6 extra routes and recreate them, than check data path before L3VPN creation
    BuiltIn.Log    Delete all extra routes
    OpenStackOperations.Update Router    @{ROUTERS}[0]    ${RT_CLEAR}
    OpenStackOperations.Show Router    @{ROUTERS}[0]    -D
    BuiltIn.Log    Adding extra route to VM
    ${CONFIG_EXTRA_ROUTE_IPV4}=    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[0] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${CONFIG_EXTRA_ROUTE_IPV4}
    ${ext_rt_ipv4} =    BuiltIn.Set Variable    destination=${EXTRA_NW_SUBNET[0]},gateway=${NET_1_VM_IPV4[0]}
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt_ipv4}
    OpenStackOperations.Update Router    @{ROUTERS}[0]    ${cmd}
    OpenStackOperations.Show Router    @{ROUTERS}[0]    -D
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[1]}    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${CONFIG_EXTRA_ROUTE_IPV6} =    BuiltIn.Catenate    sudo ip -6 addr add ${EXTRA_NW_IPV6[0]}/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[1]}    ${CONFIG_EXTRA_ROUTE_IPV6}
    ${ext_rt2} =    BuiltIn.Set Variable    destination=${EXTRA_NW_SUBNET[2]},gateway=${NET_1_VM_IPV6[1]}
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt2}
    OpenStackOperations.Update Router    @{ROUTERS}[0]    ${cmd}
    OpenStackOperations.Show Router    @{ROUTERS}[0]    -D
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[1]}    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    # clear off extra-routes before the next set of tests
    OpenStackOperations.Update Router    @{ROUTERS}[0]    ${RT_CLEAR}
    OpenStackOperations.Show Router    @{ROUTERS}[0]    -D
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs

Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTERS[0]}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${router_id}

Verify L3VPN Datapath With Router Association
    [Documentation]    Datapath test across the networks using L3VPN with router association.
    BuiltIn.Log    Verify VPN interfaces, FIB entries and Flow table
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${VPN_IFACES_URL}    ${VM_INSTANCES}
    ${RD} =    Strip String    ${RDS[0]}    characters="[]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_INSTANCES}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${VM_INSTANCES}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW_MAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    L3 Datapath test across the networks using L3VPN
    ${dst_ipv4_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV4[1]}    @{NET_2_VM_IPV4}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv4_list1}
    BuiltIn.Log Many    Source IP    ${NET_1_VM_IPV4[1]}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${dst_ipv4_list1}
    ${dst_ipv4_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV4[1]}    @{NET_1_VM_IPV4}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv4_list2}
    BuiltIn.Log Many    Source IP    ${NET_2_VM_IPV4[0]}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ${dst_ipv4_list2}
    ${dst_ipv6_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV6[1]}    @{NET_2_VM_IPV6}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv6_list1}
    BuiltIn.Log Many    Source IP    ${NET_1_VM_IPV6[1]}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ${dst_ipv6_list1}
    ${dst_ipv6_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV6[1]}    @{NET_1_VM_IPV6}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv6_list2}
    BuiltIn.Log Many    Source IP    ${NET_2_VM_IPV6[0]}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ${dst_ipv6_list2}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${cn1_conn_id}    ${cn2_conn_id}    ${os_conn_id}

Delete IPv6 Subnet And Check IPv4 datapath
    [Documentation]    Delete IPv6 subnet from router and check IPv4 datapath before L3VPN creation. Then recreate IPv6 subnet.
    BuiltIn.Log    Delete extra routes
    OpenStackOperations.Update Router    ${ROUTERS[0]}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTERS[0]}    -D
    BuiltIn.Log    Delete IPv6 subnet
    : FOR    ${PORT}    IN    @{SUBNETS6}
    \    Remove Interface    ${ROUTERS[0]}    ${PORT}
    BuiltIn.Log    Test L2 datapath
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ping -I ${NET_1_VM_IPV4[0]} -c 3 ${NET_1_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ping -I ${NET_2_VM_IPV4[0]} -c 3 ${NET_2_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    Test L3 datapath
    ${dst_ipv4_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV4[1]}    @{NET_2_VM_IPV4}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv4_list1}
    BuiltIn.Log Many    Source IP    ${NET_1_VM_IPV4[1]}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${dst_ipv4_list1}
    ${dst_ipv4_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV4[1]}    @{NET_1_VM_IPV4}
    BuiltIn.Log Many    Destination IPs list    ${dst_ipv4_list2}
    BuiltIn.Log Many    Source IP    ${NET_2_VM_IPV4[0]}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ${dst_ipv4_list2}

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTERS[0]}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    [Documentation]    Delete associate with L3VPN Router and its Ports
    # Asscoiate router with L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTERS[0]}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${router_id}
    #Delete Interface
    : FOR    ${iface}    IN    @{SUBNETS4}
    \    Remove Interface    ${ROUTERS[0]}    ${iface}
    \    ${subnet_id} =    Get Subnet Id    ${iface}
    \    ${rt_port_list} =    OpenStackOperations.Show Router Interface    ${ROUTERS[0]}
    \    BuiltIn.Should Not Contain    ${rt_port_list}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    BuiltIn.Should Not Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    BuiltIn.Create List    ${ROUTERS[0]}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    # Verify Router Entry removed from L3VPN
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Delete Router With NonExistentRouter Name
    [Documentation]    Delete router with nonExistentRouter name
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router delete nonExistentRouter
    BuiltIn.Should Match Regexp    ${output}    Unable Not At URIto find router with name or id 'nonExistentRouter'|Unable to find router\\(s\\) with id\\(s\\) 'nonExistentRouter'

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${network1_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${network2_id}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${network1_id}
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${network2_id}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${RDS[0]}    exportrt=${RDS[0]}    importrt=${RDS[0]}    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[1]}    rd=${RDS[1]}    exportrt=${RDS[1]}    importrt=${RDS[1]}    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[2]}    name=${VPN_NAME[2]}    rd=${RDS[2]}    exportrt=${RDS[2]}    importrt=${RDS[2]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[2]}

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[2]}

*** Keywords ***
Verify GWMAC Flow Entry On Flow Table
    [Arguments]    ${cnIp}
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${group_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    BuiltIn.Should Contain    ${flow_output}    table=${DISPATCHER_TABLE}
    ${dispatcher_table} =    Get Lines Containing String    ${flow_output}    table=${DISPATCHER_TABLE}
    BuiltIn.Should Contain    ${dispatcher_table}    goto_table:${GWMAC_TABLE}
    BuiltIn.Should Not Contain    ${dispatcher_table}    goto_table:${ARP_RESPONSE_TABLE}
    BuiltIn.Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    #Verify GWMAC address present in table 19
    : FOR    ${macAdd}    IN    @{GW_MAC_ADDRS}
    \    BuiltIn.Should Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
    #verify Miss entry
    BuiltIn.Should Contain    ${gwmac_table}    actions=resubmit(,17)
    #Verify ARP_CHECK_TABLE - 43
    ${arpchk_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_CHECK_TABLE}
    BuiltIn.Should Match Regexp    ${arpchk_table}    ${ARP_RESPONSE_REGEX}
    ${match} =    BuiltIn.Should Match Regexp    ${arpchk_table}    ${ARP_REQUEST_REGEX}
    ${groupID} =    Split String    ${match}    separator=:
    BuiltIn.Should Contain    ${flow_output}    table=${IPV6_TABLE}
    ${icmp_ipv6_flows} =    Get Lines Containing String    ${flow_output}    icmp_type=135
    #Verify IPv6 icmp_type=135
    : FOR    ${ip_addr}    IN    @{GW_IPV6_ADDRS}
    \    ${rule} =    BuiltIn.Set Variable    icmp_type=135,icmp_code=0,nd_target=${ip_addr} actions=CONTROLLER:65535
    \    BuiltIn.Should Match Regexp    ${icmp_ipv6_flows}    ${rule}
    VpnOperations.Verify ARP REQUEST in groupTable    ${group_output}    ${groupID[1]}
    #Verify ARP_RESPONSE_TABLE - 81
    BuiltIn.Should Contain    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    ${arpResponder_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    BuiltIn.Should Contain    ${arpResponder_table}    priority=0 actions=drop
    : FOR    ${macAdd}    ${ipAdd}    IN ZIP    ${GW1_MAC_ADDRS}    ${GW_IPV4_ADDRS}
    \    ${ARP_RESPONSE_IP_MAC_REGEX} =    BuiltIn.Set Variable    arp_tpa=${ipAdd},arp_op=1 actions=.*,set_field:${macAdd}->eth_src
    \    BuiltIn.Should Match Regexp    ${arpResponder_table}    ${ARP_RESPONSE_IP_MAC_REGEX}
