*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Elan SuiteSetup
Suite Teardown    Elan SuiteTeardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       ELAN1
@{SUBNETS}        ELANSUBNET1
@{SUBNET_CIDR}    1.1.1.0/24
@{ELAN1_PORT_LIST}    ELANPORT11    ELANPORT12
@{VM_INSTANCES_ELAN1}    ELANVM11    ELANVM12
${PING_PASS}      , 0% packet loss

*** Test Cases ***
Verify Datapath for Single ELAN with Multiple DPN
    [Documentation]    Verify Flow Table and Datapath
    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
    ${SRCMAC_CN2} =    Create List    ${VM_MACAddr_ELAN1[1]}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CN2}    ${VM_MACAddr_ELAN1}
    Log    Verify Datapath Test
    Start Tcpdumping    system=${OS_COMPUTE_1_IP}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    Stop Tcpdumping And Download
    Start Packet Capture    ${OS_COMPUTE_2_IP}    tcpdumpCN2
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}
    Stop Packet Capture and Log Trace     ${OS_COMPUTE_2_IP}    tcpdumpCN2

#Verify Datapath After OVS Restart
#    [Documentation]    Verify datapath after OVS restart
#    Log    Restarting OVS1 and OVS2
#    Restart OVSDB    ${OS_COMPUTE_1_IP}
#    Restart OVSDB    ${OS_COMPUTE_2_IP}
#    Log    Checking the OVS state and Flow table after restart
#    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
#    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
#    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
#    ${SRCMAC_CN2} =    Create List    ${VM_MACAddr_ELAN1[1]}
#    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${VM_MACAddr_ELAN1}
#    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CN2}    ${VM_MACAddr_ELAN1}
#    Log    Verify Data path test
#    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
#    Should Contain    ${output}    ${PING_PASS}
#    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
#    Should Contain    ${output}    ${PING_PASS}

Delete All ELAN1 VM And Verify Flow Table Updated
    [Documentation]    Verify Flow table after all VM instance deleted
    Log    Delete VM instances
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_ELAN1}
    \    Delete Vm Instance    ${VmInstance}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_1_IP}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_2_IP}    ${VM_MACAddr_ELAN1}

*** Keywords ***
Elan SuiteSetup
    [Documentation]    Elan suite setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    DevstackUtils.Devstack Suite Setup
    Enable ODL Karaf Log
    SingleElan SuiteSetup

Elan SuiteTeardown
    [Documentation]    Elan suite teardown
    SingleElan SuiteTeardown
    Close All Connections

SingleElan SuiteTeardown
    [Documentation]    Delete network,subnet and port
    Log    Delete Neutron Ports, Subnet and network
    : FOR    ${Port}    IN    @{ELAN1_PORT_LIST}
    \    Delete Port    ${Port}
    Delete SubNet    ${SUBNETS[0]}
    Delete Network    ${NETWORKS[0]}
    Delete SecurityGroup    sg-elanservice

SingleElan SuiteSetup
    [Documentation]    Create single ELAN with Multiple DPN
    Log    Create ELAN1 network, subnet , port and VM
    Create SecurityGroup    sg-elanservice
    Create Network    ${NETWORKS[0]}
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create Port    ${NETWORKS[0]}    ${ELAN1_PORT_LIST[0]}    sg=sg-elanservice
    Create Port    ${NETWORKS[0]}    ${ELAN1_PORT_LIST[1]}    sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[0]}    ${VM_INSTANCES_ELAN1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[1]}    ${VM_INSTANCES_ELAN1[1]}    ${OS_COMPUTE_2_IP}    sg=sg-elanservice
    Log    Verify ELAN1 VM active
    : FOR    ${VM}    IN    @{VM_INSTANCES_ELAN1}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Get IP address for ELAN1
    ${VM_IP_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_ELAN1}
    Log    ${VM_IP_ELAN1}
    Set Suite Variable    ${VM_IP_ELAN1}
    Log    Get MACAddr for ELAN1
    ${VM_MACAddr_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN1_PORT_LIST}
    Log    ${VM_MACAddr_ELAN1}
    Set Suite Variable    ${VM_MACAddr_ELAN1}

Verify Flows Are Present For ELAN Service
    [Arguments]    ${ip}    ${srcMacAddrs}    ${destMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN service
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log    ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    ${sMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log    ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{destMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    ${dMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    Log    ${sMac_output}

Verify Flows Are Removed For ELAN Service
    [Arguments]    ${ip}    ${srcMacAddrs}
    [Documentation]    Verify Flows Are Removed For ELAN Service
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log    ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Not Contain    ${sMac_output}    ${sMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log    ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Not Contain    ${dMac_output}    ${dMacAddr}

Create SecurityGroup
    [Arguments]    ${sg_name}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    ${sg_name}
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${sg_name}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Verify VMs received IP
    [Arguments]    ${VM_INSTANCES}
    [Documentation]    Verify VM received IP
    ${VM_IP}    ${DHCP_IP}    Verify VMs Received DHCP Lease    @{VM_INSTANCES}
    Log    ${VM_IP}
    Should Not Contain    ${VM_IP}    None
    [Return]    ${VM_IP}

Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set DEBUG org.opendaylight.netvirt.elan
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    log:set DEBUG org.opendaylight.genius.interfacemanager
    Log    ${output}

Start Packet Capture
    [Arguments]    ${system_ip}    ${filename}    ${network_adapter}=eth0
    [Documentation]    start packet capture and write to a file
    Run Command On Remote System    ${system_ip}    sudo /usr/sbin/tcpdump -vvv -ni ${network_adapter} -w /tmp/${filename}.pcap &

Stop Packet Capture and Log Trace
    [Arguments]    ${system_ip}    ${filename}
    [Documentation]    stop tcpdump process and log the contents of the trace file
    Run Command On Remote System    ${system_ip}    sudo ps -elf | grep tcpdump
    Run Command On Remote System    ${system_ip}    sudo kill `pgrep tcpdump`
    ${output}=    Run Command On Remote System    ${system_ip}    sudo /usr/sbin/tcpdump -nr /tmp/${filename}.pcap
    Log    ${output}
