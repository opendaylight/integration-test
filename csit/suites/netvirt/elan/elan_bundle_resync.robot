*** Settings ***
Documentation     Test suite for verifying Bundle based reconciliation with switch(OVS)
Suite Setup       Start Suite
Suite Teardown    End Suite
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${FLAG_MSG}       "bundle-based-reconciliation-enabled configuration property was changed to 'true'"
@{PORT_LIST}      port1    port2    port3    port4
@{VM_LIST}        dpn1_vm1    dpn1_vm2    dpn2_vm1    dpn2_vm2
${NETWORK_NAME}    net1
${SUBNET_NAME}    subnet1
${SUBNET_CIDR}    20.1.1.0/24
@{MASK}           32    24
${OPENSTACK_BRANCH}    stable/newton
${SGP}            elan_sg

*** Testcases ***
Check Tep State
    [Documentation]    Check the vxaln tunnels to be Up
    ${TepShow}    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    ${TunnelCount}    Get Regexp Matches    ${TepShow}    UP\\s+VXLAN
    Length Should Be    ${TunnelCount}    ${2}
    Verify Tunnel Status as UP

Create Security Group
    [Documentation]    Creating customised security Group
    ${OUTPUT}    ${SGP_ID}    OpenStackOperations.Neutron Security Group Create    ${SGP}
    Set Suite Variable    ${SGP_ID}
    ${OUTPUT1}    ${RULE_ID1}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=icmp
    ${OUTPUT2}    ${RULE_ID2}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=tcp
    ${OUTPUT3}    ${RULE_ID3}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=ingress    protocol=udp
    ${OUTPUT4}    ${RULE_ID4}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=icmp
    ${OUTPUT5}    ${RULE_ID5}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=tcp
    ${OUTPUT6}    ${RULE_ID6}    OpenStackOperations.Neutron Security Group Rule Create    ${SGP}    direction=egress    protocol=udp

Create VXLAN Network net1
    [Documentation]    Create Network with neutron request
    OpenStackOperations.Create Network    ${NETWORK_NAME}

Create Subnet For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_CIDR}

Create Port
    [Documentation]    Create ports under the subnet
    : FOR    ${Index}    IN RANGE    0    4
    \    Create Port    ${NETWORK_NAME}    ${PORT_LIST[${INDEX}]}    ${SGP_ID}

Create VM Instances in DPN1
    [Documentation]    Create VMs in DPN1 belonging to subnet1
    ${SMAC_LIST_DPN1}    BuiltIn.Create List
    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN1}
    ${NODE_HOSTNAME}    Run Command On Remote System    ${OS_CONTROL_NODE_IP}    hostname
    : FOR    ${Index}    IN RANGE    0    2
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${NODE_HOSTNAME}
    \    ${portmac}    Get Port Mac    ${PORT_LIST[${Index}]}
    \    Collections.Append To List    ${SMAC_LIST_DPN1}    ${portmac}

Create VM Instances in DPN2
    [Documentation]    Create VMs in DPN2 belonging to subnet1
    ${SMAC_LIST_DPN2}    BuiltIn.Create List
    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN2}
    ${NODE_HOSTNAME}    Run Command On Remote System    ${OS_COMPUTE_1_IP}    hostname
    : FOR    ${Index}    IN RANGE    2    4
    \    ${InstanceId}    ${VM_IP}    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${NODE_HOSTNAME}
    \    ${portmac}    Get Port Mac    ${PORT_LIST[${Index}]}
    \    Collections.Append To List    ${SMAC_LIST_DPN2}    ${portmac}

Get DPNID DMAC
    [Documentation]    Fetch the DPN Ids Mac address of the ports of the VMs spawned in DPNs.
    ${dpn1_id}    OVSDB.Get DPID    ${OS_CONTROL_NODE_IP}
    Set Suite Variable    ${dpn1_id}
    ${dpn2_id}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    Set Suite Variable    ${dpn2_id}
    @{DMAC_LIST}    Get Ports MacAddr    ${PORT_LIST}
    Set Suite Variable    @{DMAC_LIST}

Verify the Bundle based reconciliation with switch(OVS) restart scenario
    [Documentation]    Reconciliation check after OVS restart
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CONTROL_NODE_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_COMPUTE_1_IP}
    Run Command On Remote System    ${OS_CONTROL_NODE_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CONTROL_NODE_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_COMPUTE_1_IP}
    Log    Check if flows are pushed as bundle messages
    ${resyncdone_msg}=    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${dpn1_id}"
    Check_Karaf_Log_Message_Count    ${resyncdone_msg}    1    False
    Verify Elan Traffic

