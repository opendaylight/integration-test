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
${OS_CONTROL_NODE_IP}     192.168.56.100
${OS_COMPUTE_1_IP}    192.168.56.100
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
${DEF_LINUX_PROMPT}    \    #
${DCGW_PROMPT}    \    #
${REQ_NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${REQ_SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${REQ_PORT_URL}       ${CONFIG_API}/neutron:neutron/ports/
${REQ_TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${REQ_TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
@{REQ_EXTRA_NW_IP}    40.1.0.2    50.1.0.2
@{EXTRA_NW_SUBNET}    40.1.0.0/16    50.1.0.0/16
@{EXTRA_NW_IP}    10.50.0.5
@{SUBNET_IP_NET50}    10.50.0.0
${AS_ID}          100
${KARAF_SHELL_PORT}    8101
${KARAF_PROMPT}    opendaylight-user
${KARAF_USER}     karaf
${KARAF_PASSWORD}    karaf
${SECURITY_GROUP}    sg-vpnservice
${DCGW_RD}        2200:2
${LOOPBACK_IP}    5.5.5.2
${LOOPBACK_IP1}    5.5.5.3
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${CONFIG_API}     /restconf/config
${VPN_REST}          ${CONFIG_API}/odl-l3vpn:vpn-instance-to-vpn-id/ 
${OS_COMPUTE_1_IP}    192.168.56.100 
${OS_COMPUTE_2_IP}    192.168.56.101   
@{TunnelSourceIp}    192.168.56.100    192.168.56.101
${TunnelNetwork}    192.168.56.0/24 
${OS_CONTROL_NODE_IP}    192.168.56.100
${OS_USER}        openstack
${DEVSTACK_SYSTEM_PASSWORD}    openstack
${DEVSTACK_DEPLOY_PATH}    /home/openstack/devstack
${tempest_directory}      devstack
# ODL system variables
${ODL_SYSTEM_IP}    192.168.56.105    # Override if ODL is not running locally to pybot
${ODL_SYSTEM_1_IP}   192.168.56.105
${ODL_SYSTEM_USER}    openstack 
${ODL_SYSTEM_PASSWORD}    openstack 
${DCGW_SYSTEM_IP}  192.168.56.103
${USER_HOME}      /root/
${DELAY_AFTER_VM_CREATION}    30
${VAR_BASE}       /root/sanjo_csit/test/csit/variables/vpnservice
${RESTCONFPORT}    8181
${BGP_SHOW}       display-bgp-config
${hostname_compute_node}    OS_Controller
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
${OPENSTACK_BRANCH}    stable/newton
${CIRROS_stable/newton}    cirros-0.3.4-x86_64-uec
#${OS_CMP1_HOSTNAME}    Openstack-Controller
#${OS_CMP2_HOSTNAME}     OpenstackCompute 
${ODL_STREAM}     dummy
${PRE_CLEAN_OPENSTACK_ALL}    False
${DEFAULT_LINUX_PROMPT_STRICT}    > 
${DEFAULT_LINUX_PROMPT}    >
ODL_ENABLE_L3_FWD    yes
