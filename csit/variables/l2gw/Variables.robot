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
${PHY_NET_NAME}    physnet1
${PHY_VLAN_ID_1}    2902
${PHY_VLAN_ID_2}    2903
${PHY_NW_VLAN_TYPE}    vlan
${PHY_NW_FLAT_TYPE}    flat
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
${DEF_CONN_SEG_ID}    0
${BM_PORT1_MAC}    00:a1:00:00:00:01
${BM_PORT2_MAC}    00:b1:00:00:00:01
${BM_PORT1_IP}    13.0.0.254
${BM_PORT2_IP}    14.0.0.254
#List Variables
@{HWVTEP_PORT_LIST}    ${NS_PORT1}    ${NS_PORT2}
@{HWVTEP_NS_LIST}    ${HWVTEP_NS1}    ${HWVTEP_NS2}
@{HWVTEP2_PORT_LIST}    ${NS2_PORT1}    ${NS2_PORT2}
@{HWVTEP2_NS_LIST}    ${HWVTEP2_NS1}    ${HWVTEP2_NS2}
#Dont Change The Below Entries
${GREP_OVSDB_DUMP_PHYSICAL_SWITCH}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Physical_Switch table"
${ADD_VTEP_PS}    sudo vtep-ctl add-ps
${CREATE VTEP}    sudo ovsdb-tool create /etc/openvswitch/vtep.db ${OVS_HOME}/vtep.ovsschema
${CREATE_OVS_BRIDGE}    sudo ovs-vsctl add-br
${CREATE_OVS_PORT}    sudo ovs-vsctl add-port
${CREATE_OVSDB}    sudo ovsdb-tool create /etc/openvswitch/ovs.db ${OVS_HOME}/vswitch.ovsschema
${DEL_OVS_BRIDGE}    sudo ovs-vsctl del-br
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
${KILL_VTEP_PROC}    sudo killall -9 ovs-vtep
${KILL_DHCLIENT_PROC}    sudo killall -9 dhclient
${L2GW_CONN_CREATE}    neutron l2-gateway-connection-create --default-segmentation-id 0
${L2GW_CONN_DELETE}    neutron l2-gateway-connection-delete
${L2GW_LIST_REST_URL}    /restconf/config/neutron:neutron/l2gateways/
${L2GW_CONN_LIST_REST_URL}    /restconf/config/neutron:neutron/l2gatewayConnections/
${L2GW_CREATE}    neutron l2-gateway-create --device
${L2GW_UPDATE}    neutron l2-gateway-update --device
${L2GW_DELETE}    neutron l2-gateway-delete
${L2GW_GET_CONN_YAML}    neutron l2-gateway-connection-list -f yaml
${L2GW_GET_CONN}    neutron l2-gateway-connection-list
${L2GW_GET_YAML}    neutron l2-gateway-list -f yaml
${L2GW_GET}       neutron l2-gateway-list
${L2GW_SHOW}      neutron l2-gateway-show
${NET_ADDT_ARG}    --provider-network-type vxlan --provider-segment
${VXLAN_VLAN_SEG}    provider:physical_network=${PHY_NET_NAME},provider:segmentation_id=${PHY_VLAN_ID_1},provider:network_type=${PHY_NW_VLAN_TYPE} provider:physical_network='',provider:segmentation_id=${NET_1_SEGID},provider:network_type=vxlan
${VXLAN_FLAT_SEG}    provider:physical_network=${PHY_NET_NAME},provider:network_type=${PHY_NW_FLAT_TYPE} provider:physical_network='',provider:segmentation_id=${NET_1_SEGID},provider:network_type=vxlan
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
${REM_OVSDB}      sudo rm /etc/openvswitch/ovs.db
${REM_VTEPDB}     sudo rm /etc/openvswitch/vtep.db
${SET_FAIL_MODE}    sudo ovs-vsctl set-fail-mode
${SET_VTEP_PS}    sudo vtep-ctl set ${PHYSICAL_SWITCH_TABLE}
${SLEEP1S}        sleep 1
${START_OVSDB_SERVER}    sudo ovsdb-server --pidfile --detach --log-file --remote punix:/var/run/openvswitch/db.sock --remote=db:hardware_vtep,Global,managers /etc/openvswitch/ovs.db /etc/openvswitch/vtep.db
${START_OVSVTEP}    sudo /usr/share/openvswitch/scripts/ovs-vtep --log-file=/var/log/openvswitch/ovs-vtep.log --pidfile=/var/run/openvswitch/ovs-vtep.pid --detach
${STR_VIF_REPLACE}    "neutron-binding:vif-type":"hw_veb"
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
#Flow Table ids
${DEST_MAC_TABLE}    51
${DHCP_HWVTEP_TABLE}    18
#Regular Expressions
${VLAN_BINDING_REGEX}    vlan_bindings+\\s+:\\s+[{]0[=]
${NETSTAT_OVSDB_REGEX}    ${ODL_SYSTEM_IP}:${OVSDBPORT}\\s+ESTABLISHED\\s
${NETSTAT_OF_REGEX}    ${ODL_SYSTEM_IP}:${ODL_OF_PORT}\\s+ESTABLISHED\\s
