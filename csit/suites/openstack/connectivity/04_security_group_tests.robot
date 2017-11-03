*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities, including negative tests.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Force Tags        skip_if_${SECURITY_GROUP_MODE}
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${SECURITY_GROUP}    sg-remote
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    sg-net1-vm-1    sg-net1-vm-2
@{NET_2_VM_INSTANCES}    sg-net2-vm-1
@{SUBNETS_RANGE}    61.0.0.0/24    62.0.0.0/24

*** Test Cases ***
Create VXLAN Network (network_1)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[0]

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Create VXLAN Network (network_2)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[1]

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]

Add TCP Allow Rules
    [Documentation]    Allow only TCP packets for this suite
    Security Group Create Without Default Security Rules    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Show    ${SECURITY_GROUP}

Create Vm Instances For network_1
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS_NAME}[0]    sg-net1-vm-1    ${OS_CMP1_HN}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS_NAME}[0]    sg-net1-vm-2    ${OS_CMP2_HN}    sg=${SECURITY_GROUP}

Create Vm Instances For network_2
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS_NAME}[1]    sg-net2-vm-1    ${OS_CMP2_HN}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    Collect VM IP Addresses    false    @{NET_2_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Set Suite Variable    ${NET1_DHCP_IP}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    Set Suite Variable    ${NET2_VM_IPS}
    Set Suite Variable    ${NET2_DHCP_IP}
    Should Not Contain    ${NET2_VM_IPS}    None
    Should Not Contain    ${NET2_DHCP_IP}    None
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
    Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    Neutron Security Group Show    ${SECURITY_GROUP}

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

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    router1

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    router1    ${interface}

Ping From Vm Instance1 To Vm Instance3
    [Documentation]    Login to the vm instance and test some operations
    ${VM3_LIST}    Create List    @{NET2_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM3_LIST}

Repeat Ping From Vm Instance1 To Vm Instance2 With a Router
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With a Router
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Add Additional Security Group To VMs
    [Documentation]    Add an additional security group to the VMs - this is done to test a different logic put in place for ports with multiple SGs
    Security Group Create Without Default Security Rules    additional-sg
    #TODO Remove this after the Newton jobs are removed, Openstack CLI with Newton lacks support to configure rule with remote_ip_prefix
    Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=@{NET1_DHCP_IP}[0]/32
    Neutron Security Group Show    additional-sg
    : FOR    ${VM}    IN    @{NET_1_VM_INSTANCES}
    \    Add Security Group To VM    ${VM}    additional-sg

Ping From DHCP To Vm Instance1
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]

Ping From DHCP To Vm Instance2
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]

Repeat Ping From Vm Instance1 To Vm Instance2 With additional SG
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With additional SG
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Remove The Rules From Additional Security Group
    Delete All Security Group Rules    additional-sg

No Ping From DHCP To Vm Instance1 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[0]

No Ping From DHCP To Vm Instance2 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    Ping From DHCP Should Not Succeed    network_1    @{NET1_VM_IPS}[1]

Add The Rules To Additional Security Group Again
    Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=@{NET1_DHCP_IP}[0]/32

Ping From DHCP To Vm Instance1 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[0]

Ping From DHCP To Vm Instance2 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    Ping Vm From DHCP Namespace    network_1    @{NET1_VM_IPS}[1]

Remove the additional Security Group from First Vm
    [Documentation]    Remove the additional Security group
    Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    additional-sg

Repeat Ping From Vm Instance1 To Vm Instance2 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Remove Router Interfaces
    [Documentation]    Delete the Router Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router1    ${interface}

Delete Router
    [Documentation]    Delete the Router
    Delete Router    router1

Repeat Ping From Vm Instance1 To Vm Instance2 With Router Removed
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With Router Removed
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Repeat Ping From Vm Instance1 To Vm Instance2 With network_2 VM Deleted
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    Create List    @{NET1_VM_IPS}[1]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With network_2 VM Deleted
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    Create List    @{NET1_VM_IPS}[0]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete SecurityGroups
    [Documentation]    Delete Security group
    Delete SecurityGroup    additional-sg
    Delete SecurityGroup    ${SECURITY_GROUP}

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    @{SUBNETS_NAME}[0]

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    @{SUBNETS_NAME}[1]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    Verify Flows Are Cleaned Up On All OpenStack Nodes