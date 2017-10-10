*** Settings ***
Documentation     Test suite to verify security groups basic and advanced functionalities, including negative tests.
...               These test cases are not so relevant for transparent mode, so each test case will be tagged with
...               "skip_if_transparent" to allow any underlying keywords to return with a PASS without risking
...               a false failure. The real value of this suite will be in stateful mode.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
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
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    sg_sg
@{NETWORKS}       sg_net_1    sg_net_2
@{SUBNETS}        sg_sub_1    sg_sub_2
${ROUTER}         sg_router
@{NET_1_VMS}      sg_net_1_vm_1    sg_net_1_vm_2
@{NET_2_VMS}      sg_net_2_vm_1
@{SUBNET_CIDRS}    51.0.0.0/24    52.0.0.0/24

*** Test Cases ***
Neutron Setup
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Add TCP Allow Rules
    [Documentation]    Allow only TCP packets for this suite
    OpenStackOperations.Security Group Create Without Default Security Rules    ${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Show    ${SECURITY_GROUP}

Create Vm Instances For net_1
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET_1_DHCP_IP}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]

No Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}    ping_should_succeed=False

No Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}    ping_should_succeed=False

Add Ping Allow Rules With Remote SG (only between VMs)
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_group_id=${SECURITY_GROUP}
    OpenStackOperations.Neutron Security Group Show    ${SECURITY_GROUP}

Verify No Ping From DHCP To Vm Instance1
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

Verify No Ping From DHCP To Vm Instance2
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]

Ping From Vm Instance1 To Vm Instance2
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Ping From Vm Instance2 To Vm Instance1
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    ${ROUTER}

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}

Ping From Vm Instance1 To Vm Instance3
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_2_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance1 To Vm Instance2 With a Router
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With a Router
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Add Additional Security Group To VMs
    [Documentation]    Add an additional security group to the VMs - this is done to test a different logic put in place for ports with multiple SGs
    OpenStackOperations.Security Group Create Without Default Security Rules    additional-sg
    #TODO Remove this after the Newton jobs are removed, Openstack CLI with Newton lacks support to configure rule with remote_ip_prefix
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=${NET_1_DHCP_IP}/32
    OpenStackOperations.Neutron Security Group Show    additional-sg
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Add Security Group To VM    ${vm}    additional-sg

Ping From DHCP To Vm Instance1
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

Ping From DHCP To Vm Instance2
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]

Repeat Ping From Vm Instance1 To Vm Instance2 With additional SG
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With additional SG
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Test Connection when Rules Change Dynamically
    [Documentation]    Initiate ping from DHCP to VM instance and remove security rules
    ...    dynamically check the communication has stopped after removing the security group rules.
    ${net_id}=    Get Net Id    @{NETWORKS}[0]
    Get ControlNode Connection
    ${output}=    Write    sudo ip netns exec qdhcp-${net_id} ping @{NET_1_VM_IPS}[0]
    Delete All Security Group Rules    additional-sg
    Read    delay=10s
    Write_Bare_Ctrl_C
    ${output}=    Read Until    packet loss
    Should Not Contain    ${output}    0% packet loss

No Ping From DHCP To Vm Instance1 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

No Ping From DHCP To Vm Instance2 With Additional Security Group Rules Removed
    [Documentation]    Check non-reachability of vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]

Add The Rules To Additional Security Group Again
    OpenStackOperations.Neutron Security Group Rule Create Legacy Cli    additional-sg    direction=ingress    protocol=icmp    remote_ip_prefix=${NET_1_DHCP_IP}/32

Ping From DHCP To Vm Instance1 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

Ping From DHCP To Vm Instance2 After Rules Are Added Again
    [Documentation]    Check reachability of vm instances by pinging to them from DHCP.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]

Remove the additional Security Group from First Vm
    OpenStackOperations.Remove Security Group From VM    @{NET_1_VMS}[0]    additional-sg

Repeat Ping From Vm Instance1 To Vm Instance2 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With Additional SG Removed From Vm1
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Remove Router Interfaces
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${interface}

Delete Router
    OpenStackOperations.Delete Router    ${ROUTER}

Repeat Ping From Vm Instance1 To Vm Instance2 With Router Removed
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With Router Removed
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Delete Vm Instances In net_2
    : FOR    ${vm}    IN    @{NET_2_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Repeat Ping From Vm Instance1 To Vm Instance2 With net_2 VM Deleted
    [Documentation]    Login to the vm instance and test some operations
    ${vm_ips}    BuiltIn.Create List    @{NET_1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${vm_ips}

Repeat Ping From Vm Instance2 To Vm Instance1 With net_2 VM Deleted
    [Documentation]    Login to the vm instance and test operations
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${vm_ips}

Delete Vm Instances In net_1
    : FOR    ${VmElement}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Security Groups
    OpenStackOperations.Delete SecurityGroup    additional-sg
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
