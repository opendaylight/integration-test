*** Settings ***
Documentation     Test suite to validate IPv6 responder functionality in an Openstack
...               integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Suite Setup  
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Teardown     VpnOperations.VNI Test Teardown
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/VpnOperations.robot

*** Variables ***
@{EXTRA_NW_SUBNET_IPV4}    76.1.1.0/24    77.1.1.0/24
@{EXTRA_NW_SUBNET_IPV6}    3001:db9:cafe:d::/64    3001:db9:abcd:d::/64
@{NETWORKS}       ipv6_na_net_1    ipv6_na_net_2
@{NET_1_VM_INSTANCES}    ipv6_na_net_1_vm_1    ipv6_na_net_1_vm_2
@{NET_2_VM_INSTANCES}    ipv6_na_net_2_vm_1    ipv6_na_net_2_vm_2
@{PORTS}          ipv6_na_port_1    ipv6_na_port_2    ipv6_na_port_3    ipv6_na_port_4    ipv6_na_port_5    ipv6_na_port_6    ipv6_na_port_7
...               ipv6_na_port_8
@{ROUTER}         ipv6_na_router1
@{RDS}       ["2600:2"]    ["2700:2"]
${SECURITY_GROUP}    ipv6_na_sg
@{SUBNETS4}       ipv6_na_subnet_ipv4_1    ipv6_na_subnet_ipv4_2
@{SUBNETS6}       ipv6_na_subnet_ipv6_1    ipv6_na_subnet_ipv6_2
@{SUBNETS4_CIDR}    30.1.1.0/24    40.1.1.0/24
@{SUBNETS6_CIDR}    2001:db5:0:2::/64    2001:db5:0:3::/64
${SUBNET_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
@{SUBNET_ROUTER1}    ipv6_na_subnet_ipv4_1    ipv6_na_subnet_ipv4_2    ipv6_na_subnet_ipv6_1    ipv6_na_subnet_ipv6_2
@{VPN_NAMES}      ipv6_na_vpn1    ipv6_na_L3VPN1    ipv6_na_InternetBgpVpn
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261551


*** Test Cases ***
Verify NA Responder flows of IPv6 with Single VNIC per server 
    [Documentation]    To verify ipv6 ping and NA responder flows accross VM's
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    Ipv6 Ping Verification
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP1_CONN_ID}
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP2_CONN_ID}
    Flow Verification with Elan Tag    @{NETWORKS}[0]    ${OS_COMPUTE_1_IP}    2
    Flow Verification with Elan Tag    @{NETWORKS}[1]    ${OS_COMPUTE_2_IP}    2
    Flow Verification with Elan Tag    @{NETWORKS}[0]    ${OS_COMPUTE_2_IP}    2
    Flow Verification with Elan Tag    @{NETWORKS}[1]    ${OS_COMPUTE_1_IP}    2
    Verify IPV6 NA responder flows   ${OS_COMPUTE_1_IP}    @{NETWORKS}[0]   @{PORTS}[0]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_1_IP}    @{NETWORKS}[1]   @{PORTS}[1]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_2_IP}    @{NETWORKS}[0]   @{PORTS}[2]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_2_IP}    @{NETWORKS}[1]   @{PORTS}[3]

Verify NA Responder flows of IPv6 with Single VNIC, by doing Router Association with VPN
    [Documentation]    To verify ipv6 ping and NA responder flows accross VM's after router association
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[1]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]
    ${router_id} =    OpenStackOperations.Get Router Id    @{ROUTER}[0]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}    
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    Ipv6 Ping Verification
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP1_CONN_ID}
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP2_CONN_ID}
    Flow Verification with Elan Tag    @{NETWORKS}[0]    ${OS_COMPUTE_1_IP}    2
    Flow Verification with Elan Tag    @{NETWORKS}[1]    ${OS_COMPUTE_2_IP}    2
    Flow Verification with Elan Tag    @{NETWORKS}[0]    ${OS_COMPUTE_2_IP}    2
    Flow Verification with Elan Tag    @{NETWORKS}[1]    ${OS_COMPUTE_1_IP}    2
    Verify IPV6 NA responder flows   ${OS_COMPUTE_1_IP}    @{NETWORKS}[0]   @{PORTS}[0]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_1_IP}    @{NETWORKS}[1]   @{PORTS}[1]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_2_IP}    @{NETWORKS}[0]   @{PORTS}[2]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_2_IP}    @{NETWORKS}[1]   @{PORTS}[3]

Verify NA Responder flows of IPv6 by doing Router Disassociation with VPN
    [Documentation]    Disassociate subnets from router and verify NA responder flows and ping across vm's
    ...    Verify NA Responder flows of IPv6 with Single VNIC per server (VM) & DPN, for Router Disassociation
    ${router_id} =    OpenStackOperations.Get Router Id    @{ROUTER}[0]
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]   
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    Ipv6 Ping Verification
    Verify IPV6 NA responder flows   ${OS_COMPUTE_1_IP}    @{NETWORKS}[0]   @{PORTS}[0]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_1_IP}    @{NETWORKS}[1]   @{PORTS}[1]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_2_IP}    @{NETWORKS}[0]   @{PORTS}[2]
    Verify IPV6 NA responder flows   ${OS_COMPUTE_2_IP}    @{NETWORKS}[1]   @{PORTS}[3]

