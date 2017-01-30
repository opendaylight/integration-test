*** Settings ***
Documentation     Test Suite for SF218_EVPN_In_Inter_DC_Deployments with CSS.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           String
Library           RequestsLibrary
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/SetupUtils.robot
Resource          ../../libraries/KarafKeywords.robot
#Variables         ../variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.py
#Resource          ../variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.robot
Variables          ../../variables/Inter-DC_Deployments_TestPlan_Var/SF218_EVPN_In_Inter_DC_Deployments_vars.py
Resource           ../../variables/Inter-DC_Deployments_TestPlan_Var/SF218_EVPN_In_Inter_DC_Deployments_vars.robot
Variables          ../../variables/Variables.py
#Variables          /home/mininet/final_sf218/test/csit/variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.py
#Resource           /home/mininet/final_sf218/test/csit/variables/SF218_EVPN_In_Inter_DC_Deployments/SF218_EVPN_In_Inter_DC_Deployments_vars.robot

*** Keywords ***

Start Suite
    [Documentation]    Test Suite for SF218_EVPN_In_Inter_DC_Deployments with CSS.
    DevstackUtils.Devstack Suite Setup
    #SetupUtils.Setup_Utils_For_Setup_And_Teardown
    #Enable ODL Karaf Log
    #Presuite Cleanup
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Delete Setup
    #Disable ODL Karaf Log
    Close All Connections

Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Disable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set INFO org.opendaylight.netvirt
    Log    ${output}

Presuite Cleanup
    [Documentation]    Clean the already existing tunnels and tep interfaces
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_TRANSPORTZONE}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_INTERFACES}
    Log    ${resp.content}

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
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

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
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Arguments]    ${NUM_OF_PORTS}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of ports under previously created subnets
    ${REQUIRED_PORT_LIST}=    Get Slice From List    ${PORT_LIST}    0    ${NUM_OF_PORTS}
    Log To Console    "REQUIRED PORT LIST IS"
    Log To Console    ${REQUIRED_PORT_LIST}
    :FOR    ${item}    IN RANGE    0    ${NUM_OF_PORTS}
    \    ${port_name}    Get From List    ${PORT_LIST}     ${item}
    \    ${match}    Get Regexp Matches    ${port_name}    [A-Z]*(.).*    1
    \    ${net}    Get From List    ${match}    0
    \    ${net}    Convert To Integer     ${net}
    \    ${network}    Get From List       ${NETWORKS}    ${net-1}
    \    Create Port     ${network}    ${port_name}    sg=sg-vpnservice
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${VM_IP_NET1}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
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

Create ITM Tunnel
    [Documentation]    Checks that vxlan tunnels are created successfully. This testcase expects that the two DPNs are in the same network hence populates the gateway accordingly.
    ${node_1_dpid} =    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid} =    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_1_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${subnet} =    Get Subnet    ${OS_COMPUTE_1_IP}
    ${gateway} =    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ITM Create Tunnel    tunneltype=vxlan    vlanid=0    prefix=${subnet}    gateway=${gateway}    ipaddress1=${OS_COMPUTE_1_IP}    dpnid1=${node_1_dpid}
    ...    portname1=${node_1_adapter}    ipaddress2=${OS_COMPUTE_2_IP}    dpnid2=${node_2_dpid}    portname2=${node_2_adapter}
    Get DumpFlows And Ovsconfig    ${OS_COMPUTE_1_IP}
    Get DumpFlows And Ovsconfig    ${OS_COMPUTE_2_IP}
    ${output} =    ITM Get Tunnels
    Log    ${output}

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
#    ${resp}=    Should Contain    ${flow_output}    table=50
#    Log    ${resp}
#    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
#    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
#    ${table51_output} =    Get Lines Containing String    ${flow_output}    table=51
#    Log    ${table51_output}
#    @{table51_output}=    Split To Lines    ${table51_output}    0    -1
#    : FOR    ${line}    IN    @{table51_output}
#    \    Log    ${line}
#    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}
    
Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs on each DPN
    Log    Create two networks
    ${Req_no_of_net} =    Evaluate    2
    Create Neutron Networks    ${Req_no_of_net}
    Log    Create two subnets for previously created networks
    ${Req_no_of_subNet} =     Evaluate    2
    Create Neutron Subnets    ${Req_no_of_subNet}
    Log    Create eight ports under previously created subnets
    ${Req_no_of_ports} =    Evaluate    8
    Add Ssh Allow Rule
    Create Neutron Ports    ${Req_no_of_ports}
    Log    Create VM Instances
    ${Req_no_of_vms_per_dpn} =    Evaluate    4
    Create Nova VMs     ${Req_no_of_vms_per_dpn}
    ${VM_IP_NET1}    ${VM_IP_NET2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs received IP
    Set Suite Variable    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET1}
    Log    Create ITM Tunnel
    Create ITM Tunnel
    Verify Tunnel Status as UP
    Verify Flows Are Present    ${OS_COMPUTE_1_IP}

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
