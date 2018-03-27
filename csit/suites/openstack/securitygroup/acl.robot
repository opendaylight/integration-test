*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown
Test Setup
Test Teardown     
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Library           BuiltIn
Library           DebugLibrary
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot

*** Variables ***
${NUM_OF_NETWORK}   2
${Req_no_of_net}    1
${Req_no_of_subNet}    1
${Req_no_of_ports}    6
${Req_no_of_vms_per_dpn}    1
#${OS_CONTROL_NODE_IP}    192.168.56.100
@{PORT_LIST}    port_1    port_2    port_3    port_4    port_5    port_6
@{table_list}    table=220    table=17
${VM1_ROUTER_ID}    127.1.1.100
${VM2_ROUTER_ID}    127.1.1.200
${VM1_Loopback_address}    127.1.1.1/32
${VM2_Loopback_address}    127.1.1.2/32
${OSPF_Area}    0.0.0.0
${OSPF_Network1}    127.1.1.0/24
${OSPF_Network2}    30.30.30.0/24
@{VM_NAMES}    myvm1    myvm2    myvm3 
@{SECURITY_GROUP}    SG1    SG2
@{REQ_NETWORKS}    _Net1    _Net2
@{REQ_SUBNETS}    subnet1    subnet2
@{REQ_SUBNET_CIDR}    30.30.30.0/24    40.40.40.0/24
${NUM_OF_VMS_PER_DPN}    1
${br_name}    br-int
${Virtual_IP}    30.30.30.100/24
@{Priority}    100    90
${router_name}    router1
${Cirros_user}     cirros
${Cirrios_password}    cubswin:)
${table_no}    table=210
${packet_count}    5
${random_ip}    11.11.11.11
${spoof_mac_address}    FA:16:3E:73:65:86
${packet_count_zero}    0
@{spoof}    30.30.30.100
${netmask}    255.255.255.0
@{check_list}    goto_table:239    goto_table:210    reg6=
${VM1_Config}    configure \n delete interfaces tunnel tun0 \n delete interfaces loopback lo \n delete protocols \n commit \n save \n set interfaces loopback lo address ${VM1_Loopback_address} \n set protocols ospf area ${OSPF_Area} \n set protocols ospf area ${OSPF_Area} network ${OSPF_Network1} \n set protocols ospf area ${OSPF_Area} network ${OSPF_Network2} \n set protocols ospf parameters router-id ${VM1_ROUTER_ID} \n set protocols ospf log-adjacency-changes\n set protocols ospf redistribute connect \n commit \n save
${VM2_Config}    configure \n delete interfaces tunnel tun0 \n delete interfaces loopback lo \n delete protocols \n commit \n save \n set interfaces loopback lo address ${VM2_Loopback_address} \n set protocols ospf area ${OSPF_Area} \n set protocols ospf area ${OSPF_Area} network ${OSPF_Network1} \n set protocols ospf area ${OSPF_Area} network ${OSPF_Network2} \n set protocols ospf parameters router-id ${VM2_ROUTER_ID} \n set protocols ospf log-adjacency-changes \n set protocols ospf redistribute connect \n commit \n save
${VM1_VRRP_CONFIG}    configure \n delete interfaces tunnel tun0 \n delete interfaces loopback lo \n delete protocols \n commit \n save \n set interfaces ethernet eth0 vrrp vrrp-group 1 priority ${Priority[0]} \n set interfaces ethernet eth0 vrrp vrrp-group 1 rfc3768-compatibility \n set interfaces ethernet eth0 vrrp vrrp-group 1 virtual-address ${Virtual_IP} \n commit \n save
${VM2_VRRP_CONFIG}    configure \n delete interfaces tunnel tun0 \n delete interfaces loopback lo \n delete protocols \n commit \n save \n set interfaces ethernet eth0 vrrp vrrp-group 1 priority ${Priority[1]} \n set in    terfaces ethernet eth0 vrrp vrrp-group 1 rfc3768-compatibility \n set interfaces ethernet eth0 vrrp vrrp-group 1 virtual-address ${Virtual_IP} \n commit \n save
 
