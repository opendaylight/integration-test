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
${LOG_BEFORE_RESTART}    LOG_BEFORE_RESTART.txt
${LOG_AFTER_RESTART}    LOG_AFTER_RESTART.txt
${SECURITY_GROUP}    upgrade_sg
@{NETWORKS}       upgrade_net_1    upgrade_net_2
@{SUBNETS}        upgrade_sub_1    upgrade_sub_2
@{NET_1_VMS}      upgrade_net_1_vm_1    upgrade_net_1_vm_2
@{NET_2_VMS}      upgrade_net_2_vm_1    upgrade_net_2_vm_2
@{SUBNETS_RANGE}    91.0.0.0/24    92.0.0.0/24
${BRINT}          br-int
${ROUTER}         router_1
${TYPE}           tun
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}

*** Test Cases ***
Create Setup
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    ...    Dump br-int flows and log them to log file ${LOG_BEFORE_RESTART}
    Create Resources
    Check Resource Connectivity
    DevstackUtils.Set Node Data For Control Only Node Setup
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    OVSDB.Get Info From Bridge    ${node}    ${BRINT}    ${LOG_BEFORE_RESTART}

Stop ODL
    [Documentation]    Stop ODL
    ClusterManagement.Stop_Members_From_List_Or_All

Disconnect OVS
    [Documentation]    Delete OVS manager, controller and groups and tun ports
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    OVSDB.Delete OVS Manager    ${node}
    \    OVSDB.Delete OVS Controller    ${node}
    \    OVSDB.Delete Groups    ${node}    ${BRINT}
    \    OVSDB.Delete Ports    ${node}    ${BRINT}    ${TYPE}

Wipe Cache
    [Documentation]    Delete journal/, snapshots
    SSHLibrary.Get Directory    ${KARAF_HOME}/data/log    karaf_log/before_delete/    recursive=True
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All

Start ODL
    [Documentation]    Start ODL
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=False

Trigger Full Sync
    [Documentation]    Trigger full sync from networking-odl. It is done every 30 secs. Get # of neutron ports at the end of sync
    BuiltIn.Sleep    50
    ${AUTH} =    Set Variable    ${ODL_RESTCONF_USER}    ${ODL_RESTCONF_PASSWORD}
    RequestsLibrary.Create Session    ODL_SESSION    http://${ODL_SYSTEM_IP}:${PORT}    auth=${AUTH}
    ${headers}=    Create Dictionary    Content-Type=application/json
    ${resp}=    RequestsLibrary.GET Request    ODL_SESSION    ${CONFIG_API}/neutron:neutron/ports    headers=${headers}
    Log    STATUS_CODE: ${resp.status_code} CONTENT: ${resp.content}

Check Connectivity With Previously Created Resources And br-int Info
    Check Resource Connectivity
    : FOR    ${node}    IN    @{OS_ALL_IPS}
    \    OVSDB.Get Info From Bridge    ${node}    ${BRINT}    ${LOG_AFTER_RESTART}

Delete Setup
    [Documentation]    Delete resources created in above step
    OpenStackOperations.OpenStack Cleanup All

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
