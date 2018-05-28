*** Settings ***
Documentation           Test Suite for Network and Subnet Broadcast with security group
Suite Setup             Start Suite
Suite Teardown          Stop Suite
Library                 String
Library                 RequestsLibrary
Library                 SSHLibrary
Library                 Collections
Library                 json
Library                 OperatingSystem
Resource                ../../../libraries/DevstackUtils.robot
Resource                ../../../libraries/KarafKeywords.robot
Resource                ../../../libraries/OpenStackOperations.robot
Resource                ../../../libraries/OVSDB.robot
Resource                ../../../libraries/SetupUtils.robot
Resource                ../../../libraries/Utils.robot
Resource                ../../../variables/Variables.robot
Resource                ../../../variables/netvirt/Variables.robot

*** Variables ***
@{SECURITY_GROUP}    sg1    sg2
@{NETWORKS}    sg_net_1    sg_net_2
@{SUBNETS}    sg_sub_1    sg_sub_2
@{SUBNET_CIDRS}    10.0.0.0/24    20.0.0.0/24
${ROUTER}    sg_router
@{PORTS_NET1}    sg_net1_port1    sg_net1_port2    sg_net1_port3
@{PORTS_NET2}    sg_net2_port1    sg_net2_port2
@{NET_1_VMS}    net_1_sg1_vm_1    net_1_sg1_vm_2    net_1_sg1_vm_3
@{NET_2_VMS}    net_2_sg1_vm_1    net_2_sg1_vm_2
${ACL_Anti_Spoofing_Table}    table=240
${ether_type}    IPv4
#${CIRROS_USER}     cirros
#${CIRRIOS_PASSWORD}    cubswin:)
${DUMP_FLOW}    sudo ovs-ofctl dump-flows br-int -OOPenflow13
${br_name}    br-int
${PACKET_COUNT}    5
${BCAST_IP}    255.255.255.255
${SUBNET1_BCAST_IP}    10.0.0.255
${SUBNET2_BCAST_IP}    20.0.0.255
${INGRESS_DISPATURE_TABLE}    table=220
#@{PORTS}    @{PORTS_NET1}[0]    @{PORTS_NET1}[1]    @{PORTS_NET1}[2]    @{PORTS_NET2}[0]    @{PORTS_NET2}[1]
#@{VMS}    @{NET_1_VMS}[0]    @{NET_1_VMS}[1]    @{NET_1_VMS}[2]    @{NET_2_VMS}[0]    @{NET_2_VMS}[1]
#@{NODES}    ${OS_CMP1_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}   ${OS_CMP2_HOSTNAME}
#@{VM_IPS}   VM1_NET1_DPN1_IP_Address    VM2_NET1_DPN1_IP_Address    VM3_NET1_DPN1_IP_Address    VM1_NET2_DPN1_IP_Address    VM2_NET2_DPN1_IP_Address
#@{VMPORTS}    VM1_Port    VM2_Port    VM3_Port    VM4_Port    VM5_Port
#@{CONN_IDS}    ${OS_CMP1_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}
#@{VMS_METADATA}   vm1_metadata    vm2_metadata    vm3_metadata    vm4_metadata    vm5_metadata


