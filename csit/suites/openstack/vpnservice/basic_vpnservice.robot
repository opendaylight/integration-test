*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
@{NET_1_VM_IPS}    10.1.1.3    10.1.1.4
@{NET_2_VM_IPS}    20.1.1.3    20.1.1.4
# Values passed by the calling method to API
${CREATE_ID}      "4ae8cd92-48ca-49b5-94e1-b2921a261111"
${CREATE_NAME}    "vpn2"
${CREATE_ROUTER_DISTINGUISHER}    ["2200:2"]
${CREATE_EXPORT_RT}    ["3300:2","8800:2"]
${CREATE_IMPORT_RT}    ["3300:2","8800:2"]
${CREATE_TENANT_ID}    "6c53df3a-3456-11e5-a151-feff819c1111"
@{VPN_INSTANCE}    vpn_instance_template.json
@{VPN_INSTANCE_NAME}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7    4ae8cd92-48ca-49b5-94e1-b2921a261111

*** Test Cases ***
Verify Tunnel Creation
    [Documentation]    Checks that vxlan tunnels have been created properly.
    ${node_dpid}=    Get DPID For Compute Node    ${OS_CONTROL_NODE_IP}
    ${node_1_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID For Compute Node    ${OS_COMPUTE_2_IP}
    ${node_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter From Compute Node    ${OS_COMPUTE_2_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.0.0/16
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}

    # Create tunnel using ODL CLI commands
    Create TEP For Compute Node    ${OS_CONTROL_NODE_IP}    ${node_dpid}    ${node_adapter}    ${subnet}    ${gateway}
    Create TEP For Compute Node    ${OS_COMPUTE_1_IP}    ${node_1_dpid}    ${node_1_adapter}    ${subnet}    ${gateway}
    Create TEP For Compute Node    ${OS_COMPUTE_2_IP}    ${node_2_dpid}    ${node_2_adapter}    ${subnet}    ${gateway}

Verify Tunnel get
    [Documentation]
    ${output}=    Run Command On Remote System     ${OS_COMPUTE_1_IP}     sudo ovs-vsctl show
    Log      ${output}
    ${output}=    Run Command On Remote System     ${OS_COMPUTE_2_IP}     sudo ovs-vsctl show
    Log      ${output}
    ${output}=    Run Command On Remote System     ${OS_CONTROL_NODE_IP}     sudo ovs-vsctl show   
    Log      ${output}

Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}    --provider:network_type local
    Create Network    ${NETWORKS[1]}    --provider:network_type local
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}

Check OpenDaylight Neutron Ports
    [Documentation]    Checking OpenDaylight Neutron API for known ports
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Add Ssh Allow Rule
    [Documentation]    Allow all TCP packets for testing
    Create Security Group    csit    "CSIT SSH Allow"
    Create Security Rule    ingress    tcp    1    65535    0.0.0.0/0    csit
    Create Security Rule    egress    tcp    1    65535    0.0.0.0/0    csit

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}
    Get DHCP Namespace List    ${NETWORKS[0]}
    Get DHCP Namespace List    ${NETWORKS[1]}

Create VM13
    [Documentation]    Create Vm instances for a network.
    Create Vm Instances1    ${NETWORKS[0]}    VM13    sg=csit

Ping Vm Instance13 From Network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Get DHCP Namespace List    ${NETWORKS[0]}
    Ping Vm From DHCP Namespace    ${NETWORKS[0]}    10.1.1.5

Ping Vm Instance1 From Network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Get DHCP Namespace List    ${NETWORKS[0]}
    Ping Vm From DHCP Namespace    ${NETWORKS[0]}    @{NET_1_VM_IPS}[0]

Ping Vm Instance1 From Network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Get DHCP Namespace List    ${NETWORKS[1]}
    Ping Vm From DHCP Namespace    ${NETWORKS[1]}    @{NET_2_VM_IPS}[0]

