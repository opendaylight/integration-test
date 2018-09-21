*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    l2_sg
@{NETWORKS}       l2_net_1    l2_net_2
@{SUBNETS}        l2_sub_1    l2_sub_2
@{NET_1_VMS}      l2_net_1_vm_1    l2_net_1_vm_2    l2_net_1_vm_3
@{NET_2_VMS}      l2_net_2_vm_1    l2_net_2_vm_2    l2_net_2_vm_3
@{SUBNET_CIDRS}    21.0.0.0/24    22.0.0.0/24
${NET_1_VLAN_ID}    1121

*** Test Cases ***
Ping Vm Instance1 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Login to the vm instance and test some operations
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${NET_1_VM_IPS}

CHECK CIRROS PROBLEMS 1
    ${conn_id} =    SSHLibrary.Open Connection    ${OS_CNTL_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    Utils.Write Commands Until Expected Prompt    sudo netstat -tulpn     ${OS_SYSTEM_PROMPT}
    Utils.Write Commands Until Expected Prompt    sudo iptables -L     ${OS_SYSTEM_PROMPT}
    Utils.Write Commands Until Expected Prompt    sudo dmesg -Tr     ${OS_SYSTEM_PROMPT}
    Utils.Write Commands Until Expected Prompt    sudo journalctl -xe     ${OS_SYSTEM_PROMPT}
    Utils.Run Command On Remote System    ${OS_CNTL_IP}
    OpenStackOperations.Get ControlNode Connection
    Utils.Write Commands Until Expected Prompt    \n     ${OS_SYSTEM_PROMPT}


Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names. Also remove the VM from the
    ...    list so that later cleanup will not try to delete it.
    OpenStackOperations.Delete Vm Instance    @{NET_1_VMS}[0]
    Remove From List    ${NET_1_VMS}    0

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

*** Keywords ***
Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Network    @{NETWORKS}[0]    --provider-network-type vlan --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK} --provider-segment ${NET_1_VLAN_ID}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs
