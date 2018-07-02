*** Settings ***
Documentation     Test suite to validate ARP functionality for ACL_Enhancement feature.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
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
${BR_NAME}        br-int
${VIRTUAL_IP}     30.30.30.100/24
${TABLE_NO}       table=210
${PACKET_COUNT}    5
${RANDOM_IP}      11.11.11.11
${NETMASK}        255.255.255.0
${PACKET_COUNT_ZERO}    0
${INCOMPLETE}     incomplete
${FLOW_DUMP_CMD}    sudo ovs-ofctl dump-flows -O Openflow13 br-int
${DHCP_CMD}       sudo /sbin/cirros-dhcpc up eth1
@{SPOOF}          30.30.30.100
@{SPOOF_MAC_ADDRESS}    FA:17:3E:73:65:86    fa:16:3e:3d:3b:5e
${ARP_CONFIG}     sudo ifconfig eth0 down \n sudo ifconfig eth0 hw ether ${SPOOF_MAC_ADDRESS[0]} \n sudo ifconfig eth0 up
${ARP_CMD}        sudo arp -a
${timeout}        60

*** Test Cases ***
Verify ARP request Valid MAC and Valid IP for the VM Egress Table
    [Documentation]    Verify ARP request for Valid MAC and Valid IP and verify VM Egress Table
    Create Setup
    OpenStackOperations.Create Vm Instance With Ports    @{PORTS}[0]    @{PORTS}[1]    @{VM_NAMES}[0]    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Ports    @{PORTS}[2]    @{PORTS}[3]    @{VM_NAMES}[1]    ${OS_CMP2_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Ports    @{PORTS}[4]    @{PORTS}[5]    @{VM_NAMES}[2]    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=@{SECURITY_GROUP}[0]
    @{VM_IP_DPN1}    BuiltIn.Wait Until Keyword Succeeds    440 sec    60 sec    Get Two Port VM IP Address    ${OS_CMP1_CONN_ID}    @{VM_NAMES}[0]
    @{VM_IP_DPN2}    BuiltIn.Wait Until Keyword Succeeds    440 sec    60 sec    Get Two Port VM IP Address    ${OS_CMP2_CONN_ID}    @{VM_NAMES}[1]
    @{VM_IP_DPN3}    BuiltIn.Wait Until Keyword Succeeds    440 sec    60 sec    Get Two Port VM IP Address    ${OS_CMP1_CONN_ID}    @{VM_NAMES}[2]
    BuiltIn.Set Global Variable    @{VM_IP_DPN1}
    BuiltIn.Set Global Variable    @{VM_IP_DPN2}
    BuiltIn.Set Global Variable    @{VM_IP_DPN3}
    ${VM1_PORT}    In Port VM    ${OS_COMPUTE_1_IP}    @{PORTS}[0]
    ${VM2_PORT}    In Port VM    ${OS_COMPUTE_2_IP}    @{PORTS}[2]
    ${VM3_PORT}    In Port VM    ${OS_COMPUTE_1_IP}    @{PORTS}[4]
    ${VM1_METADATA}    OVSDB.Get Port Metadata    ${OS_COMPUTE_1_IP}    ${VM1_PORT}
    ${VM2_METADATA}    OVSDB.Get Port Metadata    ${OS_COMPUTE_2_IP}    ${VM2_PORT}
    ${VM3_METADATA}    OVSDB.Get Port Metadata    ${OS_COMPUTE_1_IP}    ${VM3_PORT}
    BuiltIn.Set Global Variable    ${VM1_METADATA}
    BuiltIn.Set Global Variable    ${VM2_METADATA}
    BuiltIn.Set Global Variable    ${VM3_METADATA}
    BuiltIn.Set Global Variable    ${VM1_PORT}
    BuiltIn.Set Global Variable    ${VM2_PORT}
    BuiltIn.Set Global Variable    ${VM3_PORT}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN1}[0]    ${DHCP_CMD}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN2}[0]    ${DHCP_CMD}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_DPN3}[0]    ${DHCP_CMD}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${cmd}    BuiltIn.Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    ${REQ_NETWORKS[1]}    @{VM_IP_DPN1}[1]    ${cmd}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${pkt_diff}    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed IP for the VM
    [Documentation]    Verify ARP request generated from spoofed IP for the VM
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${cmd}    BuiltIn.Set Variable    sudo ifconfig eth0:1 ${SPOOF[0]} netmask ${NETMASK} up
    ${output}    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN1[1]}
    ...    ${cmd}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_before}    OvsManager.Get Packet Count From Table    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep goto_table:217
    ${cmd}    BuiltIn.Set Variable    sudo arping -s ${SPOOF[0]} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    ${output}    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]
    ...    ${cmd}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    arp|grep goto_table:217
    ${pkt_diff_arp_drop}    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    ${pkt_diff}    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed MAC for the VM
    [Documentation]    Verify ARP request generated from Spoofed MAC for the VM
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Log    Change the Mac Address of eth1
    ${count}    String.Get Line Count    ${ARP_CONFIG}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    String.Get Line    ${ARP_CONFIG}    ${index}
    \    ${output}    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]
    \    ...    @{VM_IP_DPN1}[1]    ${cmd}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_before}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    arp|grep goto_table:217
    ${cmd}    BuiltIn.Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${cmd}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    arp|grep goto_table:217
    ${pkt_diff}    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop}    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

