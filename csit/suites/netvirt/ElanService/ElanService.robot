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
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       ELAN1    ELAN2    ELAN3
@{SUBNETS}        ELANSUBNET1    ELANSUBNET2    ELANSUBNET3
@{SUBNET_CIDR}    1.1.1.0/24    2.1.1.0/24    3.1.1.0/24
@{ELAN1_PORT_LIST}    ELANPORT11    ELANPORT12
@{ELAN2_PORT_LIST}    ELANPORT21    ELANPORT22
@{ELAN3_PORT_LIST}    ELANPORT31    ELANPORT32
@{VM_INSTANCES_ELAN1}    ELANVM11    ELANVM12
@{VM_INSTANCES_ELAN2}    ELANVM21    ELANVM22
@{VM_INSTANCES_ELAN3}    ELANVM31    ELANVM32
${PING_PASS}      , 0% packet loss

*** Test Cases ***
Verify Datapath for Single ELAN with Multiple DPN
    [Documentation]    Verify Flow Table and Datapath
    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
    ${SRCMAC_CN2} =    Create List    ${VM_MACAddr_ELAN1[1]}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CN2}    ${VM_MACAddr_ELAN1}
    Log    Verify Datapath Test
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}

Verify Datapath After OVS Restart
    [Documentation]    Verify datapath after OVS restart
    Log    Restarting OVS1 and OVS2
    Restart OVSDB    ${OS_COMPUTE_1_IP}
    Restart OVSDB    ${OS_COMPUTE_2_IP}
    Log    Checking the OVS state and Flow table after restart
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
    ${SRCMAC_CN2} =    Create List    ${VM_MACAddr_ELAN1[1]}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CN2}    ${VM_MACAddr_ELAN1}
    Log    Verify Data path test
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}

Verify Datapath After Recreate VM Instance
    [Documentation]    Verify datapath after recreating Vm instance
    Log    Delete VM and verify flows updated
    Delete Vm Instance    ${VM_INSTANCES_ELAN1[0]}
    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}
    Remove RSA Key From KnowHosts    ${VM_IP_ELAN1[0]}
    Log    ReCreate VM and verify flow updated
    Create Vm Instance With Port On Compute Node    ${ELAN1_PORT_LIST[0]}    ${VM_INSTANCES_ELAN1[0]}    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify VM Is ACTIVE    ${VM_INSTANCES_ELAN1[0]}
    ${VM_IP_ELAN1}    Wait Until Keyword Succeeds    60s    10s    Verify VMs received IP    ${VM_INSTANCES_ELAN1}
    Log    ${VM_IP_ELAN1}
    Set Suite Variable    ${VM_IP_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${VM_MACAddr_ELAN1}
    Log    Verify Data path Test
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[0]}    ping -c 3 ${VM_IP_ELAN1[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_ELAN1[1]}    ping -c 3 ${VM_IP_ELAN1[0]}
    Should Contain    ${output}    ${PING_PASS}

Delete All ELAN1 VM And Verify Flow Table Updated
    [Documentation]    Verify Flow table after all VM instance deleted
    Log    Delete VM instances
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_ELAN1}
    \    Delete Vm Instance    ${VmInstance}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_1_IP}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_2_IP}    ${VM_MACAddr_ELAN1}

