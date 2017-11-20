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
${SECURITY_GROUP}    sg_sg
@{NETWORKS_NAME}    sg_net_1    sg_net_2
@{SUBNETS_NAME}    sg_sub_1    sg_sub_2
${ROUTER_NAME}    sg_router
@{NET_1_VM_INSTANCES}    sg_net_1_vm_1    sg_net_1_vm_2
@{NET_2_VM_INSTANCES}    sg_net_2_vm_1
@{SUBNETS_RANGE}    51.0.0.0/24    52.0.0.0/24

*** Test Cases ***
Neutron Setup
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[0]
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS_NAME}
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS_NAME}

Add TCP Allow Rules
    [Documentation]    Allow only TCP packets for this suite
    OpenStackOperations.Security Group Create Without Default Security Rules    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Show    ${SECURITY_GROUP}

Create Vm Instances For net_1
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_INSTANCES}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_INSTANCES}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET_1_DHCP_IP}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]

No Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}    ping_should_succeed=False

No Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}    ping_should_succeed=False

Add Ping Allow Rules With Remote SG (only between VMs)
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Show    ${SECURITY_GROUP}

Verify No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]

Verify No Ping From DHCP To Vm Instance2
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]

Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    ${ROUTER_NAME}

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    ${ROUTER_NAME}    ${interface}

Ping From Vm Instance1 To Vm Instance3
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_2_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance1 To Vm Instance2 With a Router
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With a Router
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Add Additional Security Group To VMs
    [Documentation]    Add an additional security group to the VMs - this is done to test a different logic put in place for ports with multiple SGs
    OpenStackOperations.Security Group Create Without Default Security Rules    additional-sg
    #TODO Remove this after the Newton jobs are removed, Openstack CLI with Newton lacks support to configure rule with remote_ip_prefix
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=${NET_1_DHCP_IP}/32
    OpenStackOperations.Neutron Security Group Show    additional-sg
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Add Security Group To VM    ${vm}    additional-sg

Ping From DHCP To Vm Instance1
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]

Ping From DHCP To Vm Instance2
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]

Repeat Ping From Vm Instance1 To Vm Instance2 With additional SG
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With additional SG
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Remove The Rules From Additional Security Group
    OpenStackOperations.Delete All Security Group Rules    additional-sg

No Ping From DHCP To Vm Instance1 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]

No Ping From DHCP To Vm Instance2 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]

Add The Rules To Additional Security Group Again
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=${NET_1_DHCP_IP}/32

Ping From DHCP To Vm Instance1 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]

Ping From DHCP To Vm Instance2 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]

Remove the additional Security Group from First Vm
    OpenStackOperations.Remove Security Group From VM    @{NET_1_VM_INSTANCES}[0]    additional-sg

Repeat Ping From Vm Instance1 To Vm Instance2 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Remove Router Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    ${ROUTER_NAME}    ${interface}

Delete Router
    OpenStackOperations.Delete Router    ${ROUTER_NAME}

Repeat Ping From Vm Instance1 To Vm Instance2 With Router Removed
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With Router Removed
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Delete Vm Instances In net_2
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Repeat Ping From Vm Instance1 To Vm Instance2 With net_2 VM Deleted
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With net_2 VM Deleted
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Delete Vm Instances In net_1
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
