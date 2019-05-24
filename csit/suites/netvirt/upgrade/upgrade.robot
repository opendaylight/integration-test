*** Settings ***
Documentation     Test suite for ODL Upgrade. It is assumed that OLD + OpenStack
...               integrated environment is deployed and ready.
Suite Setup       Suite Setup
Suite Teardown    Upgrade Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SECURITY_GROUP}    upgrade_sg
@{NETWORKS}       upgrade_net_1    upgrade_net_2
@{SUBNETS}        upgrade_sub_1    upgrade_sub_2
@{NET_1_VMS}      upgrade_net_1_vm_1    upgrade_net_1_vm_2
@{NET_2_VMS}      upgrade_net_2_vm_1    upgrade_net_2_vm_2
@{SUBNETS_RANGE}    91.0.0.0/24    92.0.0.0/24
${ROUTER}         upgrade_router_1
${TYPE}           tun
${PASSIVE_MANAGER}    ptcp:6641:127.0.0.1
@{DEBUG_LOG_COMPONENTS}    org.opendaylight.ovsdb    org.opendaylight.ovsdb.lib    org.opendaylight.netvirt    org.opendaylight.genius
${UPDATE_FLAG_PATH}    /restconf/config/odl-serviceutils-upgrade:upgrade-config

*** Test Cases ***
Create Setup And Verify Instance Connectivity
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    Check Resource Connectivity
    Dump Debug With Annotations    POST_SETUP

Stop ODL
    ClusterManagement.Stop_Members_From_List_Or_All

Disconnect OVS
    [Documentation]    Delete OVS manager, controller and groups and tun ports
    FOR    ${node}    IN    @{OS_ALL_IPS}
        OVSDB.Delete OVS Manager    ${node}
        OVSDB.Delete OVS Controller    ${node}
        OVSDB.Delete Groups On Bridge    ${node}    ${INTEGRATION_BRIDGE}
        OVSDB.Delete Ports On Bridge By Type    ${node}    ${INTEGRATION_BRIDGE}    ${TYPE}
    END

Wipe Local Data
    [Documentation]    Delete data/, journal/, snapshots/
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All

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
    ${resp} =    RequestsLibrary.Put Request    session    ${UPDATE_FLAG_PATH}    {"upgrade-config":{"upgradeInProgress":true}}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Set OVS Manager And Controller
    [Documentation]    Set controller and manager on each OpenStack node and check that egress flows are present
    FOR    ${node}    IN    @{OS_ALL_IPS}
        Utils.Run Command On Remote System And Log    ${node}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT} ${PASSIVE_MANAGER}
    END
    Wait Until Keyword Succeeds    180s    15s    Check OVS Nodes Have Egress Flows

UnSet Upgrade Flag
    ${resp} =    RequestsLibrary.Put Request    session    ${UPDATE_FLAG_PATH}    {"upgrade-config":{"upgradeInProgress":false}}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Check Connectivity With Previously Created Resources And br-int Info
    [Documentation]    Check that pre-existing instance connectivity still works after the new controller is brought
    ...    up and config is sync'd
    Dump Debug With Annotations    POST_UPGRADE
    Wait Until Keyword Succeeds    90s    10s    Check Resource Connectivity

*** Keywords ***
Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    Create Resources
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs

Create Resources
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    FOR    ${net}    IN    @{NETWORKS}
        OpenStackOperations.Create Network    ${net}
    END
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNETS_RANGE}[1]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Nano Flavor
    FOR    ${vm}    IN    @{NET_1_VMS}
        OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    ${vm}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    END
    FOR    ${vm}    IN    @{NET_2_VMS}
        OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    ${vm}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    END
    OpenStackOperations.Create Router    ${ROUTER}
    FOR    ${interface}    IN    @{SUBNETS}
        OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    END
    @{NET1_VM_IPS}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET2_VM_IPS}    ${NET2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET2_DHCP_IP}    None

Check Resource Connectivity
    [Documentation]    Ping 2 VMs in the same net and 1 from another net.
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_1    @{NET1_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_1    @{NET1_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_1    @{NET2_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_2    @{NET2_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_2    @{NET2_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_2    @{NET1_VM_IPS}[0]

Check OVS Nodes Have Egress Flows
    [Documentation]    Loop over all openstack nodes to ensure they have the proper flows installed.
    FOR    ${node}    IN    @{OS_ALL_IPS}
        Does OVS Have Multiple Egress Flows    ${node}
    END

Does OVS Have Multiple Egress Flows
    [Arguments]    ${ip}
    [Documentation]    Verifies that at least 1 flow exists on the node for the ${EGRESS_L2_FWD_TABLE}
    ${flows} =    Utils.Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
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
    FOR    ${node}    IN    @{OS_ALL_IPS}
        ${conn_id} =    DevstackUtils.Open Connection    ${node}_CONNECTION_NAME    ${node}
        Builtin.Log    Start dumping for ${node} at phase ${tag}
        OpenStackOperations.Get DumpFlows And Ovsconfig    ${conn_id}
        Builtin.Log    End dumping for ${node} at phase ${tag}
        SSHLibrary.Close Connection
    END
    Builtin.Log    End dumping at phase ${tag}

Canary Network Should Exist
    OpenStackOperations.Get Neutron Network Rest    bd8db3a8-2b30-4083-a8b3-b3fd46401142

Upgrade Suite Teardown
    Set Custom Component Logging To    INFO
    OpenStackOperations.OpenStack Suite Teardown
