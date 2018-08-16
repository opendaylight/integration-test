*** Settings ***
Documentation     The objective of this testsuite is to test QBGP and ODL for multipath/ECMP support.
...               QBGP should be capable to receive multiple ECMP paths from different DC-GWs and
...               to export the ECMP paths to ODL instead of best path selection.
...               ODL should be capable to receive ECMP paths and it should program the FIB with ECMP paths.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       of_punt_net1    of_punt_net2    of_punt_net3
${EXT_NETWORKS}    of_punt_ext_net1
@{PORT_LIST}      of_punt_net1_port_1    of_punt_net1_port_2    of_punt_net2_port_1    of_punt_net2_port_2    of_punt_net3_port_1    of_punt_net3_port_2
@{EXTRA_PORTS}    of_punt_net_1_port_3    of_punt_net_2_port_3
@{EXTRA_VMS}      of_punt_net_1_vm_3    of_punt_net_2_vm_3
@{EXTRA_NW_IP}    11.1.1.100    22.1.1.100    12.1.1.12    13.1.1.13
@{VM_LIST}        of_punt_net1_vm_1    of_punt_net1_vm_2    of_punt_net2_vm_1    of_punt_net2_vm_2    of_punt_net3_vm_1    of_punt_net3_vm_2
@{SUBNETS}        of_punt_subnet1    of_punt_subnet2    of_punt_subnet3
${EXT_SUBNETS}    of_punt_ext_subnet1
@{SUBNETS_CIDR}    11.1.1.0/24    22.1.1.0/24    33.1.1.0/24
${EXT_SUBNETS_CIDR}    55.1.1.0/24
${EXT_SUBNETS_FIXED_IP}    55.1.1.100
@{VPN_ID}         4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222
@{VPN_NAME}       of_punt_vpn1    of_punt_vpn2
@{DCGW_RD}        ["2200:2"]
@{ROUTERS}        of_punt_router1    of_punt_router2
${SECURITY_GROUP}    of_punt_sg
${ALLOW_ALL_ADDRESS}    0.0.0.0
${ODL_ENABLE_L3_FWD}    yes
${AS_ID}          100
@{DCGW_RD_IRT_ERT}    11:1    22:1
@{L3VPN_RD_IRT_ERT}    ["@{DCGW_RD_IRT_ERT}[0]"]    ["@{DCGW_RD_IRT_ERT}[1]"]
@{LOOPBACK_IP}    1.1.1.1    2.2.2.2
${DUMP_FLOWS}     sudo ovs-ofctl dump-flows br-int -O Openflow13
@{FILES_PATH}     /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-vpnmanager-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml    /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
${OVS_SHOW}       sudo ovs-vsctl show
${SNAT_DEFAULT_HARD_TIMEOUT}    5
${L3_DEFAULT_HARD_TIMEOUT}    10
${ARP_DEFAULT_HARD_TIMEOUT}    5
@{DEFAULT_HARD_TIMEOUT}    ${L3_DEFAULT_HARD_TIMEOUT}    ${SNAT_DEFAULT_HARD_TIMEOUT}    ${ARP_DEFAULT_HARD_TIMEOUT}
${HARD_TIMEOUT_180}    180
${SNAT_PUNT_TABLE}    46
${L3_PUNT_TABLE}    22
${ARP_PUNT_TABLE_1}    195
${ARP_PUNT_TABLE_2}    196
@{OF_PUNT_TABLES}    ${L3_PUNT_TABLE}    ${SNAT_PUNT_TABLE}    ${ARP_PUNT_TABLE_1}    ${ARP_PUNT_TABLE_2}
${HARD_TIMEOUT_VALUE_ZERO}    0
@{HARD_TIMEOUT_VALUES}    20    30    100    1000    10000
${TCP_PORT}       80
${UDP_PORT}       33435
${TELNET_PORT}    23

