*** Settings ***
Documentation     Test Suite for    CR118:Gateway mac based L2L3 seggragation 
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown   
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../variables/ARP_GWMAC_VARIABLE.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${Req_no_of_net}    2
${Req_no_of_subNet}    2
${Req_no_of_ports}    4
${Req_no_of_vms_per_dpn}    2
${Req_no_of_routers}    1
#${OS_CONTROL_NODE_IP}    192.168.56.100
${Req_no_of_ports_per_dpn}     2
${num_of_ports_per_host}     2
@{REQ_NETWORKS}       NET1    NET2
@{VM_INSTANCES_DPN1}    VM1    VM2
@{VM_INSTANCES_DPN2}    VM3    VM4
@{VM_NAMES}    VM1    VM2    VM3    VM4
@{NET_1_VMS}    VM1    VM2
@{NET_2_VMS}     VM3   VM4
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4
${num_of_ports_per_host}     2
@{REQ_SUBNETS}        SUBNET1    SUBNET2
@{ROUTER_INTERFACE}    SUBNET1    SUBNET2
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16
${REQ_ROUTER}        RTR1
@{DEFAULT_GATEWAY_IPS}    10.1.0.1    10.2.0.1
${NEXTHOP}    0.0.0.0
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261112
${VPN_NAME}       vpn1
${OS_CONTROL_NODE_IP}     192.168.56.100
${OS_COMPUTE_1_IP}    192.168.56.100
${NUM_OF_L3VPN}    1
${CREATE_RD}      ["100:31"]
${CREATE_EXPORT_RT}    ["100:31"]
${CREATE_IMPORT_RT}    ["100:31"]
${LOGIN_PSWD}     admin123
${SECURITY_GROUP}    sg-vpnservice
@{TunnelSourceIp}    192.168.56.100    192.168.56.101
${TunnelNetwork}    192.168.56.0/24
${OS_CONTROL_NODE_IP}    192.168.56.100
${DELAY_AFTER_VM_CREATION}    30
${TABLE_NO_0}   table=0
${TABLE_NO_17}    table=17
${TABLE_NO_19}    table=19
${TABLE_NO_21}    table=21
${TABLE_NO_43}    table=43
${TABLE_NO_81}    table=81
${TABLE_NO_220}    table=220
${arp_response}    arp_op=2
${arp_request}     arp_op=1
${resubmit_value}    17
${GWMAC_table}       19
${DISPATCHER_TABLE}    17
${ARP_RESPONDER_TABLE}     81
${pkt_divariable1}    n_packets=0
${L3VPN_TABLE}     21
${TABLE_43}    43
${dump_flows}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
${group_flows}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
${CONTROLLER_ACTION}     CONTROLLER:65535
${ARP_REQUEST_REGEX}    arp,arp_op=1 actions=group:\\d+
${NUM_OS_SYSTEM}     3

*** Test Cases ***
TC1_Verify that table Miss entry for GWMAC table 19 points to table 17 dispatcher table
    [Documentation]     To Verify there should be not be an entry for table=17,in the table=19 dump_flows
    Get ControlNode Connection
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep table=${GWMAC_table}
    Should Contain   ${flow_output}    priority=0     actions=resubmit(,17)


