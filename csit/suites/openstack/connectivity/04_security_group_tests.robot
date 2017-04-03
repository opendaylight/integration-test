*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
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
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
@{NETWORKS_NAME}    network_1
@{SUBNETS_NAME}    l2_subnet_1
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{SUBNETS_RANGE}    30.0.0.0/24

*** Test Cases ***
Create VXLAN Network (network_1)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[0]

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Add Ssh Allow Rules
    [Documentation]    Allow all TCP packets for this suite
    Neutron Security Group Create    csit-remote-sgs
    Neutron Security Group Rule Create    csit-remote-sgs    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit-remote-sgs    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    sg=csit-remote-sgs

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

No Ping Vm Instance1 In network_1
    [Tags]    skip_if_transparent
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]

No Ping Vm Instance2 In network_1
    [Tags]    skip_if_transparent
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

No Connectivity Tests From Vm Instance1 In network_1
    [Tags]    skip_if_transparent
    [Documentation]    Login to the vm instance and test some operations
    Test No Ping From Vm Instance    network_1    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]

No Connectivity Tests From Vm Instance2 In network_1
    [Tags]    skip_if_transparent
    [Documentation]    Login to the vm instance and test operations
    Test No Ping From Vm Instance    network_1    @{NET1_VM_IPS}[1]    @{NET1_VM_IPS}[0]

Add Ping Allow Rules With Remote SG (only between VMs)
    Neutron Security Group Rule Create    csit-remote-sgs    direction=ingress    protocol=icmp    remote_group_id=csit-remote-sgs
    Neutron Security Group Rule Create    csit-remote-sgs    direction=egress    protocol=icmp    remote_group_id=csit-remote-sgs

Verify No Ping Vm Instance1 In network_1
    [Tags]    skip_if_transparent
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]

Verify No Ping Vm Instance2 In network_1
    [Tags]    skip_if_transparent
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

Connectivity Tests From Vm Instance1 In network_1
    [Documentation]    Login to the vm instance and test some operations
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]

Connectivity Tests From Vm Instance2 In network_1
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    @{NET1_VM_IPS}[0]

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_1

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