*** Test Cases ***
Verify resync subnet, SNAT and ARP route flow table after disconnect and reconnecting CSC-CSS control path
    [Documentation]    Verify resync subnet, SNAT and ARP route flow table after disconnect and reconnecting CSC-CSS control path
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${HARD_TIMEOUT_180}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_180}
    Restart Karaf
    Sleep    120s
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]   True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=${HARD_TIMEOUT_180}
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    traceroute @{EXTRA_NW_IP}[2] -w 1 -q 1 -m 4
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    wget -qc http://@{EXTRA_NW_IP}[2]/ &
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table   ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table   ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   True     ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{VM_IPS}[0]
    OVSDB.Delete OVS Manager    ${OS_CMP1_IP}
    OVSDB.Delete OVS Controller    ${OS_CMP1_IP}
    OVSDB.Delete OVS Manager    ${snat_napt_switch_ip}
    OVSDB.Delete OVS Controller    ${snat_napt_switch_ip}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   False     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   False     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   False     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   False     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{VM_IPS}[0]
    OVSDB.Set Controller In OVS Bridge    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    tcp:${ODL_SYSTEM_IP}:6653
    OVSDB.Set Controller In OVS Bridge    ${snat_napt_switch_ip}    ${INTEGRATION_BRIDGE}    tcp:${ODL_SYSTEM_IP}:6653
    Set OVS Manager    ${OS_CMP1_IP}    ${ODL_SYSTEM_IP}
    Set OVS Manager    ${snat_napt_switch_ip}    ${ODL_SYSTEM_IP}
    Sleep    60s
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False     ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    190s    40s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[1],arp_tpa=@{VM_IPS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    learn(table=${ARP_PUNT_TABLE_1},hard_timeout=${HARD_TIMEOUT_180}
    [Teardown]    Set Default TimeOut In Xml

Verify resync subnet, SNAT and ARP route flow table after ODL and cluster restart
    [Documentation]    Verify resync subnet, SNAT and ARP route flow table after ODL and cluster restart
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${HARD_TIMEOUT_180}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_180}
    Restart Karaf
    Sleep    120s
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]    True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=${HARD_TIMEOUT_180}
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    traceroute @{EXTRA_NW_IP}[3] -w 1 -q 1 -m 4
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    wget -qc http://@{EXTRA_NW_IP}[3]/ &
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table   ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{VM_IPS}[1]
    OVSDB.Verify Dump Flows For Specific Table   ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   True     ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{VM_IPS}[0]
    Restart Karaf
    #BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   False     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    #BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   False     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    #OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   False     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    #OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   False     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    #OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{VM_IPS}[1]
    #OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{VM_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False     ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    190s    40s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[1],arp_tpa=@{VM_IPS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    learn(table=${ARP_PUNT_TABLE_1},hard_timeout=${HARD_TIMEOUT_180}
    [Teardown]    Set Default TimeOut In Xml