*** Test Cases ***
#TC1_Verify OSPF traffic ( Hello Packets-Multicast) works fine with Default SG in same subnet
#    [Documentation]    Verify OSPF traffic ( Hello Packets-Multicast) works fine with Default SG in same subnet
#    Log    Suite testing
#    Create Nova VMs    ${Req_no_of_vms_per_dpn}
#    Sleep    10 minutes
#    ${VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
#    ${VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
#    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${PORT_LIST[0]}
#    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${PORT_LIST[1]}
#    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
#    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
#    #${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
#    #@{vm2_metadata1}   Split String    ${vm2_metadata}    :
#    Alllowed Adress Pair Config    ${Req_no_of_ports}
#    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
#    OSPF CONFIG ON VM    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}
#    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
#    Verify OSPF Neighbourship FULL State    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2}    ${VM1_ROUTER_ID}
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP1_CONN_ID}    ${br_name}    ${check_list[0]}
#    ...    ${table_list[0]}
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    ${check_list[1]}
#    ...    ${table_list[1]}
#    @{table_220}    Create List    actions=output:${VM2_Port}    goto_table:239
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    table=220 
#    ...    @{table_220}
#    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list SG1 | grep ospf | awk '{print $2}'
#    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
#    : FOR    ${rule}    IN    @{sg_rules}
#    \    ${output} =    OpenStack CLI    openstack security group rule delete ${rule}
#    Sleep    180 
#    ${output}    Show IP OSPF Neighbour    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2}
#    Should Not Contain    ${output}    Full/DR
#    [Teardown]    Delete TestSetup
#
#TC2_Verify VRRP traffic (Advertisements-Multicast) works fine with Default SG in same subnet
#    [Documentation]    Verify VRRP traffic (Advertisements-Multicast) works fine with Default SG in same subnet
#    Log    Suite testing
#    Create Nova VMs    ${Req_no_of_vms_per_dpn}
#    Sleep    10 minutes
#    ${VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
#    ${VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
#    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${PORT_LIST[0]}
#    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${PORT_LIST[1]}
#    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
#    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
#    #${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
#    #@{vm2_metadata1}   Split String    ${vm2_metadata}
#    VRRP Alllowed Adress Pair Config    ${Req_no_of_ports}    ${VM_IP_DPN1}    ${VM_IP_DPN2}
#    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
#    VRRP CONFIG    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}
#    Verify VRRP State    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}
#    Verify VRRP State    ${REQ_NETWORKS[0]}    ${VM_IP_DPN2}    BACKUP
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP1_CONN_ID}    ${br_name}    ${check_list[0]}
#    ...    ${table_list[0]}
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    ${check_list[1]}
#    ...    ${table_list[1]}
#    @{table_220}    Create List    actions=output:${VM2_Port}    goto_table:239
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    table=220
#    ...    @{table_220}
#    ${sg_rules_output} =    OpenStack CLI    openstack security group rule list SG1 | grep vrrp | awk '{print $2}'
#    @{sg_rules} =    String.Split String    ${sg_rules_output}    \n
#    : FOR    ${rule}    IN    @{sg_rules}
#    \    ${output} =    OpenStack CLI    openstack security group rule delete ${rule}
#    ${cmd}    Set Variable    show vrrp
#    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
#    ...    ${VM_IP_DPN1}    ${cmd}    vyos    vyos
#    Should Contain    ${output}    MASTER
#    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
#    ...    ${VM_IP_DPN2}    ${cmd}    vyos    vyos
#    Should Contain    ${output}    MASTER
#    [Teardown]    Delete Setup