*** Keywords ***
Suite Setup
    [Documentation]    Start suite for IPV6 NA responder test suite
    VpnOperations.Basic Suite Setup
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
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[2]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VM_INSTANCES}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_2_VM_INSTANCES}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VM_INSTANCES}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_2_VM_INSTANCES}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
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
    ${VM_IPv6_NET1} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_1_VM_INSTANCES}    network=@{NETWORKS}[0]    subnet=${prefix_net1}
    ${VM_IPv6_NET2} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_2_VM_INSTANCES}    network=@{NETWORKS}[1]    subnet=${prefix_net2}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IPv6_NET1}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{NET_1_VM_INSTANCES}[0]    30s
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IPv6_NET2}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{NET_2_VM_INSTANCES}[0]    30s
    OpenStackOperations.Copy DHCP Files From Control Node
    BuiltIn.Set Suite Variable    ${VM_IPv6_NET1}
    BuiltIn.Set Suite Variable    ${VM_IPv6_NET2}
    BuiltIn.Should Not Contain    ${VM_IPv6_NET1}    None
    BuiltIn.Should Not Contain    ${VM_IPv6_NET2}    None
    
Verify IPV6 NA responder flows
    [Arguments]    ${compute_node}    ${network}    ${port}
    [Documentation]    Verify NA responder flow tables in compute nodes
    ${port_id}    OpenStackOperations.Get Port Id    ${port}
    ${resp} =    RequestsLibrary.Get Request    session    restconf/operational/ietf-interfaces:interfaces-state/interface/${port_id}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    @{port_tag} =    String.Get_Regexp_Matches    ${resp.content}    \"if-index\":(\\d+)    1
    ${port_tag_hex_upper}    BuiltIn.Convert To Hex    ${port_tag}[0]
    ${port_tag_hex}    String.Convert To Lowercase    ${port_tag_hex_upper}
    ${elan_tag}    Get Elan Tag    ${network}
    ${port_meta}    BuiltIn.Set Variable    ${port_tag_hex}${elan_tag}
    ${flow_output} =    Utils.Run Command On Remote System    ${compute_node}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE} | grep table=${IPV6_TABLE} | grep ${port_meta} | grep type=135
    BuiltIn.Should Contain X Times    ${flow_output}    icmp_type=135    4
    ${flow_output} =    Utils.Run Command On Remote System    ${compute_node}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE} | grep table=${ARP_RESPONSE_TABLE} | grep ${port_meta} | grep type=136
    BuiltIn.Should Contain X Times    ${flow_output}    table=${ARP_RESPONSE_TABLE}    4

Get Elan Tag
    [Arguments]    ${network_name}
    ${net_id}    OpenStackOperations.Get Net Id    ${network_name}
    ${instances}    Utils.Get Data From URI    session      /restconf/config/elan:elan-instances/elan-instance/${net_id}
    ${tag1}=         String.Get Regexp Matches     ${instances}     "elan-tag":([0-9]+)    1
    ${elan_tags}    BuiltIn.Convert To Hex    @{tag1}[0]
    ${elan_meta}    String.Convert To Lowercase    ${elan_tags}
    [Return]    ${elan_meta}

Flow Verification with Elan Tag
    [Arguments]    ${network}    ${node_ip}    ${ipv6_src}
    [Documentation]    Show information of a given two port VM and grep for two ip address. VM name should be sent as arguments.
    ${elan_tag_output}   Get Elan Tag    ${network}
    ${elan_tag_with_space}   BuiltIn.Catenate    0x    ${elan_tag_output}
    ${elan_tag}    Remove Space on String    ${elan_tag_with_space}
    ${flow_output} =    Utils.Run Command On Remote System    ${node_ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE} | grep ${IPV6_TABLE} | grep icmp_type=135 | grep metadata=${elan_tag} | grep ipv6_src=::
    BuiltIn.Should Contain X Times    ${flow_output}    ipv6_src=::    ${ipv6_src}

Ipv6 Ping Verification
    [Documentation]    Verifying all the ipv4 and ipv6 ping between the VM's
    FOR   ${ip}   IN    @{VM_IPv6_NET1}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPv6_NET1}[0]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    FOR   ${ip}   IN    @{VM_IPv6_NET2}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPv6_NET1}[0]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    FOR   ${ip}   IN    @{VM_IPv6_NET1}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPv6_NET1}[1]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    FOR   ${ip}   IN    @{VM_IPv6_NET2}        
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPv6_NET1}[1]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    
    FOR   ${ip}   IN    @{VM_IPv6_NET1}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IPv6_NET2}[0]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    FOR   ${ip}   IN    @{VM_IPv6_NET2}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IPv6_NET2}[0]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    FOR   ${ip}   IN    @{VM_IPv6_NET1}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IPv6_NET2}[1]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END
    FOR   ${ip}   IN    @{VM_IPv6_NET2}
        ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IPv6_NET2}[1]    ping6 -c ${DEFAULT_PING_COUNT} ${ip}
        BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    END