Verify resync subnet, SNAT and ARP flow table after CSS restart
    [Documentation]    Verify resync subnet, SNAT and ARP flow table after CSS restart
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${HARD_TIMEOUT_180}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_180}
    Restart Karaf
    Sleep    120s
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Set Suite Variable    ${snat_napt_switch_ip}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]   True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=${HARD_TIMEOUT_180}
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    traceroute @{EXTRA_NW_IP}[2] -w 1 -q 1 -m 4
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    wget -qc http://@{EXTRA_NW_IP}[2]/ &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{VM_IPS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table   ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{VM_IPS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table   ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   True     ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{VM_IPS}[0]
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    OVSDB.Restart OVSDB    ${snat_napt_switch_ip}
    #BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   False     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    #BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   False     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    #OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   False     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    #OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   False     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    #OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{VM_IPS}[1]
    #OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False    ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{VM_IPS}[0]
    Sleep    60s
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=11.1.1.255 actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False     ${EMPTY}    tp_dst=${UDP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    190s    40s    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}    False     ${EMPTY}    tp_dst=${TCP_PORT} actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False    ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[1],arp_tpa=@{VM_IPS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    learn(table=${L3_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    OVSDB.Verify Dump Flows For Specific Table    ${snat_napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     ${EMPTY}    learn(table=${SNAT_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    learn(table=${ARP_PUNT_TABLE_1},hard_timeout=${HARD_TIMEOUT_180}
    [Teardown]    Set Default TimeOut In Xml

Verify the subnet route punt path rate limiting is off, by bring up the destination IP host and by deleting the destination IP host brought in previous case
    [Documentation]    Subnet route punt path rate limiting is on to the unknow destination IP
    ...    Subnet route punt path rate limiting is off, by bring up the destination IP host
    ...    By deleting the destination IP host subnet route punt path rate limiting is back on.
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]    ${HARD_TIMEOUT_180}
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_180}
    Restart Karaf
    Sleep    120s
    ${snat_napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Check OVS OpenFlow Connections    ${OS_CMP1_IP}    2
    : FOR    ${index}    IN RANGE    0    3
    \    BuiltIn.Wait Until Keyword Succeeds    120s    20s    Verify Dump Flows For Specific Table     ${snat_napt_switch_ip}    @{OF_PUNT_TABLES}[${index}]   True    ${EMPTY}    learn(table=@{OF_PUNT_TABLES}[${index}],hard_timeout=${HARD_TIMEOUT_180}
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    actions=CONTROLLER:65535,learn(table=${L3_PUNT_TABLE},hard_timeout=${HARD_TIMEOUT_180}
    ${pkt_count_before}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE}    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    Log    ${pkt_count_before}
    BuiltIn.Should Be True    ${pkt_count_before} == 4
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{EXTRA_PORTS}[1]    @{EXTRA_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Sleep    30s
    OpenStackOperations.Get VM IP    True    @{EXTRA_VMS}[1]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    Sleep    20s
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${L3_PUNT_TABLE}   True     ${EMPTY}    nw_dst=@{EXTRA_NW_IP}[1] actions=drop
    ${pkt_count_after}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE}    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    Log    ${pkt_count_after}
    BuiltIn.Should Be True    ${pkt_count_after} == 4
    OpenStackOperations.Delete Vm Instance     @{EXTRA_VMS}[1]
    Sleep    30s
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo ping -c 5 @{EXTRA_NW_IP}[1]
    Sleep    20s
    ${pkt_count}    OvsManager.Get Packet Count From Table    ${OS_CMP1_IP}    ${INTEGRATION_BRIDGE}    table=${L3_PUNT_TABLE}    |grep "nw_dst=@{EXTRA_NW_IP}[1] actions=drop"
    Log    ${pkt_count}
    BuiltIn.Should Be True    ${pkt_count} == 9
    [Teardown]    Set Default TimeOut In Xml

Verify the ARP request punt path for same destination from different source
    [Documentation]    Verify the ARP request punt path for same destination from different source
    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{DEFAULT_HARD_TIMEOUT}[2]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 @{EXTRA_NW_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}    True     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=@{EXTRA_NW_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}    True     ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[0],arp_tpa=@{VM_IPS}[0]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[1]    sudo arping -c 2 @{EXTRA_NW_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}    True     ${EMPTY}    arp_spa=@{VM_IPS}[1],arp_tpa=@{EXTRA_NW_IP}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}    True     ${EMPTY}    arp_spa=@{EXTRA_NW_IP}[0],arp_tpa=@{VM_IPS}[1]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_BASETABLE}    True     ${EMPTY}    arp,reg4=0x1/0xffff

Verify the ARP punt path for ARP Request from the VM should be punted to CSC and the reply from the subnet gateway shouldn’t be punted
    [Documentation]    Verify the ARP punt path for ARP Request from the VM should be punted to CSC and the reply from the subnet gateway shouldn’t be punted
    Verify Punt Values In XML File    @{FILES_PATH}[2]    @{DEFAULT_HARD_TIMEOUT}[2]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IPS}[0]    sudo arping -c 2 -I eth0 -s @{VM_IPS}[0] 11.1.1.1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   True     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=11.1.1.1
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_1}   False     ${EMPTY}    arp_spa=11.1.1.1,arp_tpa=@{VM_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   True     ${EMPTY}    arp_spa=11.1.1.1,arp_tpa=@{VM_IPS}[0]
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ARP_PUNT_TABLE_2}   False     ${EMPTY}    arp_spa=@{VM_IPS}[0],arp_tpa=11.1.1.1
    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_IP}    ${ELAN_BASETABLE}   True     ${EMPTY}    arp,reg4=0x101/0xffff

Verify the SNAT punt path from same source IP to different destination
    [Documentation]    Verify the SNAT punt path from same source IP to different destination
    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{DEFAULT_HARD_TIMEOUT}[1]
    ${napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    telnet @{EXTRA_NW_IP}[2] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_dst=@{EXTRA_NW_IP}[2]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_src=@{VM_IPS}[5]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${pkt_count_before}    OvsManager.Get Packet Count From Table    ${napt_switch_ip}    ${INTEGRATION_BRIDGE}    ${SNAT_PUNT_TABLE}    |grep nw_src=@{VM_IPS}[5],tp_src=
    Log    ${pkt_count_before}
    BuiltIn.Should Be True    ${pkt_count_before} > 0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    telnet @{EXTRA_NW_IP}[3] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_dst=@{EXTRA_NW_IP}[3]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_src=@{VM_IPS}[5]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src

Verify the punt path with traffic for same destination from different source IP
    [Documentation]    Verify the punt path with traffic for same destination from different source IP
    Verify Punt Values In XML File    @{FILES_PATH}[1]    @{DEFAULT_HARD_TIMEOUT}[1]
    ${napt_switch_ip} =     Get Compute IP From DPIN ID    @{ROUTERS}[1]
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[4]    telnet @{EXTRA_NW_IP}[2] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_dst=@{EXTRA_NW_IP}[2]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_src=@{VM_IPS}[4]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src
    ${pkt_count_before}    OvsManager.Get Packet Count From Table    ${napt_switch_ip}    ${INTEGRATION_BRIDGE}    ${SNAT_PUNT_TABLE}    |grep nw_src=@{VM_IPS}[5],tp_src=
    Log    ${pkt_count_before}
    BuiltIn.Should Be True    ${pkt_count_before} > 0
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{VM_IPS}[5]    telnet @{EXTRA_NW_IP}[2] &
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_dst=@{EXTRA_NW_IP}[2]    tp_dst=${TELNET_PORT} actions=drop
    OVSDB.Verify Dump Flows For Specific Table    ${napt_switch_ip}    ${SNAT_PUNT_TABLE}   True     |grep nw_src=@{VM_IPS}[5]    actions=set_field:${EXT_SUBNETS_FIXED_IP}->ip_src

*** Keywords ***
Set Default TimeOut In Xml
    [Documentation]    Verify Default TimeOut In Xml
    : FOR    ${index}    IN RANGE    0    3
    \    Change Hard Timeout Value In XML File    @{FILES_PATH}[${index}]    ${HARD_TIMEOUT_180}    @{DEFAULT_HARD_TIMEOUT}[${index}]
    \    Verify Punt Values In XML File    @{FILES_PATH}[${index}]    @{DEFAULT_HARD_TIMEOUT}[${index}]
    Restart Karaf
    Sleep    120s

Start Suite
    [Documentation]    Start suite to create common setup related SF441 openflow punt path
    VpnOperations.Basic Suite Setup
    Common Setup

Common Setup
    [Documentation]    create common topology
    Create Neutron Networks
    Create Neutron External Networks
    Create Neutron Subnets
    Create Neutron External Subnets
    Create Neutron Routers
    Add Router Interfaces
    Create And Configure Security Group    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs
    VPN Create L3VPNs
    Add Router Gateways
    Create Dictionary For DPN ID And Compute IP Mapping For 2 DPNS

Stop Suite
    [Documentation]    Setup start suite
    BuiltIn.Run Keyword And Ignore Error    Remove Gateway    @{ROUTERS}[0]
    BuiltIn.Run Keyword And Ignore Error    Remove Gateway    @{ROUTERS}[1]
    Issue_Command_On_Karaf_Console    configure-bgp -op delete-neighbor --ip ${TOOLS_SYSTEM_1_IP} --as-num ${AS_ID} --use-source-ip ${ODL_SYSTEM_IP}
    Issue Command On Karaf Console    bgp-cache
    : FOR    ${vpn}    IN    @{VPN_ID}
    \    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=${vpn}
    OpenStackOperations.OpenStack Cleanup All

Create Neutron Networks
    [Documentation]    Create Network with openstack request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron External Networks
    [Documentation]    Create External Network with openstack request.
    ${additional_args}    BuiltIn.Set Variable    --external --provider-network-type gre
    OpenStackOperations.Create Network    ${EXT_NETWORKS}    additional_args=${additional_args}
    ${elements} =    BuiltIn.Create List    ${EXT_NETWORKS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${elements}

Create Neutron Subnets
    [Documentation]    Create Subnet with openstack request.
    ${count} =    Get length    ${SUBNETS}
    : FOR    ${index}    IN RANGE    0    ${count}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNETS_CIDR}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Create Neutron External Subnets
    [Documentation]    Create Subnet with openstack request.
    ${additional_args}    BuiltIn.Set Variable    --no-dhcp
    OpenStackOperations.Create SubNet    ${EXT_NETWORKS}    ${EXT_SUBNETS}    ${EXT_SUBNETS_CIDR}    additional_args=${additional_args}
    ${elements} =    BuiltIn.Create List    ${EXT_SUBNETS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${elements}

Create Neutron Routers
    [Documentation]    Create Router with openstack request.
    ${router_id_list}    BuiltIn.Create List    @{EMPTY}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    Collections.Append To List    ${router_id_list}    ${router_id}
    BuiltIn.Set Suite Variable    ${router_id_list}

Add Router Interfaces
    [Documentation]    Add subnet interface to the routers.
    : FOR    ${index}    IN RANGE    0    2
    \    Add Router Interface    @{ROUTERS}[0]    @{SUBNETS}[${index}]
    Add Router Interface    @{ROUTERS}[1]    @{SUBNETS}[2]

Add Router Gateways
    [Documentation]    Add external gateway to the routers.
    ${cmd}    BuiltIn.Set Variable    openstack router set @{ROUTERS}[1] --external-gateway ${EXT_NETWORKS} --fixed-ip subnet=${EXT_SUBNETS},ip-address=${EXT_SUBNETS_FIXED_IP} --enable-snat
    OpenStack CLI    ${cmd}

VPN Create L3VPNs
    [Documentation]    Create an L3VPN using the Json using the list of optional arguments received.
    : FOR    ${index}    IN RANGE    0    2
    \    VpnOperations.VPN Create L3VPN    name=@{VPN_NAME}[${index}]    vpnid=@{VPN_ID}[${index}]    rd=@{L3VPN_RD_IRT_ERT}[${index}]    exportrt=@{L3VPN_RD_IRT_ERT}[${index}]    importrt=@{L3VPN_RD_IRT_ERT}[${index}]
    VpnOperations.Associate VPN to Router    routerid=@{router_id_list}[0]    vpnid=@{VPN_ID}[0]
    ${network_id} =    OpenStackOperations.Get Net Id    ${EXT_NETWORKS}
    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_ID}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_ID}[1]
    BuiltIn.Should Contain    ${resp}    ${network_id}

Create Neutron Ports
    [Documentation]    Create Port with openstack request.
    ${address_pair}    BuiltIn.Set Variable    --allowed-address ip-address=${ALLOW_ALL_ADDRESS}
    ${port1}    BuiltIn.Set Variable    --allowed-address ip-address=${ALLOW_ALL_ADDRESS} --fixed-ip subnet=@{SUBNETS}[0],ip-address=@{EXTRA_NW_IP}[0]
    ${port2}    BuiltIn.Set Variable    --allowed-address ip-address=${ALLOW_ALL_ADDRESS} --fixed-ip subnet=@{SUBNETS}[1],ip-address=@{EXTRA_NW_IP}[1]
    ${ext_net} =    BuiltIn.Create List    ${EXT_NETWORKS}
    ${NETWORKS_ALL}    Combine Lists    ${NETWORKS}    ${ext_net}
    : FOR    ${index}    IN RANGE    0    3
    \    Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index}}]    sg=${SECURITY_GROUP}
    \    Create Port    @{NETWORKS_ALL}[${index}]    @{PORT_LIST}[${index + ${index + 1}}]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{EXTRA_PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${port1}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{EXTRA_PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${port2}

Create Nova VMs
    [Documentation]    Create Port with neutron request
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[0]    @{VM_LIST}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[1]    @{VM_LIST}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[2]    @{VM_LIST}[2]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[3]    @{VM_LIST}[3]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[4]    @{VM_LIST}[4]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    @{PORT_LIST}[5]    @{VM_LIST}[5]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VM_LIST}
    Set Suite Variable    ${VM_IPS}
    BuiltIn.Should Not Contain    ${VM_IPS}    None
    BuiltIn.Should Not Contain    ${DHCP_IP}    None

Restart Karaf
    [Documentation]    Restarts Karaf and polls log to detect when Karaf is up and running again
    ${status} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/status
    Log    ${status}
    ${stop_msg} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/stop
    Log    ${stop_msg}
    Sleep    60s
    ${start_msg} =    Utils.Run Command On Remote System    ${ODL_SYSTEM_IP}    /tmp/${BUNDLEFOLDER}/bin/start
    Log    ${start_msg}

Verify Punt Values In XML File
    [Arguments]    ${file_path}    ${value}
    [Documentation]    To verify the default value for SNAT, ARP in ELAN, Subnet Routing in the xml file in ODL Controller
    SSHKeywords.Open_Connection_To_ODL_System
    ${output} =    Utils.Write Commands Until Expected Prompt    cat ${file_path} | grep punt-timeout    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{matches}    BuiltIn.Should Match Regexp    ${output}    punt.timeout.*?([0-9]+)
    BuiltIn.Should be true    @{matches}[1] == ${value}
    SSHLibrary.Close_Connection

Change Hard Timeout Value In XML File
    [Arguments]    ${file_path}    ${value_1}    ${value_2}
    [Documentation]    To change the default value in xml in the ODL controller for subnet route, SNAT and ARP
    SSHKeywords.Open_Connection_To_ODL_System
    Utils.Write Commands Until Expected Prompt    sed -i -e 's/punt-timeout\>${value_1}/punt-timeout\>${value_2}/' ${file_path}    ${DEFAULT_LINUX_PROMPT_STRICT}
    SSHLibrary.Close_Connection

Create Dictionary For DPN ID And Compute IP Mapping For 2 DPNS
    [Documentation]    Creating dictionary for DPN ID and compute IP mapping
    ${COMPUTE_1_DPNID} =    Get DPID    ${OS_CMP1_IP}
    BuiltIn.Set Suite Variable    ${COMPUTE_1_DPNID}
    ${COMPUTE_2_DPNID} =    Get DPID    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${COMPUTE_2_DPNID}
    ${CNTL_DPNID} =    Get DPID    ${OS_CNTL_IP}
    BuiltIn.Set Suite Variable    ${CNTL_DPNID}
    ${DPN_TO_COMPUTE_IP} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_1_DPNID}    ${OS_CMP1_IP}
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_2_DPNID}    ${OS_CMP2_IP}
    Collections.Set To Dictionary    ${DPN_TO_COMPUTE_IP}    ${CNTL_DPNID}    ${OS_CNTL_IP}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_1_DPNID}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${COMPUTE_2_DPNID}
    Collections.Dictionary Should Contain Key    ${DPN_TO_COMPUTE_IP}    ${CNTL_DPNID}
    BuiltIn.Set Suite Variable    ${DPN_TO_COMPUTE_IP}