TC3_Verify ARP request Valid MAC and Valid IP for the VM Egress Table
    Create Nova VMs    3    cirros
    @{VM_IP_DPN1}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[0]}
    @{VM_IP_DPN2}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP2_CONN_ID}    ${VM_NAMES[1]}
    @{VM_IP_DPN3}    Wait Until Keyword Succeeds    240 sec    60 sec    Get VM IP Address    ${OS_CMP1_CONN_ID}    ${VM_NAMES[2]}
    Set Global Variable    @{VM_IP_DPN1}
    Set Global Variable    @{VM_IP_DPN3}
    Set Global Variable    @{VM_IP_DPN2}
    ${VM1_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${PORT_LIST[0]}
    ${VM2_Port}    In Port VM    ${OS_CMP2_CONN_ID}    ${br_name}    ${PORT_LIST[2]}
    ${VM3_Port}    In Port VM    ${OS_CMP1_CONN_ID}    ${br_name}    ${PORT_LIST[4]}
    Check In Port    ${VM1_Port}   ${OS_CMP1_CONN_ID}
    Check In Port    ${VM2_Port}   ${OS_CMP2_CONN_ID}
    Check In Port    ${VM3_Port}   ${OS_CMP1_CONN_ID}
    ${vm1_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM1_Port}
    ${vm2_metadata}    Get Metadata    ${OS_CMP2_CONN_ID}    ${VM2_Port}
    ${vm3_metadata}    Get Metadata    ${OS_CMP1_CONN_ID}    ${VM3_Port}
    Set Global Variable    ${vm1_metadata}
    Set Global Variable    ${vm2_metadata} 
    Set Global Variable    ${vm3_metadata}
    Set Global Variable    ${VM1_Port}   
    Set Global Variable    ${VM2_Port}
    Set Global Variable    ${VM3_Port}
    ${VM1_Port_MAC}    Get Port Mac    ${PORT_LIST[0]}
    Set Global Variable    ${VM1_Port_MAC}
    ${cmd}    Set Variable    ifconfig eth0  
    Sleep    120
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}    ${Cirros_user}    ${Cirrios_password}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${cmd}    Set Variable    sudo /sbin/cirros-dhcpc up eth1
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN3[0]}    ${cmd}
    ${cmd}    Set Variable    sudo arping -I eth1 -c ${packet_count} \ ${random_ip} 
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}    
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${packet_count} 


TC4_Verify ARP request generated from spoofed IP for the VM
    Switch Connection    ${OS_CMP1_CONN_ID}
    ${cmd}    Set Variable    sudo ifconfig eth1:1 ${spoof[0]} netmask ${netmask} up
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    arp|grep drop
    ${cmd}    Set Variable    sudo arping -s ${spoof[0]} -c ${packet_count} \ ${random_ip} 
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_after}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    arp|grep drop
    ${pkt_diff_arp_drop}    Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${packet_count_zero}
    Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${packet_count}


TC5_Verify ARP request generated from spoofed MAC for the VM
    Switch Connection    ${OS_CMP1_CONN_ID}
    Log     Change the Mac Address of eth1
    ${cmd}    Set Variable    sudo ifconfig eth1 down
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth1 hw ether ${spoof_mac_address}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth1 up  
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    arp|grep drop 
    ${cmd}    Set Variable    sudo arping -I eth1 -c ${packet_count} \ ${random_ip}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_after}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    arp|grep drop
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop}    Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    Should Be Equal As Numbers    ${pkt_diff}    ${packet_count_zero}
    Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${packet_count}

