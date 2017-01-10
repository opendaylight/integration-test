*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
#...               AND    Enable ODL Karaf Log
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keyword If Test Failed    Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       ELAN1    ELAN2    ELAN3
@{SUBNETS}        ELANSUBNET1    ELANSUBNET2     ELANSUBNET3
@{SUBNET_CIDR}    1.1.1.0/24    2.1.1.0/24     3.1.1.0/24
@{ELAN1_PORT_LIST}      ELANPORT11    ELANPORT21
@{ELAN2_PORT_LIST}      ELANPORT12    ELANPORT22
@{ELAN3_PORT_LIST}      ELANPORT31    ELANPORT32
@{VM_INSTANCES_ELAN1}    ELANVM11    ELANVM21
@{VM_INSTANCES_ELAN2}    ELANVM12    ELANVM22
@{VM_INSTANCES_ELAN3}    ELANVM13    ELANVM23
${ELAN_SMACTABLE}    50
${ELAN_DMACTABLE}    51
${PING_PASS}          , 0% packet loss
${PING_FAIL}          , 100% packet loss

*** Test Cases ***
Add Ssh SecurityGroup Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    sg-elanservice
    Neutron Security Group Rule Create    sg-elanservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Verify Datapath for Single ELAN with Multiple DPN
    [Documentation]    Create single ELAN with Multiple DPN and do ping test
    Log To Console     Create network, subnet , port and VM
    Create Network    ${NETWORKS[0]}
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create Port    ${NETWORKS[0]}    ${ELAN1_PORT_LIST[0]}     sg=sg-elanservice
    Create Port    ${NETWORKS[0]}    ${ELAN1_PORT_LIST[1]}     sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[0]}    ${VM_INSTANCES_ELAN1[0]}    ${OS_COMPUTE_1_IP}     sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[1]}    ${VM_INSTANCES_ELAN1[1]}    ${OS_COMPUTE_2_IP}     sg=sg-elanservice
    Log To Console    Verify VM active
    : FOR    ${VM}    IN    @{VM_INSTANCES_ELAN1}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log To Console     Get IP address
    ${VM_IP_ELAN1}    ${DHCP_IP1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_ELAN1}
    Log    ${VM_IP_ELAN1}
    Set Suite Variable    ${VM_IP_ELAN1}
    Log To Console     Get MACAdd
    ${VM_MACAddr_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    @{ELAN1_PORT_LIST}
    Log    ${VM_MACAddr_ELAN1}
    Set Suite Variable    ${VM_MACAddr_ELAN1}
    Log To Console     Verify Flow Table
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      @{VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      @{VM_MACAddr_ELAn1}

    Log To Console     Verify Datapath Test
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}
    
    Log To Console     Delete VM and verify flows updated
    Delete Vm Instance    ${VM_INSTANCES_ELAN1[0]}  
    ${VM_MACAddr} =      Create List     ${VM_MACAddr_ELAN1[0]}  
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_1_IP}      @{VM_MACAddr}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_2_IP}      @{VM_MACAddr}

    Log To Console      Create VM again and verify flow updated and traffic 
    Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[0]}    ${VM_INSTANCES_ELAN1[0]}    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      @{VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      @{VM_MACAddr_ELAN1}
	
    Log To Console    Verify Datapath Test After VM recreation
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}

    Log To Console    Restarting OVS1 and OVS2
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}
    Log To Console    Checking the OVS state after restart
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      @{VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      @{VM_MACAddr_ELAN1}

    Log To Console    Verify Datapath Test After OVS restart
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}


    Log To console    Delete All Vm instances 
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_ELAN1}
    \    Delete Vm Instance    ${VmInstance}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_1_IP}      @{VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_2_IP}      @{VM_MACAddr_ELAN1}
    
    Log To Console     Delete Neutron Ports, Subnet and network 
    : FOR    ${Port}    IN    @{ELAN1_PORT_LIST}
    \    Delete Port    ${Port}
    Delete SubNet    ${SUBNETS[0]}
    Delete Network    ${NETWORKS[0]}


#Verify Datapath for Multiple ELAN with Multiple DPN
#    [Documentation]    Create single ELAN with Multiple DPN and do ping test
#    Create Network    ${NETWORKS[1]}
#    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
#    Create Port    ${NETWORKS[1]}    ${ELAN2_PORT_LIST[0]}     sg=sg-elanservice
#    Create Port    ${NETWORKS[1]}    ${ELAN2_PORT_LIST[1]}     sg=sg-elanservice
#    Create Vm Instance With Port On Compute Node    ${ELAN2_PORT_LIST[0]}    ${VM_INSTANCES_ELAN2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-elanservice
#    Create Vm Instance With Port On Compute Node    ${ELAN2_PORT_LIST[1]}    ${VM_INSTANCES_ELAN2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-elanservice
#    #Verify VM active
#    : FOR    ${VM}    IN    @{VM_INSTANCES_ELAN2}
#    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
#    
#    # Get IP address
#    ${VM_IP_ELAN2}    ${DHCP_IP1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_ELAN2}
#    Log    ${VM_IP_ELAN2}
#    Set Suite Variable    ${VM_IP_ELAN2}
#
#    # Get MACAdd
#    ${VM_MACAddr_ELAN2}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    @{ELAN2_PORT_LIST}
#    Log    ${VM_MACAddr_ELAN2}
#    Set Suite Variable    ${VM_MACAddr_ELAN2}
#
#    ${VM_MACAddr_ELAN3}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    @{ELAN3_PORT_LIST}
#    Log    ${VM_MACAddr_ELAN2}
#    Set Suite Variable    ${VM_MACAddr_ELAN3}
#
#    # Verify Datapath Test
#    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN2[0]}    ping -c 3 ${VM_IP_ELAN2[1]}
#    Should Contain    ${output}    ${PING_PASS}
#    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN2[0]}    ping -c 3 ${VM_IP_ELAN1[0]}
#    Should Contain    ${output}    ${PING_FAIL}
#
#    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      @{VM_MACAddr_ELAN2}
#    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      @{VM_MACAddr_ELAN1}

Delete SecurityGroup
    [Documentation]    Delete Security Group
    Delete Security Group With Name     sg-elanservice 

*** Keywords ***
Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Get Ports MacAddr
    [Arguments]    @{portName_list}    
    [Documentation]    Retrieve the port MacAddr for the given list of port name and return the MAC address list. 
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${MacAddr-list}    Create List    
    : FOR    ${portName}    IN    @{portName_list}
    \    ${output} =    Write Commands Until Prompt    neutron port-list | grep "${portName}" | awk '{print $6}'    30s
    \    Log      ${output}
    \    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    \    ${macAddr}=    Get from List    ${splitted_output}    0
    \    Log    ${macAddr}
    \    Append To List    ${MacAddr-list}    ${macAddr}
    [Return]    ${MacAddr-list}

Verify Flows Are Present For ELAN
    [Arguments]    ${ip}     @{srcMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    ${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log     ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    ${sMacAddr}
        Should Contain    ${flow_output}    ${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log      ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    ${dMacAddr}

Verify Flows Are Removed For ELAN
    [Arguments]    ${ip}     @{srcMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    ${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log     ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Not Contain    ${sMac_output}    ${sMacAddr}
        Should Contain    ${flow_output}    ${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log      ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Not Contain    ${dMac_output}    ${dMacAddr}

Delete Security Group With Name
    [Arguments]    ${sg_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-delete ${sg_name}    40s
    Log     ${output}
    Should Contain    ${output}     Deleted security_group: ${sg_name} 
    Close Connection