TC2_Verify the pipeline flow from dispatcher table 17 (L3VPN) to table 19
    [Documentation]   To  Verify the end to end pipeline flow from table=17 to table=19 dump_flows
    Get ControlNode Connection
    ${subport_id_1}    Get Sub Port Id    ${PORT_LIST[0]}
    ${subport_id_2}    Get Sub Port Id    ${PORT_LIST[1]}
    ${port_num_1}    Get Port Number    ${subport_id_1}    ${OS_COMPUTE_1_IP}  
    ${port_num_2}    Get Port Number    ${subport_id_2}    ${OS_COMPUTE_1_IP}
    #${devstack_conn_id}=    Get ControlNode Connection
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_0}
    Log    ${flow_output}
    Should Contain   ${flow_output}  in_port=${port_num_1}    goto_table:${DISPATCHER_TABLE}
    ${metadata}    Get Metadata    ${OS_COMPUTE_1_IP}    ${port_num_1}
    #DevstackUtils.Devstack Suite Setup
    ${vpn_id}=    VPN Get L3VPN ID
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_17} | grep ${vpn_id}
    Log    ${flow_output}
    Should Contain     ${flow_output}    ${vpn_id}
    Should Contain     ${flow_output}    goto_table:${GWMAC_table}
    #Get ControlNode Connection
    ${gw_mac_addr}   Get Default Mac Addr    ${DEFAULT_GATEWAY_IPS[0]}     
    ${port_mac_addr}    Get Port Mac     ${PORT_LIST[0]}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} |grep ${TABLE_NO_19}
    Log    ${flow_output}
    Should Contain     ${flow_output}    resubmit(,17)
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_17} |grep ${metadata}
    Log    ${flow_output}
    Should Contain    ${flow_output}    goto_table:${TABLE_43}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_43}
    Log    ${flow_output}
    @{group_id}     Get Regexp Matches    ${flow_output}     group:(\\d+)    1
    Log    ${group_id[0]}
    Should Contain    ${flow_output}     arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${group_flows} |grep group_id=${group_id[0]}
    Log    ${flow_output}
    Should Contain      ${flow_output}    bucket=actions=resubmit(,81)
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_81}
    Log    ${flow_output}
    Should Contain      ${flow_output}      set_field:${gw_mac_addr}
    Should Contain      ${flow_output}      resubmit(,220)
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_220}
    Log    ${flow_output}
    Should Contain    ${flow_output}    output:${port_num_2}

TC3_Verify that ARP requests received on GWMAC table are punted to controller for learning ,resubmitted to table 17,sent to ARP responder
    [Documentation]    To verify the ARP Request entry should be there after the dump_groups and dispatcher table should point to ARP responder
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_19}
    Should Contain    ${flow_output}     arp,arp_op=1 actions=resubmit(,17)
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_17}
    Should Contain    ${flow_output}    goto_table:${TABLE_43}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_43}
    @{group_id}     Get Regexp Matches      ${flow_output}     group:(\\d+)    1
    Log    ${group_id[0]}
    Should Contain    ${flow_output}     arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${group_flows}|grep group_id=${group_id[0]} 
    Should Contain      ${flow_output}    bucket=actions=resubmit(,81)

TC4_Verify that ARP response received on GWMAC table are punted to controller for learning, resubmitted to table 17
    [Documentation]    Verify that ARP response received on GWMAC table are punted to controller for learning, resubmitted to table 17
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_19} 
    Should Contain     ${flow_output}     arp,arp_op=2 actions=resubmit(,17)
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_17}
    Should Contain    ${flow_output}    goto_table:${TABLE_43}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_43}
    @{group_id}     Get Regexp Matches      ${flow_output}     group:(\\d+)    1
    Log    ${group_id[0]}
    Should Contain    ${flow_output}     arp,arp_op=1 actions=group:${group_id[0]}
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${group_flows}|grep group_id=${group_id[0]}
    Should Contain      ${flow_output}    bucket=actions=resubmit(,81)

TC5_Verify that table miss entry for table 17 should not point to table 81 arp table_
    [Documentation]    To Verify there should not be an entry for the arp_responder_table in table=17
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} |grep ${TABLE_NO_17} |grep priority=0
    Should Not Contain      ${flow_output}     goto_table:${ARP_RESPONDER_TABLE} 


