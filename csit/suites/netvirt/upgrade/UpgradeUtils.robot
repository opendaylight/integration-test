*** Settings ***
Documentation     Helper Test suite for ODL Upgrade. Contains common functions to create and delete resources
Library           SSHLibrary
Library           OperatingSystem
Resource          ../../../libraries/OpenStackOperations.robot

*** Variables ***
${SECURITY_GROUP}    sg-connectivity
@{NETWORKS_NAME}    net_1    net_2
@{SUBNETS_NAME}    subnet_1    subnet_2
@{NET_1_VM_GRP_NAME}    NET1-VM
@{NET_2_VM_GRP_NAME}    NET2-VM
@{NET_1_VM_INSTANCES}    NET1-VM-1    NET1-VM-2
@{NET_2_VM_INSTANCES}    NET2-VM-1    NET2-VM-2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24

*** Keywords ***
Create resources and check connectivity
    [Documentation] Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[0]
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instances    net_1    ${NET_1_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2
    OpenStackOperations.Create Vm Instances    net_2    ${NET_2_VM_GRP_NAME}    sg=${SECURITY_GROUP}    min=2    max=2
    OpenStackOperations.Create Router    router_1
    # Add interfaces to router
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    router_1    ${interface}
    @{NET1_VM_IPS}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    @{NET2_VM_IPS}    ${NET2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_INSTANCES}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET2_DHCP_IP}    None
    OpenStackOperations.Ping Vm From DHCP Namespace    net_1    @{NET1_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    net_1    @{NET1_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    net_2    @{NET2_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    net_2    @{NET2_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    network_1    @{NET2_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    network_1    @{NET2_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    network_2    @{NET1_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    network_2    @{NET1_VM_IPS}[1]

Get flows from br-int
    [Arguments]    ${openstack_node_ip}     ${log_file}
    [Documentation]    Get the OvsConfig and Flow entries from OVS from the Openstack Node
    OperatingSystem.Create File    ${log_file}
    OperatingSystem.Append To File    ${log_file}    ${openstack_node_ip}
    SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${br_int_show}=    Write Commands Until Expected Prompt    sudo ovs-ofctl show br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${br_int_show}
    ${flows}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${flows}
    Log File    ${log_file}
    SSHKeywords.Copy File To Remote System    ${OS_CONTROL_NODE_IP}    ${flows}    ${log_file}

Delete OVS controller
    [Arguments]    ${node}
    ${del_ctr}=    Run Command On Remote System    ${node}    sudo ovs-vsctl del-controller br-int
    Log    ${del_ctr}

Delete OVS manager
    [Arguments]    ${node}
    ${del_mgr}=    Run Command On Remote System    ${node}    sudo ovs-vsctl del-manager
    Log    ${del_mgr}

Delete groups
    [Arguments]    ${node}
    ${del_grp}=    Run Command On Remote System    ${node}    sudo ovs-ofctl -O Openflow13 br-int
    Log    ${del_grp}

Delete tun ports
    [Arguments]    ${node}
    [Documentation]    List all ports of br-int and delete tun ports
    ${tun_ports}=    Run Command On Remote System    ${node}    sudo ovs-vsctl list-ports br-int | grep "tun"
    Log    ${tun_ports}
    : FOR    ${tun_port}    IN    @{tun_ports}
    \     ${del-ports}=    Run Command On Remote System    ${node}    sudo ovs-vsctl del-port br-int ${tun_port}
    \     Log    ${del-ports}

Delete resources
    [Documentation] Delete created networks, subnets, security groups and VMs
    # Delete Vm instances using instance names in net_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}
    # Delete Vm instances using instance names in net_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}
    # Delete subnets
    : FOR    ${SubnetElement}    IN    ${SUBNETS_NAME}
    \    OpenStackOperations.Delete SubNet    ${SubnetElement}
    # Delete networks
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${NetworkElement}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${interface}
    OpenStackOperations.Delete Router    ${router_1}
