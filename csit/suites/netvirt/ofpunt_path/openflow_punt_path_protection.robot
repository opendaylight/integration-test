*** Settings ***
Documentation     Test suite for OpenFlow punt path protection for subnet route, SNAT, ARP and GARP
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       of_punt_net_1    of_punt_net_2    of_punt_net_3
${EXT_NETWORKS}    of_punt_ext_net_1
@{PORT_LIST}      of_punt_net1_port_1    of_punt_net1_port_2    of_punt_net2_port_1    of_punt_net2_port_2    of_punt_net3_port_1    of_punt_net3_port_2
@{EXTRA_PORTS}    of_punt_net_1_port_3    of_punt_net_2_port_3
@{EXTRA_VMS}      of_punt_net_1_vm_3    of_punt_net_2_vm_3
@{EXTRA_NW_IP}    11.1.1.100    22.1.1.100    12.1.1.12    13.1.1.13
@{VM_LIST}        of_punt_net1_vm_1    of_punt_net1_vm_2    of_punt_net2_vm_1    of_punt_net2_vm_2    of_punt_net3_vm_1    of_punt_net3_vm_2
@{SUBNETS}        of_punt_sub_1    of_punt_sub_2    of_punt_sub_3
${EXT_SUBNETS}    of_punt_ext_sub_1
@{SUBNETS_CIDR}    11.1.1.0/24    22.1.1.0/24    33.1.1.0/24
${EXT_SUBNETS_CIDR}    55.1.1.0/24
${EXT_SUBNETS_FIXED_IP}    55.1.1.100
@{VPN_ID}         4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222
@{VPN_NAME}       of_punt_vpn_1    of_punt_vpn_2
@{ROUTERS}        of_punt_router_1    of_punt_router_2
@{ROUTERS_ID}     @{EMPTY}
@{DPN_IDS}        @{EMPTY}
${SECURITY_GROUP}    of_punt_sg
@{DCGW_RD_IRT_ERT}    11:1    22:1
@{L3VPN_RD_IRT_ERT}    ["@{DCGW_RD_IRT_ERT}[0]"]    ["@{DCGW_RD_IRT_ERT}[1]"]
@{FILES_PATH}     ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/netvirt-vpnmanager-config.xml    ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    ${KARAF_HOME}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
${SNAT_ORIGINAL_TIMEOUT}    5
${L3_ORIGINAL_TIMEOUT}    10
${ARP_ORIGINAL_TIMEOUT}    5
@{ORIGINAL_TIMEOUTS}    ${L3_ORIGINAL_TIMEOUT}    ${SNAT_ORIGINAL_TIMEOUT}    ${ARP_ORIGINAL_TIMEOUT}
@{OF_PUNT_TABLES}    ${L3_PUNT_TABLE}    ${SNAT_PUNT_TABLE}    ${ARP_PUNT_TABLE}    ${ARP_LEARN_TABLE}
@{VALID_TIMEOUTS}    20    30    100    1000    10000
${TCP_PORT}       80
${UDP_PORT}       33435
${TELNET_PORT}    23
${ARP_REG}        0x1
${GARP_REG}       0x101

*** Test Cases ***
Verify default punt timeout values and flows
    [Documentation]    Verify default time out for subnet route, SNAT and ARP in respective defualt openflow tables
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{ORIGINAL_TIMEOUTS}[${index}]

Set punt timeout to zero and verify flows
    [Documentation]    Verify default flows in OVS for subnet route, SNAT and ARP after the changing the default punt timeout value to zero.
    ...    Default subnet route, SNAT and ARP should get deleted after changing default timeout value to zero
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]    ${0}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${0}
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    False    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{ORIGINAL_TIMEOUTS}[${index}]