TC6_Verify ARP request generated from spoofed IP and spoofed MAC for the VM
    Switch Connection    ${OS_CMP1_CONN_ID}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    arp|grep drop
    ${cmd}    Set Variable    sudo arping -s ${spoof[0]} -c ${packet_count} \ ${random_ip}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${ovs1_output}    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    ${vm1_metadata}|grep arp_sha
    ${get_arp_drop_pkt_before}    Get Packetcount    ${OS_CMP1_CONN_ID}    ${br_name}    ${table_no}    arp|grep drop
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    ${pkt_diff_arp_drop}    Evaluate    int(${get_arp_drop_pkt_after})-int(${get_arp_drop_pkt_before})
    Should Be Equal As Numbers    ${pkt_diff}    ${packet_count_zero}
    Should Be Equal As Numbers    ${pkt_diff_arp_drop}    ${packet_count}
    Log    Get the vm mac address and put back the original 
    ${cmd}    Set Variable    sudo ifconfig eth1 down
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth1 hw ether ${mac1}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN[0]}    ${cmd}
    ${cmd}    Set Variable    sudo ifconfig eth1 ${VM_IP_DPN1[1]}/24 up
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN1[0]}    ${cmd}

TC7_ Verify Ping - Valid MAC and Valid IP for the VM by clearing the ARP Cache
    Switch Connection    ${OS_CMP2__CONN_ID}
    Debug
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${VM_IP_DPN1[1]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -d ${VM_IP_DPN3[1]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${flow_dump_cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int 
    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_before_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${table_no}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_before_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${table_no}    ${vm2_metadata}|grep arp_sha
    ${cmd}    Set Variable    ping -c 5 ${VM_IP_DPN3[1]}
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    ${cmd}    Set Variable    sudo arp -a
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${REQ_NETWORKS[0]}
    ...    ${VM_IP_DPN2[0]}    ${cmd}
    Capture Flows    ${OS_CMP1_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    Capture Flows    ${OS_CMP2_CONN_ID}    ${br_name}    ${flow_dump_cmd}
    ${get_pkt_count_after_arp_nw_src}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${table_no}    ${vm2_metadata}|grep nw_src
    ${get_pkt_count_after_arp}     Get Packetcount    ${OS_CMP2_CONN_ID}    ${br_name}    ${table_no}    ${vm2_metadata}|grep arp_sha
    ${pkt_diff}    Evaluate    int(${get_pkt_count_after_arp_nw_src})-int(${get_pkt_count_before_arp_nw_src})
    ${pkt_diff_arp_sha}    Evaluate    int(${get_pkt_count_after_arp})-int(${get_pkt_count_before_arp})
    Should Be Equal As Numbers    ${pkt_diff}    ${packet_count}
    Should Be Equal As Numbers    ${pkt_diff_arp_sha}    ${packet_count_zero}
    [Teardown]    Delete Setup
    
#
#TC3_Verify
#    [Documentation]    Verify UDP Multicast traffic with custom SG with default rules
#    UDP/TCP/ICMP Multicast traffic with custom SG
#    Log    Suite testing
#    Create Nova VMs    ${Req_no_of_vms_per_dpn}
#    @{VM_IP_DPN1}    Get VM Ip Addresses    @{VM_INSTANCES_DPN1}
#    @{VM_IP_DPN2}    Get VM Ip Addresses    @{VM_INSTANCES_DPN2}
#    Verify VM to VM Ping Status    ${REQ_NETWORKS[0]}    ${VM_IP_DPN1}    ${VM_IP_DPN2}    ${PING_REGEXP}
#    Allowed Adress Pair Config    ${Req_no_of_ports}
#    Add Static Route to Multicast IP
#    ${proto_arg}    Set Variable If    '${protocol}'=='udp'    nc -u    nc
#    ${cmd}    Set Variable
#    Execute Command on VM Instance    ${REQ_NETWORKS[0]}    ${VM1_IP_DPN1[0]}    ${cmd}    ${user}=cirros    ${password}=cubswin:)    ${expec_output}
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP1_CONN_ID}    ${br_name}    ${vm1_metadata}
#    ...    ${table_list[0]}
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    ${vm2_metadata}
#    ...    ${table_list[1]}
#    @{table_220}    Create List    reg6=${vm1_metadata}    actions=output:${VM2_Port}    actions=load:${vm1_metadata}    goto_table:241
#    Wait Until Keyword Succeeds    40 sec    10 sec    Table Check    ${OS_CMP2_CONN_ID}    ${br_name}    reg6=
#    ...    @{table_220}
#    Table Check for 220    ${OS_CMP2_CONN_ID}    ${br_name}    reg6=
#    ${Pkt_cnt_before_ping}    get packetcount    ${br_name}    ${OS_CMP1_CONN_ID}    table=0    ${load_vm1_metadata}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for CR156 Multicast
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    #Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create tunnels between the 2 compute nodes
    ${devstack_conn_id}    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    @{availibity_zone}    Create List    ${OS_CNTL_HOSTNAME}    ${OS_CMP2_HOSTNAME}    ${OS_CNTL_HOSTNAME}
    Set Global Variable    @{availibity_zone}    
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP[0]}
    Create Neutron Ports    6
    #Create Router    ${router_name}
    Security Group Rule with Remote IP Prefix

Security Group Rule with Remote IP Prefix
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=icmp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=ospf    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=ospf    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=egress    protocol=vrrp    remote-ip=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP[0]}    direction=ingress    protocol=vrrp    remote-ip=0.0.0.0/0


Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    Create Network    ${NET}
    ${NET_LIST}    List Networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    List Subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Create required number of ports under previously created subnets
    :FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    Create Port    ${REQ_NETWORKS[0]}    ${PORT_LIST[${index}]}    sg=${SECURITY_GROUP[0]}

Create Nova VMs
    [Arguments]    ${index}    ${image}=vyos    ${flavor}=m1.medium   
    [Documentation]    Create Vm instances on compute nodes
    BuiltIn.Run Keyword If    '${image}' == 'vyos'    VYOS VM    ${index}    ${image}    ${flavor}
    ...    ELSE    CIRROS VM    ${index}        
    : FOR    ${i}    IN RANGE    0    ${index}
    \    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${VM_NAMES[${i}]}

VYOS VM
    [Arguments]    ${index}    ${image}    ${flavor}
    [Documentation]    Create Vm instances on compute nodes
    : For    ${i}    IN RANGE    0    ${index}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${i}]}    ${VM_NAMES[${i}]}    ${availibity_zone[${i}]}    ${image}    ${flavor}    sg=${SECURITY_GROUP[0]}

