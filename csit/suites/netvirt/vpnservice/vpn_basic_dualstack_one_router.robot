*** Settings ***
Documentation     Test suite to validate dualstack (IPv4 + IPv6) vpnservice functionality in an Openstack
...               integrated environment.
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
${SECURITY_GROUP}    vpn_sg_dualstack
@{NETWORKS}       vpn_net_1_dualstack    vpn_net_2_dualstack
@{SUBNETS4}       vpn_net_ipv4_1_dualstack    vpn_net_ipv4_2_dualstack
@{SUBNETS6}       vpn_net_ipv6_1_dualstack    vpn_net_ipv6_2_dualstack
@{SUBNETS4_CIDR}    30.1.1.0/24    40.1.1.0/24
@{SUBNETS6_CIDR}    2001:db5:0:2::/64    2001:db5:0:3::/64
${SUBNET_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
@{PORTS}          vpn_port_1_dualstack    vpn_port_2_dualstack    vpn_port_3_dualstack    vpn_port_4_dualstack
@{NET_1_VM_INSTANCES}    vpn_net_1_vm_1_dualstack    vpn_net_1_vm_2_dualstack
@{NET_2_VM_INSTANCES}    vpn_net_2_vm_1_dualstack    vpn_net_2_vm_2_dualstack
@{EXTRA_NW_IPV4}    76.1.1.2    77.1.1.2
@{EXTRA_NW_IPV6}    3001:db9:cafe:d::10    3001:db9:abcd:d::20
@{EXTRA_NW_SUBNET_IPv4}    76.1.1.0/24    77.1.1.0/24
@{EXTRA_NW_SUBNET_IPv6}    3001:db9:cafe:d::/64    3001:db9:abcd:d::/64
${ROUTER}         vpn_router_dualstack
${UPDATE_NETWORK}    UpdateNetwork_dualstack
${UPDATE_SUBNET}    UpdateSubnet_dualstack
${UPDATE_PORT}    UpdatePort_dualstack
@{VPN_INSTANCE_ID}    1bc8cd92-48ca-49b5-94e1-b2921a261661    1bc8cd92-48ca-49b5-94e1-b2921a261662    1bc8cd92-48ca-49b5-94e1-b2921a261663
@{VPN_NAME}       vpn1_dualstack    vpn2_dualstack    vpn3_dualstack
@{RDS}            ["2506:2"]    ["2606:2"]    ["2706:2"]

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create two networks.
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    ${NET_LIST} =    OpenStackOperations.List Networks
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    [Documentation]    Create subnets for previously created networks.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS4}[0]    @{SUBNETS4_CIDR}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS6}[0]    @{SUBNETS6_CIDR}[0]    ${SUBNET_ADDITIONAL_ARGS}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS4}[1]    @{SUBNETS4_CIDR}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS6}[1]    @{SUBNETS6_CIDR}[1]    ${SUBNET_ADDITIONAL_ARGS}
    ${SUB_LIST} =    OpenStackOperations.List Subnets
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS4}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS6}
    OpenStackOperations.Update SubNet    @{SUBNETS4}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS4}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}

Create Router
    [Documentation]    Create Router.
    OpenStackOperations.Create Router    ${ROUTER}
    @{ROUTER_LIST} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${ROUTER_LIST}

Add Router Ports
    [Documentation]    Add created subnets to router.
    : FOR    ${PORT}    IN    @{SUBNETS4}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${PORT}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GW1_MAC_ADDRS}    ${GW_IPV4_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}
    : FOR    ${PORT}    IN    @{SUBNETS6}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${PORT}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GW2_MAC_ADDRS}    ${GW_IPV6_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}    ${IP6_REGEX}
    ${GW_MAC_ADDRS} =    BuiltIn.Create List    @{GW1_MAC_ADDRS}    @{GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW1_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_IPV4_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_IPV6_ADDRS}

Create Allow All Security Group IPv4+IPv6
    [Documentation]    Create neutron security group with Allow All rule set for IPv4 ethertype.
    ...    Then add in this group Allow All rule set for IPv6 ethertype.
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}    IPv4
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp

Create Neutron Ports
    [Documentation]    Create 2 ports in previously created IPv4 subnets and 2 ports in previously created IPv6 subnets.
    ${allowed_address_pairs_args} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[1] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[1]
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
    [Documentation]    Launch a VM for each previously created port.
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    ${NET_1_VM_INSTANCES[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    ${NET_1_VM_INSTANCES[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    ${NET_2_VM_INSTANCES[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    ${NET_2_VM_INSTANCES[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${VM_INSTANCES} =    BuiltIn.Create List    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    BuiltIn.Set Suite Variable    ${VM_INSTANCES}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS4_CIDR}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS6_CIDR}
    @{NET_1_VM_IPV4}    ${NET_1_DHCP_IPV4} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    @{NET_2_VM_IPV4}    ${NET_2_DHCP_IPV4} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_INSTANCES}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IPV4}    None
    BuiltIn.Log    Collect VMs IPv6 addresses
    ${prefix_net10} =    String.Replace String    @{SUBNETS6_CIDR}[0]    ${IP6_SUBNET_CIDR_SUFFIX}    ${IP6_ADDR_SUFFIX}
    ${prefix_net20} =    String.Replace String    @{SUBNETS6_CIDR}[1]    ${IP6_SUBNET_CIDR_SUFFIX}    ${IP6_ADDR_SUFFIX}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    true    ${NET_1_VM_INSTANCES}    @{NETWORKS}[0]    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    true    ${NET_2_VM_INSTANCES}    @{NETWORKS}[1]    ${prefix_net20}
    ${NET_1_VM_IPV6} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    false    ${NET_1_VM_INSTANCES}    @{NETWORKS}[0]    ${prefix_net10}
    ${NET_2_VM_IPV6} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    false    ${NET_2_VM_INSTANCES}    @{NETWORKS}[1]    ${prefix_net20}
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
    ${VM_IPS} =    BuiltIn.Create List    @{NET_1_VM_IPV4}    @{NET_2_VM_IPV4}    @{NET_1_VM_IPV6}    @{NET_2_VM_IPV6}
    BuiltIn.Set Suite Variable    ${VM_IPS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ping -I ${NET_1_VM_IPV4[0]} -c 3 ${NET_1_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ping6 -I ${NET_1_VM_IPV6[0]} -c 3 ${NET_1_VM_IPV6[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ping -I ${NET_2_VM_IPV4[0]} -c 3 ${NET_2_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ping6 -I ${NET_2_VM_IPV6[0]} -c 3 ${NET_2_VM_IPV6[1]}
    BuiltIn.Should Contain    ${output}    64 bytes

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    L3 Datapath test across networks using previously created router.
    BuiltIn.Log    Verification of FIB Entries and Flow
    @{tcpdump_conn_ids} =    OpenStackOperations.Start Packet Capture On Nodes    tcpdump_vpn_ds    ${EMPTY}    ${OS_CONTROL_NODE_IP}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    ${vm_instances} =    BuiltIn.Create List    @{NET_1_VM_IPV4}    @{NET_2_VM_IPV4}    @{NET_1_VM_IPV6}    @{NET_2_VM_IPV6}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    : FOR    ${VM}    IN    ${vm_instances}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW_MAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    L3 Datapath test across the networks using router
    ${dst_ipv4_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV4[1]}    @{NET_2_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${dst_ipv4_list1}
    ${dst_ipv4_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV4[1]}    @{NET_1_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ${dst_ipv4_list2}
    ${dst_ipv6_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV6[1]}    @{NET_2_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ${dst_ipv6_list1}
    ${dst_ipv6_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV6[1]}    @{NET_1_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ${dst_ipv6_list2}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${tcpdump_conn_ids}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    [Documentation]    Add multiple extra routes and check data path before L3VPN creation.
    BuiltIn.Log    Add extraroutes to VM
    : FOR    ${extra_ip}    IN    @{EXTRA_NW_IPV4}
    \    ${cmd} =    BuiltIn.Catenate    sudo ip addr add ${extra_ip}/24 dev eth0
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ${cmd}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ip a
    \    BuiltIn.Should Contain    ${output}    ${extra_ip}/24
    ${ext_rt1} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET_IPV4}[0],gateway=@{NET_1_VM_IPV4}[0]
    ${ext_rt2} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET_IPV4}[1],gateway=@{NET_1_VM_IPV4}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt1}    ${RT_OPTIONS}    ${ext_rt2}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    : FOR    ${extra_ip}    IN    @{EXTRA_NW_IPV6}
    \    ${cmd} =    BuiltIn.Catenate    sudo ip -6 addr add ${extra_ip}/64 dev eth0
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ${cmd}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ip -6 a
    \    BuiltIn.Should Contain    ${output}    ${extra_ip}/64
    ${ext_rt3} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET_IPV6}[0],gateway=@{NET_1_VM_IPV6}[0]
    ${ext_rt4} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET_IPV6}[1],gateway=@{NET_1_VM_IPV6}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt3}    ${RT_OPTIONS}    ${ext_rt4}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    BuiltIn.Log    Verify FIB table
    ${vm_ips} =    BuiltIn.Create List    @{EXTRA_NW_SUBNET_IPV4}    @{EXTRA_NW_SUBNET_IPV6}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_ips}
    : FOR    ${extra_ip}    IN    @{EXTRA_NW_IPV4}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[1]}    ping -c 3 ${extra_ip}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ping -c 3 ${extra_ip}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[1]}    ping -c 3 ${extra_ip}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    : FOR    ${extra_ip}    IN    @{EXTRA_NW_IPV6}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[1]}    ping6 -c 3 ${extra_ip}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ping6 -c 3 ${extra_ip}
    \    BuiltIn.Should Contain    ${output}    64 bytes
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[1]}    ping6 -c 3 ${extra_ip}
    \    BuiltIn.Should Contain    ${output}    64 bytes

Delete And Recreate Extra Route
    [Documentation]    Delete IPv4 and IPv6 extra routes and recreate it.
    ...    Then check data path before L3VPN creation.
    BuiltIn.Log    Delete all extra routes
    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${cmd}=    BuiltIn.Catenate    sudo ip addr add @{EXTRA_NW_IPV4}[0]/24 dev eth0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ${cmd}
    ${ext_rt_ipv4} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET_IPV4}[0],gateway=@{NET_1_VM_IPV4}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt_ipv4}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${cmd} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IPV6}[0]/64 dev eth0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ${cmd}
    ${ext_rt2} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET_IPV6}[0],gateway=@{NET_1_VM_IPV6}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt2}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    # clear off extra-routes before the next set of tests
    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    ...    AND    OpenStackOperations.Show Router    ${ROUTER}    -D
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN.
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${router_id}

