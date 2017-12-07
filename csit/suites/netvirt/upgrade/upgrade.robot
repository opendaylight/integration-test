*** Settings ***
Documentation     Test suite for ODL Upgrade. It is assumed that OLD + OpenStack
...               integrated environment is deployed and ready.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
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
${BRINT}          br-int
${ROUTER}         upgrade_router_1
${TYPE}           tun
${PASSIVE_MANAGER}      ptcp:6641:127.0.0.1

*** Test Cases ***
Create Setup
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    Create Resources
    Check Resource Connectivity
    DevstackUtils.Set Node Data For Control Only Node Setup
    Dump Debug With Annotations    POST_SETUP

Stop ODL
    ClusterManagement.Stop_Members_From_List_Or_All

Disconnect OVS
    [Documentation]    Delete OVS manager, controller and groups and tun ports
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    OVSDB.Delete OVS Manager    ${node}
    \    OVSDB.Delete OVS Controller    ${node}
    \    OVSDB.Delete Groups    ${node}    ${BRINT}
    \    OVSDB.Delete Ports By Type    ${node}    ${BRINT}    ${TYPE}

Wipe Cache
    [Documentation]    Delete journal/, snapshots
    ClusterManagement.Clean_Journals_Data_And_Snapshots_On_List_Or_All

Start ODL
    [Documentation]    Install odl-netvirt-openstack and Start ODL
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True
    KarafKeywords.Install_A_Feature    odl-restconf-all odl-netvirt-openstack
    Wait Until Keyword Succeeds    100s    5s    Utils.Check Diagstatus
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    False
    KarafKeywords.Verify_Feature_Is_Installed    odl-netvirt-openstack
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG org.opendaylight.ovsdb
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG org.opendaylight.ovsdb.lib
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG org.opendaylight.netvirt
    KarafKeywords.Issue_Command_On_Karaf_Console    log:set DEBUG org.opendaylight.genius
    KarafKeywords.Issue_Command_On_Karaf_Console    log:list

Wait For Full Sync
    [Documentation]    Wait for networking_odl to sync neutron configuration
    Wait Until Keyword Succeeds    60s    5s    OpenStackOperations.Neutron Port List Rest

Set OVS Manager And Controller
    [Documentation]    Set controller and manager on each node
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    Run Command On Remote System    ${node}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:${OVSDBPORT} ${PASSIVE_MANAGER}
    Wait Until Keyword Succeeds    180s    15s    OVS Nodes Have Egress Flows

Check Connectivity With Previously Created Resources And br-int Info
    Dump Debug With Annotations    POST_UPGRADE
    Check Resource Connectivity

*** Keywords ***
Create Resources
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    : FOR    ${net}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${net}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNETS_RANGE}[1]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Nano Flavor
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    ${vm}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    : FOR    ${vm}    IN    @{NET_2_VMS}
    \    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    ${vm}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Router    ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
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

OVS Nodes Have Egress Flows
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    Does OVS Have Multiple Egress Flows    ${node}

Does OVS Have Multiple Egress Flows
    [Arguments]    ${ip}
    ${flows} =    Utils.Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${egress_flows} =    String.Get Lines Containing String    ${flows}    table=220
    ${num_egress_flows} =    String.Get Line Count    ${egress_flows}
    Should Be True    ${num_egress_flows} > 1

Dump Debug With Annotations
    [Documentation]    Dump tons of debug logs for each OS node but also emit tags to make parsing easier
    [Arguments]     ${tag}
    Builtin.Log     Start dumping at phase ${tag}
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    ${conn_id} =    DevstackUtils.Open Connection    ${node}_CONNECTION_NAME    ${node}
    \    Builtin.Log     Start dumping for ${node} at phase ${tag}
    \    OpenStackOperations.Get DumpFlows And Ovsconfig    ${conn_id}
    \    Builtin.Log     End dumping for ${node} at phase ${tag}
    \    SSHLibrary.Close Connection
    Builtin.Log     End dumping at phase ${tag}