CIRROS VM
    [Arguments]    ${index}   
    [Documentation]    Create Vm instances on compute nodes
    Create Vm Instance With Ports    ${PORT_LIST[0]}    ${PORT_LIST[1]}    ${VM_NAMES[0]}    ${availibity_zone[0]}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Ports    ${PORT_LIST[2]}    ${PORT_LIST[3]}    ${VM_NAMES[1]}    ${availibity_zone[1]}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}
    Create Vm Instance With Ports    ${PORT_LIST[4]}    ${PORT_LIST[5]}    ${VM_NAMES[2]}    ${availibity_zone[2]}    flavor=m1.tiny    sg=${SECURITY_GROUP[0]}

Verify VM to VM Ping Status
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}    ${PING_REGEXP}
    [Documentation]    Verify Ping Success among VMs
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
    ...    ping ${VM_IP2} count 8    vyos    vyos
    Should Contain    ${output}    ${PING_REGEXP}

OSPF CONFIG ON VM
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}
    [Documentation]    Verify Ping Success among VMs
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP1} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    vyos    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM1_Config}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM1_Config}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    \#
    Utils.Write Commands Until Expected Prompt    exit    $
    Utils.Write Commands Until Expected Prompt    exit    $
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP2} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    vyos    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM2_Config}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM2_Config}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    \#
    Utils.Write Commands Until Expected Prompt    exit    $
    Utils.Write Commands Until Expected Prompt    exit    $

Show IP OSPF Neighbour
    [Arguments]    ${NETWORK}    ${VM_IP1}
    [Documentation]    Display OSPF neighbour output
    ${cmd}    Set Variable    show ip ospf neighbor
    ${output}    Wait Until Keyword Succeeds    80s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
    ...    ${cmd}    vyos    vyos
    log    ${output}
    [Return]    ${output}

