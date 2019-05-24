*** Settings ***
Documentation     Test suite to validate subnet routing functionality for hidden IPv4/IPv6 address in an Openstack
...               integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/VpnOperations.robot

*** Variables ***
${SECURITY_GROUP}    vpndssr_sg
@{NETWORKS}       vpndssr_net_1    vpndssr_net_2
@{SUBNETS4}       vpndssr_ipv4_sub_1    vpndssr_ipv4_sub_2
@{SUBNETS6}       vpndssr_ipv6_sub_1    vpndssr_ipv6_sub_2
@{SUBNETS4_CIDR}    30.1.1.0/24    40.1.1.0/24
@{SUBNETS6_CIDR}    2001:db5:0:2::/64    2001:db5:0:3::/64
${SUBNET_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
@{PORTS}          vpndssr_port_1    vpndssr_port_2    vpndssr_port_3    vpndssr_port_4
@{NET_1_VMS}      vpndssr_net_1_vm_1    vpndssr_net_1_vm_2
@{NET_2_VMS}      vpndssr_net_2_vm_1    vpndssr_net_2_vm_2
@{EXTRA_NW_IPV4}    30.1.1.209    30.1.1.210    40.1.1.209    40.1.1.210    40.1.1.211    30.1.1.211
@{EXTRA_NW_IPV6}    2001:db5:0:2::10    2001:db5:0:2::20    2001:db5:0:3::10    2001:db5:0:3::20    2001:db5:0:3::30    2001:db5:0:2::30
@{EXTRA_NW_SUBNET_IPv4}    30.1.1.0/24    40.1.1.0/24
@{EXTRA_NW_SUBNET_IPv6}    2001:db5:0:2::/64    2001:db5:0:3::/64
${ROUTER}         vpn_router_dualstack_subnet
${UPDATE_NETWORK}    update_network_dualstack_subnet
${UPDATE_SUBNET}    update_subnet_dualstack_subnet
${UPDATE_PORT}    update_port_dualstack_subnet
@{VPN_INSTANCE_ID}    1bc8cd92-48ca-49b5-94e1-b2921a261661    1bc8cd92-48ca-49b5-94e1-b2921a261662    1bc8cd92-48ca-49b5-94e1-b2921a261663
@{VPN_NAME}       vpn1_dualstack_subnet    vpn2_dualstack_subnet    vpn3_dualstack_subnet
@{RDS}            ["2506:2"]    ["2606:2"]    ["2706:2"]
${LOOP_COUNT}     4
@{TABLE_NO_21}    21
${DUMP_FLOWS}     sudo ovs-ofctl dump-flows br-int -O Openflow13

*** Test Cases ***
Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[0]    ping -I @{net_1_vm_ipv4}[0] -c 3 @{net_1_vm_ipv4}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[0]    ping6 -I @{net_1_vm_ipv6}[0] -c 3 @{net_1_vm_ipv6}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[0]    ping -I @{net_2_vm_ipv4}[0] -c 3 @{net_2_vm_ipv4}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[0]    ping6 -I @{net_2_vm_ipv6}[0] -c 3 @{net_2_vm_ipv6}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Create L3VPN
    [Documentation]    Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]    name=@{VPN_NAME}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_ID}[0]

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN.
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_ID}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}

Configure Extra IPv4/IPv6 Addresss On Interface For Subnet Routing
    [Documentation]    Extra IPv4/IPv6 Address configuration on Interfaces
    ${VM_IPV6} =    BuiltIn.Create List    @{net_1_vm_ipv6}[0]    @{net_1_vm_ipv6}[1]    @{net_2_vm_ipv6}[0]    @{net_2_vm_ipv6}[1]
    ${VM_IPV4} =    BuiltIn.Create List    @{net_1_vm_ipv4}[0]    @{net_1_vm_ipv4}[1]    @{net_2_vm_ipv4}[0]    @{net_2_vm_ipv4}[1]
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Execute Command on VM Instance    @{network_list}[${index}]    @{VM_IPV6}[${index}]    sudo ip -6 addr add @{EXTRA_NW_IPV6}[${index}]/64 dev eth0; sudo ifconfig eth0 allmulti; ip -6 a
    END
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Execute Command on VM Instance    @{network_list}[${index}]    @{VM_IPV4}[${index}]    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[${index}] netmask 255.255.255.0 up; ip a
    END
    BuiltIn.Set Suite Variable    ${VM_IPV6}
    BuiltIn.Set Suite Variable    ${VM_IPV4}
    BuiltIn.Should Not Contain    ${VM_IPV6}    None
    BuiltIn.Should Not Contain    ${VM_IPV4}    None

