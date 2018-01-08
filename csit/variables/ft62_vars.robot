*** Settings ***
Documentation     Variables for EVPN_In_Intra_DC_Deployments Test Suites

*** Variables ***
@{REQ_NETWORKS}       NET1    NET2    NET3        
@{VM_INSTANCES_DPN1}    VM11    VM21    VM31        
@{VM_INSTANCES_DPN2}    VM12    VM22    VM32
@{REQ_VM_INSTANCES_NET1}    VM11    VM21    
@{REQ_VM_INSTANCES_NET2}    VM12    VM22    
@{REQ_VM_INSTANCES_NET3}    VM31    VM32
@{VM_INSTANCES_DPN1_PORTS}    PORT11    PORT21    PORT31    
@{VM_INSTANCES_DPN2_PORTS}    PORT12    PORT22    PORT32
@{VM_INSTANCES}    VM11    VM21    VM31    VM12    VM22    VM32    
@{REQ_PORT_LIST}      PORT11    PORT21    PORT31    PORT12    PORT22    PORT32    
@{REQ_SUBNETS}        SUBNET1    SUBNET2    SUBNET3   
${ROUTER_INTERFACE}    SUBNET3
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16  
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222    4ae8cd92-48ca-49b5-94e1-b2921a263333    4ae8cd92-48ca-49b5-94e1-b2921a264444
...   4ae8cd92-48ca-49b5-94e1-b2921a265555    AAAAAAAA-4848-4949-9494-666666666666
@{VPN_NAME}       vpn1    vpn2    vpn3    vpn4    vpn5
${REQ_ROUTER}        RTR1    
@{CREATE_RD}      ["100:31"]    ["100:32"]    ["100:33"]    ["100:34"]    ["100:35"]
@{CREATE_EXPORT_RT}    ["100:31"]    ["100:32"]    ["100:33"]    ["100:34"]    ["100:35"]
@{CREATE_IMPORT_RT}    ["100:31"]    ["100:32"]    ["100:33"]    ["100:34"]    ["100:35"]
${RT_LIST1}    ["100:31"]    ["100:32"]
${RT_LIST2}    ["100:31"]    ["100:33"]
${RT_LIST3}    ["100:31"]    ["100:34"]
${RT_LIST4}    ["100:31"]    ["100:35"]
${LOGIN_PSWD}     admin123
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h    ${ODL_SYSTEM_IP} -p 7644 add
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
${AS_ID}          100
${KARAF_SHELL_PORT}    8101
${KARAF_PROMPT}    opendaylight-user
${KARAF_USER}     karaf
${KARAF_PASSWORD}    karaf
${SECURITY_GROUP}    sg-vpnservice
${DCGW_RD}        100:31
${LOOPBACK_IP}    5.5.5.2
${LOOPBACK_IP1}    5.5.5.3
${FIB_ENTRIES_URL}    ${CONFIG_API}/odl-fib:fibEntries/
${CONFIG_API}     /restconf/config
@{TunnelSourceIp}    192.168.56.100    192.168.56.101
${TunnelNetwork}    192.168.56.0/24 
${OS_USER}        root
${DEVSTACK_DEPLOY_PATH}    /opt/openstack/devstack
${tempest_directory}      devstack
${USER_HOME}      /root/
${DELAY_AFTER_VM_CREATION}    30
${VAR_BASE}       /root/FT62/test/csit/variables/vpnservice
${RESTCONFPORT}    8181
${BGP_SHOW}       display-bgp-config
${BGP_DELETE_NEIGH_CMD}    configure-bgp -op delete-neighbor --ip
${BGP_STOP_SERVER_CMD}    configure-bgp -op stop-bgp-server
${BGP_CONFIG_CMD}    configure-bgp -op start-bgp-server --as-num 100 --router-id
${BGP_CONFIG_ADD_NEIGHBOR_CMD}    configure-bgp -op add-neighbor --ip
${origin}    "origin":"c"
${NUM_INSTANCES}    30