Set punt timeout to combination of valid ranges and verfiy flows
    [Documentation]    Verify the default flow in OVS for subnet route, SNAT and ARP after the changing the default value to different set of values.
    ...    Default subnet route, SNAT and ARP flows should get changed after changing default timeout value to different set of values
    Set Original TimeOut In Xml    ${0}
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]    @{VALID_TIMEOUTS}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{VALID_TIMEOUTS}[0]
    ${count} =    BuiltIn.Get length    ${VALID_TIMEOUTS}
    : FOR    ${index}    IN RANGE    1    ${count}
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[0]    @{VALID_TIMEOUTS}[${index - 1}]    @{VALID_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[0]    @{VALID_TIMEOUTS}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[1]    @{VALID_TIMEOUTS}[${index - 1}]    @{VALID_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{VALID_TIMEOUTS}[${index}]
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[2]    @{VALID_TIMEOUTS}[${index - 1}]    @{VALID_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{VALID_TIMEOUTS}[${index}]
    \    ClusterManagement.Stop_Members_From_List_Or_All
    \    ClusterManagement.Start_Members_From_List_Or_All
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    \    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${L3_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    120s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${ARP_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[${index}]
    \    BuiltIn.Wait Until Keyword Succeeds    180s    5s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}
    \    ...    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[${index}]
    Set Original TimeOut In Xml    @{VALID_TIMEOUTS}[4]

Verify learnt flow for subnet route flow table
    [Documentation]    Get default subnet table packet count before sending traffic to unkwon destination.
    ...    Send subnet route traffic using Ping with packet count 5.
    ...    Punt the first packet to controller and add new rule to stop pipeline processing.
    ...    Check packet count before and after traffic for both(defualt and learnt tables).
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]    @{VALID_TIMEOUTS}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{VALID_TIMEOUTS}[0]
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE},    |grep "ip actions=CONTROLLER:65535,learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    ${learnt_packet_count}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE},    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    BuiltIn.Should be true    ${learnt_packet_count} > 1
    ${count_after_traffic}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE},    |grep "ip actions=CONTROLLER:65535,learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    ${count_before_traffic} =    BuiltIn.Evaluate    ${count_before_traffic} + 1
    BuiltIn.Should be true    ${count_after_traffic} == ${count_before_traffic}

Verify learnt flow in table=195 and table=196 for ARP request
    [Documentation]    To verify the learnt flow in ovs for ARP request, after traffic is generated from a Vm to unknow IP destination using arping..
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${SNAT_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    Sleep    30s
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    ${count_before_traffic_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ELAN_BASETABLE}    |grep "table=${ELAN_BASETABLE}.*n_packets=[\0-9+].*reg4=${ARP_REG}.0xffff"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IPS}[3]    sudo arping -c 5 -I eth0 22.1.1.101
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=22.1.1.101,arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=22.1.1.101,arp_op=1
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    ${learnt_packet_count} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "table=${ARP_PUNT_TABLE}.*n_packets=[\0-9+].*arp_tpa=22.1.1.101,arp_op=1.*actions=load:0x1"
    BuiltIn.Should be true    ${learnt_packet_count} > 0
    ${count_after_traffic_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ELAN_BASETABLE}    |grep "table=${ELAN_BASETABLE}.*n_packets=[\0-9+].*reg4=${ARP_REG}.0xffff"
    BuiltIn.Should be true    ${count_after_traffic_arp} > ${count_before_traffic_arp}

Verify learnt flow in table=195 and table=196 for ARP reply
    [Documentation]    To verify the learnt flow in ovs for ARP request, after traffic is generated from a Vm to unknow IP destination using arping.
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${SNAT_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    Sleep    30s
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    ${count_before_traffic_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ELAN_BASETABLE}    |grep "table=${ELAN_BASETABLE}.*n_packets=[\0-9+].*reg4=${ARP_REG}.0xffff"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[1]    sudo arping -A -c 5 -I eth0 -s @{VM_IPS}[1] 11.1.1.101
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=11.1.1.101,arp_op=2
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=11.1.1.101,arp_op=2
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    ${learnt_packet_count} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "table=${ARP_PUNT_TABLE}.*n_packets=[\0-9+].*arp_tpa=11.1.1.101,arp_op=2.*actions=load:0x1"
    BuiltIn.Should be true    ${learnt_packet_count} > 0
    ${count_after_traffic_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ELAN_BASETABLE}    |grep "table=${ELAN_BASETABLE}.*n_packets=[\0-9+].*reg4=${ARP_REG}.0xffff"
    BuiltIn.Should be true    ${count_after_traffic_arp} > ${count_before_traffic_arp}

Verify learnt flow in table=195 and table=196 for GARP
    [Documentation]    To verify the learnt flow in ovs for ARP request, after traffic is generated from a Vm to unknow IP destination using arping..
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    Sleep    30s
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    ${count_before_traffic_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${ELAN_BASETABLE}    |grep "table=${ELAN_BASETABLE}.*n_packets=[\0-9+].*reg4=${GARP_REG}.0xffff"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -U -c 5 -I eth0 @{VM_IPS}[0] &
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=@{VM_IPS}[0],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_op=1
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    ${learnt_packet_count} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp_tpa=@{VM_IPS}[0],arp_op=1"
    BuiltIn.Should be true    ${learnt_packet_count} > 0
    ${count_after_traffic_arp} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${ELAN_BASETABLE}    |grep "table=${ELAN_BASETABLE}.*n_packets=[\0-9+].*reg4=${GARP_REG}.0xffff"
    BuiltIn.Should be true    ${count_after_traffic_arp} > ${count_before_traffic_arp}

Verify learnt flow for UDP in SNAT flow table
    [Documentation]    Get default SNAT table packet count before sending traffic to unkwon destination.
    ...    Send UDP traffic using traceroute with packet count 4.
    ...    Punt the first packet to controller and add new rule to stop pipeline processing.
    ...    Check packet count before and after traffic for both(defualt and learnt tables).
    ${compute_ip}    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*udp.*learn(table=46"
    BuiltIn.Should be true    ${count_before_traffic} == 0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    traceroute @{EXTRA_NW_IP}[2] -w 1 -q 1 -m 4
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*udp.*learn(table=46"
    ${count_before_traffic} =    BuiltIn.Evaluate    ${count_before_traffic} + 1
    BuiltIn.Should be true    ${count_after_traffic} == ${count_before_traffic}
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${controller_packet_count} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*udp.*nw_src=@{VM_IPS}[4].*actions=set_field:${EXT_SUBNETS_FIXED_IP}.*goto_table:47"
    BuiltIn.Should be true    ${controller_packet_count} > 1

Verify learnt flow for TCP in SNAT flow table
    [Documentation]    Get default SNAT table packet count before sending traffic to unkwon destination.
    ...    Send TCP traffic using wget.
    ...    Punt the first packet to controller and add new rule to stop pipeline processing.
    ...    Check packet count before and after traffic for both(defualt and learnt tables).
    ${compute_ip}    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*tcp.*learn(table=46"
    BuiltIn.Should be true    ${count_before_traffic} == 0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    wget -qc http://@{EXTRA_NW_IP}[2]/ &
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*tcp.*learn(table=46"
    ${count_before_traffic} =    BuiltIn.Evaluate    ${count_before_traffic} + 1
    BuiltIn.Should be true    ${count_after_traffic} == ${count_before_traffic}
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${controller_packet_count} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*tcp.*nw_src=@{VM_IPS}[4].*actions=set_field:${EXT_SUBNETS_FIXED_IP}.*goto_table:47"
    BuiltIn.Should be true    ${controller_packet_count} > 1

Verify resync subnet, SNAT and ARP route flow table after disconnect and reconnecting CSC-CSS control path
    [Documentation]    Verify resync subnet, SNAT and ARP route flow table after disconnect and reconnecting CSC-CSS control path
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    traceroute @{EXTRA_NW_IP}[2] -w 1 -q 1 -m 4
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    wget -qc http://@{EXTRA_NW_IP}[2]/ &
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=@{VM_IPS}[1],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_op=1
    OVSDB.Delete OVS Manager    ${OS_CMP1_IP}
    OVSDB.Delete OVS Controller    ${OS_CMP1_IP}
    OVSDB.Delete OVS Manager    ${snat_napt_switch_ip}
    OVSDB.Delete OVS Controller    ${snat_napt_switch_ip}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    False    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    False    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    False    ${EMPTY}    arp_tpa=@{VM_IPS}[1],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    False    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_op=1
    OVSDB.Set Controller In OVS Bridge    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    tcp:${ODL_SYSTEM_IP}:6653
    OVSDB.Set Controller In OVS Bridge    ${snat_napt_switch_ip}    ${INTEGRATION_BRIDGE}    tcp:${ODL_SYSTEM_IP}:6653
    Set OVS Manager    ${OS_CMP1_IP}    ${ODL_SYSTEM_IP}
    Set OVS Manager    ${snat_napt_switch_ip}    ${ODL_SYSTEM_IP}
    Sleep    60s
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    190s    40s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    False    ${EMPTY}    arp_tpa=@{EXTRA_NW_IP}[1],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    False    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[1],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]

Verify resync subnet, SNAT and ARP route flow table after ODL and cluster restart
    [Documentation]    Verify resync subnet, SNAT and ARP route flow table after ODL and cluster restart
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    traceroute @{EXTRA_NW_IP}[3] -w 1 -q 1 -m 4
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    wget -qc http://@{EXTRA_NW_IP}[3]/ &
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=@{VM_IPS}[1],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_op=1
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True
    ...    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False
    ...    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    190s    40s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False
    ...    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    False
    ...    ${EMPTY}    arp_tpa=@{EXTRA_NW_IP}[1],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    False
    ...    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[1],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]

Verify resync subnet, SNAT and ARP flow table after CSS restart
    [Documentation]    Verify resync subnet, SNAT and ARP flow table after CSS restart
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Set Suite Variable    ${snat_napt_switch_ip}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True
    ...    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True
    ...    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    traceroute @{EXTRA_NW_IP}[2] -w 1 -q 1 -m 4
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True
    ...    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    wget -qc http://@{EXTRA_NW_IP}[2]/ &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True
    ...    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{VM_IPS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True
    ...    ${EMPTY}    arp_tpa=@{VM_IPS}[1],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    True
    ...    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_op=1
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    OVSDB.Restart OVSDB    ${snat_napt_switch_ip}
    Sleep    60s
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True
    ...    ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False
    ...    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    190s    40s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False
    ...    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    False
    ...    ${EMPTY}    arp_tpa=@{EXTRA_NW_IP}[1],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    False
    ...    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[1],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]

Verify the subnet route punt path rate limiting is off, by bring up the destination IP host and by deleting the destination IP host brought in previous case
    [Documentation]    Subnet route punt path rate limiting is on to the unknow destination IP
    ...    Subnet route punt path rate limiting is off, by bring up the destination IP host
    ...    By deleting the destination IP host subnet route punt path rate limiting is back on.
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True
    ...    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True
    ...    ${EMPTY}    actions=CONTROLLER:65535,learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]
    ${pkt_count_before}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE}    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    Log    ${pkt_count_before}
    BuiltIn.Should Be True    ${pkt_count_before} == 4
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{EXTRA_PORTS}[1]    @{EXTRA_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    ${pkt_count_after}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE}    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    Log    ${pkt_count_after}
    Run Keyword And Ignore Error    BuiltIn.Should Be True    ${pkt_count_after} == 4
    OpenStackOperations.Delete Vm Instance    @{EXTRA_VMS}[1]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    ${pkt_count}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE}    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    Log    ${pkt_count}
    Run Keyword And Ignore Error    BuiltIn.Should Be True    ${pkt_count} == 9
    [Teardown]    Run Keyword And Ignore Error    OpenStackOperations.Delete Vm Instance    @{EXTRA_VMS}[1]

Verify the ARP request punt path for same destination from different source
    [Documentation]    Verify the ARP request punt path for same destination from different source
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{EXTRA_NW_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True
    ...    ${EMPTY}    arp_tpa=@{EXTRA_NW_IP}[0],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    True
    ...    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[0],arp_op=1
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[1]    sudo arping -c 2 @{EXTRA_NW_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_PUNT_TABLE}    True
    ...    ${EMPTY}    arp_tpa=@{EXTRA_NW_IP}[0],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_LEARN_TABLE}    True
    ...    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[0],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ELAN_BASETABLE}    True
    ...    ${EMPTY}    arp,reg4=0x1/0xffff

Verify the ARP punt path for ARP Request from the VM should be punted to CSC and the reply from the subnet gateway shouldn’t be punted
    [Documentation]    Verify the ARP punt path for ARP Request from the VM should be punted to CSC and the reply from the subnet gateway shouldn’t be punted
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 -I eth0 -s @{VM_IPS}[0] 11.1.1.1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    True
    ...    ${EMPTY}    arp_tpa=11.1.1.1,arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE}    False
    ...    ${EMPTY}    arp_tpa=@{VM_IPS}[0],arp_op=1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    True
    ...    ${EMPTY}    arp_spa=11.1.1.1,arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_LEARN_TABLE}    False    ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_BASETABLE}    True    ${EMPTY}    arp,reg4=0x101/0xffff

