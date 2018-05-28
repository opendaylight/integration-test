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
${DUMP_FLOW}    sudo ovs-ofctl dump-flows br-int -OOPenflow13
${DUMP_PORT_DESC}    sudo ovs-ofctl dump-ports-desc br-int -OOPenflow13
${PACKET_COUNT}    5
${BCAST_IP}    255.255.255.255
${SUBNET1_BCAST_IP}    10.0.0.255
${SUBNET2_BCAST_IP}    20.0.0.255
${INGRESS_DISPATURE_TABLE}    table=220
${ENABLE_BCAST}    sudo -s && echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

*** Test case ***
Verify Network Broadcast traffic between the VMs hosted on same compute node in Single Network
    [Documentation]      Verify Network Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${get_pkt_count_before_bcast} =     Bcast Packetcount    ${OS_COMPUTE1_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =     Bcast Packetcount    ${OS_COMPUTE1_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Network Broadcast traffic between the VMs hosted on Different compute node in Single Network
    [Documentation]      Verify Network Broadcast traffic between the VMs hosted on Different compute node in Single Network
    ${get_pkt_count_before_bcast} =     Bcast Packetcount    ${OS_COMPUTE2_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =     Bcast Packetcount    ${OS_COMPUTE2_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Network Broadcast traffic between the VMs hosted on same compute node in Multi Network
    [Documentation]      Verify L3 (Network) Broadcast traffic between the VMs hosted on same compute node in Multi Network
    ${get_pkt_count_before_bcast} =    Bcast Packetcount    ${OS_COMPUTE1_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =    Bcast Packetcount    ${OS_COMPUTE1_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Network Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    [Documentation]      Verify L3 (Network) Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    ${get_pkt_count_before_bcast} =    Bcast Packetcount    ${OS_COMPUTE2_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${BCAST_IP}
    ${get_pkt_count_after_bcast} =     Bcast Packetcount    ${OS_COMPUTE2_IP}    ${ACL_Anti_Spoofing_Table}    ${BCAST_IP}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount     ${OS_COMPUTE_1_IP}     ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}   ${VM2_SUBMETA}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET1_BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET1_BCAST_IP}| grep ${VM2_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_1_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}    ${VM2_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Single Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Single Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}   ${VM3_SUBMETA}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET1_BCAST_IP}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET1_BCAST_IP}| grep ${VM3_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET1_BCAST_IP}    ${VM3_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}

Verify Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on same compute node in Multi Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_1_IP}     ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}   ${VM4_SUBMETA}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET2_BCAST_IP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET2_BCAST_IP}| grep ${VM4_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_1_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}    ${VM4_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

Verify Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    [Documentation]      Verify L3-Subnet Broadcast traffic between the VMs hosted on Different compute node in Multi Network
    ${get_pkt_count_before_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}   ${VM5_SUBMETA}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s     OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    ${VM1_NET1_DPN1_IP_Address}    ping -c 5 ${SUBNET2_BCAST_IP}
    ${bcast_egress} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    ${DUMP_FLOW} | grep ${ACL_Anti_Spoofing_Table} | grep ${SUBNET2_BCAST_IP}| grep ${VM5_SUBMETA}
    ${get_pkt_count_after_bcast} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    SubnetBcast Packetcount    ${OS_COMPUTE_2_IP}      ${ACL_Anti_Spoofing_Table}    ${SUBNET2_BCAST_IP}    ${VM5_SUBMETA}
    ${pkt_diff} =    Evaluate    int(${get_pkt_count_after_bcast})-int(${get_pkt_count_before_bcast})
    Should Be True    ${pkt_diff}==0

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

    ${VM1_DPN1_Enable_Bcast} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM1_NET1_DPN1_IP_Address}    ${ENABLE_BCAST}

    ${VM1_In_Port}   ${VM1_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET1}[0]    ${OS_COMPUTE_1_IP}
    ${VM2_In_Port}   ${VM2_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET1}[1]    ${OS_COMPUTE_1_IP}
    ${VM3_In_Port}   ${VM3_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET1}[2]    ${OS_COMPUTE_2_IP}
    ${VM4_In_Port}   ${VM4_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET2}[0]    ${OS_COMPUTE_1_IP}
    ${VM5_In_Port}   ${VM5_META} =    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Get VMs Metadata and In Port    @{PORTS_NET2}[1]    ${OS_COMPUTE_2_IP}

    BuiltIn.Set Suite Variable    ${VM1_In_Port}
    BuiltIn.Set Suite Variable    ${VM2_In_Port}
    BuiltIn.Set Suite Variable    ${VM3_In_Port}
    BuiltIn.Set Suite Variable    ${VM4_In_Port}
    BuiltIn.Set Suite Variable    ${VM5_In_Port}

    BuiltIn.Set Suite Variable    ${VM1_META}
    BuiltIn.Set Suite Variable    ${VM2_META}
    BuiltIn.Set Suite Variable    ${VM3_META}
    BuiltIn.Set Suite Variable    ${VM4_META}
    BuiltIn.Set Suite Variable    ${VM5_META}

    ${VM1_SUBMETA} =    Get Submetadata   ${VM1_META}
    ${VM2_SUBMETA} =    Get Submetadata   ${VM2_META}
    ${VM3_SUBMETA} =    Get Submetadata   ${VM3_META}
    ${VM4_SUBMETA} =    Get Submetadata   ${VM4_META}
    ${VM5_SUBMETA} =    Get Submetadata   ${VM5_META}

    BuiltIn.Set Suite Variable    ${VM1_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM2_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM3_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM4_SUBMETA}
    BuiltIn.Set Suite Variable    ${VM5_SUBMETA}