Verify OSPF Neighbourship FULL State
    [Arguments]    ${Network}    ${VM_IP}    ${ROUTER_ID}
    [Documentation]    Verify OSPF Neighbourship FULL State Established
    ${output}    Show IP OSPF Neighbour    ${Network}    ${VM_IP}
    ${rc}    Should Match Regexp    ${output}    (${ROUTER_ID})(\\W+\\d\\W)(Full/DR)

Alllowed Adress Pair Config
    [Arguments]    ${NUM_OF_PORTS}
    [Documentation]    Update Port with AAP
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port-id}    Get Port Id    ${PORT_LIST[${index}]}    ${OS_CMP1_CONN_ID}
    \    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:05,ip-address=224.0.0.5

VRRP Alllowed Adress Pair Config
    [Arguments]    ${NUM_OF_PORTS}    ${VM_IP_DPN1}    ${VM_IP_DPN2}
    [Documentation]    Update Port with AAP
    ${port-id}    Get Port Id    ${PORT_LIST[0]}    ${OS_CMP1_CONN_ID}
    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:12,ip-address=224.0.0.18 --allowed-address mac-address=00:00:5e:00:01:01,ip-address=${VM_IP_DPN1}
    ${port-id}    Get Port Id    ${PORT_LIST[1]}    ${OS_CMP1_CONN_ID}
    Update Port    ${port-id}    --allowed-address mac-address=01:00:5e:00:00:12,ip-address=224.0.0.18 --allowed-address mac-address=00:00:5e:00:01:01,ip-address=${VM_IP_DPN2}
    


VRRP CONFIG
    [Arguments]    ${NETWORK}    ${VM_IP1}    ${VM_IP2}    
    [Documentation]    Configure VRRP
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP1} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    vyos    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM1_VRRP_CONFIG}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM1_VRRP_CONFIG}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    \#
    Utils.Write Commands Until Expected Prompt    exit    $
    Utils.Write Commands Until Expected Prompt    exit    $
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh vyos@${VM_IP2} -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null    password:
    ${output} =    Utils.Write Commands Until Expected Prompt    vyos    ${OS_SYSTEM_PROMPT}
    ${count}    Get Line Count    ${VM2_VRRP_CONFIG}
    :FOR    ${index}    IN RANGE    0    ${count}
    \    ${cmd}    Get Line    ${VM2_VRRP_CONFIG}    ${index}
    \    Utils.Write Commands Until Expected Prompt    ${cmd}    \#
    Utils.Write Commands Until Expected Prompt    exit    $
    Utils.Write Commands Until Expected Prompt    exit    $


Run Show VRRP
    [Arguments]    ${NETWORK}    ${VM_IP}
    [Documentation]    Display run Show VRRP output.
    ${cmd}    Set Variable    show vrrp
    ${output}    Wait Until Keyword Succeeds    60s    10s    Execute Command on VM Instance    ${NETWORK}
    ...    ${VM_IP}    ${cmd}    vyos    vyos
    [Return]    ${output}

Verify VRRP State
    [Arguments]    ${NETWORK}    ${VM_IP}    ${State}=MASTER
    [Documentation]    Verify the RUN SHOW VRRP o/p for MASTER and BACKUP.
    ${output}    Run Show VRRP    ${NETWORK}    ${VM_IP}
    Should Contain    ${output}    ${State}

Add Static Route to Multicast IP
    [Arguments]    ${Network}    ${VM_IP1}
    [Documentation]    Add static route to Multicast IP.
    ${cmd}    Set Variable    Sudo route add -host 224.0.0.1 ${ens}
    ${rc}    ${output}=    Execute Command on VM Instance    ${Network}    ${VM_IP1}    ${cmd}
    Should Be True    '${rc}' == '0'
    [Return]    ${output}

