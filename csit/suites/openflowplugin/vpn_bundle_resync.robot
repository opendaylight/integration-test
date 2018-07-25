*** Settings ***
Documentation     Test suite for verifying Bundle based reconciliation with switch(OVS)
Suite Setup       Start Suite
#Suite Teardown    End Suite
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../libraries/DevstackUtils.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/BgpOperations.robot
Resource          ../../libraries/OpenStackOperations.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot
Variables         ../../variables/SF278/Variables.py    

*** Variables ***
${DEBUG_MSG}      "bundle-based-reconciliation-enabled configuration property was changed to 'true'"
${DEBUG_MODULE}    "org.opendaylight.openflowplugin.applications.frm.impl.FlowNodeReconciliationImpl"
@{PORTS}          bundle_resync_port_1    bundle_resync_port_2    bundle_resync_port_3    bundle_resync_port_4
@{VMS}            bundle_resync_dpn1_vm_1    bundle_resync_dpn1_vm_2    bundle_resync_dpn2_vm_1    bundle_resync_dpn2_vm_2
${NETWORK}        bundle_resync_net_1
${SUBNET}         bundle_resync_subnet_1
${SUBNET_CIDR}    21.1.1.0/24
${SECURITY_GROUP}    bundle_resync_vpn_sg
${COUNT}          0
${VPN_INSTANCE_ID}    4af8cd92-48ca-49b5-94e1-b2921a261441
${VPN_NAME}       vpn_1
${RD}             ["100:1"]
${AS_ID}          100
${BGP_CONNECT}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
${NETWORK_IP}     5.5.5.1

*** Testcases ***
Check Tep State
    [Documentation]    Check the vxlan tunnels to be Up
    #VpnOperations.Verify Tunnel Status as UP

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
    : FOR    ${index}    IN RANGE    0    2
    \    ${instanceId}    ${vm_ip} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VMS[${index}]}    ${OS_CMP1_HOSTNAME}
    \    ...    sg=${SECURITY_GROUP}

Create VM Instances in DPN2
    [Documentation]    Create VMs in DPN2 belonging to subnet1
    : FOR    ${index}    IN RANGE    2    4
    \    ${instanceId}    ${vm_ip} =    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORTS[${index}]}    ${VMS[${index}]}    ${OS_CMP2_HOSTNAME}
    \    ...    sg=${SECURITY_GROUP}

Check VM IP
    [Documentation]    Check if the VM has got ips.
    @{VM_IPS}    ${dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VMS}
    : FOR    ${vmip}    IN    @{VM_IPS}
    \    BuiltIn.Should Not Contain    ${vmip}    None
    BuiltIn.Set Suite Variable    @{VM_IPS}

Create Router
    OpenStackOperations.Create Router    ${ROUTER}
    ${router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${router_list}

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}

Check Elan Traffic
    [Documentation]    Verify Dataflow by pinging other vms
    : FOR    ${index}    IN RANGE    0    4
    \    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${NETWORK}    @{VM_IPS}[0]    ping -c 3 @{VM_IPS}[${index}]
    \    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${RD}    exportrt=${RD}    importrt=${RD}    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID}

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${net_id} =    OpenStackOperations.Get Net Id    ${NETWORK}
    VpnOperations.Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}
    BuiltIn.Should Contain    ${resp}    ${net_id}

