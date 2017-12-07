*** Settings ***
Documentation     Test suite for ODL Upgrade. It is assumed that OLD + OpenStack
...               integrated environment is deployed and ready.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    OpenStackOperations.OpenStack Suite Teardown
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           DiffLibrary
Library           SSHLibrary
Library           OperatingSystem
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot

*** Variables ***
${LOG_BEFORE_RESTART}    /tmp/LOG_BEFORE_RESTART.txt
${LOG_AFTER_RESTART}    /tmp/LOG_AFTER_RESTART.txt
${SECURITY_GROUP}    upgrade_sg
@{NETWORKS}       upgrade_net_1    upgrade_net_2
@{SUBNETS}        upgrade_sub_1    upgrade_sub_2
@{NET_1_VMS}      upgrade_net_1_vm_1    upgrade_net_1_vm_2
@{NET_2_VMS}      upgrade_net_2_vm_1    upgrade_net_2_vm_2
@{SUBNETS_RANGE}    91.0.0.0/24    92.0.0.0/24
${bridge}         br-int

*** Test Cases ***
Create setup
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    ...    Dump br-int flows and log them to log file ${LOG_BEFORE_RESTART}
    Create resources
    Check resource connectivity
    Get flows from br-int    ${OS_CONTROL_NODE_IP}    ${LOG_BEFORE_RESTART}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Get info from br-int    ${OS_COMPUTE_1_IP}    ${LOG_BEFORE_RESTART}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Get info from br-int    ${OS_COMPUTE_2_IP}    ${LOG_BEFORE_RESTART}

Stop ODL
    [Documentation]    Stop ODL
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    ${ODL_STOP}

Disconnect OVS
    [Documentation]    Delete OVS manager, controller and groups and tun ports
    OVSDB.Delete OVS manager    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    OVSDB.Delete OVS manager    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    OVSDB.Delete OVS manager    ${OS_COMPUTE_1_IP}
    OVSDB.Delete OVS controller    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    OVSDB.Delete OVS controller    ${OS_COMPUTE_1_IP}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    OVSDB.Delete OVS controller    ${OS_COMPUTE_2_IP}
    OVSDB.Delete groups    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    OVSDB.Delete groups    ${OS_COMPUTE_1_IP}    ${bridge}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    OVSDB.Delete groups    ${OS_COMPUTE_2_IP}    ${bridge}
    OVSDB.Delete tun ports    ${OS_CONTROL_NODE_IP}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    OVSDB.Delete ports    ${OS_COMPUTE_1_IP}    ${bridge}    ${port}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    OVSDB.Delete ports    ${OS_COMPUTE_2_IP}    ${bridge}    ${port}

Wipe cache
    [Documentation]    Delete journal/, snapshots
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All    ${OS_CONTROL_NODE_IP}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_1_IP}

Start ODL
    [Documentation]    Start ODL
    Utils.Run Command On Remote System And Log    ${ODL_SYSTEM_IP}    ${ODL_START}

Trigger Full sync
    [Documentation]    Trigger full sync from networking-odl. It is done every 30 secs.
    sleep 50

Check connectivity with previously created resources and br-int info
    Check resource connectivity
    Get flows from br-int    ${OS_CONTROL_NODE_IP}    ${LOG_AFTER_RESTART}
    Run Keyword If    1 < ${NUM_OS_SYSTEM}    Get info from br-int    ${OS_COMPUTE_1_IP}    ${LOG_AFTER_RESTART}
    Run Keyword If    2 < ${NUM_OS_SYSTEM}    Get info from br-int    ${OS_COMPUTE_2_IP}    ${LOG_AFTER_RESTART}

Delete setup
    [Documentation]    Delete resources created in above step
    OpenStackOperations.OpenStack Cleanup All
    OpenStackOperations.Cleanup Router    router_1

Compare flows before and after result
    DiffLibrary.Diff Files    ${LOG_BEFORE_RESTART}    {LOG_AFTER_RESTART}

*** Keywords ***
Create resources
    [Documentation]    Create 2 VXLAN networks, subnets with 2 VMs each and a router. Ping all 4 VMs.
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNETS_RANGE}[1]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[0]    ${NET_1_VMS}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[1]    ${NET_2_VMS}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Router    router_1
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    router_1    ${interface}
    @{NET1_VM_IPS}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET2_VM_IPS}    ${NET2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET2_DHCP_IP}    None

Check resource connectivity
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_1    @{NET1_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_1    @{NET1_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_1    @{NET2_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_2    @{NET2_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_2    @{NET2_VM_IPS}[1]
    OpenStackOperations.Ping Vm From DHCP Namespace    upgrade_net_2    @{NET1_VM_IPS}[0]

Get info from br-int
    [Arguments]    ${openstack_node_ip}    ${log_file}
    [Documentation]    Get the OvsConfig, Flow entries and greoup info from OVS from the Openstack Node
    OperatingSystem.Create File    ${log_file}
    OperatingSystem.Append To File    ${log_file}    ${openstack_node_ip}
    SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${br_int_show}=    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl show br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${br_int_show}
    ${flows}=    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${flows}
    ${groups}=    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups br-int -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${groups}
    BuiltIn.Log File    ${log_file}
    SSHKeywords.Copy File To Remote System    ${OS_CONTROL_NODE_IP}    ${log_file}    ${log_file}
