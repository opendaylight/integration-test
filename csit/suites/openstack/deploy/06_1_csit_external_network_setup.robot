*** Settings ***
Documentation     Suite that Configures External Networks for CSIT
Suite Setup       OpenStackInstallUtils.Get All Ssh Connections
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackInstallUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SystemUtils.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Configure External Networks For Testing
    Local Install Rpm Package    openvswitch
    Run Command In Local Node    sudo systemctl start openvswitch
    Setup External Network In Robot VM    flat1    101.0.0.2/24    101.0.0.1/24
    Install Configure OvsSwitch    ${OS_CONTROL_1_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Configure OvsSwitch    ${OS_CONTROL_2_IP}
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Install Configure OvsSwitch    ${OS_CONTROL_3_IP}
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Install Configure OvsSwitch    ${OS_CONTROL_4_IP}
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Install Configure OvsSwitch    ${OS_CONTROL_5_IP}
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Install Configure OvsSwitch    ${OS_COMPUTE_1_IP}
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Install Configure OvsSwitch    ${OS_COMPUTE_2_IP}
    Create External Network For CSIT    flat1     ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_IP}    9786
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat1    ${OS_CONTROL_2_IP}
    ...    ${OS_CONTROL_2_IP}    9786
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat1    ${OS_CONTROL_3_IP}
    ...    ${OS_CONTROL_3_IP}    9786
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat1    ${OS_CONTROL_4_IP}
    ...    ${OS_CONTROL_4_IP}    9786
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat1    ${OS_CONTROL_5_IP}
    ...    ${OS_CONTROL_5_IP}    9786
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    flat1    ${OS_COMPUTE_1_IP}
    ...    ${OS_COMPUTE_1_IP}    9786
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    flat1    ${OS_COMPUTE_2_IP}
    ...    ${OS_COMPUTE_2_IP}    9786
    Setup External Network In Robot VM    flat2    102.0.0.2/24    102.0.0.1/24
    Create External Network For CSIT    flat2     ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_IP}    9787
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat2    ${OS_CONTROL_2_IP}
    ...    ${OS_CONTROL_2_IP}    9787
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat2    ${OS_CONTROL_3_IP}
    ...    ${OS_CONTROL_3_IP}    9787
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat2    ${OS_CONTROL_4_IP}
    ...    ${OS_CONTROL_4_IP}    9787
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    flat2    ${OS_CONTROL_5_IP}
    ...    ${OS_CONTROL_5_IP}    9787
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    flat2    ${OS_COMPUTE_1_IP}
    ...    ${OS_COMPUTE_1_IP}    9787
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    flat2    ${OS_COMPUTE_2_IP}
    ...    ${OS_COMPUTE_2_IP}    9787
    Setup External Network In Robot VM    physnet1    10.10.10.253/24    10.10.10.250/24
    Create External Network For CSIT    physnet1    ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_IP}    9788
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    physnet1    ${OS_CONTROL_2_IP}
    ...    ${OS_CONTROL_2_IP}    9788
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    physnet1    ${OS_CONTROL_3_IP}
    ...    ${OS_CONTROL_3_IP}    9788
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    physnet1    ${OS_CONTROL_4_IP}
    ...    ${OS_CONTROL_4_IP}    9788
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    physnet1    ${OS_CONTROL_5_IP}
    ...    ${OS_CONTROL_5_IP}    9788
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    physnet1    ${OS_COMPUTE_1_IP}
    ...    ${OS_COMPUTE_1_IP}    9788
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    physnet1    ${OS_COMPUTE_2_IP}
    ...    ${OS_COMPUTE_2_IP}    9788
    Run Command In Local Node    sudo ip tuntap add dev internet_tap mode tap
    Run Command In Local Node    sudo ifconfig internet_tap up 10.9.9.9/24
    Run Command In Local Node    sudo ip netns add vlantest
    Run Command In Local Node    sudo ovs-vsctl add-br br-vlantest
    Local Install Rpm Package    vconfig
    Setup External Network with Vlan    vlantest     28     105.0.0.2/24     vlantest1
    Setup External Network with Vlan    vlantest     29     106.0.0.2/24     vlantest2
    Create External Network For CSIT    vlantest     ${OS_CONTROL_1_IP}    ${OS_CONTROL_1_IP}    9789
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    vlantest    ${OS_CONTROL_2_IP}
    ...    ${OS_CONTROL_2_IP}    9789
    Run Keyword If    2 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    vlantest    ${OS_CONTROL_3_IP}
    ...    ${OS_CONTROL_3_IP}    9789
    Run Keyword If    3 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    vlantest    ${OS_CONTROL_4_IP}
    ...    ${OS_CONTROL_4_IP}    9789
    Run Keyword If    4 < ${NUM_CONTROL_NODES}    Create External Network For CSIT    vlantest    ${OS_CONTROL_5_IP}
    ...    ${OS_CONTROL_5_IP}    9789
    Run Keyword If    0 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    vlantest    ${OS_COMPUTE_1_IP}
    ...    ${OS_COMPUTE_1_IP}    9789
    Run Keyword If    1 < ${NUM_COMPUTE_NODES}    Create External Network For CSIT    vlantest    ${OS_COMPUTE_2_IP}
    ...    ${OS_COMPUTE_2_IP}    9789

