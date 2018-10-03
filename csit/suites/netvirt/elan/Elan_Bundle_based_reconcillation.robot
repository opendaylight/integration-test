*** Settings ***
Documentation     Test suite for verifying Elan Bundle based reconciliation with switch(OVS)
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
#Suite Setup       Start Suite
#Suite Teardown    End Suite
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot
#Library           %{SDN}/Lib/controller/CeeUtils.py    WITH NAME    cee
#Library           %{SDN}/Lib/Switch/OvsSw.py    ${logger}    ${bridgename}    ${HIPVS_server1}    ${sbi_ip}

*** Variables ***
${DEBUG_MSG}      "bundle-based-reconciliation-enabled configuration property was changed to 'true'"
${DEBUG_MODULE}    "org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl"
@{PORTS}          elan_bundle_port_1    elan_bundle_port_2    elan_bundle_port_3    elan_bundle_port_4
${NUM_OF_VM_NAMES_PER_DPN}    2
@{VM_NAMES}      elan_bundle_dpn_1_vm_1    elan_bundle_dpn_1_vm_2    elan_bundle_dpn_2_vm_1    elan_bundle_dpn_2_vm_2
@{NET_1_VM_NAMES}     elan_bundle_dpn_1_vm_1     elan_bundle_dpn_1_vm_2 
@{NET_2_VM_NAMES}     elan_bundle_dpn_2_vm_1      elan_bundle_dpn_2_vm_2
${NETWORK}        elan_bundle_net_1
${SUBNET}         elan_bundle_sub_net_1
${SUBNET_CIDR}    85.1.1.0/24
${SECURITY_GROUP}    elan_bundle_sg
${COUNT}          0
#@{SMAC_LIST_DPN1}    @{EMPTY}
3@{SMAC_LIST_DPN2}    @{EMPTY}
#@{ODL_IP}    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
#@{COUNT_BEFORE}    0    0    0
#@{COUNT_AFTER}    0    0    0
${VM_IP}     4
${RESTART_COUNTS}     3

*** Testcases ***
#Check Tep State
#    [Documentation]    Check the vxlan tunnels to be Up
#    VpnOperations.Verify Tunnel Status as UP
#
#Create VXLAN Network net_1
#    [Documentation]    Create Network with neutron request
#    OpenStackOperations.Create Network    ${NETWORK}
#
#Create Subnet For net_1
#    [Documentation]    Create Sub Nets for the Networks with neutron request.
#    OpenStackOperations.Create SubNet    ${NETWORK}    ${SUBNET}    ${SUBNET_CIDR}
#
#Add Ssh Allow All Rule
#    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
#    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
#
#Create Port
#    [Documentation]    Create ports under the subnet
#    : FOR    ${port}    IN    @{PORTS}
#    \    OpenStackOperations.Create Port    ${NETWORK}    ${port}    ${SECURITY_GROUP}
#
#Create VM Instances in DPN1
#    [Documentation]    Create VMs in DPN1 belonging to subnet1
#    @{SMAC_LIST_DPN1} =    BuiltIn.Create List
#    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN1}
#    : FOR    ${index}    IN RANGE    0    2
#    \    ${instanceId}    ${vm_ip} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VM_NAMES[${index}]}    ${OS_COMPUTE_1_IP}
#    \    ...    sg=${SECURITY_GROUP}
#    \    ${portmac} =    OpenStackOperations.Get Port Mac    ${PORTS[${index}]}
#    \    Collections.Append To List    ${SMAC_LIST_DPN1}    ${portmac}
#
#Create VM Instances in DPN2
#    [Documentation]    Create VMs in DPN2 belonging to subnet1
#    @{SMAC_LIST_DPN2} =    BuiltIn.Create List
#    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN2}
#    : FOR    ${index}    IN RANGE    2    4
#    \    ${instanceId}    ${vm_ip} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VM_NAMES[${index}]}    ${OS_COMPUTE_2_IP}
#    \    ...    sg=${SECURITY_GROUP}
#    \    ${portmac} =    OpenStackOperations.Get Port Mac    ${PORTS[${index}]}
#    \    Collections.Append To List    ${SMAC_LIST_DPN2}    ${portmac}
#
#Check VM IP
#    [Documentation]    Check if the VM has got ips.
#    @{vm_ips}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VM_NAMES}
#    : FOR    ${vmip}    IN    @{vm_ips}
#    \    BuiltIn.Should Not Contain    ${vmip}    None

Verify the Bundle based reconciliation with switch(OVS1) restart scenario
    [Documentation]    Reconciliation check after OVS restart
    @{dmac_list} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${dmac_list}    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${dmac_list}    ${OS_CMP2_IP}
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${dmac_list}    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${dmac_list}    ${OS_CMP2_IP}
    ${switch_idx}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}
    BuiltIn.Set Global Variable    ${switch_idx}
    Check Karaf Message     ${switch_idx}
    Verify Elan Traffic

