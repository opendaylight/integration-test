*** Variables ***
#Configurable Variables
${OS_IP}          ${OS_CONTROL_NODE_IP}
${OVS_IP}         ${OS_COMPUTE_1_IP}
${OVS2_IP}        ${OS_COMPUTE_2_IP}
${HWVTEP_IP}      ${TOOLS_SYSTEM_1_IP}
${HWVTEP2_IP}     ${TOOLS_SYSTEM_2_IP}
${ODL_IP}         ${ODL_SYSTEM_1_IP}
${OS_PASSWORD}    ${EMPTY}
${HWVTEP_BRIDGE}    br-hwvtep-blue
${HWVTEP2_BRIDGE}    br-hwvtep-red
${DEVSTACK_DEPLOY_PATH}    /home/stack/devstack
${HWVTEP_NS1}     NS1
${HWVTEP_NS2}     NS2
${HWVTEP2_NS1}    NS3
${HWVTEP2_NS2}    NS4
${HWVTEP_PORT_1}    HWVPORT1
${HWVTEP_PORT_2}    HWVPORT2
${HWVTEP_PORT_3}    HWVPORT3
${HWVTEP2_PORT_1}    HWVPORT4
${HWVTEP2_PORT_2}    HWVPORT5
${L2GW_NAME1}     GW1
${L2GW_NAME2}     GW2
${L2GW_NAME3}     GW3
${L2GW_NAME4}     GW4
${NET_1_SEGID}    1063
${NET_1}          NETHWV1
${NET_2_SEGID}    1064
${NET_2}          NETHWV2
${NS_PORT1}       PORT1
${NS_PORT2}       PORT2
${NS_PORT3}       PORT3
${NS2_PORT1}      PORT4
${NS2_PORT2}      PORT5
${NS_TAP1}        TAP1
${NS_TAP2}        TAP2
${NS_TAP3}        TAP3
${NS2_TAP1}       TAP4
${NS3_TAP1}       TAP5
${NS4_TAP1}       TAP6
${OVS_BRIDGE}     br-int
${OVS_PORT_1}     OVSPORT1
${OVS_PORT_2}     OVSPORT2
${OVS2_PORT_1}    OVSPORT3
${OVS2_PORT_2}    OVSPORT4
${OVS_VM1_NAME}    VM1
${OVS_VM2_NAME}    VM2
${OVS2_VM1_NAME}    VM3
${OVS_VM2_NAME}    VM4
${SECURITY_GROUP_L2GW}    sg-l2gateway
${SECURITY_GROUP_L2GW_NONE}    --no-security-groups
${SUBNET_1}       HWV-SUB1
${SUBNET_2}       HWV-SUB2
${SUBNET_RANGE1}    13.0.0.0/24
${SUBNET_RANGE2}    14.0.0.0/24
## Configure 02_Configure_verify_l2gateway ###
# VM Instance
${VM_NAME1}       vm1
${NET_NAME1}      NET1
${NET_SEGID1}     1111
${SUBNET_NAME1}    SUBNET1
${SUBNET_RANGE_IP1}    192.168.11.0/24
# L2GW#1
${GW_NAME1}       gw1
${GW_DEV_NAME1}    l2gw1
${GW_DEV_IF1}     OVSPORT1
${GW_DEV_IF2}     OVSPORT2
${GW_CONN_SEGID_VID1}    1111
&{NS_PORT_INFO1}    ovs_port_name=${GW_DEV_IF1}    ns_name=NS1    ns_tap_name=TAP1    mac=5a:4d:06:03:01:01    ip=192.168.11.201    vlan=${GW_CONN_SEGID_VID1}    type=ns
&{NS_PORT_INFO2}    ovs_port_name=${GW_DEV_IF2}    ns_name=NS2    ns_tap_name=TAP2    mac=5a:4d:06:03:01:02    ip=192.168.11.202    vlan=${GW_CONN_SEGID_VID1}    type=ns
@{GW_NS_PORTS1}    ${NS_PORT_INFO1}    ${NS_PORT_INFO2}
# L2GW#2
${GW_NAME2}       gw2
${GW_DEV_NAME2}    l2gw2
${GW_DEV_IF3}     OVSPORT3
${GW_CONN_SEGID_VID2}    2222
&{NS_PORT_INFO3}    ovs_port_name=${GW_DEV_IF3}    ns_name=NS3    ns_tap_name=TAP3    mac=5a:4d:06:03:01:03    ip=192.168.11.203    vlan=${GW_CONN_SEGID_VID2}    type=ns
@{GW_NS_PORTS2}    ${NS_PORT_INFO3}
## Configure 03_Configure_verify_l2gateway ###
# VM Instance
${VM_NAME11}      vm11
${NET_NAME11}     NET11
${NET_SEGID11}    1111
${SUBNET_NAME11}    SUBNET11
${SUBNET_RANGE_IP11}    192.168.111.0/24
${VM_NAME12}      vm12
${NET_NAME12}     NET12
${NET_SEGID12}    2222
${SUBNET_NAME12}    SUBNET12
${SUBNET_RANGE_IP12}    192.168.112.0/24
# L2GW#1
${GW_NAME11}      gw11
${GW_NAME12}      gw12
${GW_DEV_NAME11}    l2gw11
${GW_DEV_IF11}    OVSPORT11
${GW_DEV_IF12}    OVSPORT12
${GW_DEV_IF13}    OVSPORT13
${GW_DEV_IF14}    OVSPORT14
${GW_DEV_IF15}    OVSPORT15
${GW_DEV_IF16}    OVSPORT16
${GW_DEV_IF17}    OVSPORT17
${GW_CONN_SEGID_VID11}    2222
${GW_CONN_SEGID_VID12}    0
${GW_CONN_SEGID_VID13}    1111
${GW_CONN_SEGID_VID14}    1111
${GW_CONN_SEGID_VID15}    0
${GW_CONN_SEGID_VID16}    2222
${GW_CONN_SEGID_VID17}    0
&{NS_PORT_INFO11}    ovs_port_name=${GW_DEV_IF11}    ns_name=NS11    ns_tap_name=TAP11    mac=5a:4d:06:03:01:11    ip=192.168.111.211    vlan=${GW_CONN_SEGID_VID11}    type=ns
&{NS_PORT_INFO12}    ovs_port_name=${GW_DEV_IF12}    ns_name=NS12    ns_tap_name=TAP12    mac=5a:4d:06:03:01:12    ip=192.168.111.212    type=ns
&{NS_PORT_INFO13}    ovs_port_name=${GW_DEV_IF13}    ns_name=NS13    ns_tap_name=TAP13    mac=5a:4d:06:03:01:13    ip=192.168.111.213    vlan=${GW_CONN_SEGID_VID13}    type=ns
&{NS_PORT_INFO14}    ovs_port_name=${GW_DEV_IF14}    ns_name=NS14    ns_tap_name=TAP14    mac=5a:4d:06:03:01:14    ip=192.168.111.214    vlan=${GW_CONN_SEGID_VID14}    type=ns
&{NS_PORT_INFO15}    ovs_port_name=${GW_DEV_IF15}    ns_name=NS15    ns_tap_name=TAP15    mac=5a:4d:06:03:01:15    ip=192.168.111.215    type=ns
&{NS_PORT_INFO16}    ovs_port_name=${GW_DEV_IF16}    ns_name=NS16    ns_tap_name=TAP16    mac=5a:4d:06:03:01:16    ip=192.168.112.216    vlan=${GW_CONN_SEGID_VID16}    type=ns
&{NS_PORT_INFO17}    ovs_port_name=${GW_DEV_IF17}    ns_name=NS17    ns_tap_name=TAP17    mac=5a:4d:06:03:01:17    ip=192.168.112.217    type=ns
@{GW_NS_PORTS11}    ${NS_PORT_INFO11}    ${NS_PORT_INFO12}    ${NS_PORT_INFO13}    ${NS_PORT_INFO14}    ${NS_PORT_INFO15}    ${NS_PORT_INFO16}    ${NS_PORT_INFO17}
# L2GW#2
${GW_NAME21}      gw21
${GW_DEV_NAME21}    l2gw21
${GW_DEV_IF21}    OVSPORT21
${GW_DEV_IF22}    OVSPORT22
${GW_CONN_SEGID_VID21}    1111
${GW_CONN_SEGID_VID22}    0
&{NS_PORT_INFO21}    ovs_port_name=${GW_DEV_IF21}    ns_name=NS21    ns_tap_name=TAP21    mac=5a:4d:06:03:01:21    ip=192.168.111.221    vlan=${GW_CONN_SEGID_VID21}    type=ns
&{NS_PORT_INFO22}    ovs_port_name=${GW_DEV_IF22}    ns_name=NS22    ns_tap_name=TAP22    mac=5a:4d:06:03:01:22    ip=192.168.111.222    type=ns
@{GW_NS_PORTS21}    ${NS_PORT_INFO21}    ${NS_PORT_INFO22}
#Dont Change The Below Entries
${GREP_OVSDB_DUMP_PHYSICAL_SWITCH}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Physical_Switch table"
${ADD_VTEP_PS}    sudo vtep-ctl add-ps
${CREATE VTEP}    sudo ovsdb-tool create /etc/openvswitch/vtep.db ${OVS_HOME}/vtep.ovsschema
${CREATE_OVS_BRIDGE}    sudo ovs-vsctl add-br
${CREATE_OVS_PORT}    sudo ovs-vsctl add-port
${CREATE_OVSDB}    sudo ovsdb-tool create /etc/openvswitch/ovs.db ${OVS_HOME}/vswitch.ovsschema
${DEL_OVS_BRIDGE}    sudo ovs-vsctl del-br
${DEL_OVS_PORT}    sudo ovs-vsctl del-port
${DETACH_VSWITCHD}    sudo ovs-vswitchd --pidfile --detach
${GET_DPNID}      printf "%d\\n" 0x`sudo ovs-ofctl show -O Openflow13 br-int | head -1 | awk -F "dpid:" '{print $2}'`
${GET_PORT_URL}    neutron:neutron/ports/port
${GREP_OVS}       ps -ef | grep ovs
${GREP_OVSDB_DUMP_MANAGER_TABLE}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Manager table"
${HW_ETHER}       hw ether
${HWVTEP_NETWORK_TOPOLOGY}    /restconf/operational/network-topology:network-topology/topology/hwvtep:1/
${IFCONF}         ifconfig
${INIT_VSCTL}     sudo ovs-vsctl --no-wait init
${IP_LINK_ADD}    ${IP_LINK} add
${IP_LINK_DEL}    ${IP_LINK} del
${IP_LINK_SET}    ${IP_LINK} set
${IP_LINK}        sudo ip link
${IPLINK_SET}     ip link set dev
${KILL_OVSDB_PROC}    sudo killall -9 ovsdb-server
${KILL_VSWITCHD_PROC}    sudo killall -9 ovs-vswitchd
${KILL_VTEP_PROC}    sudo killall -9 python
${L2GW_CONN_CREATE}    neutron l2-gateway-connection-create --default-segmentation-id 0
${L2GW_CONN_CREATE_NOOPTS}    neutron l2-gateway-connection-create
${L2GW_CONN_DELETE}    neutron l2-gateway-connection-delete
${L2GW_CONN_SHOW}    neutron l2-gateway-connection-show
${L2GW_LIST_REST_URL}    /restconf/config/neutron:neutron/l2gateways/
${L2GW_CONN_LIST_REST_URL}    /restconf/config/neutron:neutron/l2gatewayConnections/
${L2GW_CREATE}    neutron l2-gateway-create --device
${L2GW_UPDATE}    neutron l2-gateway-update --device
${L2GW_UPDATE_NOOPTS}    neutron l2-gateway-update
${L2GW_DELETE}    neutron l2-gateway-delete
${L2GW_GET_CONN_YAML}    neutron l2-gateway-connection-list -f yaml
${L2GW_GET_CONN}    neutron l2-gateway-connection-list
${L2GW_GET_YAML}    neutron l2-gateway-list -f yaml
${L2GW_GET}       neutron l2-gateway-list
${L2GW_SHOW}      neutron l2-gateway-show
${NET_ADDT_ARG}    --provider-network-type vxlan --provider-segment
${NETNS_ADD}      ${NETNS} add
${NETNS_DEL}      ${NETNS} del
${NETNS_EXEC}     ${NETNS} exec
${NETNS}          sudo ip netns
${NETSTAT}        sudo netstat -nap
${PACKET_LOSS}    , 100% packet loss
${ODL_STREAM}     dummy
${OVS_DEL_CTRLR}    sudo ovs-vsctl del-controller
${OVS_DEL_MGR}    sudo ovs-vsctl del-manager
${OVS_HOME}       /usr/share/openvswitch/
${OVS_RESTART}    sudo service openvswitch-switch restart
${OVS_SET_CTRLR}    sudo ovs-vsctl set-controller
${OVS_SET_MGR}    sudo ovs-vsctl set-manager tcp
${OVS_SHOW}       sudo ovs-vsctl show
${OVSDB_CLIENT_DUMP}    sudo ovsdb-client dump hardware_vtep
${OVSDB_NETWORK_TOPOLOGY}    /restconf/operational/network-topology:network-topology/topology/ovsdb:1/
${OVS_OFDUMP_FLOWS}    sudo ovs-ofctl dump-flows
${OVS_OFSHOW}     sudo ovs-ofctl show
${OVS_OFDUMP_GROUPS}    sudo ovs-ofctl dump-groups
${REM_OVSDB}      sudo rm /etc/openvswitch/ovs.db
${REM_VTEPDB}     sudo rm /etc/openvswitch/vtep.db
${SET_FAIL_MODE}    sudo ovs-vsctl set-fail-mode
${SET_VTEP_PS}    sudo vtep-ctl set ${PHYSICAL_SWITCH_TABLE}
${SLEEP1S}        sleep 1
${START_OVSDB_SERVER}    sudo ovsdb-server --pidfile --detach --log-file --remote punix:/var/run/openvswitch/db.sock --remote=db:hardware_vtep,Global,managers /etc/openvswitch/ovs.db /etc/openvswitch/vtep.db
${START_OVSVTEP}    sudo /usr/share/openvswitch/scripts/ovs-vtep --log-file=/var/log/openvswitch/ovs-vtep.log --pidfile=/var/run/openvswitch/ovs-vtep.pid --detach
${STR_VIF_REPLACE}    "neutron-binding:vif-type":"ovs"
${STR_VIF_TYPE}    "neutron-binding:vif-type":"unbound"
${STR_VNIC_REPLACE}    "neutron-binding:vnic-type":"direct"
${STR_VNIC_TYPE}    "neutron-binding:vnic-type":"normal"
${SUBNET_ADDT_ARG}    --dhcp
${UUID_COL_NAME}    _uuid
${VTEP LIST}      sudo vtep-ctl list
${VTEP_ADD_MGR}    sudo vtep-ctl set-manager tcp
${VTEP_DEL_MGR}    sudo vtep-ctl del-manager
${VTEP_LIST_COLUMN}    sudo vtep-ctl --columns=
#HWVTEP Table Names
${LOGICAL_SWITCH_TABLE}    Logical_Switch
${GLOBAL_TABLE}    Global
${MANAGER_TABLE}    Manager
${MCAST_MACS_LOCAL_TABLE}    Mcast_Macs_Local
${MCAST_MACS_REMOTE_TABLE}    Mcast_Macs_Remote
${PHYSICAL_LOCATOR_TABLE}    Physical_Locator
${PHYSICAL_PORT_TABLE}    Physical_Port
${PHYSICAL_SWITCH_TABLE}    Physical_Switch
${TUNNEL_TABLE}    Tunnel
${UCAST_MACS_LOCALE_TABLE}    Ucast_Macs_Local
${UCAST_MACS_REMOTE_TABLE}    Ucast_Macs_Remote
#Regular Expressions
${VLAN_BINDING_REGEX}    vlan_bindings+\\s+:\\s+[{]0[=]
${NETSTAT_OVSDB_REGEX}    ${ODL_SYSTEM_IP}:${OVSDBPORT}\\s+ESTABLISHED\\s
${NETSTAT_OF_REGEX}    ${ODL_SYSTEM_IP}:${ODL_OF_PORT}\\s+ESTABLISHED\\s
${NEUTRON_UUID}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
