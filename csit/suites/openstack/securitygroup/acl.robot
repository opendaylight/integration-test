*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
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
@{REQ_NETWORKS}    _Net1    _Net2
@{REQ_SUBNETS}    subnet1    subnet2
@{REQ_SUBNET_CIDR}    30.30.30.0/24    40.40.40.0/24
@{PORTS}    port_1    port_2    port_3    port_4    port5    port6 
@{VM_NAMES}    myvm1    myvm2    myvm3
@{SECURITY_GROUP}    SG1
${BR_NAME}    br-int
${VIRTUAL_IP}    30.30.30.100/24
${TABLE_NO}    table=210
${PACKET_COUNT}    5
${RANDOM_IP}    11.11.11.11
${NETMASK}    255.255.255.0
${PACKET_COUNT_ZERO}    0
${INCOMPLETE}    incomplete
${FLOW_DUMP_CMD}    sudo ovs-ofctl dump-flows -O Openflow13 br-int
${DHCP_CMD}    sudo /sbin/cirros-dhcpc up eth1
@{SPOOF}    30.30.30.100
@{SPOOF_MAC_ADDRESS}    FA:17:3E:73:65:86    fa:16:3e:3d:3b:5e
${ARP_CONFIG}    sudo ifconfig eth0 down \n sudo ifconfig eth0 hw ether ${SPOOF_MAC_ADDRESS[0]} \n sudo ifconfig eth0 up
 
*** Test Cases ***

TC1_Verify ARP request Valid MAC and Valid IP for the VM Egress Table
    Create Setup
    Create Vm Instance With Ports    ${PORTS[0]}    ${PORTS[1]}    ${VM_NAMES[0]}    ${OS_CMP1_HOSTNAME}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Ports    ${PORTS[2]}    ${PORTS[3]}    ${VM_NAMES[1]}    ${OS_CMP2_HOSTNAME}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    @{VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
    @{VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
    @{VM_IP_DPN3}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[2]}
    Set Global Variable    @{VM_IP_DPN1}
    Set Global Variable    @{VM_IP_DPN2}
    Set Global Variable    @{VM_IP_DPN3}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${PORTS[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${PORTS[2]}
    ${VM3_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${PORTS[4]}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
    ${vm3_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM3_Port}
    Set Global Variable    ${vm1_metadata}
    Set Global Variable    ${vm2_metadata}
    Set Global Variable    ${vm3_metadata}
    Set Global Variable    ${VM1_Port}
    Set Global Variable    ${VM2_Port}
    Set Global Variable    ${VM3_Port}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
    Check In Port    ${VM3_Port}   ${OS_CMP1_CONN_ID}
    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1[0]}    ${DHCP_CMD}
    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2[0]}    ${DHCP_CMD}
    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}    ${VM_IP_DPN3[0]}    ${DHCP_CMD}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${cmd}    Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP} 
    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN1[1]}    ${cmd}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT} 
    Delete Setup

TC4_Verify ARP request generated from SPOOFed IP for the VM
    Switch Connection    ${OS_CMP1_CONN_ID}
    ${cmd}    Set Variable    sudo ifconfig eth0:1 ${SPOOF[0]} netmask ${NETMASK} up
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep drop
    ${cmd}    Set Variable    sudo arping -s ${SPOOF[0]} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_after}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep drop
    ${pkt_diff_arp_drop}    Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

TC5_Verify ARP request generated from SPOOFed MAC for the VM
    Switch Connection    ${OS_CMP1_CONN_ID}
    Log     Change the Mac Address of eth1
    ${count}    Get Line Count    ${ARP_CONFIG}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${ARP_CONFIG}    ${index}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep drop
    ${cmd}    Set Variable    sudo arping -I eth0 -c ${PACKET_COUNT} \ ${RANDOM_IP}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_after}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep drop
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop}    Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}