Verify the SNAT punt path from same source IP to different destination
    [Documentation]    Verify the SNAT punt path from same source IP to different destination
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    telnet @{EXTRA_NW_IP}[2] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True
    ...    |grep nw_dst=@{EXTRA_NW_IP}[2]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    |grep nw_src=@{VM_IPS}[5]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${pkt_count_before}    OvsManager.Get Packet Count From Table    ${snat_napt_switch_ip}    ${INTEGRATION_BRIDGE}    ${SNAT_PUNT_TABLE}    |grep nw_src=@{VM_IPS}[5],tp_src=
    Log    ${pkt_count_before}
    BuiltIn.Should Be True    ${pkt_count_before} > 0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    telnet @{EXTRA_NW_IP}[3] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True
    ...    |grep nw_dst=@{EXTRA_NW_IP}[3]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    |grep nw_src=@{VM_IPS}[5]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src

Verify the punt path with traffic for same destination from different source IP
    [Documentation]    Verify the punt path with traffic for same destination from different source IP
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]
    \    ...    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=@{VALID_TIMEOUTS}[0]
    ${snat_napt_switch_ip} =    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    telnet @{EXTRA_NW_IP}[2] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True
    ...    |grep nw_dst=@{EXTRA_NW_IP}[2]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    |grep nw_src=@{VM_IPS}[4]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${pkt_count_before}    OvsManager.Get Packet Count From Table    ${snat_napt_switch_ip}    ${INTEGRATION_BRIDGE}    ${SNAT_PUNT_TABLE}    |grep nw_src=@{VM_IPS}[5],tp_src=
    Log    ${pkt_count_before}
    BuiltIn.Should Be True    ${pkt_count_before} > 0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    telnet @{EXTRA_NW_IP}[2] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True
    ...    |grep nw_dst=@{EXTRA_NW_IP}[2]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    True    |grep nw_src=@{VM_IPS}[5]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src

