*** Settings ***
Documentation     Test Suite for Retention of NAPT Switch after Upgrade for SNAT.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
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
${UPGRADE_NAT_EXTERNAL_BGPVPN}    upgrade_nat_external_bgpvpn
${UPGRADE_NAT_EXTERNAL_NETWORKS}    upgrade_nat_external_network
${UPGRADE_NAT_EXTERNAL_SUBNET}    upgrade_nat_external_subnet
${UPGRADE_NAT_EXTERNAL_SUBNET_CIDRS}    100.100.200.0/24
${UPGRADE_NAT_NETWORKS}    upgrade_nat_net
@{UPGRADE_NAT_PORTS}    upgrade_nat_port_1    upgrade_nat_port_2
${UPGRADE_NAT_PROVIDER_NETWORK_TYPE}    gre
${UPGRADE_NAT_ROUTER}    upgrade_nat_router
${UPGRADE_NAT_SECURITY_GROUP}    upgrade_nat_sg
${UPGRADE_NAT_SUBNET_CIDRS}    71.1.2.0/24
${UPGRADE_NAT_SUBNETS}    upgrade_nat_sub
@{UPGRADE_NAT_VMS}    upgrade_nat_vm_1    upgrade_nat_vm_2
${UPGRADE_NAT_RDS}    ["2200:2"]
${UPGRADE_NAT_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-c2921a261441

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
    ...    connect all the non napt switches then connect the napt switch
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    BuiltIn.Run Keyword If    '${node}' != '${NAPT_SWITCH_IP}'    Connect back the ovs    ${node}
    Connect back the ovs    ${NAPT_SWITCH_IP}

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
    ...    After upgrade verify that the same switch is made napt as before upgrade.
    ${napt_switch_id} =    OpenStackOperations.Get Napt Switch Id Rest
    ${dpn_id1} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CNTL_CONN_ID}
    ${dpn_id2} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP1_CONN_ID}
    ${dpn_id3} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP2_CONN_ID}
    ${napt_switch_dpn_id_after_upgrade} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id1}'    BuiltIn.Set Variable    ${dpn_id1}
    ${napt_switch_dpn_id_after_upgrade} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id2}'    BuiltIn.Set Variable    ${dpn_id2}
    ${napt_switch_dpn_id_after_upgrade} =    BuiltIn.Run Keyword If    '${napt_switch_id}'=='${dpn_id3}'    BuiltIn.Set Variable    ${dpn_id3}
    BuiltIn.Should Be Equal As Numbers    ${NAPT_SWITCH_DPN_ID_BEFORE_UPGRADE}    ${napt_switch_dpn_id_after_upgrade}
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
    OpenStackOperations.Create Allow All SecurityGroup    ${UPGRADE_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Network    ${UPGRADE_NAT_NETWORKS}
    OpenStackOperations.Create SubNet    ${UPGRADE_NAT_NETWORKS}    ${UPGRADE_NAT_SUBNETS}    ${UPGRADE_NAT_SUBNET_CIDRS}
    OpenStackOperations.Create Port    ${UPGRADE_NAT_NETWORKS}    @{UPGRADE_NAT_PORTS}[0]    sg=${UPGRADE_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Port    ${UPGRADE_NAT_NETWORKS}    @{UPGRADE_NAT_PORTS}[1]    sg=${UPGRADE_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Router    ${UPGRADE_NAT_ROUTER}
    OpenStackOperations.Add Router Interface    ${UPGRADE_NAT_ROUTER}    ${UPGRADE_NAT_SUBNETS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{UPGRADE_NAT_PORTS}[0]    @{UPGRADE_NAT_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${UPGRADE_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{UPGRADE_NAT_PORTS}[1]    @{UPGRADE_NAT_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${UPGRADE_NAT_SECURITY_GROUP}
    @{NET_VM_IPS}    ${NET_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{UPGRADE_NAT_VMS}
    BuiltIn.Should Not Contain    ${NET_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_DHCP_IP}    None
    ${net_additional_args} =    BuiltIn.Catenate    --external --provider-network-type ${UPGRADE_NAT_PROVIDER_NETWORK_TYPE}
    OpenStackOperations.Create Network    ${UPGRADE_NAT_EXTERNAL_NETWORKS}    ${net_additional_args}
    OpenStackOperations.Create SubNet    ${UPGRADE_NAT_EXTERNAL_NETWORKS}    ${UPGRADE_NAT_EXTERNAL_SUBNET}    ${UPGRADE_NAT_EXTERNAL_SUBNET_CIDRS}
    OpenStackOperations.Add Router Gateway    ${UPGRADE_NAT_ROUTER}    ${UPGRADE_NAT_EXTERNAL_NETWORKS}
    ${net_id} =    OpenStackOperations.Get Net Id    ${UPGRADE_NAT_EXTERNAL_NETWORKS}
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${UPGRADE_NAT_VPN_INSTANCE_IDS}    name=${UPGRADE_NAT_EXTERNAL_BGPVPN}    rd=${UPGRADE_NAT_RDS}    exportrt=${UPGRADE_NAT_RDS}    importrt=${UPGRADE_NAT_RDS}    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${UPGRADE_NAT_VPN_INSTANCE_IDS}
    BuiltIn.Should Contain    ${resp}    ${UPGRADE_NAT_VPN_INSTANCE_IDS}
    VpnOperations.Associate L3VPN To Network    networkid=${net_id}    vpnid=${UPGRADE_NAT_VPN_INSTANCE_IDS}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${UPGRADE_NAT_VPN_INSTANCE_IDS}
    BuiltIn.Should Contain    ${resp}    ${net_id}
    ${VM_FLOATING_IPS} =    OpenStackOperations.Create And Associate Floating IPs    ${UPGRADE_NAT_EXTERNAL_NETWORKS}    @{UPGRADE_NAT_VMS}