Verify Data Traffic On Configured Subnet Ipv4/IPv6 Address
    [Documentation]    Check Dual Stack data path verifcation within and across network.
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data Traffic

Dissociate L3VPN From Routers and verify traffic
    [Documentation]    Dissociating router from L3VPN and check data path verification
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_ID}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data No Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data No Traffic

Associate L3VPN Again To Routers and verify traffic
    [Documentation]    Associating router to L3VPN and check data path verification
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_ID}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data Traffic

Delete the configured extra IPv4/IPv6 Addresss and verify traffic
    [Documentation]    Delete IPv4/IPv6 Address configuration on Interfaces and verify traffic
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Execute Command on VM Instance    @{network_list}[${index}]    @{VM_IPV6}[${index}]    sudo ip -6 addr del @{EXTRA_NW_IPV6}[${index}]/64 dev eth0
    END
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Execute Command on VM Instance    @{network_list}[${index}]    @{VM_IPV4}[${index}]    sudo ifconfig eth0:1 down
    END
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data No Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data No Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    40s    Verify Table 21 for No VPN Routes

Configure Again Extra IPv4/IPv6 Addresss On Interface For Subnet Routing
    [Documentation]    Extra IPv4/IPv6 Address configuration on Interfaces
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Execute Command on VM Instance    @{network_list}[${index}]    @{VM_IPV6}[${index}]    sudo ip -6 addr add @{EXTRA_NW_IPV6}[${index}]/64 dev eth0; sudo ifconfig eth0 allmulti; ip -6 a
    END
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Execute Command on VM Instance    @{network_list}[${index}]    @{VM_IPV4}[${index}]    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[${index}] netmask 255.255.255.0 up; ip a
    END
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data Traffic

Remove Interface From Router And Verify Traffic
    [Documentation]    Remove subnet from router and check data path verification
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    FOR    ${interface}    IN    @{SUBNETS4}
        OpenStackOperations.Remove Interface    ${ROUTER}    ${INTERFACE}
    END
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    FOR    ${interface}    IN    @{SUBNETS6}
        OpenStackOperations.Remove Interface    ${ROUTER}    ${INTERFACE}
    END
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    FOR    ${interface}    IN    @{SUBNETS4}
        ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}
        BuiltIn.Should Not Contain    ${interface_output}    ${subnet_id}
    END
    FOR    ${interface}    IN    @{SUBNETS6}
        ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}
        BuiltIn.Should Not Contain    ${interface_output}    ${subnet_id}
    END
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data No Traffic

Add Interface To Router And Verify Traffic
    [Documentation]    Add interface router to again and check data path verification
    FOR    ${interface}    IN    @{SUBNETS4}
        OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    END
    FOR    ${interface}    IN    @{SUBNETS6}
        OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    END
    BuiltIn.Wait Until Keyword Succeeds    10x    60s    Verify Ipv4 Data Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    60s    Verify Ipv6 Data Traffic

Delete L3VPN
    [Documentation]    Delete L3VPN.
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data No Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data No Traffic

ReCreate L3VPN and associate L3VPN To Routers and verify traffic
    [Documentation]    Recreate L3VPN and associate L3VPN To Routers and verify ipv4/ipv6 traffic
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]    name=@{VPN_NAME}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_ID}[0]
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_ID}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv4 Data Traffic
    BuiltIn.Wait Until Keyword Succeeds    10x    30s    Verify Ipv6 Data Traffic