Add Static Route to Multicast IP
    [Arguments]    ${Network}    ${VM_IP1}
    [Documentation]    Add static route to Multicast IP

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
    [Arguments]    ${connec_id}    ${br_name}    ${portname}
    [Documentation]    Get the port number for given portname
    SSHLibrary.Switch Connection    ${connec_id}
    ${pnum}    Get Sub Port Id    ${portname}    ${connec_id}
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pnum} | awk '{print$1}'
    log    sudo ovs-ofctl -O OpenFlow13 show ${br_name} | grep ${pnum} | awk '{print$1}'
    ${num}    DevstackUtils.Write Commands Until Prompt    ${command_1}    30
    log    ${num}
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    [Return]    ${port_number}

In Port VM
    [Arguments]    ${conn_id}    ${br_name}    ${portname}
    [Documentation]    Get the port number for given portname
    ${VM_Port}    Get Port Number    ${conn_id}    ${br_name}    ${portname}
    [Return]    ${VM_port}

Check In Port
    [Arguments]    ${port}    ${conn_id}
    [Documentation]    Check the port present in table 0
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep table=0
    ${output}    DevstackUtils.Write Commands Until Prompt   ${cmd}    60
    log    ${output}
    should contain    ${output}    in_port=${port}

Get Metadata
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Get the Metadata for a given port
    Switch Connection    ${conn_id}
    ${grep_metadata}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name}| grep table=0 | grep in_port=${port} | awk '{print$7}'    30
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
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    @{validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}   30
    Log    ${cmd}
    : FOR    ${elem}    IN    @{validation_list}
    \    Should Contain    ${cmd}    ${elem}

Table Check for 220
    [Arguments]    ${connection_id}    ${br_name}    ${table_cmdSuffix}    ${validation_list}
    [Documentation]    Check the table
    Switch Connection    ${connection_id}
    ${cmd}    DevstackUtils.Write Commands Until Prompt    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_cmdSuffix}    30
    Log    ${cmd}
    ${i}    Create List
    ${p}    Get Line Count    ${cmd}
    : FOR    ${line}    IN RANGE    0    2
    \    ${line1}    Get Line    ${cmd}    ${line}
    \    ${match}    Get Regexp Matches    ${line1}    n_packets=(\\d+)
    \    Append To List    ${i}    ${match}
    Should Be Equal    ${i[0]}    ${i[1]}

Send Traffic Using Netcat
    [Arguments]    ${virshid1}    ${virshid2}    ${vm1_ip}    ${vm2_ip}    ${compute_1_conn_id}    ${compute_2_conn_id}
    ...    ${port_no}    ${verify_string}    ${protocol}=udp
    [Documentation]    Send traffic using netcat
    ${proto_arg}    Set Variable If    '${protocol}'=='udp'    nc -u    nc
    Log    >>>Logging into the vm1>>>
    Switch Connection    ${compute_1_conn_id}
    Virsh Login    ${virshid1}
    DevstackUtils.Write Until Expected Output    ${proto_arg} -s ${vm1_ip} -l -p ${port_no} -v\r    expected=listening    timeout=5s    retry_interval=1s
    Log    >>>Logging into the vm2>>>
    Switch Connection    ${compute_2_conn_id}
    Virsh Login    ${virshid2}
    DevstackUtils.Write Until Expected Output    ${proto_arg} ${vm1_ip} ${port_no} -v\r    expected=open    timeout=5s    retry_interval=1s
    DevstackUtils.Write Until Expected Output    60s    10s    Execute Command on VM Instance    ${NETWORK}    ${VM_IP1}
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write    ${verify_string}
    Write_Bare_Ctrl_C
    Virsh Exit
    Switch Connection    ${compute_1_conn_id}
    ${cmdoutput}    Read
    Log    ${cmdoutput}
    Write_Bare_Ctrl_C
    Virsh Exit
    Should Contain    ${cmdoutput}    ${verify_string}