Bcast Packetcount
    [Arguments]    ${OS_COMPUTE_IP}    ${TABLE_NO}   ${BCAST_IP}
    [Documentation]    Capture packetcount for network broadcast request
    ${output} =    Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep ${TABLE_NO} | grep ${BCAST_IP}
    @{output_list} =    String.Split String    ${output}    \r\n
    ${flow} =    Get From List    ${output_list}     0
    ${packetcount_list} =    String.Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1
    ${count} =    Get From List    ${packetcount_list}    0
    [Return]    ${count}

SubnetBcast Packetcount
    [Arguments]    ${OS_COMPUTE_IP}    ${TABLE_NO}   ${SUBNET_BCAST_IP}    ${VM_SUBMETA}
    [Documentation]    Capture packetcount for subnet broadcast request
    ${flow_output1} =    Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep ${TABLE_NO} | grep ${SUBNET_BCAST_IP}| grep ${VM_SUBMETA}
    log    ${flow_output1}
    @{output_list} =    String.Split String    ${flow_output1}    \r\n
    ${flow} =    Collections.Get From List    ${output_list}     0
    ${packetcount_list} =    Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1
    ${count} =    Collections.Get From List    ${packetcount_list}    0
    [Return]    ${count}

Get VMs Metadata and In Port
    [Arguments]    ${portname}    ${OS_COMPUTE_IP}
    [Documentation]    This keyword is to get the VM metadata and the in_port Id of the VM
    ${port_id} =    OpenStackOperations.Get Port Id    ${portname}
    BuiltIn.Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{subport} =    String.Get Regexp Matches    ${port_id}    (\\w{8}-\\w{2})
#    ${subport} =    OpenStackOperations.Get Sub Port Id    ${portname}
#    ${get_vm_in_port} =    OpenStack CLI    ${DUMP_PORT_DESC} | grep ${subport} | awk '{print$1}'
#    ${get_vm_in_port} =    OpenStack CLI    ${DUMP_PORT_DESC} | grep @{subport}[0] | awk '{print$1}'

    ${get_vm_in_port} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_PORT_DESC} | grep @{subport}[0] | awk '{print$1}'
    ${vms_in_port} =     BuiltIn.Should Match Regexp    ${get_vm_in_port}    [0-9]+
    ${grep_metadata} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_IP}    ${DUMP_FLOW} | grep table=0 | grep in_port=${vms_in_port} | awk '{print$7}'
    log    ${grep_metadata}
    @{metadata} =    String.Split string    ${grep_metadata}    ,
    ${get_write_metadata} =    Collections.get from list    ${metadata}    0
    @{complete_metadata} =    Split string    ${get_write_metadata}    :
    ${extract_metadata} =    Collections.get from list    ${complete_metadata}    1
    @{split_metadata} =    String.Split string    ${extract_metadata}    /
    ${vm_metadata} =    Collections.get from list    ${split_metadata}    0
    [Return]   ${vms_in_port}    ${vm_metadata}

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

