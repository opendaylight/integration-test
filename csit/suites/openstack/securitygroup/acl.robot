*** Settings ***
Documentation     Test suite to validate ARP functionality for ACL_Enhancement feature.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{REQ_NETWORKS}    acl_net_1    acl_net_2
@{REQ_SUBNETS}    acl_subnet_1    acl_subnet_2
@{REQ_SUBNET_CIDR}    30.30.30.0/24    40.40.40.0/24
@{PORTS}          acl_port_1    acl_port_2    acl_port_3    acl_port_4
@{VM_NAMES}       acl_myvm_1    acl_myvm_2
@{SECURITY_GROUP}    acl_sg_1
${VIRTUAL_IP}     30.30.30.100/24
${PACKET_COUNT}    5
${RANDOM_IP}      11.11.11.11
${NETMASK}        255.255.255.0
${PACKET_COUNT_ZERO}    0
${DHCP_CMD}       sudo /sbin/cirros-dhcpc up eth1
${SPOOF_IP}       30.30.30.100
@{SPOOF_MAC_ADDRESSES}    FA:17:3E:73:65:86    fa:16:3e:3d:3b:5e
${ARP_CONFIG}     sudo ifconfig eth0 down \n sudo ifconfig eth0 hw ether ${SPOOF_MAC_ADDRESSES[0]} \n sudo ifconfig eth0 up
${ARP_SHA}        arp_sha
${ARP}            arp
${TABLE}          goto_table:217

*** Test Cases ***
Verify ARP request Valid MAC and Valid IP for the VM Egress Table
    [Documentation]    Verifying ARP resquest resolved for Valid MAC and Valid IP at the VM Egress Table
    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN1}[0]    ${DHCP_CMD}
    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN2}[0]    ${DHCP_CMD}
    ${get_pkt_count_before_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    OpenStackOperations.Execute Command on VM Instance    ${REQ_NETWORKS[1]}    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed IP for the VM
    [Documentation]    Verifying ARP resquest generated for Spoofed IP with Valid MAC and Validate the packet drop at the VM Egress Table
    ${arp_int_up_cli} =    BuiltIn.Set Variable    sudo ifconfig eth0:1 ${SPOOF_IP} netmask ${NETMASK} up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${arp_int_up_cli}
    ${get_pkt_count_before_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${get_arp_drop_pkt_before} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${ARP}.*${TABLE}
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -s ${SPOOF_IP} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${ARP}.*${TABLE}
    ${pkt_diff_arp_drop} =    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed MAC for the VM
    [Documentation]    Verifying ARP resquest generated for Spoofed MAC with Valid IP and Validate the ARP packet drop at the VM Egress Table
    ${count} =    String.Get Line Count    ${ARP_CONFIG}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd} =    String.Get Line    ${ARP_CONFIG}    ${index}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${cmd}
    ${get_pkt_count_before_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${get_arp_drop_pkt_before} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${ARP}.*${TABLE}
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${ARP}.*${TABLE}
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop} =    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed IP and spoofed MAC for the VM
    [Documentation]    Verifying ARP resquest generated for Spoofed MAC with Spoofed IP and Validate the ARP packet drop at the VM Egress Table
    ${get_pkt_count_before_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${get_arp_drop_pkt_before} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${ARP}.*${TABLE}
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -s ${SPOOF_IP} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}.*${ARP_SHA}
    ${get_arp_drop_pkt_after} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${ARP}.*${TABLE}
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop} =    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup for ACL_Enhancement feature
    OpenStackOperations.OpenStack Suite Setup
    Create Setup

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports
    Create Multiple Networks    @{REQ_NETWORKS}
    Create Multiple Subnets    ${REQ_NETWORKS}    ${REQ_SUBNETS}    ${REQ_SUBNET_CIDR}
    OpenStackOperations.Neutron Security Group Create    @{SECURITY_GROUP}[0]
    OpenStackOperations.Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{PORTS}[0]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{PORTS}[1]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{PORTS}[2]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{PORTS}[3]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=icmp    remote_ip=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=icmp    remote_ip=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[0]    @{PORTS}[1]    @{VM_NAMES}[0]    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[2]    @{PORTS}[3]    @{VM_NAMES}[1]    ${OS_CMP2_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    : FOR    ${vm}    IN    @{VM_NAMES}
    \    OpenStackOperations.Poll VM Is ACTIVE    ${vm}
    @{VM_IP_DPN1} =    BuiltIn.Wait Until Keyword Succeeds    300 sec    15 sec    OpenStackOperations.Get All VM IP Addresses    ${OS_CMP1_CONN_ID}    @{VM_NAMES}[0]
    @{VM_IP_DPN2} =    BuiltIn.Wait Until Keyword Succeeds    300 sec    15 sec    OpenStackOperations.Get All VM IP Addresses    ${OS_CMP2_CONN_ID}    @{VM_NAMES}[1]
    BuiltIn.Set Suite Variable    @{VM_IP_DPN1}
    BuiltIn.Set Suite Variable    @{VM_IP_DPN2}
    : FOR    ${ip}    IN    @{VM_IP_DPN1}
    \    BuiltIn.Should Not Contain    ${ip}    None
    : FOR    ${ip}    IN    @{VM_IP_DPN2}
    \    BuiltIn.Should Not Contain    ${ip}    None
    ${VM1_PORT} =    Get VMs OVS Port Number    ${OS_CMP1_IP}    @{PORTS}[0]
    ${VM1_METADATA} =    OVSDB.Get Port Metadata    ${OS_CMP1_IP}    ${VM1_PORT}
    BuiltIn.Set Suite Variable    ${VM1_METADATA}
