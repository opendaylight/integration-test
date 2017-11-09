*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities, including negative tests.
...               These test cases are not so relevant for transparent mode, so each test case will be tagged with
...               "skip_if_transparent" to allow any underlying keywords to return with a PASS without risking
...               a false failure. The real value of this suite will be in stateful mode.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Force Tags        skip_if_${SECURITY_GROUP_MODE}
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    sg-remote
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{ROUTERS_NAME}    router1
@{NET_1_VM_INSTANCES}    sg-net1-vm-1    sg-net1-vm-2
@{NET_2_VM_INSTANCES}    sg-net2-vm-1
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24

*** Test Cases ***
Neutron Setup
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[0]
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS_NAME}
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Add TCP Allow Rules
    [Documentation]    Allow only TCP packets for this suite
    OpenStackOperations.Security Group Create Without Default Security Rules    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Show    ${SECURITY_GROUP}

Create Vm Instances For network_1
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=${SECURITY_GROUP}

Create Vm Instances For network_2
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_INSTANCES}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Poll VM Is ACTIVE    ${vm}
    ${status}    ${message}    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OpenStackOperations.Collect VM IP Addresses
    ...    true    @{NET_1_VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    OpenStackOperations.Collect VM IP Addresses    false    @{NET_1_VM_INSTANCES}
    ${NET2_VM_IPS}    ${NET2_DHCP_IP}    OpenStackOperations.Collect VM IP Addresses    false    @{NET_2_VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${NET_1_VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    BuiltIn.Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Should Not Contain    @{VM_IPS}[${index}]    None
    \    BuiltIn.Run Keyword If    '${status}' == 'FAIL'    DevstackUtils.Write Commands Until Prompt    openstack console log show @{VM_INSTANCES}[${index}]    30s
    BuiltIn.Set Suite Variable    ${NET1_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET1_DHCP_IP}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_DHCP_IP}    None
    BuiltIn.Set Suite Variable    ${NET2_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET2_DHCP_IP}
    BuiltIn.Should Not Contain    ${NET2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET2_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]

No Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${vms}    ping_should_succeed=False

No Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${vms}    ping_should_succeed=False

Add Ping Allow Rules With Remote SG (only between VMs)
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Show    ${SECURITY_GROUP}

Verify No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]

Verify No Ping From DHCP To Vm Instance2
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]

Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${vms}

Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${vms}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    @{ROUTERS_NAME}[0]

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    @{ROUTERS_NAME}[0]    ${interface}

Ping From Vm Instance1 To Vm Instance3
    [Documentation]    Login to the vm instance and test some operations
    ${vms} =    BuiltIn.Create List    @{NET2_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${vms}

Repeat Ping From Vm Instance1 To Vm Instance2 With a Router
    [Documentation]    Login to the vm instance and test some operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${vms}

Repeat Ping From Vm Instance2 To Vm Instance1 With a Router
    [Documentation]    Login to the vm instance and test operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${vms}

Add Additional Security Group To VMs
    [Documentation]    Add an additional security group to the VMs - this is done to test a different logic put in place for ports with multiple SGs
    OpenStackOperations.Security Group Create Without Default Security Rules    additional-sg
    #TODO Remove this after the Newton jobs are removed, Openstack CLI with Newton lacks support to configure rule with remote_ip_prefix
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=@{NET1_DHCP_IP}[0]/32
    OpenStackOperations.Neutron Security Group Show    additional-sg
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Add Security Group To VM    ${vms}    additional-sg

Ping From DHCP To Vm Instance1
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]

Ping From DHCP To Vm Instance2
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]

Repeat Ping From Vm Instance1 To Vm Instance2 With additional SG
    [Documentation]    Login to the vm instance and test some operations
    ${vms}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${vms}

Repeat Ping From Vm Instance2 To Vm Instance1 With additional SG
    [Documentation]    Login to the vm instance and test operations
    ${vms}    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${vms}

Remove The Rules From Additional Security Group
    OpenStackOperations.Delete All Security Group Rules    additional-sg

No Ping From DHCP To Vm Instance1 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]

No Ping From DHCP To Vm Instance2 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]

Add The Rules To Additional Security Group Again
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=@{NET1_DHCP_IP}[0]/32

Ping From DHCP To Vm Instance1 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]

Ping From DHCP To Vm Instance2 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]

Remove the additional Security Group from First Vm
    OpenStackOperations.Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    additional-sg

Repeat Ping From Vm Instance1 To Vm Instance2 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test some operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${vms}

Repeat Ping From Vm Instance2 To Vm Instance1 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test operations
    ${vms} =    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${vms}

Remove Router Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    @{ROUTERS_NAME}[0]    ${interface}

Delete Router
    OpenStackOperations.Delete Router    @{ROUTERS_NAME}[0]

Repeat Ping From Vm Instance1 To Vm Instance2 With Router Removed
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With Router Removed
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Delete Vm Instances In network_2
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Repeat Ping From Vm Instance1 To Vm Instance2 With network_2 VM Deleted
    [Documentation]    Login to the vm instance and test some operations
    ${VM2_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[0]    ${VM2_LIST}

Repeat Ping From Vm Instance2 To Vm Instance1 With network_2 VM Deleted
    [Documentation]    Login to the vm instance and test operations
    ${VM1_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[1]    ${VM1_LIST}

Delete Vm Instances In network_1
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Security Groups
    OpenStackOperations.Delete SecurityGroup    additional-sg
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

*** Keywords ***
Suite Teardown
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${subnet}    IN    @{SUBNETS_NAME}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete SubNet    ${subnet}
    : FOR    ${network}    IN    @{NETWORKS_NAME}
    \    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete Network    ${network}
    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete SecurityGroup    additional-sg
    BuiltIn.Run Keyword And Ignore Error    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
    SSHLibrary.Close All Connections