Verify Datapath for Multiple ELAN with Multiple DPN
    [Documentation]    Verify Flow Table and Data path for Multiple ELAN with Multiple DPN
    [Setup]    MultipleElan Testsuit Setup
    Log    Verify Flow Table
    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN2[0]}    ${VM_MACAddr_ELAN3[0]}
    ${SRCMAC_CN2} =    Create List    ${VM_MACAddr_ELAN2[1]}    ${VM_MACAddr_ELAN3[1]}
    ${MAC_LIST} =    Create List    @{VM_MACAddr_ELAN2}    @{VM_MACAddr_ELAN3}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${MAC_LIST}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CN2}    ${MAC_LIST}
    Log    Verify Data path Test
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_ELAN2[0]}    ping -c 3 ${VM_IP_ELAN2[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_ELAN3[1]}    ping -c 3 ${VM_IP_ELAN3[0]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_ELAN2[0]}    ping -c 3 ${VM_IP_ELAN3[0]}
    Should Not Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_ELAN3[1]}    ping -c 3 ${VM_IP_ELAN2[1]}
    Should Not Contain    ${output}    ${PING_PASS}
    Log    Reboot VM instance and verify flow
    Reboot Nova VM    ${VM_INSTANCES_ELAN2[0]}
    Log    Get IP address for ELAN2
    Wait Until Keyword Succeeds    30s    10s    Verify VM Is ACTIVE    ${VM_INSTANCES_ELAN2[0]}
    ${VM_IP_ELAN2}    ${DHCP_IP2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_ELAN2}
    Log    ${VM_IP_ELAN2}
    Should Not Contain    ${VM_IP_ELAN2}    None
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${MAC_LIST}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_ELAN2[1]}    ping -c 3 ${VM_IP_ELAN2[0]}
    Should Contain    ${output}    ${PING_PASS}
    [Teardown]    MultipleElan Testsuit Cleanup

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

MultipleElan Testsuit Setup
    [Documentation]    Create additional ELAN for multipleElan with Multiple DPN test
    Create Network    ${NETWORKS[1]}
    Create Network    ${NETWORKS[2]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    Create Port    ${NETWORKS[1]}    ${ELAN2_PORT_LIST[0]}    sg=sg-elanservice
    Create Port    ${NETWORKS[1]}    ${ELAN2_PORT_LIST[1]}    sg=sg-elanservice
    Create Port    ${NETWORKS[2]}    ${ELAN3_PORT_LIST[0]}    sg=sg-elanservice
    Create Port    ${NETWORKS[2]}    ${ELAN3_PORT_LIST[1]}    sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN2_PORT_LIST[0]}    ${VM_INSTANCES_ELAN2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN2_PORT_LIST[1]}    ${VM_INSTANCES_ELAN2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN3_PORT_LIST[0]}    ${VM_INSTANCES_ELAN3[0]}    ${OS_COMPUTE_1_IP}    sg=sg-elanservice
    Create Vm Instance With Port On Compute Node    ${ELAN3_PORT_LIST[1]}    ${VM_INSTANCES_ELAN3[1]}    ${OS_COMPUTE_2_IP}    sg=sg-elanservice
    Log    Verify ELAN2 VM active
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_ELAN2}    @{VM_INSTANCES_ELAN3}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Get IP address for ELAN2 and ELAN3
    ${VM_IP_ELAN2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_ELAN2}
    Log    ${VM_IP_ELAN2}
    Set Suite Variable    ${VM_IP_ELAN2}
    ${VM_IP_ELAN3}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_ELAN3}
    Log    ${VM_IP_ELAN3}
    Set Suite Variable    ${VM_IP_ELAN3}
    Log    Get MACAddr for ELAN2 and ELAN3 PORT_LIST
    ${VM_MACAddr_ELAN2}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN2_PORT_LIST}
    Log    ${VM_MACAddr_ELAN2}
    Set Suite Variable    ${VM_MACAddr_ELAN2}
    ${VM_MACAddr_ELAN3}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN3_PORT_LIST}
    Log    ${VM_MACAddr_ELAN3}
    Set Suite Variable    ${VM_MACAddr_ELAN3}

MultipleElan Testsuit Cleanup
    [Documentation]    Delete ELAN2 network,subnet and port
    Get Test Teardown Debugs
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES_ELAN2}    @{VM_INSTANCES_ELAN3}
    \    Delete Vm Instance    ${VmInstance}
    : FOR    ${Port}    IN    @{ELAN2_PORT_LIST}    @{ELAN3_PORT_LIST}
    \    Delete Port    ${Port}
    Delete SubNet    ${SUBNETS[1]}
    Delete SubNet    ${SUBNETS[2]}
    Delete Network    ${NETWORKS[1]}
    Delete Network    ${NETWORKS[2]}

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