*** Keywords ***
Suite Setup
    [Documentation]    Create basic setup for feature.Create two network,subnet,four ports and four VMs
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS4}[0]    @{SUBNETS4_CIDR}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS6}[0]    @{SUBNETS6_CIDR}[0]    ${SUBNET_ADDITIONAL_ARGS}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS4}[1]    @{SUBNETS4_CIDR}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS6}[1]    @{SUBNETS6_CIDR}[1]    ${SUBNET_ADDITIONAL_ARGS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS4}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS6}
    OpenStackOperations.Update SubNet    @{SUBNETS4}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS4}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}
    OpenStackOperations.Create Router    ${ROUTER}
    @{router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    FOR    ${port}    IN    @{SUBNETS4}
        OpenStackOperations.Add Router Interface    ${ROUTER}    ${port}
    END
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    FOR    ${port}    IN    @{SUBNETS6}
        OpenStackOperations.Add Router Interface    ${ROUTER}    ${port}
    END
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    Create Allow All SecurityGroup    ${SECURITY_GROUP}    IPv4    True
    ${allowed_address_pairs_args} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[1] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[1]
    ${network_list} =    BuiltIn.Create List    @{NETWORKS}[0]    @{NETWORKS}[0]    @{NETWORKS}[1]    @{NETWORKS}[1]
    BuiltIn.Set Suite Variable    ${network_list}
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OpenStackOperations.Create Port    @{network_list}[${index}]    @{PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    END
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORTS}
    OpenStackOperations.Update Port    @{PORTS}[0]    additional_args=--name ${UPDATE_PORT}
    ${output} =    Show Port    ${UPDATE_PORT}
    BuiltIn.Should Contain    ${output}    ${UPDATE_PORT}
    OpenStackOperations.Update Port    ${UPDATE_PORT}    additional_args=--name @{PORTS}[0]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS4_CIDR}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS6_CIDR}
    @{net_1_vm_ipv4}    ${net_1_dhcp_ipv4} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{net_2_vm_ipv4}    ${net_2_dhcp_ipv4} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Should Not Contain    ${net_1_vm_ipv4}    None
    BuiltIn.Should Not Contain    ${net_2_vm_ipv4}    None
    BuiltIn.Should Not Contain    ${net_1_dhcp_ipv4}    None
    BuiltIn.Should Not Contain    ${net_2_dhcp_ipv4}    None
    BuiltIn.Log    Collect VMs IPv6 addresses
    ${prefix_net10} =    String.Replace String    @{SUBNETS6_CIDR}[0]    ${IP6_SUBNET_CIDR_SUFFIX}    ${IP6_ADDR_SUFFIX}
    ${prefix_net20} =    String.Replace String    @{SUBNETS6_CIDR}[1]    ${IP6_SUBNET_CIDR_SUFFIX}    ${IP6_ADDR_SUFFIX}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    true    ${NET_1_VMS}    @{NETWORKS}[0]    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    true    ${NET_2_VMS}    @{NETWORKS}[1]    ${prefix_net20}
    ${net_1_vm_ipv6} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    false    ${NET_1_VMS}    @{NETWORKS}[0]    ${prefix_net10}
    ${net_2_vm_ipv6} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    false    ${NET_2_VMS}    @{NETWORKS}[1]    ${prefix_net20}
    ${loop_count}    Get Length    ${NET_1_VMS}
    FOR    ${index}    IN RANGE    0    ${loop_count}
        ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${net_1_vm_ipv6}[${index}]    None
        Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{NET_1_VMS}[${index}]    30s
        ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${net_2_vm_ipv6}[${index}]    None
        Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{NET_2_VMS}[${index}]    30s
    END
    BuiltIn.Set Suite Variable    ${net_1_vm_ipv4}
    BuiltIn.Set Suite Variable    ${net_2_vm_ipv4}
    BuiltIn.Set Suite Variable    ${net_1_vm_ipv6}
    BuiltIn.Set Suite Variable    ${net_2_vm_ipv6}
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs

Verify Ipv4 Data Traffic
    [Documentation]    Check Ipv4 data path verification within and across network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Ipv4 Data No Traffic
    [Documentation]    Check Ipv4 data path verification within and across network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[2]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[2]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}

Verify Ipv6 Data Traffic
    [Documentation]    Check Ipv6 data path verification within and across network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Ipv6 Data No Traffic
    [Documentation]    Check Ipv6 data path verification within and across network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[2]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{net_1_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[2]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{net_2_vm_ipv6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}

Verify Table 21 for VPN Routes
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${TABLE_NO_21}    True    ${EMPTY}    ipv6_dst=@{EXTRA_NW_IPV6}[${index}]
    END
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${TABLE_NO_21}    True    ${EMPTY}    ipv6_dst=@{EXTRA_NW_IPV4}[${index}]
    END

Verify Table 21 for No VPN Routes
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${TABLE_NO_21}    False    ${EMPTY}    ipv6_dst=@{EXTRA_NW_IPV6}[${index}]
    END
    FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
        OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${TABLE_NO_21}    False    ${EMPTY}    ipv6_dst=@{EXTRA_NW_IPV4}[${index}]
    END

Suite Teardown
    [Documentation]    Delete the setup
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[1]
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[2]
    OpenStackOperations.OpenStack Suite Teardown