TC18 Verify the punt path work together for ARP, SNAT and Subnet routing
    [Documentation]    Verify the punt path work together for ARP, SNAT and Subnet routing
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]    @{VALID_TIMEOUTS}[0]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{VALID_TIMEOUTS}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE},    |grep "ip actions=CONTROLLER:65535,learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}    True    ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    ${learnt_packet_count}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE},    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    BuiltIn.Should be true    ${learnt_packet_count} > 1
    ${count_after_traffic}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE},    |grep "ip actions=CONTROLLER:65535,learn(table=${L3_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}

    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IPS}[3]    sudo arping -c 5 -I eth0 22.1.1.101
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=22.1.1.101,arp_op=1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=22.1.1.101,arp_op=1
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    ${learnt_packet_count} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "table=${ARP_PUNT_TABLE}.*n_packets=[\0-9+].*arp_tpa=22.1.1.101,arp_op=1.*actions=load:0x1"
    BuiltIn.Should be true    ${learnt_packet_count} > 0

    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[1]    sudo arping -A -c 5 -I eth0 -s @{VM_IPS}[1] 11.1.1.101
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_PUNT_TABLE}    True    ${EMPTY}    arp_tpa=11.1.1.101,arp_op=2
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP2_IP}    ${ARP_LEARN_TABLE}    True    ${EMPTY}    arp_spa=11.1.1.101,arp_op=2
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "arp actions=CONTROLLER:65535,learn(table=${ARP_PUNT_TABLE},hard_timeout=@{VALID_TIMEOUTS}[0]"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    ${learnt_packet_count} =    OvsManager.Get Packet Count From Table    ${OS_CMP2_IP}    ${INTEGRATION_BRIDGE}    table=${ARP_PUNT_TABLE}    |grep "table=${ARP_PUNT_TABLE}.*n_packets=[\0-9+].*arp_tpa=11.1.1.101,arp_op=2.*actions=load:0x1"
    BuiltIn.Should be true    ${learnt_packet_count} > 0

    ${compute_ip}    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*udp.*learn(table=46"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    traceroute @{EXTRA_NW_IP}[2] -w 1 -q 1 -m 4
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*udp.*learn(table=46"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${controller_packet_count} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*udp.*nw_src=@{VM_IPS}[4].*actions=set_field:${EXT_SUBNETS_FIXED_IP}.*goto_table:47"
    BuiltIn.Should be true    ${controller_packet_count} > 1

    ${compute_ip}    Get NAPT Switch IP From DPID    @{ROUTERS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    @{VALID_TIMEOUTS}[0]
    ${count_before_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*tcp.*learn(table=46"
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    wget -qc http://@{EXTRA_NW_IP}[2]/ &
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    ${count_after_traffic} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*tcp.*learn(table=46"
    BuiltIn.Should be true    ${count_after_traffic} > ${count_before_traffic}
    OVSDB.Verify Dump Flows For Specific Table    ${compute_ip}    ${SNAT_PUNT_TABLE}    True    ${EMPTY}    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${controller_packet_count} =    OvsManager.Get Packet Count From Table    ${compute_ip}    ${INTEGRATION_BRIDGE}    table=${SNAT_PUNT_TABLE}    |grep "table=46.*n_packets=[\0-9+].*tcp.*nw_src=@{VM_IPS}[4].*actions=set_field:${EXT_SUBNETS_FIXED_IP}.*goto_table:47"
    BuiltIn.Should be true    ${controller_packet_count} > 1

*** Keywords ***
Suite Setup
    [Documentation]    Create common setup related to openflow punt path protection
    VpnOperations.Basic Suite Setup
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    OpenStackOperations.Create Network    ${EXT_NETWORKS}    additional_args=--external --provider-network-type gre
    ${elements} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${count} =    BuiltIn.Get length    ${SUBNETS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNETS_CIDR}[${index}]
    OpenStackOperations.Create SubNet    ${EXT_NETWORKS}    ${EXT_SUBNETS}    ${EXT_SUBNETS_CIDR}    additional_args=--no-dhcp
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    Collections.Append To List    ${ROUTERS_ID}    ${router_id}
    BuiltIn.Set Suite Variable    @{ROUTERS_ID}
    : FOR    ${index}    IN RANGE    0    2
    \    OpenStackOperations.Add Router Interface    @{ROUTERS}[0]    @{SUBNETS}[${index}]
    OpenStackOperations.Add Router Interface    @{ROUTERS}[1]    @{SUBNETS}[2]
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP}
    ${ext_net} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${NETWORKS_ALL} =    Collections.Combine Lists    ${NETWORKS}    ${ext_net}
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index}}]    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index + 1}}]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{EXTRA_PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=--allowed-address ip-address=0.0.0.0 --fixed-ip subnet=@{SUBNETS}[0],ip-address=@{EXTRA_NW_IP}[0]
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{EXTRA_PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=--allowed-address ip-address=0.0.0.0 --fixed-ip subnet=@{SUBNETS}[1],ip-address=@{EXTRA_NW_IP}[1]
    : FOR    ${index}    IN RANGE    0    3
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[${index + ${index}}]    @{VM_LIST}[${index + ${index}}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORT_LIST}[${index + ${index + 1}}]    @{VM_LIST}[${index + ${index + 1}}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IPS}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VM_LIST}
    BuiltIn.Set Suite Variable    ${VM_IPS}
    OpenStackOperations.Show Debugs    @{VM_LIST}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${dhcp_ip}    None
    : FOR    ${index}    IN RANGE    0    2
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${index}]    vpnid=@{VPN_ID}[${index}]    rd=@{L3VPN_RD_IRT_ERT}[${index}]    exportrt=@{L3VPN_RD_IRT_ERT}[${index}]    importrt=@{L3VPN_RD_IRT_ERT}[${index}]
    VpnOperations.Associate VPN to Router    routerid=@{ROUTERS_ID}[0]    vpnid=@{VPN_ID}[0]
    ${network_id} =    OpenStackOperations.Get Net Id    ${EXT_NETWORKS}
    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_ID}[1]
    OpenStackOperations.Add Router Gateway    @{ROUTERS}[1]    ${EXT_NETWORKS}    additional_args=--fixed-ip subnet=${EXT_SUBNETS},ip-address=${EXT_SUBNETS_FIXED_IP} --enable-snat
    Create Dictionary For DPN ID And Compute IP Mapping For All DPNS
    OpenStackOperations.Get Suite Debugs

