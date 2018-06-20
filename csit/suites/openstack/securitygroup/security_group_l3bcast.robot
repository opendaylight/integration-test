*** Settings ***
Documentation     Test Suite for Network and Subnet Broadcast with security group
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Library           String
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           json
Library           OperatingSystem
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{SECURITY_GROUP}    sgbcast1    sgbcast2
@{NETWORKS}       sgbcast_net_1    sgbcast_net_2
@{SUBNETS}        sgbcast_sub_1    sgbcast_sub_2
@{SUBNET_CIDRS}    55.0.0.0/24    56.0.0.0/24
${ROUTER}         sgbcast_router
@{PORTS_NET1}     sgbcast_net1_port1    sgbcast_net1_port2    sgbcast_net1_port3
@{PORTS_NET2}     sgbcast_net2_port1    sgbcast_net2_port2
@{NET_1_VMS}      sgbcast_net1_vm1    sgbcast_net1_vm2    sgbcast_net1_vm3
@{NET_2_VMS}      sgbcast_net2_vm1    sgbcast_net2_vm2
${DUMP_FLOW}      sudo ovs-ofctl dump-flows br-int -OOPenflow13
${DUMP_PORT_DESC}    sudo ovs-ofctl dump-ports-desc br-int -OOPenflow13
${PACKET_COUNT}    5
${BCAST_IP}       255.255.255.255
${SUBNET1_BCAST_IP}    10.0.0.255
${SUBNET2_BCAST_IP}    20.0.0.255
${ENABLE_BCAST}    echo 0 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

*** Test case ***
Verify Network Broadcast traffic between the VMs hosted in Single Network
    [Documentation]    This TC is to verify Network Broadcast traffic between the VMs hosted in Same Network on same/different compute node.
    Check L3Broadcast in Same Subnet    ${OS_COMPUTE1_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}

Verify Network Broadcast traffic between the VMs hosted in Multi Network
    [Documentation]    This TC is to verify Network Broadcast traffic between the VMs hosted in Different Network on same/different compute node.
    Check L3Broadcast in Different Subnet    ${OS_COMPUTE1_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Network and Subnet Broadcast with security group
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Create Setup
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    : FOR    ${i}    IN RANGE    2
    \    OpenStackOperations.Create SubNet    ${NETWORKS[${i}]}    ${SUBNETS[${i}]}    ${SUBNET_CIDRS[${i}]}
    OpenStackOperations.Create Allow All SecurityGroup    @{SECURITY_GROUP}[0]
    OpenStackOperations.Create Router    ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    : FOR    ${port_net1}    IN    @{PORTS_NET1}
    \    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port_net1}    sg=@{SECURITY_GROUP}[0]
    : FOR    ${port_net2}    IN    @{PORTS_NET2}
    \    OpenStackOperations.Create Port    @{NETWORKS}[1]    ${port_net2}    sg=@{SECURITY_GROUP}[0]
    @{ports} =    BuiltIn.Create List    @{PORTS_NET1}[0]    @{PORTS_NET1}[1]    @{PORTS_NET1}[2]    @{PORTS_NET2}[0]    @{PORTS_NET2}[1]
    @{vms} =    BuiltIn.Create List    @{NET_1_VMS}[0]    @{NET_1_VMS}[1]    @{NET_1_VMS}[2]    @{NET_2_VMS}[0]    @{NET_2_VMS}[1]
    @{nodes} =    BuiltIn.Create List    ${OS_CMP1_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}
    : FOR    ${port}    ${vm}    ${node}    IN ZIP    ${ports}    ${vms}
    ...    ${nodes}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${port}    ${vm}    ${node}    sg=@{SECURITY_GROUP}[0]
    @{vms} =    BuiltIn.Create List    @{NET_1_VMS}[0]    @{NET_1_VMS}[1]    @{NET_1_VMS}[2]    @{NET_2_VMS}[0]    @{NET_2_VMS}[1]
    @{vm_ips} =    OpenStackOperations.Get VM IPs    @{vms}
    ${VM1_DPN1_Enable_Bcast} =    OpenStackOperations.Execute Command on VM Instance    ${NETWORKS[0]}    @{vm_ips}[0]    ${ENABLE_BCAST}
    ${VM3_DPN1_Enable_Bcast} =    OpenStackOperations.Execute Command on VM Instance    ${NETWORKS[1]}    @{vm_ips}[3]    ${ENABLE_BCAST}
    ${VM1_In_Port}    ${VM1_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET1}[0]
    ...    ${OS_COMPUTE_1_IP}
    ${VM2_In_Port}    ${VM2_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET1}[1]
    ...    ${OS_COMPUTE_1_IP}
    ${VM3_In_Port}    ${VM3_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET1}[2]
    ...    ${OS_COMPUTE_2_IP}
    ${VM4_In_Port}    ${VM4_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET2}[0]
    ...    ${OS_COMPUTE_1_IP}
    ${VM5_In_Port}    ${VM5_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET2}[1]
    ...    ${OS_COMPUTE_2_IP}
    ${VM1_SUBMETA} =    Get Submetadata    ${VM1_META}
    ${VM2_SUBMETA} =    Get Submetadata    ${VM2_META}
    ${VM3_SUBMETA} =    Get Submetadata    ${VM3_META}
    ${VM4_SUBMETA} =    Get Submetadata    ${VM4_META}
    ${VM5_SUBMETA} =    Get Submetadata    ${VM5_META}
    BuiltIn.Set Suite Variable    ${VM1_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM2_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM3_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM4_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM5_SUBMETA}