*** Keywords ***
Install Configure OvsSwitch
    [Arguments]    ${os_node_cxn}
    Run Keyword If    '${OS_APPS_PRE_INSTALLED}' == 'no'    Install Rpm Package    ${os_node_cxn}    openvswitch
    Crudini Edit    ${os_node_cxn}    /usr/lib/systemd/system/ovsdb-server.service    Service    Restart    always
    Crudini Edit    ${os_node_cxn}    /usr/lib/systemd/system/ovs-vswitchd.service    Service    Restart    always
    Enable Service    ${os_node_cxn}    openvswitch
    Start Service    ${os_node_cxn}    openvswitch

Setup External Network In Robot VM
    [Arguments]    ${external_network_name}    ${host_ip_cidr_format}    ${ext_gateway_ip_addr}
    Run Command In Local Node    sudo ip netns add ${external_network_name}
    Run Command In Local Node    sudo ip link add ${external_network_name}_ns type veth peer name ${external_network_name}_ovs
    Run Command In Local Node    sudo ip link set ${external_network_name}_ns netns ${external_network_name}
    Run Command In Local Node    sudo ip netns exec ${external_network_name} ifconfig ${external_network_name}_ns ${host_ip_cidr_format} up
    Run Command In Local Node    sudo ip netns exec ${external_network_name} ip link set ${external_network_name}_ns up
    Run Command In Local Node    sudo ovs-vsctl add-br br-${external_network_name}
    Run Command In Local Node    sudo ovs-vsctl add-port br-${external_network_name} ${external_network_name}_ovs
    Run Command In Local Node    sudo ip link set ${external_network_name}_ovs up
    Run Command In Local Node    sudo ifconfig br-${external_network_name} ${ext_gateway_ip_addr} up

Create External Network For CSIT
    [Arguments]    ${external_network_name}      ${os_node_cxn}    ${os_node_ip_address}    ${tunnel_port_number}
    Run Command In Local Node    sudo ovs-vsctl add-port br-${external_network_name} vxlan_${external_network_name}_${os_node_ip_address} -- set interface vxlan_${external_network_name}_${os_node_ip_address} type=vxlan options:remote_ip=${os_node_ip_address} options:dst_port=${tunnel_port_number} options:key=flow
    Run Command    ${os_node_cxn}    sudo ovs-vsctl --if-exists del-port br-${external_network_name}
    Run Command    ${os_node_cxn}    sudo ovs-vsctl --may-exist add-br br-${external_network_name}
    Run Command    ${os_node_cxn}    sudo ovs-vsctl add-port br-${external_network_name} vxlan_${external_network_name}_robot -- set interface vxlan_${external_network_name}_robot type=vxlan options:local_ip=${os_node_ip_address} options:remote_ip=${ROBOT_VM_IP} options:dst_port=${tunnel_port_number} options:key=flow
    Run Command    ${os_node_cxn}    sudo ifconfig br-${external_network_name} up

Setup External Network with Vlan
    [Arguments]    ${external_network_name}    ${vlan_id}     ${host_ip_cidr_format}      ${host_if_name}
    Run Command In Local Node    sudo ip link add ${host_if_name}_ns type veth peer name ${host_if_name}_ovs
    Run Command In Local Node    sudo ip link set ${host_if_name}_ns netns ${external_network_name}
    Run Command In Local Node    sudo ip netns exec ${external_network_name} vconfig add ${host_if_name}_ns ${vlan_id}
    Run Command In Local Node    sudo ip netns exec ${external_network_name} ifconfig ${host_if_name}_ns 0.0.0.0 up
    Run Command In Local Node    sudo ip netns exec ${external_network_name} ifconfig ${host_if_name}_ns.${vlan_id} ${host_ip_cidr_format} up
    Run Command In Local Node    sudo ovs-vsctl add-port br-${external_network_name} ${host_if_name}_ovs
    Run Command In Local Node    sudo ip link set ${host_if_name}_ovs up