Verify the Bundle based reconciliation with switch(OVS) restart of both instances
    [Documentation]    Reconciliation check after restart of both OVS instance
    @{dmac_list} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    ${dpn2_id} =    OVSDB.Get DPID    ${OS_CMP2_IP}
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    OVSDB.Restart OVSDB    ${OS_CMP2_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${dmac_list}    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${dmac_list}    ${OS_CMP2_IP}
    #${switch_idx}    OVSDB.Get DPID    ${TOOLS_SYSTEM_IP}
    #BuiltIn.Set Global Variable    ${switch_idx}
    Check Karaf Message
    ${resyncdone_msg}=    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${dpn2_id}"
    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    ${1}    False
    Verify Elan Traffic

Verify the Bundle based reconciliation with consecutive quick restarts of OVS1 instance
    [Documentation]    Reconciliation check after quick restarts of OVS instance
    @{dmac_list} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    : FOR    ${index}    IN RANGE     ${RESTART_COUNTS}
    \    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${dmac_list}    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${dmac_list}    ${OS_CMP2_IP}
    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Check Karaf Message
    Verify Elan Traffic

Verify the Bundle based reconciliation with multiple restarts (OVS1)followed by resync check
    [Documentation]    Reconciliation check after multiple restarts allowing the sync to settle.
    @{dmac_list}    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    : FOR    ${index}    IN RANGE     ${RESTART_COUNTS}
    \    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    \    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN1}    ${dmac_list}
    \    ...    ${OS_CMP1_IP}
    \    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${dmac_list}
    \    ...    ${OS_CMP2_IP}
    \    Check Karaf Message
    Verify Elan Traffic
   
Cleanup
    [Documentation]    Delete Port and VM Instances,Ports,Networks,Subnetwork and Security group
    @{sg} =    BuiltIn.Create List    ${SECURITY_GROUP}
    @{network} =    BuiltIn.Create List    ${NETWORK}
    @{subnet} =    BuiltIn.Create List    ${SUBNET}
    OpenStackOperations.Neutron Cleanup    ${VM_NAMES}    ${network}    ${subnet}    ${PORTS}    ${sg}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    OpenStackOperations.OpenStack Suite Setup
    KarafKeywords.Issue Command On Karaf Console    log:set DEBUG ${DEBUG_MODULE}
    KarafKeywords.Issue Command On Karaf Console    log:list
    #BuiltIn.Wait Until Keyword Succeeds    60s   5s    KarafKeywords.Check Karaf Log Message Count      ${DEBUG_MSG}     ${1}    False
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VM_NAMES}    @{NET_2_VM_NAMES}
    OpenStackOperations.Get Suite Debugs

Create Setup
    VpnOperations.Verify Tunnel Status as UP
    OpenStackOperations.Create Network    ${NETWORK}
    OpenStackOperations.Create SubNet    ${NETWORK}    ${SUBNET}    ${SUBNET_CIDR}    
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Port
    #Create VM Instances in DPN1
    #Create VM Instances in DPN2
    Check VM IP

Create Port
    [Documentation]    Create ports under the subnet
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Create Port    ${NETWORK}    ${port}    ${SECURITY_GROUP}

Create Nova VMs
    [Arguments]    ${NUM_OF_VM_NAMES_PER_DPN}
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VM_NAMES_PER_DPN}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index}]}    ${VM_NAMES[${index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
   # ${start} =    Evaluate    ${index}+1
   # ${NUM_OF_VM_NAMES_PER_DPN} =    Evaluate    ${start}+${NUM_OF_VM_NAMES_PER_DPN}
   # : FOR    ${index}    IN RANGE    ${start}    ${NUM_OF_VM_NAMES_PER_DPN}
     OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${index+2}    ${VM_NAMES[${index+2}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_NAMES}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_NAMES}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    @{NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None



#Create VM Instances in DPN1
#    [Documentation]    Create VMs in DPN1 belonging to subnet1
#    @{SMAC_LIST_DPN1} =    BuiltIn.Create List
#    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN1}
#    : FOR    ${index}    IN RANGE    0    2
#    \    ${instanceId}    ${vm_ip} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VM_NAMES[${index}]}    ${OS_COMPUTE_1_IP}
#    \    ...    sg=${SECURITY_GROUP}
#    \    ${portmac} =    OpenStackOperations.Get Port Mac    ${PORTS[${index}]}
#    \    Collections.Append To List    ${SMAC_LIST_DPN1}    ${portmac}
#
#Create VM Instances in DPN2
#    [Documentation]    Create VMs in DPN2 belonging to subnet1
#    @{SMAC_LIST_DPN2} =    BuiltIn.Create List
#    BuiltIn.Set Suite Variable    @{SMAC_LIST_DPN2}
#    : FOR    ${index}    IN RANGE    2    4
#    \    ${instanceId}    ${vm_ip} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VM_NAMES[${index}]}    ${OS_COMPUTE_2_IP}
#    \    ...    sg=${SECURITY_GROUP}
#    \    ${portmac} =    OpenStackOperations.Get Port Mac    ${PORTS[${index}]}
#    \    Collections.Append To List    ${SMAC_LIST_DPN2}    ${portmac}

Check VM IP
    [Documentation]    Check if the VM has got ips.
    @{vm_ips}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VM_NAMES}
    : FOR    ${vmip}    IN    @{vm_ips}
    \    BuiltIn.Should Not Contain    ${vmip}    None

#End Suite
#    [Documentation]    Run at end of the suite
#    KarafKeywords.Issue Command On Karaf Console    log:set INFO ${DEBUG_MODULE}
#    OpenStackOperations.OpenStack Suite Teardown

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
    @{vm_ips}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VM_NAMES}
    : FOR    ${index}    IN RANGE    0    ${VM_IP}
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${NETWORK}    @{vm_ips}[0]    ping -c 3 @{vm_ips}[${index}]
    \    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Check Karaf Message
    [Documentation]    Check Karaf log for the Message
    ${DPN1_ID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN1_ID}"
    ${COUNT} =    Evaluate    ${COUNT}+1
    BuiltIn.Set Suite Variable    ${COUNT}
    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    ${COUNT}

End Suite
    [Documentation]    Run at end of the suite
    KarafKeywords.Issue Command On Karaf Console    log:set INFO ${DEBUG_MODULE}
    OpenStackOperations.OpenStack Suite Teardown