TC6_Verify that Multiple GWMAC entries in GWMAC table points to FIB table 21 (L3VPN pipeline)
    [Documentation]    To verify the one or more default GWmac enteries on the table=19 flows that  points to FIB table 21 (L3VPN pipeline)
    #Get ControlNode Connection
    ${gw_mac_addr_1}   Get Default Mac Addr    ${DEFAULT_GATEWAY_IPS[0]}   
    ${gw_mac_addr_2}   Get Default Mac Addr    ${DEFAULT_GATEWAY_IPS[1]}  
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} |grep ${TABLE_NO_19}
    Should Contain    ${flow_output}    dl_dst=${gw_mac_addr_1}     actions=goto_table:${L3VPN_TABLE}
    Should Contain    ${flow_output}    dl_dst=${gw_mac_addr_2}     actions=goto_table:${L3VPN_TABLE}
    Get ControlNode Connection
    ${pkt_count_before_ping}    Get Packetcount    br-int    ${OS_COMPUTE_1_IP}   ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_1}
    Log    ${pkt_count_before_ping}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 8 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${pkt_count_after_ping}    Get Packetcount    br-int    ${OS_COMPUTE_1_IP}   ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_1}
    Log    ${pkt_count_after_ping}
    ${pkt_diff}    Evaluate    int(${pkt_count_after_ping})-int(${pkt_count_before_ping})
    Should Be True    ${pkt_diff} > 0
    ${pkt_count_before_ping}    Get Packetcount    br-int    ${OS_COMPUTE_1_IP}   ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_2}
    Log    ${pkt_count_before_ping}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{NET_1_VM_IPS} [1]    ping -c 8 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${pkt_count_after_ping}    Get Packetcount    br-int    ${OS_COMPUTE_1_IP}    ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_2}
    Log    ${pkt_count_after_ping}
    ${pkt_diff}    Evaluate    int(${pkt_count_after_ping})-int(${pkt_count_before_ping})
    Should Be True    ${pkt_diff} > 0
    Log   Verify Ping On Second DPN
    ${pkt_count_before_ping}    Get Packetcount    br-int    ${OS_COMPUTE_2_IP}   ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_1}
    Log    ${pkt_count_before_ping}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{NET_2_VM_IPS} [0]    ping -c 8 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${pkt_count_after_ping}    Get Packetcount    br-int    ${OS_COMPUTE_2_IP}   ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_1}
    Log    ${pkt_count_after_ping}
    ${pkt_diff}    Evaluate    int(${pkt_count_after_ping})-int(${pkt_count_before_ping})
    Should Be True    ${pkt_diff} > 0
    Log   Verify Ping On Second DPN
    ${pkt_count_before_ping}    Get Packetcount    br-int    ${OS_COMPUTE_2_IP}    ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_2}
    Log    ${pkt_count_before_ping}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{NET_2_VM_IPS}[1]    ping -c 8 @{NET_1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${pkt_count_after_ping}    Get Packetcount    br-int    ${OS_COMPUTE_2_IP}   ${TABLE_NO_19} |grep dl_dst=${gw_mac_addr_2}
    Log    ${pkt_count_after_ping}
    ${pkt_diff}    Evaluate    int(${pkt_count_after_ping})-int(${pkt_count_before_ping})
    Should Be True    ${pkt_diff} > 0

TC7_Verify table miss entry of ARP responder table points to drop actions
    [Documentation]    To Check the default flow entry of table=81 drops when openflow controller connected to DPN 
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_81} |grep priority=0
    Should Contain     ${flow_output}      actions=drop

TC8_Verify ARP eth_type entries and actions for ARP request's are populated on GWMAC table
   [Documentation]    To Verify there should be an entry for ARP request(arp=1)in the table=19
   ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep table=${GWMAC_table}
   Should Contain      ${flow_output}    ${arp_request}    actions=${resubmit_value}


TC9_Verify ARP eth_type entries and actions for ARP responses are populated on GWMAC table
   [Documentation]      To Verify there should be an entry for ARP response(arp=2)in the table=19 
   ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows} |grep table=${GWMAC_table}
   Should Contain      ${flow_output}     ${arp_response}    actions=${resubmit_value}
   Log     ${flow_output}   


TC10_Verify GWMAC entires are populated with Neutron Router MAC address per network in GWMAC table
    [Documentation]    Verify GWMAC entires are populated with Neutron Router MAC address per network in GWMAC table    
    Log    Creating Start Suite
    ${devstack_conn_id}=    Get ControlNode Connection
    ${subport_id}    Get Sub Port Id    ${PORT_LIST[1]}
    ${port_num_2}    Get Port Number    ${subport_id}    ${OS_COMPUTE_1_IP} 
   #Get ControlNode Connection 
    ${gw_mac_addr_2}   Get Default Mac Addr    ${DEFAULT_GATEWAY_IPS[1]}  
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_19}
    Should Contain    ${flow_output}   dl_dst=${gw_mac_addr_2}     actions=goto_table:${L3VPN_TABLE}
    #${rtr_id}    Get Router Id    ${ROUTER}
    ${output}=    FIB Output
    #Should Contain    ${output}    ${rtr_id}
    #Should Contain    ${output}    100:31
    Check IP And UUID In FIB Entry    ${output}    @{DEFAULT_GATEWAY_IPS}[1]    ${NEXTHOP}