Get SNAT NAPT Switch DPIN ID
    [Arguments]    ${router_name}
    [Documentation]    Returns the SNAT NAPT Switc dpnid from odl rest call.
    ${router_id}    OpenStackOperations.Get Router Id    ${router_name}
    ${output} =    Utils.Run Command On Remote System    ${OS_CMP1_IP}    curl -v -u admin:admin GET http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}${CONFIG_API}/odl-nat:napt-switches/router-to-napt-switch/${router_id}
    @{matches}    BuiltIn.Should Match Regexp    ${output}    switch.id.*?([0-9]+)
    ${dpnid} =    BuiltIn.Convert To Integer    @{matches}[1]
    [Return]    ${dpnid}

Get Compute IP From DPIN ID
    [Arguments]    ${router_name}
    [Documentation]    Returns the SNAT NAPT Switc dpnid from odl rest call.
    ${dpnid} =    Get SNAT NAPT Switch DPIN ID    ${router_name}
    ${compute_ip}    Collections.Get From Dictionary    ${DPN_TO_COMPUTE_IP}    ${dpnid}
    [Return]    ${compute_ip}

Set OVS Manager
    [Arguments]    ${ovs_ip}    ${controller_ip}    ${ovs_mgr_port}=6640
    [Documentation]    Add manager from OVS
    ${set_mgr} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl set-manager tcp:${controller_ip}:${ovs_mgr_port}
    BuiltIn.Log    ${set_mgr}
