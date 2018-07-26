*** Settings ***
Documentation     Test Suite for NAPT Switch after Upgrade for SNAT.
Suite Setup       Start Suite
Suite Teardown    Upgrade Suite Teardown
Test Setup        Run Keywords    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CNTL_CONN_ID}
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP2_CONN_ID}
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/L2GatewayOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{DEBUG_LOG_COMPONENTS}    org.opendaylight.ovsdb    org.opendaylight.ovsdb.lib    org.opendaylight.netvirt    org.opendaylight.genius
${PASSIVE_MANAGER}    ptcp:6641:127.0.0.1
${TYPE}           tun
${UPGRADE1_NAT_EXTERNAL_BGPVPN}    upgrade1_nat_external_bgpvpn
${UPGRADE1_NAT_EXTERNAL_NETWORKS}    upgrade1_nat_external_network
${UPGRADE1_NAT_EXTERNAL_SUBNET}    upgrade1_nat_external_subnet
${UPGRADE1_NAT_EXTERNAL_SUBNET_CIDRS}    200.100.200.0/24
${UPGRADE1_NAT_NETWORKS}    upgrade1_nat_net
@{UPGRADE1_NAT_PORTS}    upgrade1_nat_port_1    upgrade1_nat_port_2
${UPGRADE1_NAT_PROVIDER_NETWORK_TYPE}    gre
${UPGRADE1_NAT_ROUTER}    upgrade1_nat_router
${UPGRADE1_NAT_SECURITY_GROUP}    upgrade1_nat_sg
${UPGRADE1_NAT_SUBNET_CIDRS}    72.1.2.0/24
${UPGRADE1_NAT_SUBNETS}    upgrade1_nat_sub
@{UPGRADE1_NAT_VMS}    upgrade1_nat_vm_1    upgrade1_nat_vm_2
${UPGRADE1_NAT_RDS}    ["2300:2"]
${UPGRADE1_NAT_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-c2921a261441

*** Test Cases ***
Get NAPT Switch Before Upgrade And Verify Napt Flows Are Present For The Napt Swicth
    [Documentation]    Get the napt switch and verify napt related flows are present in the napt switch before upgrade operation.
    ${napt_switch_id} =    OpenStackOperations.Get Napt Switch Id Rest
    ${dpn_id1} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CNTL_CONN_ID}
    ${dpn_id2} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP1_CONN_ID}
    ${dpn_id3} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP2_CONN_ID}
    ${NAPT_SWITCH_DPN_ID_BEFORE_UPGRADE} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    BuiltIn.Set Variable    ${dpn_id1}
    ${NAPT_SWITCH_DPN_ID_BEFORE_UPGRADE} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id2}'    BuiltIn.Set Variable    ${dpn_id2}
    ${NAPT_SWITCH_DPN_ID_BEFORE_UPGRADE} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id3}'    BuiltIn.Set Variable    ${dpn_id3}
    ${NAPT_SWITCH_IP} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    BuiltIn.Set Variable    ${OS_CNTL_IP}
    ${NAPT_SWITCH_IP} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    BuiltIn.Set Variable    ${OS_CMP1_IP}
    ${NAPT_SWITCH_IP} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    BuiltIn.Set Variable    ${OS_CMP2_IP}
    BuiltIn.Set Suite Variable    ${NAPT_SWITCH_DPN_ID_BEFORE_UPGRADE}
    BuiltIn.Set Suite Variable    ${NAPT_SWITCH_IP}
    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    Verify Napt Switch Flows    ${OS_CNTL_CONN_ID}    'Should contain'
    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id2}'    Verify Napt Switch Flows    ${OS_CMP1_CONN_ID}    'Should contain'
    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id3}'    Verify Napt Switch Flows    ${OS_CMP2_CONN_ID}    'Should contain'

Stop ODL
    ClusterManagement.Stop_Members_From_List_Or_All

Disconnect OVS
    [Documentation]    Delete OVS manager, controller and groups and tun ports
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    OVSDB.Delete OVS Manager    ${node}
    \    OVSDB.Delete OVS Controller    ${node}
    \    OVSDB.Delete Groups On Bridge    ${node}    ${INTEGRATION_BRIDGE}
    \    OVSDB.Delete Ports On Bridge By Type    ${node}    ${INTEGRATION_BRIDGE}    ${TYPE}

Start ODL
    [Documentation]    Start controller, wait for it to come "UP" and make sure netvirt is installed
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True
    Wait Until Keyword Succeeds    100s    5s    Utils.Check Diagstatus
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    False
    KarafKeywords.Verify_Feature_Is_Installed    odl-netvirt-openstack
    Set Custom Component Logging To    DEBUG

