*** Settings ***
Documentation     Test suite to validate elan service functionality in ODL environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    elan_sg
@{NETWORKS}       elan_net_1    elan_net_2    elan_net_3
@{SUBNETS}        elan_sub_1    elan_sub_2    elan_sub_3
@{SUBNET_CIDRS}    81.1.1.0/24    82.1.1.0/24    83.1.1.0/24
@{NET_1_PORTS}    elan_net_1_port_1    elan_net_1_port_2
@{NET_2_PORTS}    elan_net_2_port_1    elan_net_2_port_2
@{NET_3_PORTS}    elan_net_3_port_1    elan_net_3_port_2
@{NET_1_VMS}      elan_net_1_vm_1    elan_net_1_vm_2
@{NET_2_VMS}      elan_net_2_vm_1    elan_net_2_vm_2
@{NET_3_VMS}      elan_net_3_vm_1    elan_net_3_vm_2

*** Test Cases ***
Create Single Elan
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    ${SUBNET_CIDRS[0]}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${NET_1_PORTS[0]}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${NET_1_PORTS[1]}    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${NET_1_PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_1_PORTS[0]}    ${NET_1_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_1_PORTS[1]}    ${NET_1_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    Builtin.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    @{NET_1_MACS} =    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Get Ports MacAddr    ${NET_1_PORTS}
    Builtin.Set Suite Variable    @{NET_1_MACS}

Verify Datapath for Single ELAN with Multiple DPN
    [Documentation]    Verify Flow Table and Datapath
    ${smac_cn1} =    BuiltIn.Create List    @{NET_1_MACS}[0]
    ${smac_cn2} =    BuiltIn.Create List    @{NET_1_MACS}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${smac_cn1}    ${NET_1_MACS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${smac_cn2}    ${NET_1_MACS}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{NET_1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Datapath After OVS Restart
    [Documentation]    Verify datapath after OVS restart
    OVSDB.Restart OVSDB    ${OS_COMPUTE_1_IP}
    OVSDB.Restart OVSDB    ${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OVSDB.Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OVSDB.Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
    ${smac_cn1} =    BuiltIn.Create List    @{NET_1_MACS}[0]
    ${smac_cn2} =    BuiltIn.Create List    @{NET_1_MACS}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${smac_cn1}    ${NET_1_MACS}
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${smac_cn2}    ${NET_1_MACS}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{NET_1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Datapath After Recreate VM Instance
    [Documentation]    Verify datapath after recreating Vm instance
    OpenStackOperations.Delete Vm Instance    ${NET_1_VMS[0]}
    ${smac_cn1} =    BuiltIn.Create List    @{NET_1_MACS}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_1_IP}    ${smac_cn1}
    OpenStackOperations.Remove RSA Key From KnownHosts    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_1_PORTS[0]}    ${NET_1_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    Builtin.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${smac_cn1}    ${NET_1_MACS}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{NET_1_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Delete All elan_net_1 VM And Verify Flow Table Updated
    [Documentation]    Verify Flow table after all VM instance deleted
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_1_IP}    ${NET_1_MACS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Removed For ELAN Service    ${OS_COMPUTE_2_IP}    ${NET_1_MACS}

Verify Datapath for Multiple ELAN with Multiple DPN
    [Documentation]    Verify Flow Table and Data path for Multiple ELAN with Multiple DPN
    [Setup]    BuiltIn.Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ...    AND    MultipleElan Testsuite Setup
    ${smac_cn1} =    BuiltIn.Create List    @{VM_MACAddr_elan_net_2}[0]    @{VM_MACAddr_elan_net_3}[0]
    ${smac_cn2} =    BuiltIn.Create List    @{VM_MACAddr_elan_net_2}[1]    @{VM_MACAddr_elan_net_3}[1]
    ${MAC_LIST} =    BuiltIn.Create List    @{VM_MACAddr_elan_net_2}    @{VM_MACAddr_elan_net_3}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${smac_cn1}    ${MAC_LIST}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${smac_cn2}    ${MAC_LIST}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 ${NET_2_VM_IPS[1]}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{NET_3_VM_IPS}[1]    ping -c 3 ${NET_3_VM_IPS[0]}
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 ${NET_3_VM_IPS[0]}
    BuiltIn.Should Not Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[2]    @{NET_3_VM_IPS}[1]    ping -c 3 ${NET_2_VM_IPS[1]}
    BuiltIn.Should Not Contain    ${output}    ${PING_REGEXP}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${smac_cn1}    ${MAC_LIST}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    ${NET_2_VM_IPS[1]}    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    MultipleElan Testsuite Cleanup

*** Keywords ***
MultipleElan Testsuite Setup
    [Documentation]    Create additional ELAN for multipleElan with Multiple DPN test
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create Network    @{NETWORKS}[2]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    ${SUBNET_CIDRS[1]}
    OpenStackOperations.Create SubNet    @{NETWORKS}[2]    @{SUBNETS}[2]    ${SUBNET_CIDRS[2]}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    ${NET_2_PORTS[0]}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    ${NET_2_PORTS[1]}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[2]    ${NET_3_PORTS[0]}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[2]    ${NET_3_PORTS[1]}    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${NET_3_PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_2_PORTS[0]}    ${NET_2_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_2_PORTS[1]}    ${NET_2_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_3_PORTS[0]}    ${NET_3_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_3_PORTS[1]}    ${NET_3_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    @{NET_3_VM_IPS}    ${NET_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VMS}
    Builtin.Set Suite Variable    @{NET_2_VM_IPS}
    Builtin.Set Suite Variable    @{NET_3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_DHCP_IP}    None
    @{VM_MACAddr_elan_net_2}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Get Ports MacAddr    ${NET_2_PORTS}
    Builtin.Set Suite Variable    @{VM_MACAddr_elan_net_2}
    @{VM_MACAddr_elan_net_3}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Get Ports MacAddr    ${NET_3_PORTS}
    Builtin.Set Suite Variable    @{VM_MACAddr_elan_net_3}

MultipleElan Testsuite Cleanup
    [Documentation]    Delete elan_net_2 network,subnet and port
    OpenStackOperations.Get Test Teardown Debugs
    : FOR    ${vm}    IN    @{NET_2_VMS}    @{NET_3_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${Port}    IN    @{NET_2_PORTS}    @{NET_3_PORTS}
    \    OpenStackOperations.Delete Port    ${Port}
    OpenStackOperations.Delete SubNet    @{SUBNETS}[1]
    OpenStackOperations.Delete SubNet    @{SUBNETS}[2]
    OpenStackOperations.Delete Network    @{NETWORKS}[1]
    OpenStackOperations.Delete Network    @{NETWORKS}[2]

Verify Flows Are Present For ELAN Service
    [Arguments]    ${ip}    ${smacs}    ${dmacs}
    ${flow_output} =    Utils.Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    BuiltIn.Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${smac_output} =    String.Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Builtin.Log    ${smac_output}
    : FOR    ${smac}    IN    @{smacs}
    \    ${resp} =    BuiltIn.Should Contain    ${smac_output}    ${smac}
    BuiltIn.Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dmac_output} =    String.Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Builtin.Log    ${dmac_output}
    : FOR    ${dmac}    IN    @{dmacs}
    \    ${resp} =    BuiltIn.Should Contain    ${dmac_output}    ${dmac}
    BuiltIn.Should Contain    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    ${smac_output} =    String.Get Lines Containing String    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    Builtin.Log    ${smac_output}

Verify Flows Are Removed For ELAN Service
    [Arguments]    ${ip}    ${smacs}
    ${flow_output} =    Utils.Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    BuiltIn.Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${smac_output} =    String.Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Builtin.Log    ${smac_output}
    : FOR    ${smac}    IN    @{smacs}
    \    ${resp} =    BuiltIn.Should Not Contain    ${smac_output}    ${smac}
    BuiltIn.Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dmac_output} =    String.Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Builtin.Log    ${dmac_output}
    : FOR    ${dmac}    IN    @{smacs}
    \    ${resp} =    BuiltIn.Should Not Contain    ${dmac_output}    ${dmac}
