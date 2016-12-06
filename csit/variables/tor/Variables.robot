*** Variables ***
${PHYSICAL_SWITCH_NAME}    br0
${PHYSICAL_SWITCH_IP}    12.0.0.11
${GREP_OVSDB_DUMP_PHYSICAL_SWITCH}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Physical_Switch table"
${GREP_OVSDB_DUMP_MANAGER_TABLE}    sudo ovsdb-client dump hardware_vtep -f csv | grep -A2 "Manager table"
${KILL_VTEP_PROC}    sudo killall -9 ovs-vtep
${KILL_VSWITCHD_PROC}    sudo killall -9 ovs-vswitchd
${KILL_OVSDB_PROC}    sudo killall -9 ovsdb-server
${GREP_OVS}       ps -ef | grep ovs
${REM_OVSDB}      sudo rm /etc/openvswitch/ovs.db
${REM_VTEPDB}     sudo rm /etc/openvswitch/vtep.db
${EXPORT_OVS_HOME}    export OVS_HOME=\"/home/mininet/TOR/openvswitch-2.4.0/\"
${CREATE_OVSDB}    sudo ovsdb-tool create /etc/openvswitch/ovs.db $OVS_HOME/vswitchd/vswitch.ovsschema
${CREATE VTEP}    sudo ovsdb-tool create /etc/openvswitch/vtep.db $OVS_HOME/vtep/vtep.ovsschema
${SLEEP1S}        sleep 1
${START_OVSDB_SERVER}    sudo ovsdb-server --pidfile --detach --log-file --remote punix:/usr/local/var/run/openvswitch/db.sock --remote=db:hardware_vtep,Global,managers /etc/openvswitch/ovs.db /etc/openvswitch/vtep.db
${INIT_TOR}       sudo ovs-vsctl --no-wait init
${DETACH_VSWITCHD}    sudo ovs-vswitchd --pidfile --detach
${CREATE_TOR_BRIDGE}    sudo ovs-vsctl add-br br0
${OVS_SHOW}       sudo ovs-vsctl show
${ADD_VTEP_PS}    sudo vtep-ctl add-ps br0
${SET_VTEP_PS}    sudo vtep-ctl set Physical_Switch br0 tunnel_ips=12.0.0.11
${START_OVSVTEP}    sudo $OVS_HOME/vtep/ovs-vtep --log-file=/var/log/openvswitch/ovs-vtep.log --pidfile=/var/run/openvswitch/ovs-vtep.pid --detach br0
${VTEP_DEL_MGR}    sudo vtep-ctl del-manager
${VTEP_ADD_MGR}    sudo vtep-ctl set-manager tcp
${OPERATIONAL_NODES_HWTEP}    /restconf/operational/network-topology:network-topology/topology/hwvtep:1