Wait For Full Sync
    [Documentation]    Wait for networking_odl to sync neutron configuration
    Wait Until Keyword Succeeds    90s    5s    Canary Network Should Exist

Set Upgrade Flag
    ${resp} =    RequestsLibrary.Put Request    session    ${UPDATE_FLAG_PATH}    {"config":{"upgradeInProgress":true}}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Set OVS Manager And Controller
    [Documentation]    Set controller and manager on each OpenStack node and check that egress flows are present
    ...    connect all the non napt switches except napt switch
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    BuiltIn.Run Keyword If    '${node}' != '${NAPT_SWITCH_IP}'    Connect Back The Ovs    ${node}

UnSet Upgrade Flag
    ${resp} =    RequestsLibrary.Put Request    session    ${UPDATE_FLAG_PATH}    {"config":{"upgradeInProgress":false}}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Check Connectivity With Previously Created Resources And br-int Info
    [Documentation]    Check that pre-existing instance connectivity still works after the new controller is brought
    ...    up and config is sync'd
    Dump Debug With Annotations    POST_UPGRADE
    Wait Until Keyword Succeeds    90s    10s    Check Resource Connectivity

Get NAPT Switch After Upgrade And Verify Napt Flows Are Present For The Napt Swicth
    [Documentation]    Get the napt switch and verify napt related flows are present in the napt switch after upgrade operation.
    ...    After upgrade verify that one of the non napt switch has become the napt switch.
    ${napt_switch_id} =    OpenStackOperations.Get Napt Switch Id Rest
    ${dpn_id1} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CNTL_CONN_ID}
    ${dpn_id2} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP1_CONN_ID}
    ${dpn_id3} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP2_CONN_ID}
    ${napt_switch_dpn_id_after_upgrade} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    BuiltIn.Set Variable    ${dpn_id1}
    ${napt_switch_dpn_id_after_upgrade} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id2}'    BuiltIn.Set Variable    ${dpn_id2}
    ${napt_switch_dpn_id_after_upgrade} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id3}'    BuiltIn.Set Variable    ${dpn_id3}
    BuiltIn.Should Not Be Equal As Numbers    ${NAPT_SWITCH_DPN_ID_BEFORE_UPGRADE}    ${napt_switch_dpn_id_after_upgrade}
    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    Verify Napt Switch Flows    ${OS_CNTL_CONN_ID}    'Should contain'
    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id2}'    Verify Napt Switch Flows    ${OS_CMP1_CONN_ID}    'Should contain'
    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id3}'    Verify Napt Switch Flows    ${OS_CMP2_CONN_ID}    'Should contain'

