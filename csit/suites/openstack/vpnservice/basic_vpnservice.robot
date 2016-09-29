*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Test Setup        Log Testcase Start To Controller Karaf
Test Teardown     Run Keywords    Show Debugs    ${NET_1_VM_INSTANCES}
...               AND    Show Debugs    ${NET_2_VM_INSTANCES}
...               AND    Get OvsDebugInfo
#Suite Setup       Basic Vpnservice Suite Setup
#Suite Teardown    Basic Vpnservice Suite Teardown
#Test Setup        Log Testcase Start To Controller Karaf
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
@{SUBNET_CIDR}    10.0.0.0/24    20.0.0.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22 
@{NET_1_VM_INSTANCES}    VM11     VM12 
@{NET_2_VM_INSTANCES}    VM21     VM22 
@{ROUTERS}        ROUTER_1    ROUTER_2
@{NET_1_VM_IPS}    10.0.0.3    10.0.0.4 
@{NET_2_VM_IPS}    20.0.0.3    20.0.0.4
# Values passed by the calling method to API
@{CREATE_ID}      "4ae8cd92-48ca-49b5-94e1-b2921a261111"    "4ae8cd92-48ca-49b5-94e1-b2921a261112"    "4ae8cd92-48ca-49b5-94e1-b2921a261113"
@{CREATE_NAME}    "vpn1"    "vpn2"    "vpn3"
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
    #Create TEP For Compute Node    ${OS_CONTROL_NODE_IP}    ${node_dpid}    ${node_adapter}    ${subnet}    ${gateway}
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
    ${output}=    Issue Command On Karaf Console    tep:show-state  
    Log     ${output}

Create Neutron Networks
    [Documentation]    Create two networks
#    Create Network    ${NETWORKS[0]}    --provider:network_type local
#    Create Network    ${NETWORKS[1]}    --provider:network_type local
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]} 
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
    Create Security Group    csit13    "CSIT SSH Allow"
    Create Security Rule    ingress    tcp    1    65535    0.0.0.0/0    csit13
    Create Security Rule    egress    tcp    1    65535    0.0.0.0/0    csit13

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}
    Get DHCP Namespace List    ${NETWORKS[0]}
    Get DHCP Namespace List    ${NETWORKS[1]}

#Create VM Network1
#    [Documentation]    Create Vm instances for a network1.
#    Create Vm Instances    ${NETWORKS[0]}     ${NET_1_VM_INSTANCES}    sg=csit13
#    Get DHCP Namespace List    ${NETWORKS[0]}
#
#Create VM Network2
#    [Documentation]    Create Vm instances for a network2.
#    Create Vm Instances    ${NETWORKS[1]}     ${NET_2_VM_INSTANCES}    sg=csit13
#    Get DHCP Namespace List    ${NETWORKS[1]}

Ping Vm Instance1 From Network1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Get DHCP Namespace List    ${NETWORKS[0]}
    Ping Vm From DHCP Namespace    ${NETWORKS[0]}    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 From Network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Get DHCP Namespace List    ${NETWORKS[0]}
    Ping Vm From DHCP Namespace    ${NETWORKS[0]}    @{NET_1_VM_IPS}[1]

Ping Vm Instance1 From Network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Get DHCP Namespace List    ${NETWORKS[1]}
    Ping Vm From DHCP Namespace    ${NETWORKS[1]}    @{NET_2_VM_IPS}[0]

SSH Vm Instance1 From Network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    SSH Namespace Network From Stack    ${NETWORKS[0]}    @{NET_1_VM_IPS}[0]    @{NET_1_VM_IPS}[1]

SSH Vm Instance1 From Network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    SSH Namespace Network From Stack    ${NETWORKS[1]}    @{NET_2_VM_IPS}[0]    @{NET_2_VM_IPS}[1]

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

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

Get DHCP Namespace List
    [Arguments]    ${net_name}
    [Documentation]    Get DHCP name space list from Netowrk.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ip netns list    20s
    Log    ${output}
    ${output}=    Write Commands Until Prompt    sudo route    20s
    Log    ${output}
    Close Connection

SSH Namespace Network From Stack
    [Arguments]    ${net_name}    ${src_ip}    ${dst_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh in the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id}=    Get Net Id    ${net_name}    ${devstack_conn_id}
    ${output}=    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ssh ${user}@${src_ip} -o ConnectTimeout=10 -o StrictHostKeyChecking=no    d:
    Log    ${output}
    ${output}=    Write Commands Until Expected Prompt    ${password}    ${OS_SYSTEM_PROMPT}
    Log    ${output}
    ${rcode}=    Run Keyword And Return Status    Check If Console Is VmInstance
    Log    ${rcode}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    ifconfig    ${OS_SYSTEM_PROMPT}
    Log    ${rcode}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    route    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Write Commands Until Expected Prompt    arp -an    ${OS_SYSTEM_PROMPT}
    Run Keyword If    ${rcode}    Check Ping    ${dst_ip}
    [Teardown]    Exit From Vm Console

Get DPID For Compute Node
    [Arguments]    ${ip}
    [Documentation]    Returns the dpnid for the given ${ip}
    ${output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl show -O Openflow13 br-int | head -1 | awk -F "dpid:" '{print $2}' 
    Log    ${output}
    ${dpnid}=    Convert To Integer   ${output}    16
    Log    ${dpnid}
    [Return]    ${dpnid}

Get Ethernet Adapter From Compute Node
    [Arguments]    ${ip}
    [Documentation]    Returns the adapter name on the system for the provided ${ip}
    ${adapter}=    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show  
    Log    ${adapter}
    ${adapter}=    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d " " -f 11 
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway used by ${ip}
    ${gateway}=    Run Command On Remote System    ${ip}    /usr/sbin/route -n
    Log    ${gateway}
    ${gateway}=    Run Command On Remote System    ${ip}    /usr/sbin/route -n | grep '^0.0.0.0' | cut -d " " -f 10
    [Return]    ${gateway}

Create TEP For Compute Node
    [Arguments]    ${ip}    ${dpid}    ${adapter}    ${subnet}    ${gateway}
    [Documentation]    Uses tep:add and tep:commit karaf console command to create tep for given values
    ...  and verify tunnel by checking the status is UP (tep:show-state)
    Issue Command On Karaf Console    tep:add ${dpid} ${adapter} 0 ${ip} ${subnet} ${gateway} TZA
    Issue Command On Karaf Console    tep:commit
