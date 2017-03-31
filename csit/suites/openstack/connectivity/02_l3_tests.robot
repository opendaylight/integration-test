*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS_NAME}    network_1    network_2    network_3
@{SUBNETS_NAME}    subnet_1    subnet_2    subnet_3
@{NET_1_VM_INSTANCES}    l3_instance_net_1_1    l3_instance_net_1_2    l3_instance_net_1_3
@{NET_2_VM_INSTANCES}    l3_instance_net_2_1    l3_instance_net_2_2    l3_instance_net_2_3
@{NET_3_VM_INSTANCES}    l3_instance_net_3_1    l3_instance_net_3_2    l3_instance_net_3_3
@{SUBNETS_RANGE}    50.0.0.0/24    60.0.0.0/24    70.0.0.0/24
${network1_vlan_id}    1236

*** Test Cases ***
Create VLAN Network (network_1)
    [Documentation]    Create Network with neutron request.
    # in the case that the controller under test is using legacy netvirt features, vlan segmentation is not supported,
    # and we cannot create a vlan network. If those features are installed we will instead stick with vxlan.
    : FOR    ${feature_name}    IN    @{legacy_feature_list}
    \    ${feature_check_status}=    Run Keyword And Return Status    Verify Feature Is Installed    ${feature_name}
    \    Exit For Loop If    '${feature_check_status}' == 'True'
    Run Keyword If    '${feature_check_status}' == 'True'    Create Network    @{NETWORKS_NAME}[0]
    ...    ELSE    Create Network    @{NETWORKS_NAME}[0]    --provider:network_type=vlan --provider:physical_network=${PUBLIC_PHYSICAL_NETWORK} --provider:segmentation_id=${network1_vlan_id}

Create VXLAN Network (network_2)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[1]

Create VXLAN Network (network_3)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[2]

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]

Create Subnets For network_3
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    sg=csit

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_2    ${NET_2_VM_INSTANCES}    sg=csit

Create Vm Instances For network_3
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_3    ${NET_3_VM_INSTANCES}    sg=csit

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}    @{NET_3_VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_2_VM_INSTANCES}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_3_VM_INSTANCES}
    ${NET3_L3_VM_IPS}    ${NET3_DHCP_IP}    Collect VM IP Addresses    false    @{NET_3_VM_INSTANCES}
    ${NET2_L3_VM_IPS}    ${NET2_DHCP_IP}    Collect VM IP Addresses    false    @{NET_2_VM_INSTANCES}
    ${NET1_L3_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}    ${NET_2_VM_INSTANCES}    ${NET_3_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_L3_VM_IPS}    ${NET2_L3_VM_IPS}    ${NET3_L3_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_L3_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Set Suite Variable    ${NET2_L3_VM_IPS}
    Set Suite Variable    ${NET2_DHCP_IP}
    Set Suite Variable    ${NET3_L3_VM_IPS}
    Set Suite Variable    ${NET3_DHCP_IP}
    Should Not Contain    ${NET1_L3_VM_IPS}    None
    Should Not Contain    ${NET2_L3_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
    Should Not Contain    ${NET3_DHCP_IP}    None
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}    @{NET_3_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Create Routers
    [Documentation]    Create Router
    Create Router    router_1

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}

Ping Vm Instance1 In network_2 From network_1(vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_1    @{NET2_L3_VM_IPS}[0]

Ping Vm Instance2 In network_2 From network_1(vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_1    @{NET2_L3_VM_IPS}[1]

Ping Vm Instance3 In network_2 From network_1(vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_1    @{NET2_L3_VM_IPS}[2]

Ping Vm Instance1 In network_1 From network_2(vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_2    @{NET1_L3_VM_IPS}[0]

Ping Vm Instance2 In network_1 From network_2(vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_2    @{NET1_L3_VM_IPS}[1]

Ping Vm Instance3 In network_1 From network_2(vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_2    @{NET1_L3_VM_IPS}[2]

Ping Vm Instance1 In network_3 From network_2(vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_2    @{NET3_L3_VM_IPS}[0]

Ping Vm Instance2 In network_3 From network_2(vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_2    @{NET3_L3_VM_IPS}[1]

Ping Vm Instance3 In network_3 From network_2(vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Ping Vm From DHCP Namespace    network_2    @{NET3_L3_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In network_1
    [Documentation]    Login to the VM instance and test operations
    ${dst_list}=    Create List    @{NET1_L3_VM_IPS}    @{NET2_L3_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    network_1    @{NET1_L3_VM_IPS}[0]    ${dst_list}

Connectivity Tests From Vm Instance2 In network_1
    [Documentation]    Login to the vm instance and test operations
    ${dst_list}=    Create List    @{NET1_L3_VM_IPS}    @{NET2_L3_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    network_1    @{NET1_L3_VM_IPS}[1]    ${dst_list}

Connectivity Tests From Vm Instance3 In network_1
    [Documentation]    Login to the vm instance and test operations
    ${dst_list}=    Create List    @{NET1_L3_VM_IPS}    @{NET2_L3_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    network_1    @{NET1_L3_VM_IPS}[2]    ${dst_list}

Connectivity Tests From Vm Instance1 In network_2
    [Documentation]    Login to the vm instance and test operations
    ${dst_list}=    Create List    @{NET1_L3_VM_IPS}    @{NET2_L3_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    network_2    @{NET2_L3_VM_IPS}[0]    ${dst_list}

Connectivity Tests From Vm Instance2 In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_list}=    Create List    @{NET1_L3_VM_IPS}    @{NET2_L3_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    network_2    @{NET2_L3_VM_IPS}[1]    ${dst_list}

Connectivity Tests From Vm Instance3 In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_list}=    Create List    @{NET1_L3_VM_IPS}    @{NET2_L3_VM_IPS}
    Log    ${dst_list}
    Test Operations From Vm Instance    network_2    @{NET2_L3_VM_IPS}[2]    ${dst_list}

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_3
    [Documentation]    Delete Vm instances using instance names in network_3.
    : FOR    ${VmElement}    IN    @{NET_3_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}    @{NET_3_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    router_1

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_1

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_2

Delete Sub Networks In network_3
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_3

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
