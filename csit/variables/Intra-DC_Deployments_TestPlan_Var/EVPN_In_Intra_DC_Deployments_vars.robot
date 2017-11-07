*** Settings ***
Documentation     Variables for EVPN_In_Intra_DC_Deployments Test Suites

*** Variables ***
@{REQ_NETWORKS}    NET1    NET2    NET3    NET4    NET5    NET6    NET7
...               NET8
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
@{REQ_PORT_LIST}    PORT11    PORT12    PORT21    PORT22    PORT31    PORT32    PORT41
...               PORT42    PORT13    PORT14    PORT23    PORT24    PORT33    PORT34
...               PORT43    PORT44
@{REQ_SUBNETS}    SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6    SUBNET7
...               SUBNET8
@{REQ_SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16    10.5.0.0/16    10.6.0.0/16    10.7.0.0/16
...               10.8.0.0/16    10.9.0.0/16    10.10.0.0/16    10.11.0.0/16    10.12.0.0/16    10.13.0.0/16    10.14.0.0/16
...               10.15.0.0/16    10.16.0.0/16
@{REQ_SUBNET_CIDR_TESTAREA1}    10.1.0.0/16    10.2.0.0/16
${NUM_INSTANCES}    30
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a262222
@{VPN_NAME}       vpn1    vpn2
@{ROUTER_NAME}    RTR1    RTR2
@{REQ_ROUTERS}    RTR1    RTR2
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
${REQ_TEP_SHOW}    tep:show
${STATE_UP}       UP
${STATE_DOWN}     DOWN
${REQ_NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${REQ_SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${REQ_PORT_URL}    ${CONFIG_API}/neutron:neutron/ports/
${REQ_TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${REQ_TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
${AS_ID}          100
${SECURITY_GROUP}    sg-vpnservice
${DCGW_RD}        2200:2
${LOOPBACK_IP}    5.5.5.2
${LOOPBACK_IP1}    5.5.5.3
${OS_USER}        root
${DEVSTACK_SYSTEM_PASSWORD}    admin123
${DEVSTACK_DEPLOY_PATH}    /opt/stack/devstack/
# ODL system variables
${USER_HOME}      /root/
${DELAY_AFTER_VM_CREATION}    30
${VAR_BASE}       /root/SF218_REVIEW_LATEST/test/csit/variables/bgpfunctional
${RESTCONFPORT}    8181
${BGP_SHOW}       display-bgp-config
${BGP_DELETE_NEIGH_CMD}    configure-bgp -op delete-neighbor --ip
${BGP_STOP_SERVER_CMD}    configure-bgp -op stop-bgp-server
${BGP_CONFIG_CMD}    configure-bgp -op start-bgp-server --as-num 100 --router-id
${BGP_CONFIG_ADD_NEIGHBOR_CMD}    configure-bgp -op add-neighbor --ip
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h  ${ODL_SYSTEM_IP} -p 7644 add
