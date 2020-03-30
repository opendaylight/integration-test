*** Settings ***
Documentation     Test suite to validate IPv6 responder functionality in an Openstack
...               integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           DebugLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{EXTRA_NW_SUBNET_IPV4}    76.1.1.0/24    77.1.1.0/24
@{EXTRA_NW_SUBNET_IPV6}    3001:db9:cafe:d::/64    3001:db9:abcd:d::/64
@{NETWORKS}       ipv6_na_net_1    ipv6_na_net_2
@{NET_1_VM_INSTANCES}    ipv6_na_net_1_vm_1    ipv6_na_net_1_vm_2
@{NET_2_VM_INSTANCES}    ipv6_na_net_2_vm_1    ipv6_na_net_2_vm_2
@{PORTS}          ipv6_na_port_1    ipv6_na_port_2    ipv6_na_port_3    ipv6_na_port_4    ipv6_na_port_5    ipv6_na_port_6    ipv6_na_port_7
...               ipv6_na_port_8
@{ROUTER}         ipv6_na_router1
${SECURITY_GROUP}    ipv6_na_sg
@{SUBNETS4}       ipv6_na_subnet_ipv4_1    ipv6_na_subnet_ipv4_2
@{SUBNETS6}       ipv6_na_subnet_ipv6_1    ipv6_na_subnet_ipv6_2
@{SUBNETS4_CIDR}    30.1.1.0/24    40.1.1.0/24
@{SUBNETS6_CIDR}    2001:db5:0:2::/64    2001:db5:0:3::/64
${SUBNET_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
@{SUBNET_ROUTER1}    ipv6_na_subnet_ipv4_1    ipv6_na_subnet_ipv4_2    ipv6_na_subnet_ipv6_1    ipv6_na_subnet_ipv6_2

*** Test Cases ***
Verify NA Responder flows of IPv6 with Single VNIC per server (VM), Multi DPN for Router Association
    [Documentation]    To verify ipv6 and ipv4 ping and NA responder flows accross VM's after router association
    LOG    Test

*** Keywords ***
Suite Setup
    [Documentation]    Start suite for IPV6 NA responder test suite
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS4}[0]    @{SUBNETS4_CIDR}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS6}[0]    @{SUBNETS6_CIDR}[0]    ${SUBNET_ADDITIONAL_ARGS}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS4}[1]    @{SUBNETS4_CIDR}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS6}[1]    @{SUBNETS6_CIDR}[1]    ${SUBNET_ADDITIONAL_ARGS}
    OpenStackOperations.Create Router    @{ROUTER}[0]
    OpenStackOperations.Add Router Interface    @{ROUTER}[0]    @{SUBNET_ROUTER1}[0]
    OpenStackOperations.Add Router Interface    @{ROUTER}[0]    @{SUBNET_ROUTER1}[1]
    OpenStackOperations.Add Router Interface    @{ROUTER}[0]    @{SUBNET_ROUTER1}[2]
    OpenStackOperations.Add Router Interface    @{ROUTER}[0]    @{SUBNET_ROUTER1}[3]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}    IPv4
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    ${allowed_address_pairs_args} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[1] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[1]
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[4]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[5]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[6]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[7]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[0]    @{PORTS}[2]    @{NET_1_VM_INSTANCES}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[1]    @{PORTS}[3]    @{NET_1_VM_INSTANCES}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[4]    @{PORTS}[6]    @{NET_2_VM_INSTANCES}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[5]    @{PORTS}[7]    @{NET_2_VM_INSTANCES}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${vms}=    BuiltIn.Create List    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    FOR    ${vm}    IN    @{vms}
        OpenStackOperations.Poll VM Is ACTIVE    ${vm}
    END
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS6_CIDR}
    ${prefix_net1} =    Replace String    @{SUBNETS6_CIDR}[0]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${NET_1_VM_INSTANCES}    network=@{NETWORKS}[0]    subnet=${prefix_net1}
    ${prefix_net2} =    Replace String    @{SUBNETS6_CIDR}[1]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    120s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${NET_2_VM_INSTANCES}    network=@{NETWORKS}[1]    subnet=${prefix_net2}
    ${VM_IP_NET1} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_1_VM_INSTANCES}    network=@{NETWORKS}[0]    subnet=${prefix_net1}
    ${VM_IP_NET2} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_2_VM_INSTANCES}    network=@{NETWORKS}[1]    subnet=${prefix_net2}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{NET_1_VM_INSTANCES}[0]    30s
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{NET_2_VM_INSTANCES}[0]    30s
    OpenStackOperations.Copy DHCP Files From Control Node
    BuiltIn.Set Suite Variable    ${VM_IP_NET1}
    BuiltIn.Set Suite Variable    ${VM_IP_NET2}
    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    OpenStackOperations.Get Suite Debugs