TC11_Verify GWMAC entires are populated with port MAC address for network to VPN association in GWMAC table
    [Documentation]   TO Verify GWMAC entires are populated with port MAC address for network to VPN association in GWMAC table 
    Log    Creating Start Suite
    ${devstack_conn_id}=    Get ControlNode Connection
    ${subport_id}    Get Sub Port Id    ${PORT_LIST[1]}
    ${port_num_3}    Get Port Number    ${subport_id}    ${OS_COMPUTE_1_IP} 
    Get ControlNode Connection
    ${gw_mac_addr_2}   Get Default Mac Addr    ${DEFAULT_GATEWAY_IPS[1]}   
    ${flow_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    ${dump_flows}|grep ${TABLE_NO_19}
    Should Contain      ${flow_output}     dl_dst=${gw_mac_addr_2}     actions=goto_table:${L3VPN_TABLE}
    #${rtr_id}    Get Router Id    ${ROUTER}
    ${output}=    FIB Output
    Check RD And Subnet In FIB Entry    ${output}    ${CREATE_RD}    ${REQ_SUBNET_CIDR[0]}  
    Check RD And Subnet In FIB Entry    ${output}    ${CREATE_RD}    ${REQ_SUBNET_CIDR[1]}     


*** Keywords ***
Start Suite
    [Documentation]    Test Suite for CR118:Gateway mac based L2L3 seggragation 
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Nano Flavor
    Create Setup

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    ${NET_LIST}    OpenStackOperations.List Networks
    BuiltIn.Log    ${NET_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    BuiltIn.Should Contain    ${NET_LIST}    ${REQ_NETWORKS[${index}]}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    ${SUB_LIST}    OpenStackOperations.List Subnets
    BuiltIn.Log    ${SUB_LIST}
    BuiltIn.Log    REQUIRED SUBNET IS
    BuiltIn.Log    ${SUB_LIST}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \     BuiltIn.Should Contain    ${SUB_LIST}    ${REQ_SUBNETS[${index}]}

Security Group Rule with Remote IP Prefix
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Neutron Security Group Create    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0


#Create Neutron Ports
#    [Arguments]    ${NUM_OF_PORTS}
#    [Documentation]    Create required number of ports under previously created subnets
#    Create Port    ${REQ_NETWORKS[0]}    ${PORT_LIST[0]}    sg=${SECURITY_GROUP}
#    Create Port    ${REQ_NETWORKS[1]}    ${PORT_LIST[1]}    sg=${SECURITY_GROUP}
#    Create Port    ${REQ_NETWORKS[0]}    ${PORT_LIST[2]}    sg=${SECURITY_GROUP}
#    Create Port    ${REQ_NETWORKS[1]}    ${PORT_LIST[3]}    sg=${SECURITY_GROUP}

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    
    [Documentation]    Create required number of ports under previously created subnets 
    : FOR    ${index}    IN RANGE    0    ${num_of_ports_per_host}
    \    Create Port    @{REQ_NETWORKS}[${index}]    @{PORT_LIST}[${index}]    sg=${SECURITY_GROUP}    
    : FOR    ${index}    IN RANGE    0    ${num_of_ports_per_host}
    \    ${start} =    Evaluate    ${index}+2
    \    Create Port    @{REQ_NETWORKS}[${index}]    @{PORT_LIST}[${start}]    sg=${SECURITY_GROUP}   
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}


Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    ${start} =    Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}     ${VM_NAMES[${index}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    @{NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    @{VM_IPs}=    Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}
    Set Suite Variable    ${VM_IPs}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create tunnels between the 2 compute nodes
    Get ControlNode Connection
    Create Neutron Networks    ${Req_no_of_net}
    Create Neutron Subnets    ${Req_no_of_subNet}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP} 
    Create Neutron Ports    ${Req_no_of_ports}
    Create Nova VMs    ${Req_no_of_vms_per_dpn}
    Create Router           ${REQ_ROUTER}
    ${router_id}=    Get Router Id      ${REQ_ROUTER}
    Add Interfaces To Routers
    Log    session
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID} 
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}
    Should Contain    ${resp}    ${router_id}