Get Broadcast Packet Count
    [Arguments]    ${OS_COMPUTE_IP}    ${TABLE_NO}    ${BCAST_IP}
    [Documentation]    Capture packetcount for network broadcast request
    ${output} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=${TABLE_NO} | grep ${BCAST_IP}
    @{output_list} =    String.Split String    ${output}    \r\n
    ${flow} =    C0llections.Get From List    ${output_list}    0
    ${packetcount_list} =    String.Get Regexp Matches    ${flow}    n_packets=([0-9]+)    1
    ${count} =    C0llections.Get From List    ${packetcount_list}    0
    [Return]    ${count}

Get VMs Metadata and In Port
    [Arguments]    ${portname}    ${OS_COMPUTE_IP}
    [Documentation]    This keyword is to get the VM metadata and the in_port Id of the VM
    ${subport} =    OpenStackOperations.Get Sub Port Id    ${portname}
    ${get_vm_in_port} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_PORT_DESC} | grep ${subport}| awk '{print$1}'
    ${vms_in_port} =    BuiltIn.Should Match Regexp    ${get_vm_in_port}    [0-9]+
    ${grep_metadata} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=${VLAN_INTERFACE_INGRESS_TABLE} | grep in_port=${vms_in_port} | awk '{print$7}'
    @{metadata} =    String.Split string    ${grep_metadata}    ,
    ${get_write_metadata} =    Collections.get from list    ${metadata}    0
    @{complete_metadata} =    String.Split string    ${get_write_metadata}    :
    ${extract_metadata} =    Collections.get from list    ${complete_metadata}    1
    @{split_metadata} =    String.Split string    ${extract_metadata}    /
    ${vm_metadata} =    Collections.Get From List    ${split_metadata}    0
    [Return]    ${vms_in_port}    ${vm_metadata}

Get Submetadata
    [Arguments]    ${vm_metadata}
    [Documentation]    Get the submetadata of the VM
    ${cmd1} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE1_IP}    ${DUMP_FLOW} | grep ${EGRESS_LPORT_DISPATCHER_TABLE} | grep write_metadata:
    ${output1} =    String.Get Regexp Matches    ${cmd1}    reg6=(\\w+)    1
    ${cmd2} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE2_IP}    ${DUMP_FLOW} | grep ${EGRESS_LPORT_DISPATCHER_TABLE} | grep write_metadata:
    ${output2} =    String.Get Regexp Matches    ${cmd2}    reg6=(\\w+)    1
    ${metalist} =    Collections.Combine Lists    ${output1}    ${output2}
    : FOR    ${meta}    IN    @{metalist}
    \    ${metadata_check_status} =    Run Keyword And Return Status    should contain    ${vm_metadata}    ${meta}
    \    Return From Keyword if    ${metadata_check_status} == True    ${meta}

Check L3Broadcast in Same Subnet
    [Arguments]    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    [Documentation]    Verify the l3 broadcast requests are hitting to antispoofing table in same subnet
    ${get_pkt_count_before_bcast} =    Get Broadcast Packet Count    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{vm_ips}[0]    ping -c ${PACKET_COUNT} ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=${EGRESS_ACL_TABLE} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =    Get Broadcast Packet Count    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Check L3Broadcast in Different Subnet
    [Arguments]    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    [Documentation]    Verify the l3 broadcast requests are hitting to antispoofing table in different subnet
    ${get_pkt_count_before_bcast} =    Get Broadcast Packet Count    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{vm_ips}[3]    ping -c ${PACKET_COUNT} ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=${EGRESS_ACL_TABLE} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =    Get Broadcast Packet Count    ${OS_COMPUTE_IP}    ${EGRESS_ACL_TABLE}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

Stop Suite
    [Documentation]    Delete the created VMs, ports, subnet and networks
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    OpenStackOperations.Remove Interface    ${ROUTER}    @{SUBNETS}[0]
    OpenStackOperations.Remove Interface    ${ROUTER}    @{SUBNETS}[1]
    OpenStackOperations.Delete Router    ${ROUTER}
    @{vms} =    BuiltIn.Create List    @{NET_1_VMS}    @{NET_2_VMS}
    @{sgs} =    BuiltIn.Create List    @{SECURITY_GROUP}
    @{PORTS} =    BuiltIn.Create List    @{PORTS_NET1}    @{PORTS_NET2}
    OpenStackOperations.Neutron Cleanup    ${vms}    ${NETWORKS}    ${SUBNETS}    ${PORTS}    ${sgs}
