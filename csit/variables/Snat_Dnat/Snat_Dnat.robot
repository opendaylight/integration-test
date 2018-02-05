*** Settings ***
Documentation     Variables for EVPN_In_Intra_DC_Deployments Test Suites

*** Variables ***

@{FLOATING_IP}    100.100.100.101    100.100.100.102    100.100.100.103    100.100.100.104
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
@{REQ_EXTERNAL_NETWORKS}    EXT1    EXT2    EXT3    EXT4
@{REQ_EXTERNAL_SUBNETWORKS}    EXTSUBNET1    EXTSUBNET2    EXTSUBNET3    EXTSUBNET4
@{NETWORK_TYPE}    gre    mpls
@{BOOL_VALUES}    True    False
@{REQ_EXT_SUBNET_CIDR}    100.100.100.0/24    200.200.200.0/24    
#@{REQ_NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6    NET7
@{REQ_NETWORKS}       NET1    NET2    NET3    NET4    
#@{REQ_NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6    NET7
#...               NET8
@{VM_INSTANCES_DPN1}    VM11    VM12    VM21    VM22    VM31    VM32    VM41
...               VM42
@{VM_INSTANCES_DPN2}    VM13    VM14    VM23    VM24    VM33    VM34    VM43
...               VM44
@{REQ_VM_INSTANCES_NET1}    VM11    VM12    VM13    VM14
@{REQ_VM_INSTANCES_NET2}    VM21    VM22    VM23    VM24
@{REQ_VM_INSTANCES_NET3}    VM31    VM32    VM33    VM34
@{REQ_VM_INSTANCES_NET4}    VM41    VM42    VM43    VM44
@{VM_INSTANCES_DPN1_PORTS}    PORT11    PORT12    PORT21    PORT22    PORT31    PORT32    PORT41
...               PORT42
@{VM_INSTANCES_DPN2_PORTS}    PORT13    PORT14    PORT23    PORT24    PORT33    PORT34    PORT43
...               PORT44
@{VM_INSTANCES}    VM11    VM12    VM21    VM22    VM31    VM32    VM41
...               VM42    VM13    VM14    VM23    VM24    VM33    VM34
...               VM43    VM44
@{REQ_PORT_LIST}      PORT11    PORT12    PORT21    PORT22    PORT31    PORT32    PORT41
...               PORT42    PORT13    PORT14    PORT23    PORT24    PORT33    PORT34
...               PORT43    PORT44
@{REQ_SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6    SUBNET7
...               SUBNET8
@{ROUTER1_INTERFACE}    SUBNET1    SUBNET2
#@{REQ_SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6    SUBNET7
@{REQ_SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    
@{ROUTER2_INTERFACE}    SUBNET3    SUBNET4
@{ROUTER1_INTERFACE_TESTAREA3}    SUBNET3    SUBNET4
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16    10.5.0.0/16    10.6.0.0/16    10.7.0.0/16
...               10.8.0.0/16    10.9.0.0/16    10.10.0.0/16    10.11.0.0/16    10.12.0.0/16    10.13.0.0/16    10.14.0.0/16
...               10.15.0.0/16    10.16.0.0/16
@{REQ_SUBNET_CIDR_TESTAREA1}    10.1.0.0/16    10.2.0.0/16
@{REQ_SUBNET_CIDR_TESTAREA2}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16
@{REQ_SUBNET_CIDR_TESTAREA3}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16
@{REQ_SUBNET_CIDR_TESTAREA4}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16    10.5.0.0/16    10.6.0.0/16    10.7.0.0/16
...               10.8.0.0/16
@{REQ_SUBNET_CIDR_TESTAREA5}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16
@{PORT_LIST_TEST_TOPOLOGY_4}    PORT11    PORT21    PORT31    PORT41    PORT51    PORT61    PORT71
...               PORT81    PORT12    PORT22    PORT32    PORT42    PORT52    PORT62
...               PORT72    PORT82
@{VM_INSTANCES_TEST_TOPOLOGY_4}    VM11    VM21    VM31    VM41    VM51    VM61    VM71
...               VM81    VM12    VM22    VM32    VM42    VM52    VM62
...               VM72    VM82
@{PORT_LIST_TEST_TOPOLOGY_5}    PORT11    PORT21    PORT31    PORT41    PORT51    PORT61    PORT71
...               PORT81    PORT12    PORT22    PORT32    PORT42    PORT52    PORT62
...               PORT72    PORT82
@{VM_INSTANCES_TEST_TOPOLOGY_5}    VM11    VM21    VM31    VM41    VM51    VM61    VM71
...               VM81    VM12    VM22    VM32    VM42    VM52    VM62
...               VM72    VM82
@{VM_INSTANCES_DPN1_TEST_TOPOLOGY_4}    VM11    VM21    VM31    VM41    VM51    VM61    VM71
...               VM81
@{VM_INSTANCES_DPN1_TEST_TOPOLOGY_5}    VM11    VM21    VM31    VM41    VM51    VM61    VM71
...               VM81
@{VM_INSTANCES_NET1_TEST_TOPOLOGY_4}    VM11    VM12
@{VM_INSTANCES_NET2_TEST_TOPOLOGY_4}    VM21    VM22
@{VM_INSTANCES_NET3_TEST_TOPOLOGY_4}    VM31    VM32
@{VM_INSTANCES_NET4_TEST_TOPOLOGY_4}    VM41    VM42
@{VM_INSTANCES_NET5_TEST_TOPOLOGY_4}    VM51    VM52
@{VM_INSTANCES_NET6_TEST_TOPOLOGY_4}    VM61    VM62
@{VM_INSTANCES_NET7_TEST_TOPOLOGY_4}    VM71    VM72
@{VM_INSTANCES_NET8_TEST_TOPOLOGY_4}    VM81    VM82
@{ROUTER1_INTERFACE_TESTAREA4}    SUBNET3    SUBNET4
@{ROUTER2_INTERFACE_TESTAREA4}    SUBNET7    SUBNET8
@{ROUTER1_INTERFACE_TESTAREA5}    SUBNET3    SUBNET4
@{ROUTER2_INTERFACE_TESTAREA5}    SUBNET7    SUBNET8
@{NETWORKS_ASSOCIATION_TESTAREA4_EVPN1}    NET1    NET2
@{NETWORKS_ASSOCIATION_TESTAREA4_EVPN2}    NET5    NET6
#@{NETWORKS}      NET1    NET2
#@{VM_INSTANCES_DPN1}    VM11    VM12    VM21    VM22
#@{VM_INSTANCES_DPN2}    VM13    VM14    VM23    VM24
#@{VM_INSTANCES_NET1}    VM11    VM12    VM13    VM14
#@{VM_INSTANCES_NET2}    VM21    VM22    VM23    VM24
#@{VM_INSTANCES}    VM11    VM12    VM21    VM22    VM13    VM14    VM23
...               # VM24
#@{PORT_LIST}     PORT11    PORT12    PORT21    PORT22    PORT13    PORT14    PORT23
...               # PORT24
#@{SUBNETS}       SUBNET1    SUBNET2
#@{ROUTER1_INTERFACE}    SUBNET1
#@{ROUTER2_INTERFACE}    SUBNET2
#@{SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16    10.5.0.0/16    10.6.0.0/16    10.7.0.0/16
...               # 10.8.0.0/16
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222
@{VPN_NAME}       vpn1    vpn2    vpn3
@{ROUTER_NAME}    RTR1    RTR2
@{REQ_ROUTERS}        RTR1    RTR2
@{L3VPN_RD}       100:2
@{CREATE_RD}      ["100:2"]    ["100:3"]    ["100:4"]
@{CREATE_EXPORT_RT}    ["100:2"]    ["100:3"]    ["100:4"]
@{CREATE_IMPORT_RT}    ["100:2"]    ["100:3"]    ["100:4"]
${LOGIN_PSWD}     admin123
${REQ_PING_REGEXP}    , 0% packet loss
${REQ_PING_REGEXP_FAIL}    , 100% packet loss
@{CREATE_l3VNI}    200    300
${DEF_LINUX_PROMPT}    \    #
${DCGW_PROMPT}    \    #
${REQ_TEP_SHOW_STATE}    tep:show-state
${TEP_COMMIT}     tep:commit
${REQ_TEP_SHOW}       tep:show
${STATE_UP}       UP
${STATE_DOWN}     DOWN
${REQ_NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${REQ_SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${REQ_PORT_URL}       ${CONFIG_API}/neutron:neutron/ports/
${REQ_TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${REQ_TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
@{REQ_EXTRA_NW_IP}    40.1.0.2    50.1.0.2
@{EXTRA_NW_SUBNET}    40.1.0.0/16    50.1.0.0/16
@{EXTRA_NW_IP}    10.50.0.5
@{SUBNET_IP_NET50}    10.50.0.0
${AS_ID}          1000
${KARAF_SHELL_PORT}    8101
${KARAF_PROMPT}    opendaylight-user
${KARAF_USER}     karaf
${KARAF_PASSWORD}    karaf
${SECURITY_GROUP}    sg-vpnservice
${DCGW_RD}        1:1
${LOOPBACK_IP}    5.5.5.2
${LOOPBACK_IP1}    5.5.5.3
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${CONFIG_API}     /restconf/config
${OS_COMPUTE_1_IP}    192.168.56.100 
${OS_COMPUTE_2_IP}    192.168.56.101
${DCGW_SYSTEM_IP}    192.168.56.103   
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
#${VAR_BASE}       /home/SF218_4_11_2017/test/csit/variables/bgpfunctional
${VAR_BASE}       /root/SF218_testarea2/test/csit/variables/vpnservicei
${VAR_BASE_BGP}       /root/SF218_testarea2/test/csit/variables/bgpfunctional
${RESTCONFPORT}    8181
${BGP_SHOW}       display-bgp-config
${BGP_DELETE_NEIGH_CMD}    configure-bgp -op delete-neighbor --ip
${BGP_STOP_SERVER_CMD}    configure-bgp -op stop-bgp-server
${BGP_CONFIG_CMD}    configure-bgp -op start-bgp-server --as-num 100 --router-id
${BGP_CONFIG_ADD_NEIGHBOR_CMD}    configure-bgp -op add-neighbor --ip
#${hostname_compute_node}    Openstack-Controller
${origin}    "origin":"c"
