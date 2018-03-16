*** Settings ***
Documentation     Test suite for verifying Bundle based reconciliation with switch(OVS)
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${DEBUG_MSG}      "bundle-based-reconciliation-enabled configuration property was changed to 'true'"
${DEBUG_MODULE}    'org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl'
@{PORTS}          bundle_resync_port_1    bundle_resync_port_2    bundle_resync_port_3    bundle_resync_port_4
@{VMS}            bundle_resync_dpn1_vm_1    bundle_resync_dpn1_vm_2    bundle_resync_dpn2_vm_1    bundle_resync_dpn2_vm_2
${NETWORK}        bundle_resync_net_1
${SUBNET}         bundle_resync_subnet_1
${SUBNET_CIDR}    70.1.1.0/24
${SECURITY_GROUP}    bundle_resync_elan_sg
${COUNT}          0
@{SMAC_LIST_DPN1}    @{EMPTY}
@{SMAC_LIST_DPN2}    @{EMPTY}

*** Testcases ***
Check Tep State
    [Documentation]    Check the vxlan tunnels to be Up
    VpnOperations.Verify Tunnel Status as UP

Create VXLAN Network net_1
    [Documentation]    Create Network with neutron request
    OpenStackOperations.Create Network    ${NETWORK}

Create Subnet For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    ${NETWORK}    ${SUBNET}    ${SUBNET_CIDR}

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Port
    [Documentation]    Create ports under the subnet
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Create Port    ${NETWORK}    ${port}    ${SECURITY_GROUP}

Create VM Instances in DPN1
    [Documentation]    Create VMs in DPN1 belonging to subnet1
    ${SMAC_LIST_DPN1}    BuiltIn.Create List
    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN1}
    : FOR    ${index}    IN RANGE    0    2
    \    ${InstanceId}    ${VM_IP} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VMS[${index}]}    ${OS_CMP1_HOSTNAME}
    \    ...    sg=${SECURITY_GROUP}
    \    ${portmac} =    OpenStackOperations.Get Port Mac    ${PORTS[${index}]}
    \    Collections.Append To List    ${SMAC_LIST_DPN1}    ${portmac}

Create VM Instances in DPN2
    [Documentation]    Create VMs in DPN2 belonging to subnet1
    ${SMAC_LIST_DPN2}    BuiltIn.Create List
    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN2}
    : FOR    ${index}    IN RANGE    2    4
    \    ${InstanceId}    ${VM_IP} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VMS[${index}]}    ${OS_CMP2_HOSTNAME}
    \    ...    sg=${SECURITY_GROUP}
    \    ${portmac} =    OpenStackOperations.Get Port Mac    ${PORTS[${index}]}
    \    Collections.Append To List    ${SMAC_LIST_DPN2}    ${portmac}

Check VM IP
    [Documentation]    Check if the VM has got ips.
    @{VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VMS}
    : FOR    ${vmip}    IN    @{VM_IPS}
    \    BuiltIn.Should Not Contain    ${vmip}    None

Verify the Bundle based reconciliation with switch(OVS1) restart scenario
    [Documentation]    Reconciliation check after OVS restart
    @{DMAC_LIST} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    ${DPN1_ID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_CMP2_IP}
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_CMP2_IP}
    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN1_ID}"
    ${COUNT} =    Evaluate    ${COUNT}+1
    BuiltIn.Set Suite Variable    ${COUNT}
    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    ${COUNT}
    Verify Elan Traffic

Verify the Bundle based reconciliation with switch(OVS) restart of both instances
    [Documentation]    Reconciliation check after restart of both OVS instance
    @{DMAC_LIST} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    ${DPN1_ID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    ${DPN2_ID} =    OVSDB.Get DPID    ${OS_CMP2_IP}
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    OVSDB.Restart OVSDB    ${OS_CMP2_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_CMP2_IP}
    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN1_ID}"
    ${COUNT} =    Evaluate    ${COUNT}+1
    BuiltIn.Set Suite Variable    ${COUNT}
    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    ${COUNT}
    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN2_ID}"
    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    1    False
    Verify Elan Traffic

Verify the Bundle based reconciliation with consecutive quick restarts of OVS1 instance
    [Documentation]    Reconciliation check after quick restarts of OVS instance
    @{DMAC_LIST} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    ${DPN1_ID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CMP1_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_CMP2_IP}
    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN1_ID}"
    ${COUNT} =    Evaluate    ${COUNT}+3
    BuiltIn.Set Suite Variable    ${COUNT}
    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    ${COUNT}
    Verify Elan Traffic

Verify the Bundle based reconciliation with multiple restarts (OVS1)followed by resync check
    [Documentation]    Reconciliation check after multiple restarts allowing the sync to settle.
    @{DMAC_LIST}    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    ${DPN1_ID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    ${COUNT} =    Evaluate    ${COUNT}+1
    : FOR    ${index}    IN RANGE    0    3
    \    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    \    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}
    \    ...    ${OS_CMP1_IP}
    \    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}
    \    ...    ${OS_CMP2_IP}
    \    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN1_ID}"
    \    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    ${count}
    \    ${COUNT} =    Evaluate    ${COUNT} + 1
    Verify Elan Traffic

Cleanup
    [Documentation]    Delete Port and VM Instances,Ports,Networks,Subnetwork and Security group
    @{sg} =    BuiltIn.Create List    ${SECURITY_GROUP}
    @{network} =    BuiltIn.Create List    ${NETWORK}
    @{subnet} =    BuiltIn.Create List    ${SUBNET}
    OpenStackOperations.Neutron Cleanup    ${VMS}    ${network}    ${subnet}    ${PORTS}    ${sg}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    OpenStackOperations.OpenStack Suite Setup
    KarafKeywords.Issue Command On Karaf Console    log:set DEBUG ${DEBUG_MODULE}
    KarafKeywords.Issue Command On Karaf Console    log:list
    KarafKeywords.Check Karaf Log Message Count    ${DEBUG_MSG}    1    False

End Suite
    [Documentation]    Run at end of the suite
    KarafKeywords.Issue Command On Karaf Console    log:set INFO ${DEBUG_MODULE}
    OpenStackOperations.OpenStack Suite Teardown

Verify Elan Flows
    [Arguments]    ${smac_list}    ${dmac_list}    ${ip}
    [Documentation]    Verify flows of ELAN SMAC & DMAC Table
    ${output} =    Utils.Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl dump-flows br-int -OOpenflow13
    BuiltIn.Should Contain    ${output}    table=${ELAN_SMACTABLE}
    ${smac_output} =    String.Get Lines Containing String    ${output}    table=${ELAN_SMACTABLE}
    Builtin.Log    ${smac_output}
    : FOR    ${smac}    IN    @{smac_list}
    \    BuiltIn.Should Contain    ${smac_output}    ${smac}
    BuiltIn.Should Contain    ${output}    table=${ELAN_DMACTABLE}
    ${dmac_output} =    String.Get Lines Containing String    ${output}    table=${ELAN_DMACTABLE}
    Builtin.Log    ${dmac_output}
    : FOR    ${dmac}    IN    @{dmac_list}
    \    BuiltIn.Should Contain    ${dmac_output}    ${dmac}

Verify Elan Traffic
    [Documentation]    Verify Dataflow by pinging other vms
    @{VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VMS}
    : FOR    ${index}    IN RANGE    0    4
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${NETWORK}    @{VM_IPS}[0]    ping -c 3 @{VM_IPS}[${index}]
    \    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
