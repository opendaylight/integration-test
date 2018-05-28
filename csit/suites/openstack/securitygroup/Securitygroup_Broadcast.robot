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
${CIRROS_USER}     cirros
${CIRRIOS_PASSWORD}    cubswin:)
${DUMP_FLOW}    sudo ovs-ofctl dump-flows br-int -OOPenflow13
${br_name}    br-int
${PACKET_COUNT}    5
${BCAST_IP}    255.255.255.255
${SUBNET1_BCAST_IP}    10.0.0.255
${SUBNET2_BCAST_IP}    20.0.0.255

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
    ${VM2_SUBMETA} =    Get Substring    ${vm2_metadata}   0    7
    ${get_pkt_count_before_bcast} =    SubnetBcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}   ${VM2_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET1_BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET1_BCAST_IP}| grep ${VM2_SUBMETA}
    ${get_pkt_count_after_bcast} =    SubnetBcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}    ${VM2_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Single Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${VM3_SUBMETA}    Get Substring    ${vm3_metadata}   0    7
    ${get_pkt_count_before_bcast} =    SubnetBcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}   ${VM3_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET1_BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET1_BCAST_IP}| grep ${VM3_SUBMETA}
    ${get_pkt_count_after_bcast} =    SubnetBcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}    ${VM3_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    ${VM4_SUBMETA} =    Get Substring    ${vm4_metadata}   0    7
    ${get_pkt_count_before_bcast} =    SubnetBcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}   ${VM4_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET2_BCAST_IP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET2_BCAST_IP}| grep ${VM4_SUBMETA}
    ${get_pkt_count_after_bcast} =    SubnetBcast Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}    ${VM4_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    ${VM5_SUBMETA}    Get Substring    ${vm5_metadata}   0    7
    ${get_pkt_count_before_bcast} =    SubnetBcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}   ${VM5_SUBMETA}
    ${output} =    Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET2_BCAST_IP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET2_BCAST_IP}| grep ${VM5_SUBMETA}
    ${get_pkt_count_after_bcast} =    SubnetBcast Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}    ${VM5_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

*** Keywords ***

Start Suite
    [Documentation]    Test Suite for CR156-Security Group Broadcast
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Create Setup
    OpenStackOperations.Create Nano Flavor
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
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${port}    ${vm}    ${node}

    sleep    300

#    Log    Code for CSIT
#    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
#    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
#    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
#    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
#    ${VM1_NET1_DPN1_IP_Address}    ${dhcp_ip}    ${vm_console_output} =    Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Get VM IP    true     @{NET_1_VMS}[0]
#    ${VM2_NET1_DPN1_IP_Address}    ${dhcp_ip}    ${vm_console_output} =    Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Get VM IP    true     @{NET_1_VMS}[1]
#    ${VM3_NET1_DPN2_IP_Address}    ${dhcp_ip}    ${vm_console_output} =    Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Get VM IP    true     @{NET_1_VMS}[2]
#    @{NET_1_VM_IPS}    ${ips_and_console_log[1]} =    Wait Until Keyword Succeeds    60s    10s    OpenStackOperations.Get VM IPs    @{NET_1_VMS}


    ${VM1_NET1_DPN1_IP_Address} =    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NET_1_VMS}[0]
    ${VM2_NET1_DPN1_IP_Address} =    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NET_1_VMS}[1]
    ${VM3_NET1_DPN2_IP_Address} =    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NET_1_VMS}[2]
    ${VM1_NET2_DPN1_IP_Address} =    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NET_2_VMS}[0]
    ${VM2_NET2_DPN1_IP_Address} =    Wait Until Keyword Succeeds    240s    10s    Get VM IP    @{NET_2_VMS}[1]

    BuiltIn.Set Suite Variable    ${VM1_NET1_DPN1_IP_Address}
    BuiltIn.Set Suite Variable    ${VM2_NET1_DPN1_IP_Address}
    BuiltIn.Set Suite Variable    ${VM3_NET1_DPN2_IP_Address}
    BuiltIn.Set Suite Variable    ${VM1_NET2_DPN1_IP_Address}
    BuiltIn.Set Suite Variable    ${VM2_NET2_DPN1_IP_Address}

    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    @{NET_1_VMS}[0]
    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    @{NET_1_VMS}[1]
    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    @{NET_1_VMS}[2]
    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    @{NET_2_VMS}[0]
    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    @{NET_2_VMS}[1]


    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack server show @{NET_1_VMS}[0]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack console log show @{NET_1_VMS}[0]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack server show @{NET_1_VMS}[1]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack console log show @{NET_1_VMS}[1]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack server show @{NET_1_VMS}[2]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack console log show @{NET_1_VMS}[2]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack server show @{NET_2_VMS}[0]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack console log show @{NET_2_VMS}[0]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack server show @{NET_2_VMS}[1]
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    420s    10s    OpenStack CLI    openstack console log show @{NET_2_VMS}[1]

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


    @{VMS_METADATA}=    Create List   vm1_metadata    vm2_metadata    vm3_metadata    vm4_metadata    vm5_metadata
    @{CONN_IDS}=    Create List    ${OS_CMP1_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}
    @{VMPORTS}=    Create List   ${VM1_Port}    ${VM2_Port}    ${VM3_Port}    ${VM4_Port}    ${VM5_Port}
    : FOR    ${vm_metadata}    ${conn_id}    ${vmport}    IN ZIP    ${VMS_METADATA}    ${CONN_IDS}    ${VMPORTS}
    \    ${temp} =    Get Metadata    ${conn_id}    ${vmport}
    \    BuiltIn.Set Suite Variable    ${${vm_metadata}}    ${temp}
    \    log   ${${vm_metadata}}
    ${VM1_DPN1_Enable_Bcast}    Wait Until Keyword Succeeds    60s    10s    Enable Broadcast Pings On VM    ${NETWORKS[0]}    ${VM1_NET1_DPN1_IP_Address}    ${CIRROS_USER}    ${CIRRIOS_PASSWORD}

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
    [Teardown]    Close Vm Instance

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
    [Arguments]    ${conn_id}    ${br_name}    ${TABLE_NO}   ${SUBNET_BCAST_IP}    ${VM_SUBMETA}
    [Documentation]    Capture packetcount for subnet broadcast request
    Switch Connection    ${conn_id}
    ${output} =    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${TABLE_NO} | grep ${SUBNET_BCAST_IP}| grep ${VM_SUBMETA}
    @{output_list} =    String.Split String    ${output}    \r\n
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
    ${num} =   Utils.Write Commands Until Expected Prompt    ${command_1}    $
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

Stop Suite
    [Documentation]    Delete the created VMs, ports, subnet and networks
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    OpenStackOperations.OpenStack CLI    openstack flavor delete m1.nano
    OpenStackOperations.Remove Interface    ${ROUTER}    @{SUBNETS}[0]
    OpenStackOperations.Remove Interface    ${ROUTER}    @{SUBNETS}[1]
    OpenStackOperations.Delete Router    ${ROUTER}
    @{vms} =    BuiltIn.Create List    @{NET_1_VMS}    @{NET_2_VMS}
    @{sgs} =    BuiltIn.Create List    @{SECURITY_GROUP}
    @{PORTS} =    BuiltIn.Create List    @{PORTS_NET1}    @{PORTS_NET2}
    OpenStackOperations.Neutron Cleanup    ${vms}    ${NETWORKS}    ${SUBNETS}    ${PORTS}    ${sgs}