Create Sub Interfaces And Verify
    Log    Create Sub Interface and verify for all VMs
    : FOR    ${vm_ip}    IN    @{VM_IP_NET1}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    @{VM_IP_NET2}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${ALLOWED_IP[2]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    @{VM_IP_NET3}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[4]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${ALLOWED_IP[4]}
    \    ...    ${vm_ip}

Create Routers
    [Arguments]    ${NUM_OF_ROUTERS}
    [Documentation]    Create Router
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    OpenStackOperations.Create Router    ${REQ_ROUTERS[${index}]}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Log    ${router_output}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_ROUTERS}
    \    Should Contain    ${router_output}    ${REQ_ROUTERS[${index}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${REQ_ROUTERS}

Associate L3VPN To Networks
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associates L3VPN to networks and verify
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NET}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}
    \    Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Contain    ${resp}    ${network_id}

Configure_IP_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} up

Verify_IP_Configured_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for verifying specified IP on specified interface and the corresponding specified sub interface
    ${resp}    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number}
    BuiltIn.Should Contain    ${resp}    ${ip}


Add Interfaces To Routers
    [Documentation]    Add Interfaces
    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{ROUTER_INTERFACE}
    \    OpenStackOperations.Add Router Interface    ${REQ_ROUTER}    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${REQ_ROUTER}  
    : FOR    ${INTERFACE}    IN    @{ROUTER_INTERFACE}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}    
    \    Should Contain    ${interface_output}    ${subnet_id}

Dissociate L3VPN
    [Arguments]    ${NUM_OF_NET}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Dissociate L3VPN from networks
    Get ControlNode Connection
    Log Many    "Number of network"    ${NUM_OF_NET}
    ${NUM_OF_NETS}    Convert To Integer    ${NUM_OF_NET}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETS}
    \    ${network_id} =    Get Net Id    ${REQ_NETWORKS[${index}]}
    \    Dissociate L3VPN From Networks    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID[0]}
    \    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    \    Should Not Contain    ${resp}    ${network_id}

VPN Get L3VPN ID
    [Documentation]    Check that sub interface ip has been learnt after ARP request
    ${resp}    RequestsLibrary.Get Request    session    ${VPN_REST}
    BuiltIn.Log    ${resp.content}
    @{vpn_id}=    Get Regexp Matches    ${resp.content}     \"vpn-instance-name\":\"${VPN_INSTANCE_ID}\",\"vpn-id\":(\\d+)    1
    ${result}=    Evaluate    ${vpn_id[0]} * 2
    ${vpn_id_hex}=       Convert To Hex  ${result}
    [Return]    ${vpn_id_hex.lower()}

Get Packetcount
    [Arguments]    ${br_name}    ${ip_addr}    ${table_no}    ${addtioanal_args}=${EMPTY}
    [Documentation]    Getting Packet count
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 ${br_name} | grep ${table_no} ${addtioanal_args}
    ${num}=    Run Command On Remote System    ${ip_addr}    ${cmd}
    @{cmdoutput}    Split String    ${cmd}    \r\n
    log    ${cmdoutput}
    ${flow}    get from list    ${cmdoutput}    0
    ${packetcountlist}    Get Regexp Matches    ${flow}    n_packets=([0-9]+),     1
    ${packetcount}    Get From List    ${packetcountlist}    0
    [Return]    ${packetcount}

Check IP And UUID In FIB Entry
    [Arguments]    ${output_str}    ${uuid}    ${prefix}    ${nexthop}
    [Documentation]    Verification of routes entry with correct nexthop
    Log    Output String should contain \\s*${uuid}\\s*${prefix}/32\\s*${nexthop} in FIB entry
    Should Match Regexp    ${output_str}    \\s*${uuid}\\s*${prefix}/32\\s*${nexthop}
    [Return]    ${output_str}

Check RD And Subnet In FIB Entry
    [Arguments]    ${output_str}    ${rd}    ${subnet}    
    [Documentation]    Verification of routes entry with correct nexthop
    Log    Output String should contain \\s*${rd}\\s*${subnet}\\s in FIB entry
    Should Match Regexp    ${output_str}    \\s*${rd}\\s*${subnet}\\s
    [Return]    ${output_str}

FIB Output
    [Arguments]
    [Documentation]    Check FIB
    ${output}=    Issue_Command_On_Karaf_Console    fib-show
    Log    ${output}
    [Return]    ${output}


