*** Settings ***
Documentation     Variables for EVPN_In_Intra_DC_Deployments Test Suites

*** Variables ***
@{REQ_NETWORKS}       NET1    NET2            
@{VM_INSTANCES_DPN1}    VM1    VM2           
@{VM_INSTANCES_DPN2}    VM3    VM4
@{VM_NAMES}    VM1    VM2    VM3    VM4        
@{NET_1_VMS}    VM1    VM2
@{NET_2_VMS}     VM3   VM4
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4       
@{REQ_SUBNETS}        SUBNET1    SUBNET2  
@{ROUTER_INTERFACE}    SUBNET1    SUBNET2
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16
${REQ_ROUTER}        RTR1
@{DEFAULT_GATEWAY_IPS}    10.1.0.1    10.2.0.1 
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261112
${VPN_NAME}       vpn1    
#${ROUTER}        RTR1    
${NUM_OF_L3VPN}    1
#${L3VPN_RD}       100:2
${CREATE_RD}      ["100:31"]
${CREATE_EXPORT_RT}    ["100:31"]   
${CREATE_IMPORT_RT}    ["100:31"]    
${LOGIN_PSWD}     admin123
${REQ_PING_REGEXP}    , 0% packet loss
${REQ_PING_REGEXP_FAIL}    , 100% packet loss
@{CREATE_l3VNI}    200    300
${SECURITY_GROUP}    sg-vpnservice
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${CONFIG_API}     /restconf/config
${VPN_REST}          ${CONFIG_API}/odl-l3vpn:vpn-instance-to-vpn-id/ 
${VAR_BASE}       /root/sanjo_csit/test/csit/variables/vpnservice
${origin}    "origin":"c"
${NUM_INSTANCES}    30
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
${Req_no_of_net}    2
${Req_no_of_subNet}    2
${Req_no_of_ports}    4
${Req_no_of_vms_per_dpn}    2
${Req_no_of_routers}    1
${CONTROLLER_ACTION}     CONTROLLER:65535
${ARP_REQUEST_REGEX}    arp,arp_op=1 actions=group:\\d+
${NUM_OS_SYSTEM}     3
${ODL_STREAM}     dummy
${PRE_CLEAN_OPENSTACK_ALL}    False
${ODL_ENABLE_L3_FWD}     yes