Setup BGP On DCGW And ODL
    [Documentation]    Setup BGP Configuration on DCGW and ODL
    BgpOperations.Start Quagga Processes On DCGW    ${TOOLS_SYSTEM_1_IP}
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    KarafKeywords.Issue_Command_On_Karaf_Console    ${BGP_CONNECT}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${TOOLS_SYSTEM_1_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${TOOLS_SYSTEM_1_IP}
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${TOOLS_SYSTEM_1_IP}    ${AS_ID}    ${TOOLS_SYSTEM_1_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME}    ${RD}
    ...    ${NETWORK_IP}
    BuiltIn.Wait Until Keyword Succeeds    120s    20s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${TOOLS_SYSTEM_1_IP}    ${ODL_SYSTEM_IP}

Verify the Bundle based reconciliation with switch(OVS1) restart scenario
    [Documentation]    Reconciliation check after OVS restart
    ${vm_ips} =    BuiltIn.Create List    @{VM_IPS}
    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    Check Karaf Message

#Verify the Bundle based reconciliation with switch(OVS) restart of both instances
#    [Documentation]    Reconciliation check after restart of both OVS instance
#    ${gw_ip} =    OpenStackOperations.Get Subnet Gateway Ip    ${SUBNET}
#    ${dpn2_id} =    OVSDB.Get DPID    ${OS_CMP2_IP}
#    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
#    OVSDB.Restart OVSDB    ${OS_CMP2_IP}
#    Check Karaf Message
#    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${dpn2_id}"
#    KarafKeywords.Check Karaf Log Message Count    ${resyncdone_msg}    1    False

#Verify the Bundle based reconciliation with consecutive quick restarts of OVS1 instance
#    [Documentation]    Reconciliation check after quick restarts of OVS instance
#    ${gw_ip} =    OpenStackOperations.Get Subnet Gateway Ip    ${SUBNET}
#    : FOR    ${index}    IN RANGE    0    3
#    \    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
#    BuiltIn.Wait Until Keyword Succeeds    10s    5s    Check Karaf Message
#
#Verify the Bundle based reconciliation with multiple restarts (OVS1)followed by resync check
#    [Documentation]    Reconciliation check after multiple restarts allowing the sync to settle.
#    ${gw_ip} =    OpenStackOperations.Get Subnet Gateway Ip    ${SUBNET}
#    : FOR    ${index}    IN RANGE    0    3
#    \    OVSDB.Restart OVSDB    ${OS_CMP1_IP}
#    \    BuiltIn.Wait Until Keyword Succeeds    15s    5s    Verify Elan Flows    ${SMAC_LIST_DPN2}    ${dmac_list}
#    \    ...    ${OS_CMP2_IP}
#    \    Check Karaf Message

Cleanup
    [Documentation]    Delete Port and VM Instances,Ports,Networks,Subnetwork and Security group
    @{sg} =    BuiltIn.Create List    ${SECURITY_GROUP}
    @{network} =    BuiltIn.Create List    ${NETWORK}
    @{subnet} =    BuiltIn.Create List    ${SUBNET}
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID}
    OpenStackOperations.Neutron Cleanup    ${VMS}    ${network}    ${subnet}    ${PORTS}    ${sg}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    OpenStackOperations.OpenStack Suite Setup
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG ${DEBUG_MODULE}
    KarafKeywords.Issue_Command_On_Karaf_Console    log:list
   # KarafKeywords.Check_Karaf_Log_Message_Count    ${DEBUG_MSG}    1    False
    VpnOperations.Basic Suite Setup

End Suite
    [Documentation]    Run at end of the suite
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set INFO ${DEBUG_MODULE}
    OpenStackOperations.OpenStack Suite Teardown

Check Karaf Message
    [Documentation]    Check Karaf log for the Message
    ${DPN1_ID} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    ${resyncdone_msg} =    BuiltIn.Set Variable    "Completing bundle based reconciliation for device ID:${DPN1_ID}"
    ${COUNT} =    Evaluate    ${COUNT}+1
    BuiltIn.Set Suite Variable    ${COUNT}
    KarafKeywords.Check_Karaf_Log_Message_Count    ${resyncdone_msg}    ${COUNT}


Check_Karaf_Log_Message_Count
    [Arguments]    ${message}    ${count}    ${use_console}=False
    [Documentation]    Verifies that the ${message} exists specified number of times in
    ...    karaf console log or Karaf Log Folder based on the arg ${use_console}.
    Run Keyword If    ${use_console} == False    Check_Karaf_Log_File    ${message}    ${count}
    ...    ELSE    Check_Karaf_Log_From_Console    ${message}    ${count}

Check_Karaf_Log_File
    [Arguments]    ${message}    ${count}
    [Documentation]    Verifies that the ${message} exists in the Karaf Log Folder and checks
    ...    that it appears ${count} number of times
    ${output}    Run Command On Controller    ${ODL_SYSTEM_IP}    grep -o ${message} ${WORKSPACE}/${BUNDLEFOLDER}/data/log/* | wc -l
    Should Be Equal As Strings    ${output}    ${count}

