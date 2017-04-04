*** Settings ***
Documentation     Test Suite for EVPN_In_Intra_DC_Deployments with CSS.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           String
Library           RequestsLibrary
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../libraries/BgpOperations.robot 
Variables          ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.py
Resource           ../../variables/Intra-DC_Deployments_TestPlan_Var/EVPN_In_Intra_DC_Deployments_vars.robot
Variables          ../../variables/Variables.py

*** Variables ***

${DCGW_SYSTEM_IP}     ${TOOLS_SYSTEM_1_IP}


*** Keywords ***

Start Suite
    [Documentation]    Test Suite for EVPN_In_Intra_DC_Deployments with CSS.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Delete Setup
    Close All Connections

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of networks
    ${REQUIRED_NETWORKS}=    Get Slice From List    ${NETWORKS}    0    ${NUM_OF_NETWORK}
    Log To Console    "REQUIRED NETWORKS IS"
    Log To Console    ${REQUIRED_NETWORKS}
    : FOR    ${NET}    IN    @{REQUIRED_NETWORKS}
    \    Create Network    ${NET}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
    \    Should Contain    ${NET_LIST}    ${NETWORKS[${index}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
    \    Create SubNet    ${NETWORKS[${index}]}    ${SUBNETS[${index}]}    ${SUBNET_CIDR[${index}]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Log To Console    "REQUIRED SUBNET IS"
    Log To Console    ${SUB_LIST}
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_NETWORK}
    \    Should Contain    ${SUB_LIST}    ${SUBNETS[${index}]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    Log     ${PORT_LIST}
    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${PORT_LIST}    0    ${NUM_OF_PORTS}
    Log     ${REQUIRED_PORT_LIST}
    Log To Console    "REQUIRED PORT LIST IS"
    Log To Console    ${REQUIRED_PORT_LIST}
    :FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port_name}    Get From List    ${PORT_LIST}     ${item}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer     ${net}
    \    ${network}    Get From List       ${NETWORKS}    ${net-1}
    \    Create Port     ${network}    ${port_name}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET1}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES_NET2}
    ${VM_IP_NET1}    ${DHCP_IP1}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Collect VM IP Addresses    false    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET1}
    Log    ${VM_IP_NET2}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create Vm instances on compute nodes
    :FOR   ${index}   IN RANGE   0   ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES_DPN1[${index}]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    ${start} =     Evaluate    ${index}+1
    ${NUM_OF_VMS_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VMS_PER_DPN}
    :FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VMS_PER_DPN}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_INSTANCES[${index}]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    :FOR    ${VM}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}


Verify Tunnel Status as UP
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${resp}=    Should Contain    ${flow_output}    table=51
    Log    ${resp}
    
Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    CREATE TWO NETWORKS: NET1 AND NET2
    ${Req_no_of_net} =    Evaluate    2
    Create Neutron Networks    ${Req_no_of_net}
    Log    CREATE TWO SUBNETS: SUBNET1 AND SUBNET2
    ${Req_no_of_subNet} =     Evaluate    2
    Create Neutron Subnets    ${Req_no_of_subNet}
    Log    CREATE 8 PORTS: PORT11 PORT12 PORT21 PORT22 PORT13 PORT14 PORT23 PORT24
    ${Req_no_of_ports} =    Evaluate    8
    Add Ssh Allow Rule
    Create Neutron Ports    ${Req_no_of_ports}
    Log    CREATE VM INSTANCES: VM11 VM12 VM21 VM22 VM13 VM14 VM23 VM24
    ${Req_no_of_vms_per_dpn} =    Evaluate    4 
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Global Variable    ${VM_IP_NET2}
    Set Global Variable    ${VM_IP_NET1}
    Wait Until Keyword Succeeds    120s    5s    Verify Tunnel Status as UP
    Wait Until Keyword Succeeds    120s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    120s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnet and networks
    Log    Delete the VM instances
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    Delete neutron ports
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    Log    Delete subnets
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    Log    Delete networks
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
    Delete SecurityGroup    ${SECURITY_GROUP}