Verify the Bundle based reconciliation with switch(OVS) restart of both instances
    [Documentation]    Reconciliation check after restart of both OVS instance
    Run Command On Remote System    ${OS_CONTROL_NODE_IP}    sudo service openvswitch-switch restart
    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CONTROL_NODE_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_COMPUTE_1_IP}
    BuiltIn.Set Suite Variable    ${resyncdone_msg}    "Completing bundle based reconciliation for device ID:${dpn1_id}"
    Log    Check if flows are pushed as bundle messages
    Check_Karaf_Log_Message_Count    ${resyncdone_msg}    2    False
    ${resyncdone_msg}=    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${dpn2_id}"
    Check_Karaf_Log_Message_Count    ${resyncdone_msg}    1    False
    Verify Elan Traffic

Verify the Bundle based reconciliation with immediate restarts of both instances
    [Documentation]    Reconciliation check after immediate restarts
    : FOR    ${Index}    IN RANGE    0    3
    \    Run Command On Remote System    ${OS_CONTROL_NODE_IP}    sudo service openvswitch-switch restart
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}    ${OS_CONTROL_NODE_IP}
    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}    ${OS_COMPUTE_1_IP}
    Log    Check if flows are pushed as bundle messages
    ${resyncdone_msg}=    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${dpn1_id}"
    Check_Karaf_Log_Message_Count    ${resyncdone_msg}    5    False
    Verify Elan Traffic

Verify the Bundle based reconciliation with multiple restarts followed by resync check
    [Documentation]    Reconciliation check after multiple restarts allowing the sync to settle.
    ${count}    Set Variable    6
    : FOR    ${Index}    IN RANGE    0    3
    \    Run Command On Remote System    ${OS_CONTROL_NODE_IP}    sudo service openvswitch-switch restart
    \    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${DMAC_LIST}
    \    ...    ${OS_CONTROL_NODE_IP}
    \    Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${DMAC_LIST}
    \    ...    ${OS_COMPUTE_1_IP}
    \    ${resyncdone_msg}=    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${dpn1_id}"
    \    Check_Karaf_Log_Message_Count    ${resyncdone_msg}    ${count}    False
    \    ${count}    Evaluate    ${count} + 1
    Verify Elan Traffic

Delete Port and VM Instances
    [Documentation]    Delete Port and VM Instances and ensure it again via list vm and list ports
    Log    Deleting all VMs and Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Delete Vm Instance    ${VmName}
    \    Delete Port    ${PortName}
    ${VMs}    List Nova VMs
    ${Ports}    List Ports
    : FOR    ${PortName}    ${VmName}    IN ZIP    ${PORT_LIST}    ${VM_LIST}
    \    Should Not Contain    ${VMs}    ${VmName}
    \    Should Not Contain    ${Ports}    ${PortName}

Delete Net Subnet SecGroup
    [Documentation]    Delete Network Subnetwork and Security Group
    Delete SubNet    ${SUBNET_NAME}
    Delete Network    ${NETWORK_NAME}
    Delete SecurityGroup    ${SGP}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    OpenStackOperations.OpenStack Suite Setup
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl
    Check_Karaf_Log_Message_Count    ${FLAG_MSG}    1    False

End Suite
    [Documentation]    Run at end of the suite
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set INFO org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl
    OpenStackOperations.OpenStack Suite Teardown

Verify Elan Flows
    [Arguments]    ${smac_list}    ${dmac_list}    ${ip}
    [Documentation]    Verify flows of ELAN SMAC & DMAC Table
    ${output}    Run Command On Remote System    ${ip}    sudo ovs-ofctl dump-flows br-int -OOpenflow13 | grep table=${ELAN_SMACTABLE}
    BuiltIn.Should Not Be Empty    ${output}
    Log    ${output}
    : FOR    ${mac}    IN    @{smac_list}
    \    BuiltIn.Should Contain    ${output}    ${mac}
    ${output}    Run Command On Remote System    ${ip}    sudo ovs-ofctl dump-flows br-int -OOpenflow13 | grep table=${ELAN_DMACTABLE}
    BuiltIn.Should Not Be Empty    ${output}
    Log    ${output}
    : FOR    ${mac}    IN    @{dmac_list}
    \    BuiltIn.Should Contain    ${output}    ${mac}

Verify Elan Traffic
    [Documentation]    Verify Dataflow by pinging other vms
    @{VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VM_LIST}
    : FOR    ${Index}    IN RANGE    0    4
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${NETWORK_NAME}    @{VM_IPS}[0]    ping -c 3 @{VM_IPS}[${Index}]
    \    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
