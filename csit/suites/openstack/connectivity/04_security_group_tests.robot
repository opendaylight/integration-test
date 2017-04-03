*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities, including negative tests.
...               These test cases are not so relevant for transparent mode, so each test case will be tagged with
...               "skip_if_transparent" to allow any underlying keywords to return with a PASS without risking
...               a false failure. The real value of this suite will be in stateful mode.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Force Tags        skip_if_transparent
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
    [Documentation]    Allow only TCP packets for this suite
    Neutron Security Group Create Without Default Security Rules    csit-remote-sgs
    Neutron Security Group Rule Create    csit-remote-sgs    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit-remote-sgs    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances For network_1
    [Documentation]    Create VM instances using flavor and image names for a network.
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
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]

No Ping From DHCP To Vm Instance2
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

No Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}    ping_should_succeed=False

No Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}    ping_should_succeed=False

Add Ping Allow Rules With Remote SG (only between VMs)
    Neutron Security Group Rule Create    csit-remote-sgs    direction=ingress    protocol=icmp    remote_group_id=csit-remote-sgs
    Neutron Security Group Rule Create    csit-remote-sgs    direction=egress    protocol=icmp    remote_group_id=csit-remote-sgs

Verify No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]

Verify No Ping From DHCP To Vm Instance2
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Add Additional Security Group To VMs
    [Documentation]    Add an additional security group to the VMs - this is done to test a different logic put in place for ports with multiple SGs
    Create Security Group Without Default Security Rules    additional-sg
    Neutron Security Group Rule Create    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=@{NET1_DHCP_IP}[0]/0
    : FOR    ${VM}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VM}    additional-sg

Ping From DHCP To Vm Instance1
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]

Ping From DHCP To Vm Instance2
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]

Repeat Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

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