Get Sub Port Id
    [Arguments]    ${portname}
    [Documentation]    Get the Sub Port ID
    #${devstack_conn_id}=    Get ControlNode Connection
    #SSHLibrary.Switch Connection    ${conn_id}
   # ${port_id}    Get Port Id    ${portname}     ${devstack_conn_id}
    ${port_id}    Get Port Id    ${portname}
    Should Match Regexp    ${port_id}    \\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}
    @{output}     Get Regexp Matches    ${port_id}      (\\w{8}-\\w{2})
    #SSHLibrary.Close Connection
    [Return]    ${output[0]}


Get Port Number
    [Arguments]    ${portname}    ${ip_addr}
    [Documentation]    Get the port number for given portname
    #${devstack_conn_id}=    Get ControlNode Connection
    #SSHLibrary.Switch Connection    ${conn_id}
    ${command_1}    Set Variable    sudo ovs-ofctl -O OpenFlow13 show br-int | grep ${portname} | awk '{print$1}'
    log    sudo ovs-ofctl -O OpenFlow13 show br-int | grep ${portname} | awk '{print$1}'
    ${num}=    Run Command On Remote System    ${ip_addr}    ${command_1}  
    #${num}    DevstackUtils.Write Commands Until Prompt    ${command_1}    30
    log    ${num}
    ${port_number}    Should Match Regexp    ${num}    [0-9]+
    log    ${port_number}
    #SSHLibrary.Close Connection
    [Return]    ${port_number}


Get Metadata
    [Arguments]    ${ip_addr}    ${port}
    [Documentation]    Get the Metadata for a given port
    Switch Connection    ${conn_id}
    ${cmd}    Set Variable    sudo ovs-ofctl dump-flows -O Openflow13 br-int| grep table=0 | grep in_port=${port}
    ${grep_metadata}    Run Command On Remote System    ${ip_addr}    ${cmd}
    log    ${grep_metadata}
    @{metadata}  Get Regexp Matches   ${grep_metadata}     metadata:(\\w{12})    1
    ${metadata1}    Convert To String    @{metadata}
    ${output}    Get Substring     ${metadata1}     2
    [Return]    ${output}


Get Default Mac Addr
    [Arguments]    ${default_gw_ip}       
    [Documentation]    Retrieve the port id for the given port name to attach specific vm instance to a particular port
    #SSHLibrary.Switch Connection    ${conn_id}
    ${output}=    OpenStack CLI   openstack port list | grep -w ${default_gw_ip} | awk '{print $5}'
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${gw_mac_addr}=    Get from List    ${splitted_output}    0
    Log    ${gw_mac_addr}
    [Return]    ${gw_mac_addr}

Get Router MacAddr List
    [Arguments]    ${router_name}
    [Documentation]    Retrieve the router MacAddr list for the given router name and return the MAC address list.
    ${mac_list}    Create List    @{EMPTY}
    ${output}=    OpenStack CLI   openstack router port list ${router_name}  
    Log    ${output}
    @{mac_list}    Get Regexp Matches    ${output}    ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
    [Return]    ${mac_list}

Get System Connection ID
    [Arguments]    ${system_ip}    ${user}=${DEFAULT_USER}    ${password}=${DEFAULT_PASSWORD}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Get system connection ID
    ${conn_id}=    SSHLibrary.Open Connection    ${system_ip}    prompt=${prompt}
    Log    ${conn_id}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    SSHLibrary.Set Client Configuration    timeout=${prompt_timeout}
    [Return]    ${conn_id}
    
#Add Router Interface
#    [Arguments]    ${router_name}    ${interface_name}
#    #${devstack_conn_id}=    Get ControlNode Connection
#    #SSHLibrary.Switch Connection    ${devstack_conn_id}
#    ${output}=    OpenStack CLI    openstack -v router interface add ${router_name} ${interface_name}
#    #SSHLibrary.Close Connection
#    Should Contain    ${output}    Added interface

#Remove Interface
#    [Arguments]    ${router_name}    ${interface_name}
#    [Documentation]    Remove Interface to the subnets.
#    ${devstack_conn_id}=    Get ControlNode Connection
#    SSHLibrary.Switch Connection    ${devstack_conn_id}
#    ${output}=    DevstackUtils.Write Commands Until Prompt    neutron -v router-interface-delete ${router_name} ${interface_name}
#    SSHLibrary.Close Connection
#    Should Contain    ${output}    Removed interface from router