*** Test case ***
Verify Network Broadcast traffic between the VMs hosted on same compute node in Single Network
    [Documentation]      Verify Network Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${get_pkt_count_before_bcast} =     Bcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =     Bcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Network Broadcast traffic between the VMs hosted on Different compute node in Single Network
    [Documentation]      Verify Network Broadcast traffic between the VMs hosted on Different compute node in Single Network
    ${get_pkt_count_before_bcast} =     Bcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =     Bcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Network Broadcast traffic between the VMs hosted on same compute node in Multi Network
    [Documentation]      Verify L3 (Network) Broadcast traffic between the VMs hosted on same compute node in Multi Network
    ${get_pkt_count_before_bcast} =    Bcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =    Bcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Network Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    [Documentation]      Verify L3 (Network) Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    ${get_pkt_count_before_bcast} =    Bcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =     Bcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount     ${OS_COMPUTE_1_IP}     ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}   ${VM2_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET1_BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET1_BCAST_IP}| grep ${VM2_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_1_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}    ${VM2_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Single Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}   ${VM3_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET1_BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET1_BCAST_IP}| grep ${VM3_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}    ${VM3_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_1_IP}     ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}   ${VM4_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET2_BCAST_IP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET2_BCAST_IP}| grep ${VM4_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_1_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}    ${VM4_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}   ${VM5_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET2_BCAST_IP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET2_BCAST_IP}| grep ${VM5_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}    ${VM5_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

*** Keywords ***

Start Suite
    [Documentation]    Test Suite for CR156-Security Group Broadcast
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Create Setup
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    : FOR    ${i}    IN RANGE    2
    \    OpenStackOperations.Create SubNet    ${NETWORKS[${i}]}    ${SUBNETS[${i}]}    ${SUBNET_CIDRS[${i}]}
    OpenStackOperations.Create Allow All SecurityGroup    @{SECURITY_GROUP}[0]    ${ether_type}
    OpenStackOperations.Create Router       ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    : FOR    ${port_net1}    IN    @{PORTS_NET1}
    \    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port_net1}    sg=@{SECURITY_GROUP}[0]
    : FOR    ${port_net2}    IN    @{PORTS_NET2}
    \    OpenStackOperations.Create Port    @{NETWORKS}[1]    ${port_net2}    sg=@{SECURITY_GROUP}[0]

    @{PORTS}=    Create List    @{PORTS_NET1}[0]    @{PORTS_NET1}[1]    @{PORTS_NET1}[2]    @{PORTS_NET2}[0]    @{PORTS_NET2}[1]
    @{VMS}=    Create List    @{NET_1_VMS}[0]    @{NET_1_VMS}[1]    @{NET_1_VMS}[2]    @{NET_2_VMS}[0]    @{NET_2_VMS}[1]
    @{NODES}=    Create List    ${OS_CMP1_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}
    : FOR    ${port}    ${vm}    ${node}    IN ZIP    ${PORTS}    ${VMS}    ${NODES}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${port}    ${vm}    ${node}    sg=@{SECURITY_GROUP}[0]

    @{VMS}=    Create List   @{NET_1_VMS}    @{NET_2_VMS}
    @{VM_IPS}=    Create List    VM1_NET1_DPN1_IP_Address    VM2_NET1_DPN1_IP_Address    VM3_NET1_DPN1_IP_Address    VM1_NET2_DPN1_IP_Address    VM2_NET2_DPN1_IP_Address
    : FOR    ${vm_ips}    ${vms}     IN ZIP    ${VM_IPS}    ${VMS}
    \    ${temp}    ${ips_and_console_log[1]} =   BuiltIn.Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Get VM IPs     ${vms}
    \    BuiltIn.Set Suite Variable    ${${vm_ips}}    ${temp}
    \    log     ${${vm_ips}}

    @{VMPORTS}=    Create List   VM1_Port    VM2_Port    VM3_Port    VM4_Port    VM5_Port
    @{CONN_IDS}=    Create List    ${OS_CMP1_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}
    @{PORTS}=    Create List    @{PORTS_NET1}[0]    @{PORTS_NET1}[1]    @{PORTS_NET1}[2]    @{PORTS_NET2}[0]    @{PORTS_NET2}[1]
    : FOR    ${vmport}    ${conn_id}    ${port}    IN ZIP    ${VMPORTS}    ${CONN_IDS}    ${PORTS}
    \    ${temp} =   BuiltIn.Wait Until Keyword Succeeds    60s    10s    In Port VM    ${conn_id}     ${br_name}     ${port}
    \    BuiltIn.Set Suite Variable    ${${vmport}}    ${temp}
    \    log     ${${vmport}}

    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check In Port    ${VM1_Port}    ${OS_CMP1_CONN_ID}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check In Port    ${VM2_Port}    ${OS_CMP1_CONN_ID}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check In Port    ${VM3_Port}    ${OS_CMP2_CONN_ID}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check In Port    ${VM4_Port}    ${OS_CMP1_CONN_ID}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Check In Port    ${VM5_Port}    ${OS_CMP2_CONN_ID}
    
    
    ${VM1_In_Port}   ${VM1_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    ${VM1_Port}    ${OS_CMP1_CONN_ID}
    ${VM2_In_Port}   ${VM2_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    ${VM2_Port}    ${OS_CMP1_CONN_ID}
    ${VM3_In_Port}   ${VM3_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    ${VM3_Port}    ${OS_CMP2_CONN_ID}
    ${VM4_In_Port}   ${VM4_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    ${VM4_Port}    ${OS_CMP1_CONN_ID}
    ${VM5_In_Port}   ${VM5_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    ${VM5_Port}    ${OS_CMP2_CONN_ID}
    BuiltIn.Set Suite Variable    ${VM1_In_Port}   ${VM1_META}  
    BuiltIn.Set Suite Variable    ${VM2_In_Port}   ${VM2_META}
    BuiltIn.Set Suite Variable    ${VM3_In_Port}   ${VM3_META}
    BuiltIn.Set Suite Variable    ${VM4_In_Port}   ${VM4_META}
    BuiltIn.Set Suite Variable    ${VM5_In_Port}   ${VM5_META}
    
    Log Many    ${VM1_In_Port}   ${VM1_META}  
    Log Many    ${VM2_In_Port}   ${VM2_META}
    Log Many    ${VM3_In_Port}   ${VM3_META}
    Log Many    ${VM4_In_Port}   ${VM4_META}
    Log Many    ${VM5_In_Port}   ${VM5_META}
    
    @{VMS_METADATA}=    Create List   vm1_metadata    vm2_metadata    vm3_metadata    vm4_metadata    vm5_metadata
    @{CONN_IDS}=    Create List    ${OS_CMP1_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}
    @{VMPORTS}=    Create List   ${VM1_Port}    ${VM2_Port}    ${VM3_Port}    ${VM4_Port}    ${VM5_Port}
    : FOR    ${vm_metadata}    ${conn_id}    ${vmport}    IN ZIP    ${VMS_METADATA}    ${CONN_IDS}    ${VMPORTS}
    \    ${temp} =    Get Metadata    ${conn_id}    ${vmport}
    \    BuiltIn.Set Suite Variable    ${${vm_metadata}}    ${temp}
    \    log   ${${vm_metadata}}
#    ${VM1_DPN1_Enable_Bcast} =     BuiltIn.Wait Until Keyword Succeeds    60s    10s    Enable Broadcast Pings On VM    ${NETWORKS[0]}    ${VM1_NET1_DPN1_IP_Address}    ${CIRROS_USER}    ${CIRRIOS_PASSWORD}
    ${VM1_DPN1_Enable_Bcast} =     BuiltIn.Wait Until Keyword Succeeds    60s    10s    Enable Broadcast Pings On VM    ${NETWORKS[0]}    ${VM1_NET1_DPN1_IP_Address}   ${user}=cirros    ${password}=cubswin:)

    ${VM1_SUBMETA} =    Get Submetadata   ${vm1_metadata}
    ${VM2_SUBMETA} =    Get Submetadata   ${vm2_metadata}
    ${VM3_SUBMETA} =    Get Submetadata   ${vm3_metadata}
    ${VM4_SUBMETA} =    Get Submetadata   ${vm4_metadata}
    ${VM5_SUBMETA} =    Get Submetadata   ${vm5_metadata}

    BuiltIn.Set Suite Variable    ${VM1_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM2_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM3_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM4_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM5_SUBMETA}




Get VM IP
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    [Arguments]     ${vm_name}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4}'
    ${output} =    OpenStack CLI     ${cmd}
    @{z}    String.Split String    ${output}    =
    [Return]    ${z[1]}

Enable Broadcast Pings On VM
    [Arguments]    ${net_name}    ${src_ip}    ${user}    ${password}
    [Documentation]    Login to the vm instance and configure the Broadcast ping settings
    OpenStackOperations.Get ControlNode Connection
    ${net_id} =    OpenStackOperations.Get Net Id    ${net_name}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${user}@${src_ip} -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Utils.Write Commands Until Expected Prompt    sudo -s    ${OS_SYSTEM_PROMPT}
    Utils.Write Commands Until Expected Prompt    echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts    ${OS_SYSTEM_PROMPT}
    Utils.Write Commands Until Expected Prompt    exit && exit    ${OS_SYSTEM_PROMPT}
    #[Teardown]    Close Vm Instance

Bcast Packetcount
    [Arguments]    ${conn_id}    ${br_name}    ${TABLE_NO}   ${BCAST_IP}
    [Documentation]    Capture packetcount for network broadcast request
    Switch Connection    ${conn_id}
    ${output} =    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${TABLE_NO} | grep ${BCAST_IP}
    @{output_list} =    String.Split String    ${output}    \r\n
    ${flow} =    Get From List    ${output_list}     0
    ${packetcount_list} =    String.Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1
    ${count} =    Get From List    ${packetcount_list}    0
    [Return]    ${count}

SubnetBcast Packetcount
    [Arguments]    ${OS_COMPUTE_IP}    ${TABLE_NO}   ${SUBNET_BCAST_IP}    ${VM_SUBMETA}
    [Documentation]    Capture packetcount for subnet broadcast request
    #Switch Connection    ${conn_id}
    #${cmd} =   Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${TABLE_NO} | grep ${SUBNET_BCAST_IP}| grep ${VM_SUBMETA}
    #${output} =    OpenStackOperations.OpenStack CLI    ${cmd}
    #${output} =    DevstackUtils.Write Commands Until Prompt And Log    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${TABLE_NO} | grep ${SUBNET_BCAST_IP}| grep ${VM_SUBMETA}    20s
    #log    ${output}

    ${flow_output1} =    Run Command On Remote System And Log    ${OS_COMPUTE_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep ${TABLE_NO} | grep ${SUBNET_BCAST_IP}| grep ${VM_SUBMETA}
    log    ${flow_output1}
    @{output_list} =    String.Split String    ${flow_output1}    \r\n
    ${flow} =    Collections.Get From List    ${output_list}     0
    ${packetcount_list} =    Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1
    ${count} =    Collections.Get From List    ${packetcount_list}    0
    [Return]    ${count}

Get Port Id
    [Arguments]    ${port_name}    ${conn_id}
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack port list | grep "${port_name}" | awk '{print $2}'
    ${output}    OpenStack CLI    ${cmd}
    Log    ${output}
    ${splitted_output}    Split String    ${output}    ${EMPTY}
    ${port_id}    Get from List    ${splitted_output}    0
    Log    ${port_id}
    [Return]    ${port_id}

Get Sub Port Id
    [Arguments]    ${portname}    ${conn_id}
    [Documentation]    Get the Sub Port ID
    #${port_id} =    OpenStackOperations.Get Port Id    ${portname}
    ${port_id} =    Get Port Id    ${portname}    ${conn_id}
    Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{output} =    String.Get Regexp Matches    ${port_id}    (\\w{8}-\\w{2})
    [Return]    ${output[0]}

Get Port Number
    [Arguments]    ${connec_id}     ${br_name}    ${portname}
    [Documentation]    Get the port number for given portname
    SSHLibrary.Switch Connection    ${connec_id}
    ${pnum} =     Get Sub Port Id    ${portname}    ${connec_id}
    Sleep    30
    ${command_1} =    Set Variable    sudo ovs-ofctl dump-ports-desc br-int -OOPenflow13 | grep ${pnum} | awk '{print$1}'
    ${num} =   Utils.Write Commands Until Expected Prompt    ${command_1}    ${DEFAULT_LINUX_PROMPT}
    log    ${num}
    ${port_number} =     BuiltIn.Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    [Return]    ${port_number}

In Port VM
    [Arguments]    ${conn_id}    ${br_name}    ${portname}
    [Documentation]    Get the port number for given portname
    ${VM_Port} =    Get Port Number    ${conn_id}    ${br_name}    ${portname}
    [Return]    ${VM_port}

Check In Port
    [Arguments]    ${port}    ${conn_id}
    [Documentation]    Check the port present in table 0
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd} =    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0
    ${output} =    DevstackUtils.Write Commands Until Prompt   ${cmd}    60
    log    ${output}
    should contain    ${output}    in_port=${port}

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    Switch Connection    ${conn_id}
    ${grep_metadata} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}| grep table=0 | grep in_port=${port} | awk '{print$7}'    ${DEFAULT_LINUX_PROMPT}    30s
    @{metadata} =    Split string    ${grep_metadata}    ,
    ${index1} =    get from list    ${metadata}    0
    @{complete_meta} =    Split string    ${index1}    :
    ${m_data} =    get from list    ${complete_meta}    1
    log    ${m_data}
    @{split_meta} =    Split string    ${m_data}    /
    ${only_meta} =    get from list    ${split_meta}    0
    log    ${only_meta}
    [Return]    ${only_meta}

Get Submetadata
    [Arguments]    ${vm_Full_metadata}
    [Documentation]    Get the submetadata of the VM
    ${cmd1} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE1_IP}    ${DUMP_FLOW} | grep ${INGRESS_DISPATURE_TABLE} | grep write_metadata:
    Log    ${cmd1}
    ${output1} =    String.Get Regexp Matches    ${cmd1}    reg6=(\\w+)    1
    ${cmd2} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE2_IP}    ${DUMP_FLOW} | grep ${INGRESS_DISPATURE_TABLE} | grep write_metadata:
    log    ${cmd2}
    ${output2} =    String.Get Regexp Matches    ${cmd2}    reg6=(\\w+)    1
    ${metalist} =    Combine Lists     ${output1}    ${output2}
    : FOR    ${meta}    IN     @{metalist}
    \   ${metadata_check_status} =    Run Keyword And Return Status    should contain    ${vm_Full_metadata}    ${meta}
    \    Return From Keyword if    ${metadata_check_status} == True    ${meta}

 Get VMs Metadata and In Port
    [Arguments]    ${portname}    ${conn_id}
    [Documentation]    This keyword is to get the VM metadata and the in_port Id of the VM
    SSHLibrary.Switch Connection    ${conn_id}
    ${port_id} =    OpenStackOperations.Get Port Id    ${portname}
    BuiltIn.Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{subport} =    String.Get Regexp Matches    ${port_id}    (\\w{8}-\\w{2})
    ${cmd} =    Builtin.Set Variable    sudo ovs-ofctl dump-ports-desc br-int -OOPenflow13 | grep @{subport}[0] | awk '{print$1}'
    ${get_vm_in_port} =   Utils.Write Commands Until Expected Prompt    ${cmd}     ${DEFAULT_LINUX_PROMPT}
    ${vms_in_port} =     BuiltIn.Should Match Regexp    ${get_vm_in_port}    [0-9]+
#    ${grep_metadata} =    Write Commands Until Expected Prompt    ${DUMP_FLOW}| grep table=0 | grep in_port=${vms_in_port}    ${DEFAULT_LINUX_PROMPT}    30s
#    ${vm_metadatalist} =    String.Get Regexp Matches    ${grep_metadata}    actions=((\\w+):(\\w+))    3  
#    ${vm_metadata} =    Get From List    ${vm_metadatalist}    0
    ${grep_metadata} =    Write Commands Until Expected Prompt    ${DUMP_FLOW}| grep table=0 | grep in_port=${vms_in_port} | awk '{print$7}'    ${DEFAULT_LINUX_PROMPT}    30s
    @{metadata} =    String.Split string    ${grep_metadata}    ,
    ${get_write_metadata} =    Collections.get from list    ${metadata}    0
    @{complete_metadata} =    Split string    ${get_write_metadata}    :
    ${extract_metadata} =    Collections.get from list    ${complete_metadata}    1
    @{split_metadata} =    String.Split string    ${extract_metadata}    /
    ${vm_metadata} =    Collections.get from list    ${split_metadata}    0
    [Return]   ${vms_in_port}    ${vm_metadata} 

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