TC6_Verify ARP request generated from SPOOFed IP and spoofed MAC for the VM
    Switch Connection    ${OS_CMP1_CONN_ID}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep drop
    ${cmd}    Set Variable    sudo arping -s ${SPOOF[0]} -c ${PACKET_COUNT} \ ${RANDOM_IP}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_after}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    arp|grep drop
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop}    Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${PACKET_COUNT}
    Log    Get the vm mac address and put back the original
    ${cmd}    Set Variable    sudo ifconfig eth0 down
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth0 hw ether ${SPOOF_MAC_ADDRESS[1]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth0 ${VM_IP_DPN1[0]}/24 up
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}

TC7_ Verify Ping - Valid MAC and Valid IP for the VM by clearing the ARP Cache
    Switch Connection    ${OS_CMP2__CONN_ID}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    @{arp_ip}    Get Regexp Matches    ${output}    [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
    ${cmd}    Set Variable    sudo arp -d ${arp_ip[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${arp_ip[1]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${VM_IP_DPN1[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${VM_IP_DPN3[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Sleep    180
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
  ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    ${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}
    Should Not Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}

TC8_Verify IPv4 unicast traffic with MAC Address and IP Address (Valid MAC + Valid IP)
    Switch Connection    ${OS_CMP2__CONN_ID}
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    #${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT}
    #Should Not Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}

TC9_ Verify Ping - Spoofed IP and Valid Mac for the VM by clearing the ARP cache
    Switch Connection    ${OS_CMP2__CONN_ID}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    @{arp_ip}    Get Regexp Matches    ${output}    [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
    : FOR    ${item}    IN    @{arp_ip}
    \    ${cmd}    Set Variable    sudo arp -d ${item}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN2[1]}    ${cmd}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN2[1]}    ${cmd}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth0:1 ${SPOOF[0]} netmask ${NETMASK} up
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${VM_IP_DPN1[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${VM_IP_DPN3[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Sleep    10
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_before_arp}      Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    ${INCOMPLETE}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_after_arp}       Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    ${pkt_diff_drop}    Evaluate    int(${get_pkt_drop_after_arp})-int(${get_pkt_drop_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    #Should Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}
    Should Not Be Equal As Numbers     ${pkt_diff_drop}    ${PACKET_COUNT}

TC10_ Verify IPv4 unicast traffic by SPOOFing IP Address (Invalid IP + Valid MAC)
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_drop_before_arp}      Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]} -I ${SPOOF[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_drop_after_arp}       Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    #${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_drop}    Evaluate    int(${get_pkt_drop_after_arp})-int(${get_pkt_drop_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    Should Not Be Equal As Numbers     ${pkt_diff_drop}    ${PACKET_COUNT}

TC11_ Verify Ping - Vaild IP and Spoofed Mac for the VM by clearing the ARP cache
    Switch Connection    ${OS_CMP2__CONN_ID}
    #${cmd}    Set Variable    sudo ifconfig eth0 ${VM_IP_DPN2[0]} up
    #${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    #...    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    @{arp_ip}    Get Regexp Matches    ${output}    [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
    : FOR    ${item}    IN    @{arp_ip}
    \    ${cmd}    Set Variable    sudo arp -d ${item}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN2[1]}    ${cmd}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN2[1]}    ${cmd}
    \    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}    ${VM_IP_DPN2[1]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth0 down
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth0 hw ether ${SPOOF_MAC_ADDRESS[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth0 up
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN1[1]}    ${cmd}
    Sleep    10
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    #Should Not Contain    ${output}    eth0
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_before_arp}      Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]} -I ${SPOOF[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    100% packet loss
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    eth0
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_after_arp}       Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    ${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_drop}    Evaluate    int(${get_pkt_drop_after_arp})-int(${get_pkt_drop_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    Should Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}
    Should Not Be Equal As Numbers     ${pkt_diff_drop}    ${PACKET_COUNT}

TC12_ Verify IPv4 unicast traffic by SPOOFing MAC Address (Invalid MAC + Valid IP)
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_drop_before_arp}      Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]} -I ${SPOOF[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    100% packet loss
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_drop_after_arp}       Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    #${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_drop}    Evaluate    int(${get_pkt_drop_after_arp})-int(${get_pkt_drop_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    #Should Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}
    Should Not Be Equal As Numbers     ${pkt_diff_drop}    ${PACKET_COUNT}
TC13_ Verify Ping - Spoofed IP and Spoofed Mac for the VM by clearing the ARP cache
    Switch Connection    ${OS_CMP2__CONN_ID}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    eth0
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_before_arp}      Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]} -I ${SPOOF[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    100% packet loss
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    eth0
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_after_arp}       Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    ${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_drop}    Evaluate    int(${get_pkt_drop_after_arp})-int(${get_pkt_drop_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    Should Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}
    Should Not Be Equal As Numbers     ${pkt_diff_drop}    ${PACKET_COUNT}
TC14_ Verify IPv4 unicast traffic by SPOOFing MAC Address and IP Address After port security enabled false
    ${FLOW_DUMP_CMD}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    #${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_before_arp}      Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[0]} -I ${SPOOF[0]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    100% packet loss
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[1]}
    ...    ${VM_IP_DPN2[1]}    ${cmd}
    Should Contain    ${output}    eth0
    Capture Flows    ${OS_CMP1_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${FLOW_DUMP_CMD}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep nw_src
    #${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep arp_sha
    ${get_pkt_drop_after_arp}       Get Packetcount    ${OS_CMP2_CONN_ID}    ${BR_NAME}    ${TABLE_NO}    ${vm2_metadata}|grep drop|grep actions
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    #${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_drop}    Evaluate    int(${get_pkt_drop_after_arp})-int(${get_pkt_drop_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${PACKET_COUNT_ZERO}
    #Should Be Equal As Numbers    ${pkt_diff_arp_sha}    ${PACKET_COUNT_ZERO}
    Should Not Be Equal As Numbers     ${pkt_diff_drop}    ${PACKET_COUNT}
    [Teardown]    Delete Setup


*** Keywords ***

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports 
    Create Neutron Networks    2
    Create Neutron Subnets    2    
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP[0]}
    OpenStackOperations.Delete All Security Group Rules    ${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[0]}    ${PORTS[0]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[1]}    ${PORTS[1]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[0]}    ${PORTS[2]}    sg=${SECURITY_GROUP[0]}
    Create Port    ${REQ_NETWORKS[1]}    ${PORTS[3]}    sg=${SECURITY_GROUP[0]}
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0


Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${net}    IN    @{REQ_NETWORKS}
    \    Create Network    ${net}
    ${net_list}    List Networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${net_list}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${sub_list}    List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${sub_list}    ${REQ_SUBNETS[${index}]}


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
    ${port_id}    Get Port Id    ${portname}    ${conn_id}
    Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{output}    Get Regexp Matches    ${port_id}    (\\w{8}-\\w{2})
    [Return]    ${output[0]}

Get Port Number
    [Arguments]    ${connec_id}    ${BR_NAME}    ${portname}
    [Documentation]    Get the port number for given portname
    SSHLibrary.Switch Connection    ${connec_id}
    ${pnum}    Get Sub Port Id    ${portname}    ${connec_id}
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show ${BR_NAME} | grep ${pnum} | awk '{print$1}'
    log    sudo ovs-ofctl -O OpenFlow13 show ${BR_NAME} | grep ${pnum} | awk '{print$1}'
    ${num}    DevstackUtils.Write Commands Until Prompt    ${command_1}    30
    log    ${num}
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    [Return]    ${port_number}

In Port VM
    [Arguments]    ${conn_id}    ${BR_NAME}    ${portname}
    [Documentation]    Get the port number for given portname
    ${VM_Port}    Get Port Number    ${conn_id}    ${BR_NAME}    ${portname}
    [Return]    ${VM_port}

Check In Port
    [Arguments]    ${port}    ${conn_id}
    [Documentation]    Check the port present in table 0
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep table=0
    ${output}    DevstackUtils.Write Commands Until Prompt   ${cmd}    60
    log    ${output}
    should contain    ${output}    in_port=${port}

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Get the Metadata for a given port
    Switch Connection    ${conn_id}
    ${grep_metadata}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME}| grep table=0 | grep in_port=${port} | awk '{print$7}'    30
    log    ${grep_metadata}
    @{metadata}    Split String    ${grep_metadata}    ,
    ${metadata1}    Get From List    ${metadata}    0
    @{final_meta}    Split String    ${metadata1}    :
    ${metadata_final}    Get From List    ${final_meta}    1
    @{metadata_final1}    Split String    ${metadata_final}    /
    ${meta}    Get From List    ${metadata_final1}    0
    #@{metadata}  Get Regexp Matches   ${grep_metadata}     metadata:(\\w{12})
    #${metadata1}    Convert To String    @{metadata}
    #${y}    strip string    ${metadata1}    mode=right    characters=0000
    #${z}    set variable    00
    #${i}    Concatenate the String    ${y}    ${z}
    #${metadata2}    Remove Space on String    ${i}
    [Return]    ${meta}

Table Check
    [Arguments]    ${connection_id}    ${BR_NAME}    ${table_cmdSuffix}    @{validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep ${table_cmdSuffix}   30
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Table Check for 220
    [Arguments]    ${connection_id}    ${BR_NAME}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep ${table_cmdSuffix}    30
    Log    ${cmd}
    ${i}    Create List
    ${p}    Get Line Count    ${cmd}
    : FOR    ${line}    IN RANGE    0    2
    \    ${line1}    Get Line    ${cmd}    ${line}
    \    ${match}    Get Regexp Matches    ${line1}    n_packets=(\\d+)
    \    Append To List    ${i}    ${match}
    Should Be Equal    ${i[0]}    ${i[1]}

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnets, networks etc.
    Log    Dumping all the flows
    Log    Delete the VM instance
    :FOR    ${vm_name}    IN    @{VM_NAMES}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${vm_name}
    Log    Delete the Port created
    :FOR    ${port_name}    IN    @{PORTS}
    \    Run Keyword And Ignore Error    Delete Port    ${port_name}
    Log    Delete-Subnet
    :FOR    ${snet}    IN    @{REQ_SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${snet}
    Log    Delete-networks
    :FOR    ${net}    IN    @{REQ_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${net}
    :FOR    ${sec_grp}    IN    @{SECURITY_GROUP} 
    \    Run Keyword And Ignore Error    Delete SecurityGroup    ${sec_grp}

Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4$5}'
    ${output} =    OpenStack CLI     ${cmd}
    @{output}    Split String    ${output}    ;
    ${output_string1}    Convert To String    ${output[0]}
    ${output_string2}    Convert To String    ${output[1]}
    @{net1_string}    Split String    ${output_string1}    =
    @{net2_string}    Split String    ${output_string2}    =
    @{final_list}    Create List    ${net1_string[1]}    ${net2_string[1]}
    [Return]    @{final_list}

Capture Flows  
    [Arguments]    ${conn_id}    ${BR_NAME}    ${cmd}
    [Documentation]    Capture flows
    Switch Connection    ${conn_id}
    ${output}     Execute Command    ${cmd}
    Log    ${output}

Get Packetcount
    [Arguments]    ${conn_id}    ${BR_NAME}    ${TABLE_NO}    ${conn_state}
    [Documentation]    Capture flows
    Switch Connection    ${conn_id}
    ${output}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${BR_NAME} | grep ${TABLE_NO} | grep ${conn_state}  
    @{output_list}    Split String    ${output}    \r\n
    ${flow}    Get From List    ${output_list}     0 
    ${packetcount_list}    Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1 
    ${count}    Get From List    ${packetcount_list}    0
    [Return]    ${count}