Verify L3VPN Datapath With Router Association
    [Documentation]    Datapath test across networks using L3VPN associated with router.
    BuiltIn.Log    Verify VPN interfaces, FIB entries and Flow table
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${VPN_IFACES_URL}    ${VM_IPS}
    ${RD} =    Strip String    ${RDS[0]}    characters="[]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW_MAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    L3 Datapath test across the networks using L3VPN
    ${dst_ipv4_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV4[1]}    @{NET_2_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${dst_ipv4_list1}
    ${dst_ipv4_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV4[1]}    @{NET_1_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ${dst_ipv4_list2}
    ${dst_ipv6_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV6[1]}    @{NET_2_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV6[0]}    ${dst_ipv6_list1}
    ${dst_ipv6_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV6[1]}    @{NET_1_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV6[0]}    ${dst_ipv6_list2}

Delete IPv6 Subnet And Check IPv4 datapath
    [Documentation]    Delete IPv6 subnet from router and check IPv4 datapath before L3VPN creation.
    ...    Then recreate IPv6 subnet.
    BuiltIn.Log    Delete extra routes
    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    BuiltIn.Log    Delete IPv6 subnet
    : FOR    ${PORT}    IN    @{SUBNETS6}
    \    Remove Interface    ${ROUTER}    ${PORT}
    BuiltIn.Log    Test L2 datapath
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ping -I ${NET_1_VM_IPV4[0]} -c 3 ${NET_1_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ping -I ${NET_2_VM_IPV4[0]} -c 3 ${NET_2_VM_IPV4[1]}
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Log    Test L3 datapath
    ${dst_ipv4_list1} =    BuiltIn.Create List    ${NET_1_VM_IPV4[1]}    @{NET_2_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[0]    ${NET_1_VM_IPV4[0]}    ${dst_ipv4_list1}
    ${dst_ipv4_list2} =    BuiltIn.Create List    ${NET_2_VM_IPV4[1]}    @{NET_1_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[1]    ${NET_2_VM_IPV4[0]}    ${dst_ipv4_list2}

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN.
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    [Documentation]    Delete associate with L3VPN Router and its Ports.
    # Asscoiate router with L3VPN
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${router_id}
    # Delete Interface
    : FOR    ${iface}    IN    @{SUBNETS4}
    \    Remove Interface    ${ROUTER}    ${iface}
    \    ${subnet_id} =    Get Subnet Id    ${iface}
    \    ${rt_port_list} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    \    BuiltIn.Should Not Contain    ${rt_port_list}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTER}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Should Not Contain    ${router_output}    ${ROUTER}
    ${router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    # Verify Router Entry removed from L3VPN
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Delete Router With NonExistentRouter Name
    [Documentation]    Delete router with nonExistentRouter name.
    ${rc}    ${output} =    Run And Return Rc And Output    openstack router delete nonExistentRouter
    BuiltIn.Should Match Regexp    ${output}    Failed to delete router with name or ID 'nonExistentRouter'|Failed to delete router\\(s\\) with name or ID\\(s\\) 'nonExistentRouter'

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks.
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${network1_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${network2_id}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks.
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${network1_id}
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${network2_id}

Delete L3VPN
    [Documentation]    Delete L3VPN.
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then check the same.
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${RDS[0]}    exportrt=${RDS[0]}    importrt=${RDS[0]}    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[1]}    rd=${RDS[1]}    exportrt=${RDS[1]}    importrt=${RDS[1]}    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[2]}    name=${VPN_NAME[2]}    rd=${RDS[2]}    exportrt=${RDS[2]}    importrt=${RDS[2]}    tenantid=${tenant_id}
    ${resp} =    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${resp} =    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    ${resp} =    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[2]}

*** Keywords ***
Verify GWMAC Flow Entry On Flow Table
    [Arguments]    ${cnIp}
    [Documentation]    Verify GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output} =    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${group_output} =    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    BuiltIn.Should Contain    ${flow_output}    table=${DISPATCHER_TABLE}
    ${dispatcher_table} =    Get Lines Containing String    ${flow_output}    table=${DISPATCHER_TABLE}
    BuiltIn.Should Contain    ${dispatcher_table}    goto_table:${GWMAC_TABLE}
    BuiltIn.Should Not Contain    ${dispatcher_table}    goto_table:${ARP_RESPONSE_TABLE}
    BuiltIn.Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    # Verify GWMAC address present in table ${L3_TABLE}
    : FOR    ${macAdd}    IN    @{GW_MAC_ADDRS}
    \    BuiltIn.Should Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
    # Verify Miss entry
    BuiltIn.Should Contain    ${gwmac_table}    actions=resubmit(,17)
    # Verify ARP_CHECK_TABLE - ${ARP_CHECK_TABLE}
    ${arpchk_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_CHECK_TABLE}
    BuiltIn.Should Match Regexp    ${arpchk_table}    ${ARP_RESPONSE_REGEX}
    ${match} =    BuiltIn.Should Match Regexp    ${arpchk_table}    ${ARP_REQUEST_REGEX}
    ${groupID} =    Split String    ${match}    separator=:
    BuiltIn.Should Contain    ${flow_output}    table=${IPV6_TABLE}
    ${icmp_ipv6_flows} =    Get Lines Containing String    ${flow_output}    icmp_type=${ICMP_TYPE}
    # Verify IPv6 icmp_type=135
    : FOR    ${ip_addr}    IN    @{GW_IPV6_ADDRS}
    \    ${rule} =    BuiltIn.Set Variable    icmp_type=${ICMP_TYPE},icmp_code=0,nd_target=${ip_addr} actions=CONTROLLER:65535
    \    BuiltIn.Should Match Regexp    ${icmp_ipv6_flows}    ${rule}
    VpnOperations.Verify ARP REQUEST in groupTable    ${group_output}    ${groupID[1]}
    # Verify ARP_RESPONSE_TABLE - ${ARP_RESPONSE_TABLE}
    BuiltIn.Should Contain    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    ${arpResponder_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    BuiltIn.Should Contain    ${arpResponder_table}    priority=0 actions=drop
    : FOR    ${macAdd}    ${ipAdd}    IN ZIP    ${GW1_MAC_ADDRS}    ${GW_IPV4_ADDRS}
    \    ${ARP_RESPONSE_IP_MAC_REGEX} =    BuiltIn.Set Variable    arp_tpa=${ipAdd},arp_op=1 actions=.*,set_field:${macAdd}->eth_src
    \    BuiltIn.Should Match Regexp    ${arpResponder_table}    ${ARP_RESPONSE_IP_MAC_REGEX}
