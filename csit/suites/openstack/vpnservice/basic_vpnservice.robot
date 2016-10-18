*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Test Setup        Log Testcase Start To Controller Karaf
Test Teardown     Get OvsDebugInfo
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{NET10_VM_IPS}    10.1.1.3    10.1.1.4
@{NET20_VM_IPS}    20.1.1.3    20.1.1.4
@{ROUTERS}        ROUTER_1    ROUTER_2
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
Create Neutron Networks
    [Documentation]    Create two networks
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

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[0]    ping -c 3 @{NET10_VM_IPS}[1]
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    @{NET20_VM_IPS}[0]    ping -c 3 @{NET20_VM_IPS}[1]
    Should Contain    ${output}    64 bytes

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath test across the networks using router for L3.
    # Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{NET10_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET20_VM_IPS}[0]    @{NET20_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{NET10_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}
    # Check datapath from network2 to network1 
    ${dst_ip_list} =    Create List    @{NET20_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET10_VM_IPS}[0]    @{NET10_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{NET20_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Check L3 Datapath After Delete And Recreate Interface On Router
    [Documentation]    Verify recreation of router interface and check datapath
    # Remove Interface to the subnets.
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    Sleep    5
    # Add interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    # Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{NET10_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET20_VM_IPS}[0]    @{NET20_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{NET10_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}
    # Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{NET20_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET10_VM_IPS}[0]    @{NET10_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{NET20_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[0]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Get L3VPN    ${CREATE_ID[0]}

Associate L3VPN to Routers
    [Documentation]    Associating router to L3VPN
    [Tags]    Associate
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate

Check Datapath After Router Association To L3VPN
    [Documentation]    Check datapath after router association to L3VPN
    # Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{NET10_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET20_VM_IPS}[0]    @{NET20_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{NET10_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}
    # Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{NET20_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET10_VM_IPS}[0]    @{NET10_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{NET20_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Check Datapath After Delete And Recreate L3VPN On Router
    [Documentation]    Verify recreation of L3VPN and check datapath
    # Dissociate and delete L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
    VPN Delete L3VPN    ${CREATE_ID[0]}
    Sleep    5
    # Create and Associate L3VPN
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[0]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Get L3VPN    ${CREATE_ID[0]}
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    # Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{NET10_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET20_VM_IPS}[0]    @{NET20_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{NET10_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}
    # Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{NET20_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET10_VM_IPS}[0]    @{NET10_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{NET20_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}


Check Datapath After OVS Restart
    [Documentation]   Verify end to end data path within same network and from one network to the other
    [Tags]    RestartOVS
    Log    "Restarting OVS1 and OVS2"
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo service openvswitch-switch stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo service openvswitch-switch start
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo service openvswitch-switch start
    Log    ${output}
    Log    "Checking the OVS state after restart"
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
    # Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{NET10_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET20_VM_IPS}[0]    @{NET20_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{NET10_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}
    # Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{NET20_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET10_VM_IPS}[0]    @{NET10_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{NET20_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Dissociate L3VPN to Routers
    [Documentation]    Dissociating router to L3VPN
    [Tags]    Dissociate
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    ${CREATE_ID[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[0]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[1]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[2]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Get L3VPN    ${CREATE_ID[0]}
    VPN Get L3VPN    ${CREATE_ID[1]}
    VPN Get L3VPN    ${CREATE_ID[2]}

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs
    VPN Delete L3VPN    ${CREATE_ID[0]}
    VPN Delete L3VPN    ${CREATE_ID[1]}
    VPN Delete L3VPN    ${CREATE_ID[2]}

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}

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

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions

Wait For Routes To Propogate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[0]
    ${net_id} =    Get Net Id    @{NETWORKS}[1]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[1]