#Execute Command on VM Instance
#    [Arguments]    ${net_name}    ${vm_ip}    ${cmd}    ${user}=cirros    ${password}=cubswin:)    ${expec_output}
#    [Documentation]    Login to the vm instance using ssh in the network, executes a command inside the VM and returns the ouput.
#    ${devstack_conn_id}    Get ControlNode Connection
#    Switch Connection    ${devstack_conn_id}
#    ${net_id}    Get Net Id    ${net_name}    ${devstack_conn_id}
#    Log    ${vm_ip}
#    ${output}    DevstackUtils.Write Commands Until Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${vm_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
#    Log    ${output}
#    ${output}    DevstackUtils.Write Commands Until Prompt    ${password}    ${OS_SYSTEM_PROMPT}
#    Log    ${output}
#    ${rcode}    Run Keyword And Return Status    Check If Console Is VmInstance
#    ${output}    Run Keyword If    ${rcode}    DevstackUtils.Write Commands Until Prompt    ${cmd}    expected=${expec_output}    timeout=5s
#    ...    retry_interval=1s
#    #[Teardown]    Exit From Vm Console

Delete TestSetup
    [Documentation]    Delete the created VMs, ports, subnets, networks etc.
    Log    Delete the VM instance
    :FOR    ${VM_NAME}    IN    @{VM_NAMES}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VM_NAME}

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnets, networks etc.
    Log    Dumping all the flows
    #:FOR    ${table}    IN     @{TABLES}
    #\    Check Flows    ${table}
    #Switch Connection    ${control_conn_id}
    #${return}    ${output} =     Run Keyword And Ignore Error    Bgpvpn Router Associate List     ${bgp_vpn}
    #Run Keyword And Ignore Error    Bgpvpn Router DisAssociate    ${output}    ${bgp_vpn}
    #Run Keyword And Ignore Error    Delete Bgpvpn    ${bgp_vpn}
    Log    Delete the VM instance
    :FOR    ${VM_NAME}    IN    @{VM_NAMES}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VM_NAME}
    Log    Delete the Port created
    :FOR    ${port_name}    IN    @{PORT_LIST}
    \    Run Keyword And Ignore Error    Delete Port    ${port_name}
    Log    Delete-Subnet
    :FOR    ${Snet}    IN    @{REQ_SUBNETS}
    \    Run Keyword And Ignore Error    Delete SubNet    ${Snet}
    Log    Delete-networks
    :FOR    ${net}    IN    @{REQ_NETWORKS}
    \    Run Keyword And Ignore Error    Delete Network    ${net}
    :FOR    ${Sec_grp}    IN    @{SECURITY_GROUP} 
    \    Run Keyword And Ignore Error    Delete SecurityGroup    ${Sec_grp}


Get VM IP Address
    [Arguments]    ${conn_id}    ${vm_name}
    [Documentation]    Show information of a given VM and grep for ip address. VM name should be sent as arguments.
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd}    Set Variable    openstack server show ${vm_name} | grep "addresses" | awk '{print $4$5}'
    ${output} =    OpenStack CLI     ${cmd}
    @{output}    Split String    ${output}    =
    ${output_string}    Convert To String    ${output[1]}
    @{final_string}    Split String    ${output_string}    ,
    [Return]    @{final_string}

Capture Flows  
    [Arguments]    ${conn_id}    ${br_name}    ${cmd}
    [Documentation]    Capture flows
    Switch Connection    ${conn_id}
    ${output}     Execute Command    ${cmd}
    Log    ${output}

Get Packetcount
    [Arguments]    ${conn_id}    ${br_name}    ${table_no}    ${conn_state}
    [Documentation]    Capture flows
    Switch Connection    ${conn_id}
    ${output}    Execute Command    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} | grep ${conn_state}  
    @{output_list}    Split String    ${output}    \r\n
    ${flow}    Get From List    ${output_list}     0 
    ${packetcount_list}    Get Regexp Matches    ${flow}    n_packets=([0-9]+)     1 
    ${count}    Get From List    ${packetcount_list}    0
    [Return]    ${count}