SSH Vm Instance13 From Network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    SSH Namespace Network Stack    ${NETWORKS[0]}    10.1.1.5

SSH Vm Instance1 From Network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    SSH Namespace Network Stack    ${NETWORKS[0]}    @{NET_1_VM_IPS}[0]

SSH Vm Instance1 From Network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    SSH Namespace Network Stack    ${NETWORKS[1]}    @{NET_2_VM_IPS}[0]

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    [Tags]    exclude
    Log    This test will be added in the next patch

#Create Routers
#    [Documentation]    Create Router
#    Create Router    ${ROUTERS[0]}
#
#Add Interfaces To Router
#    [Documentation]    Add Interfaces
#    : FOR    ${INTERFACE}    IN    @{SUBNETS}
#    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
#
#Check L3_Datapath Traffic Across Networks With Router
#    [Documentation]    Datapath Test Across the networks using Router for L3.
#    [Tags]    exclude
#    Log    This test will be added in the next patch
#
#Create L3VPN
#    [Documentation]    Creates L3VPN and verify the same
#    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
#    VPN Get L3VPN    ${CREATE_ID}
#
#Associate L3VPN to Routers
#    [Documentation]    Associating router to L3VPN
#    [Tags]    Associate
#    ${devstack_conn_id}=    Get ControlNode Connection
#    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
#    Associate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
#
#Dissociate L3VPN to Routers
#    [Documentation]    Dissociating router to L3VPN
#    [Tags]    Dissociate
#    ${devstack_conn_id}=    Get ControlNode Connection
#    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
#    Dissociate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
#
#Delete Router Interfaces
#    [Documentation]    Remove Interface to the subnets.
#    : FOR    ${INTERFACE}    IN    @{SUBNETS}
#    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
#
#Delete Routers
#    [Documentation]    Delete Router and Interface to the subnets.
#    Delete Router    ${ROUTERS[0]}
#
#Delete L3VPN
#    [Documentation]    Delete L3VPN
#    VPN Delete L3VPN    ${CREATE_ID}

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

Delete Vm Instances1
    [Documentation]    Delete Vm instances in the given Instance List
    Delete Vm Instance    VM13 

Delete Neutron Ports
    [Documentation]    Delete Neutron Ports in the given Port List.
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}

Delete Sub Networks
    [Documentation]    Delete Sub Nets in the given Subnet List.
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

Delete Networks
    [Documentation]    Delete Networks in the given Net List
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

Delete All TEP
    [Documentation]    Uses tep:deletedatastore karaf console command to delete All tep
    Issue Command On Karaf Console     tep:deletedatastore

Verify Tunnels Deleted 
    [Documentation]
    ${output}=    Run Command On Remote System     ${OS_COMPUTE_1_IP}     sudo ovs-vsctl show
    Log      ${output}
    ${output}=    Run Command On Remote System     ${OS_COMPUTE_2_IP}     sudo ovs-vsctl show
    Log      ${output}
    ${output}=    Run Command On Remote System     ${OS_CONTROL_NODE_IP}     sudo ovs-vsctl show 
    Log      ${output}

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions

Create Vm Instances1
    [Arguments]    ${net_name}    ${vm_instance_names}    ${image}=cirros-0.3.4-x86_64-uec    ${flavor}=m1.nano    ${sg}=default
    [Documentation]    Create X Vm Instance with the net id of the Netowrk.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova boot --image ${image} --flavor ${flavor} --nic net-id=${net_id} ${vm_instance_names} --security-groups ${sg}    30s
    Log    ${output}
    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${vm_instance_names}

Get DHCP Namespace List
    [Arguments]    ${net_name}
    [Documentation]    Get DHCP name space list from Netowrk.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns list    20s
    Log    ${output}
    Close Connection

SSH Namespace Network
    [Arguments]    ${net_name}    ${src_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    #${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Log    ${rcode}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Log    ${rcode}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    [Teardown]    Exit From Vm Console

