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
@{PORTS}          acl_port_1    acl_port_2    acl_port_3    acl_port_4    acl_port_5    acl_port_6
@{VM_NAMES}       acl_myvm_1    acl_myvm_2    acl_myvm_3
@{SECURITY_GROUP}    acl_sg_1
${VIRTUAL_IP}     30.30.30.100/24
${PACKET_COUNT}    5
${RANDOM_IP}      11.11.11.11
${NETMASK}        255.255.255.0
${PACKET_COUNT_ZERO}    0
${DHCP_CMD}       sudo /sbin/cirros-dhcpc up eth1
${SPOOF}          30.30.30.100
@{SPOOF_MAC_ADDRESS}    FA:17:3E:73:65:86    fa:16:3e:3d:3b:5e
${ARP_CONFIG}     sudo ifconfig eth0 down \n sudo ifconfig eth0 hw ether ${SPOOF_MAC_ADDRESS[0]} \n sudo ifconfig eth0 up
${timeout}        60

*** Test Cases ***
Verify ARP request Valid MAC and Valid IP for the VM Egress Table
    [Documentation]    Verifying ARP resquest resolved for Valid MAC and Valid IP at the VM Egress Table
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN1}[0]    ${DHCP_CMD}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN2}[0]    ${DHCP_CMD}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    ${REQ_NETWORKS[1]}    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed IP for the VM
    [Documentation]    Verifying ARP resquest generated for Spoofed IP with Valid MAC and Validate the packet drop at the VM Egress Table
    ${arp_int_up_cli} =    BuiltIn.Set Variable    sudo ifconfig eth0:1 ${SPOOF} netmask ${NETMASK} up
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]
    ...    ${arp_int_up_cli}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_before}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep arp|grep goto_table:217
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -s ${SPOOF} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]
    ...    ${arping_cli}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep arp|grep goto_table:217
    ${pkt_diff_arp_drop} =    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed MAC for the VM
    [Documentation]    Verifying ARP resquest generated for Spoofed MAC with Valid IP and Validate the ARP packet drop at the VM Egress Table
    ${count} =    String.Get Line Count    ${ARP_CONFIG}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd} =    String.Get Line    ${ARP_CONFIG}    ${index}
    \    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]
    \    ...    @{VM_IP_DPN1}[1]    ${cmd}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_before}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep arp|grep goto_table:217
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep arp|grep goto_table:217
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop} =    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed IP and spoofed MAC for the VM
    Documentation]    Verifying ARP resquest generated for Spoofed MAC with Spoofed IP and Validate the ARP packet drop at the VM Egress Table
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_before}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep arp|grep goto_table:217
    ${arping_cli} =    BuiltIn.Set Variable    sudo arping -s ${SPOOF} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${arping_cli}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${INTEGRATION_BRIDGE}    table=@{DEFAULT_FLOW_TABLES}[15]    | grep arp|grep goto_table:217
    ${pkt_diff} =    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop} =    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup to for CR156 ACL Enhancement
    OpenStackOperations.OpenStack Suite Setup
    Create Setup

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports
    Create Neutron Networks    2
    Create Neutron Subnets    2
    OpenStackOperations.Neutron Security Group Create    @{SECURITY_GROUP}[0]
    OpenStackOperations.Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{PORTS}[0]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{PORTS}[1]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{PORTS}[2]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{PORTS}[3]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Allow All SecurityGroup    @{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[0]    @{PORTS}[1]    @{VM_NAMES}[0]    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    @{PORTS}[2]    @{PORTS}[3]    @{VM_NAMES}[1]    ${OS_CMP2_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    @{VM_IP_DPN1} =    BuiltIn.Wait Until Keyword Succeeds    440 sec    30 sec    OpenStackOperations.Get Two Port VM IP Address    ${OS_CMP1_CONN_ID}    @{VM_NAMES}[0]
    @{VM_IP_DPN2} =    BuiltIn.Wait Until Keyword Succeeds    440 sec    30 sec    OpenStackOperations.Get Two Port VM IP Address    ${OS_CMP2_CONN_ID}    @{VM_NAMES}[1]
    BuiltIn.Set Suite Variable    @{VM_IP_DPN1}
    BuiltIn.Set Suite Variable    @{VM_IP_DPN2}
    ${VM1_PORT} =    Get Vm Port    ${OS_COMPUTE_1_IP}    @{PORTS}[0]
    ${VM1_METADATA} =    OVSDB.Get Port Metadata    ${OS_COMPUTE_1_IP}    ${VM1_PORT}
    BuiltIn.Set Suite Variable    ${VM1_METADATA}

Create Neutron Networks
    [Arguments]    ${num_of_network}
    [Documentation]    Create required number of networks
    : FOR    ${net}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${net}
    ${net_list}    OpenStackOperations.List Networks
    : FOR    ${index}    IN RANGE    0    ${num_of_network}
    \    BuiltIn.Should Contain    ${net_list}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${sub_list}    OpenStackOperations.List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${sub_list}    ${REQ_SUBNETS[${index}]}

Get Vm Port
    [Arguments]    ${ip_address}    ${portname}
    [Documentation]    Get the port number for given portname
    ${subportid} =    OpenStackOperations.Get Sub Port Id    ${portname}
    ${vm_port} =    OVSDB.Get Port Number    ${subportid}    ${ip_address}
    [Return]    ${vm_port}
