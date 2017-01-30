*** Settings ***
Documentation     Variables for SF218_EVPN_In_Inter_DC_Deployments Test Suites

*** Variables ***
#@{NETWORKS}       NET1    NET2    NET3    NET4    NET5    NET6    NET7    NET8
@{NETWORKS}       NET1    NET2
@{VM_INSTANCES_DPN1}    VM11    VM12    VM21    VM22
@{VM_INSTANCES_DPN2}    VM13    VM14    VM23    VM24
@{VM_INSTANCES_NET1}    VM11    VM12    VM13    VM14
@{VM_INSTANCES_NET2}    VM21    VM22    VM23    VM24
@{VM_INSTANCES}    VM11    VM12    VM21    VM22    VM13    VM14    VM23    VM24
@{PORT_LIST}      PORT11    PORT12    PORT21    PORT22    PORT13    PORT14    PORT23    PORT24
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.0.0/16    10.2.0.0/16    10.3.0.0/16    10.4.0.0/16    10.5.0.0/16    10.6.0.0/16    10.7.0.0/16    10.8.0.0/16
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
@{VPN_NAME}       vpn1
@{L3VPN_RD}        2200:2
@{CREATE_RD}      ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_EXPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_IMPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
${PING_REGEXP}    , 0% packet loss
${CREATE_l3VNI}    200
${DEF_LINUX_PROMPT}    #
${TEP_SHOW_STATE}    tep:show-state
${STATE_UP}       UP
${STATE_DOWN}     DOWN
${NETWORK_URL}    ${CONFIG_API}/neutron:neutron/networks/
${SUBNETWORK_URL}    ${CONFIG_API}/neutron:neutron/subnets/
${PORT_URL}       ${CONFIG_API}/neutron:neutron/ports/
${TUNNEL_TRANSPORTZONE}    ${CONFIG_API}/itm:transport-zones
${TUNNEL_INTERFACES}    ${CONFIG_API}/ietf-interfaces:interfaces/
@{EXTRA_NW_IP}    40.1.0.2    50.1.0.2
@{EXTRA_NW_SUBNET}    40.1.0.0/16    50.1.0.0/16
