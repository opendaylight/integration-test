*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    SingleElan SuitSetup   
Suite Teardown    BuiltIn.Run Keywords    SingleElan SuitTeardown
...               AND    Close All Connections
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
@{NETWORKS}       ELAN1    ELAN2
@{SUBNETS}        ELANSUBNET1    ELANSUBNET2
@{SUBNET_CIDR}    1.1.1.0/24    2.1.1.0/24
@{ELAN1_PORT_LIST}      ELANPORT11    ELANPORT12
@{ELAN2_PORT_LIST}      ELANPORT21    ELANPORT22
@{VM_INSTANCES_ELAN1}    ELANVM11    ELANVM12
@{VM_INSTANCES_ELAN2}    ELANVM21    ELANVM22
${ELAN_SMACTABLE}    50
${ELAN_DMACTABLE}    51
${ELAN_UNKNOWNMACTABLE}    52
${PING_PASS}          , 0% packet loss
${PING_FAIL}          , 100% packet loss

*** Test Cases ***
Verify Datapath for Single ELAN with Multiple DPN
    [Documentation]   Verify Flow Table and Datapath
    #Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}    ${ELAN_DMACTABLE}    
    #Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}    ${ELAN_DMACTABLE}
    Log    Verify Datapath Test
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}

   
Verify Datapath After Recreate VM Instance 
     [Documentation]   Verify datapath after recreating Vm instance
     Log    Delete VM and verify flows updated
     Delete Vm Instance    ${VM_INSTANCES_ELAN1[0]}  
     ${VM_MACAddr} =      Create List     ${VM_MACAddr_ELAN1[0]}  
     Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr}
     Log    Create VM again and verify flow updated and Datapath 
     Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[0]}    ${VM_INSTANCES_ELAN1[0]}    ${OS_COMPUTE_1_IP}
     #Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}     ${ELAN_DMACTABLE}
     #Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}     ${ELAN_DMACTABLE}
     Log    Verify Datapath Test
     ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
     Should Contain    ${output}    ${PING_PASS}
     ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
     Should Contain    ${output}    ${PING_PASS}
     Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}
     Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}

Verify Datapath After OVS Restart
    [Documentation]   Verify datapath after OVS restart
    Log    Restarting OVS1 and OVS2
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}
    ${output}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}
    Log    Checking the OVS state and Flow table after restart
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
    #Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}    ${ELAN_DMACTABLE}
    #Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}    ${ELAN_DMACTABLE}
    Log    Verify Datapath test
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}

Delete All VM And Verify Flow Table Updated
    [Documentation]   Verify Flow table after all VM instance deleted
    Log To console    Delete All Vm instances 
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_ELAN1}
    \    Delete Vm Instance    ${VmInstance}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_1_IP}      ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN    ${OS_COMPUTE_2_IP}      ${VM_MACAddr_ELAN1}
 
*** Keywords ***
SingleElan SuitTeardown
    [Documentation]   Delete network,subnet and port
    Log To Console     Delete Neutron Ports, Subnet and network
    : FOR    ${Port}    IN    @{ELAN1_PORT_LIST}
    \    Delete Port    ${Port}
    Delete SubNet    ${SUBNETS[0]}
    Delete Network    ${NETWORKS[0]}
    Delete SecurityGroup     sg-elanservice

SingleElan SuitSetup
    [Documentation]    Create single ELAN with Multiple DPN and do ping test
    Log To Console     Create network, subnet , port and VM
    Create SecurityGroup     sg-elanservice
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
    ${VM_MACAddr_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN1_PORT_LIST}
    Log    ${VM_MACAddr_ELAN1}
    Set Suite Variable    ${VM_MACAddr_ELAN1}

Get Ports MacAddr
    [Arguments]    ${portName_list}    
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

Verify Flows Are Present For ELAN Table
    [Arguments]    ${ip}     ${srcMacAddrs}     ${flowTable}
    [Documentation]    Verify Flows Are Present For ELAN
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${flowTable}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${flowTable}
    Log     ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    ${sMacAddr}

Verify Flows Are Present For ELAN
    [Arguments]    ${ip}     ${srcMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log     ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    ${sMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log      ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    ${dMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    Log     ${sMac_output}

Verify Flows Are Removed For ELAN
    [Arguments]    ${ip}     ${srcMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log     ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Not Contain    ${sMac_output}    ${sMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log      ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Not Contain    ${dMac_output}    ${dMacAddr}

Delete SecurityGroup
    [Arguments]    ${sg_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-delete ${sg_name}    40s
    Log     ${output}
    Should Contain    ${output}     Deleted security_group: ${sg_name} 
    Close Connection

Create SecurityGroup 
    [Arguments]    ${sg_name}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${sg_name} 
    Neutron Security Group Rule Create    sg-elanservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-elanservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