Set Original TimeOut In Xml
    [Arguments]    ${hard_timeout}
    [Documentation]    Set default timeout in XML for all the punt files
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    ${hard_timeout}    @{ORIGINAL_TIMEOUTS}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{ORIGINAL_TIMEOUTS}[${index}]
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2

Verify Punt Values In XML File
    [Arguments]    ${file_path}    ${value}
    [Documentation]    Verify the default value for SNAT, ARP in ELAN, Subnet Routing in the xml file in ODL Controller
    ${output} =    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    cat ${file_path} | grep punt-timeout
    @{matches} =    BuiltIn.Should Match Regexp    ${output}    punt.timeout.*?([0-9]+)
    BuiltIn.Should be true    @{matches}[1] == ${value}

Change Hard Timeout Value In XML File
    [Arguments]    ${file_path}    ${value_1}    ${value_2}
    [Documentation]    Change the default value in xml in the ODL controller for subnet route, SNAT and ARP
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    sed -i -e 's/punt-timeout\>${value_1}/punt-timeout\>${value_2}/' ${file_path}

Create Dictionary For DPN ID And Compute IP Mapping For All DPNS
    [Documentation]    Creating dictionary for DPN ID and compute IP mapping
    : FOR    ${ip}    IN    @{OS_ALL_IPS}
    \    ${dpnid}    OVSDB.Get DPID    ${ip}
    \    Collections.Append To List    ${DPN_IDS}    ${dpnid}
    ${DPN_TO_COMPUTE_IP} =    BuiltIn.Create Dictionary
    ${count} =    BuiltIn.Get length    ${OS_ALL_IPS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    @{DPN_IDS}[${index}]    @{OS_ALL_IPS}[${index}]
    : FOR    ${dp_id}    IN    @{DPN_IDS}
    \    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${dp_id}
    BuiltIn.Set Suite Variable    ${DPN_TO_COMPUTE_IP}

Get SNAT NAPT Switch DPID
    [Arguments]    ${router_name}
    [Documentation]    Returns the SNAT NAPT switch dpnid from odl rest call.
    ${router_id} =    OpenStackOperations.Get Router Id    ${router_name}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/odl-nat:napt-switches/router-to-napt-switch/${router_id}
    Log    ${resp.content}
    @{matches} =    BuiltIn.Should Match Regexp    ${resp.content}    switch.id.*?([0-9]+)
    ${dpnid} =    BuiltIn.Convert To Integer    @{matches}[1]
    [Return]    ${dpnid}

Get NAPT Switch IP From DPID
    [Arguments]    ${router_name}
    [Documentation]    Return SNAT NAPT switch ip for the given router name
    ${dpnid} =    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Get SNAT NAPT Switch DPID    ${router_name}
    ${compute_ip} =    Collections.Get From Dictionary    ${DPN_TO_COMPUTE_IP}    ${dpnid}
    [Return]    ${compute_ip}

Set OVS Manager
    [Arguments]    ${ovs_ip}    ${controller_ip}    ${ovs_mgr_port}=6640
    [Documentation]    Add manager from OVS
    ${set_mgr} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl set-manager tcp:${controller_ip}:${ovs_mgr_port}
    BuiltIn.Log    ${set_mgr}