*** Keywords ***
Start Suite
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs, Router.
    ...    Associate subnet to router
    ...    Create External network and associate it to router
    ...    Create floating IPs and associate them to the Vms created
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${UPGRADE1_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Network    ${UPGRADE1_NAT_NETWORKS}
    OpenStackOperations.Create SubNet    ${UPGRADE1_NAT_NETWORKS}    ${UPGRADE1_NAT_SUBNETS}    ${UPGRADE1_NAT_SUBNET_CIDRS}
    OpenStackOperations.Create Port    ${UPGRADE1_NAT_NETWORKS}    @{UPGRADE1_NAT_PORTS}[0]    sg=${UPGRADE1_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Port    ${UPGRADE1_NAT_NETWORKS}    @{UPGRADE1_NAT_PORTS}[1]    sg=${UPGRADE1_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Router    ${UPGRADE1_NAT_ROUTER}
    OpenStackOperations.Add Router Interface    ${UPGRADE1_NAT_ROUTER}    ${UPGRADE1_NAT_SUBNETS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{UPGRADE1_NAT_PORTS}[0]    @{UPGRADE1_NAT_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${UPGRADE1_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{UPGRADE1_NAT_PORTS}[1]    @{UPGRADE1_NAT_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${UPGRADE1_NAT_SECURITY_GROUP}
    @{NET_VM_IPS}    ${NET_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{UPGRADE1_NAT_VMS}
    BuiltIn.Should Not Contain    ${NET_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_DHCP_IP}    None
    ${net_additional_args} =    BuiltIn.Catenate    --external --provider-network-type ${UPGRADE1_NAT_PROVIDER_NETWORK_TYPE}
    OpenStackOperations.Create Network    ${UPGRADE1_NAT_EXTERNAL_NETWORKS}    ${net_additional_args}
    OpenStackOperations.Create SubNet    ${UPGRADE1_NAT_EXTERNAL_NETWORKS}    ${UPGRADE1_NAT_EXTERNAL_SUBNET}    ${UPGRADE1_NAT_EXTERNAL_SUBNET_CIDRS}
    OpenStackOperations.Add Router Gateway    ${UPGRADE1_NAT_ROUTER}    ${UPGRADE1_NAT_EXTERNAL_NETWORKS}
    ${net_id} =    OpenStackOperations.Get Net Id    ${UPGRADE1_NAT_EXTERNAL_NETWORKS}
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${UPGRADE1_NAT_VPN_INSTANCE_IDS}    name=${UPGRADE1_NAT_EXTERNAL_BGPVPN}    rd=${UPGRADE1_NAT_RDS}    exportrt=${UPGRADE1_NAT_RDS}    importrt=${UPGRADE1_NAT_RDS}    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${UPGRADE1_NAT_VPN_INSTANCE_IDS}
    BuiltIn.Should Contain    ${resp}    ${UPGRADE1_NAT_VPN_INSTANCE_IDS}
    VpnOperations.Associate L3VPN To Network    networkid=${net_id}    vpnid=${UPGRADE1_NAT_VPN_INSTANCE_IDS}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${UPGRADE1_NAT_VPN_INSTANCE_IDS}
    BuiltIn.Should Contain    ${resp}    ${net_id}
    ${VM_FLOATING_IPS} =    OpenStackOperations.Create And Associate Floating IPs    ${UPGRADE1_NAT_EXTERNAL_NETWORKS}    @{UPGRADE1_NAT_VMS}

Verify Napt Switch Flows
    [Arguments]    ${conn_id}    ${check}='Should contain'
    [Documentation]    Verify Napt switch has Nat translation related flows.
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${OUTBOUND_NAPT_TABLE}
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    String.Split String    ${output}
    ${output} =    Set Variable    @{list}[0]
    BuiltIn.Run Keyword If    ${check}=='Should contain'    BuiltIn.Should Contain    ${output}    ${OUTBOUND_NAPT_TABLE}
    ...    ELSE    BuiltIn.Should Not Contain    ${output}    ${OUTBOUND_NAPT_TABLE}
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${NAPT_PFIB_TABLE}
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    String.Split String    ${output}
    ${output} =    Set Variable    @{list}[0]
    BuiltIn.Run Keyword If    ${check}=='Should contain'    BuiltIn.Should Contain    ${output}    ${NAPT_PFIB_TABLE}
    ...    ELSE    BuiltIn.Should Not Contain    ${output}    ${NAPT_PFIB_TABLE}

Connect Back The Ovs
    [Arguments]    ${node}
    [Documentation]    Connect the ovs to odl controller
    Run Command On Remote System    ${node}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT} ${PASSIVE_MANAGER}
    Wait Until Keyword Succeeds    180s    15s    Check OVS Nodes Have Egress Flows

Check Resource Connectivity
    [Documentation]    Ping 2 VMs in the same net and 1 from another net.
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_nat_net    @{NET_VM_IPS}

Check OVS Nodes Have Egress Flows
    [Documentation]    Loop over all openstack nodes to ensure they have the proper flows installed.
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    Does OVS Have Multiple Egress Flows    ${node}

Does OVS Have Multiple Egress Flows
    [Arguments]    ${ip}
    [Documentation]    Verifies that at least 1 flow exists on the node for the ${EGRESS_L2_FWD_TABLE}
    ${flows} =    Utils.Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
    ${egress_flows} =    String.Get Lines Containing String    ${flows}    table=${EGRESS_LPORT_DISPATCHER_TABLE}
    ${num_egress_flows} =    String.Get Line Count    ${egress_flows}
    BuiltIn.Should Be True    ${num_egress_flows} > 1

Set Custom Component Logging To
    [Arguments]    ${level}
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${level}    ${DEBUG_LOG_COMPONENTS}
    KarafKeywords.Issue_Command_On_Karaf_Console    log:list

Dump Debug With Annotations
    [Arguments]    ${tag}
    [Documentation]    Dump tons of debug logs for each OS node but also emit tags to make parsing easier
    Builtin.Log    Start dumping at phase ${tag}
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    ${conn_id} =    DevstackUtils.Open Connection    ${node}_CONNECTION_NAME    ${node}
    \    Builtin.Log    Start dumping for ${node} at phase ${tag}
    \    OpenStackOperations.Get DumpFlows And Ovsconfig    ${conn_id}
    \    Builtin.Log    End dumping for ${node} at phase ${tag}
    \    SSHLibrary.Close Connection
    Builtin.Log    End dumping at phase ${tag}

Canary Network Should Exist
    OpenStackOperations.Get Neutron Network Rest    bd8db3a8-2b30-4083-a8b3-b3fd46401142

Upgrade Suite Teardown
    Set Custom Component Logging To    INFO
    OpenStackOperations.OpenStack Suite Teardown