Verify ARP request generated from Spoofed IP and spoofed MAC for the VM
    [Documentation]    Verify ARP request generated from Spoofed IP and spoofed MAC for the VM
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_before}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    arp|grep goto_table:217
    ${cmd}    BuiltIn.Set Variable    sudo arping -s @{SPOOF}[0] -c ${PACKET_COUNT} \ ${RANDOM_IP}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${cmd}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    SSHLibrary.Execute Command    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    ${VM1_METADATA}|grep arp_sha
    ${get_arp_drop_pkt_after}    OvsManager.Get Packet Count From Table    ${OS_COMPUTE_1_IP}    ${BR_NAME}    ${TABLE_NO}    arp|grep goto_table:217
    ${pkt_diff}    BuiltIn.Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop}    BuiltIn.Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    BuiltIn.BuiltIn.Should.Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}
    Log    Get the vm mac address and put back the original
    ${cmd}    BuiltIn.Set Variable    sudo ifconfig eth0 down
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${cmd}
    ${cmd}    BuiltIn.Set Variable    sudo ifconfig eth0 hw ether @{SPOOF_MAC_ADDRESS}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${cmd}
    ${cmd}    BuiltIn.Set Variable    sudo ifconfig eth0 @{VM_IP_DPN1}[0]/24 up
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.SSHLibrary.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_DPN1}[1]    ${cmd}

*** Keywords ***
Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports
    Create Neutron Networks    2
    Create Neutron Subnets    2
    OpenStackOperations.Neutron Security Group Create    @{SECURITY_GROUP}[0]
    OpenStackOperations.Delete All Security Group Rules    @{SECURITY_GROUP}[0]
    : FOR    ${index}    IN RANGE    0    5
    \    ${index1}    BuiltIn.Evaluate    ${index}+1
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{PORTS}[${index}]    sg=@{SECURITY_GROUP}[0]
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{PORTS}[${index1}]    sg=@{SECURITY_GROUP}[0]
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    @{SECURITY_GROUP}[0]    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0

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
    \    Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${sub_list}    OpenStackOperations.List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${sub_list}    ${REQ_SUBNETS[${index}]}

In Port VM
    [Arguments]    ${ip_address}    ${portname}
    [Documentation]    Get the port number for given portname
    ${subportid}    OpenStackOperations.Get Sub Port Id    ${portname}
    ${vm_port}    OVSDB.Get Port Number    ${subportid}    ${ip_address}
    [Return]    ${vm_port}

Get Two Port VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    BuiltIn.Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4$5}'
    ${output} =    OpenStack CLI    ${cmd}
    @{output}    Split String    ${output}    ;
    ${output_string1}    Convert To String    @{output}[0]
    ${output_string2}    Convert To String    @{output}[1]
    @{net1_string}    Split String    ${output_string1}    =
    @{net2_string}    Split String    ${output_string2}    =
    @{final_list}    Create List    @{net1_string}[1]    @{net2_string}[1]
    [Return]    @{final_list}
