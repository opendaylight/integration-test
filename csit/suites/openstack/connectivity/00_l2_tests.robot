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

*** Variables ***
@{NETWORKS_NAME}    l2_network_0
@{SUBNETS_NAME}    l2_subnet_0
@{NET_1_VM_INSTANCES}    MyFirstInstance_1
@{SUBNETS_RANGE}    20.0.0.0/24
@{NET1_VM_IPS}      20.0.0.3

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For l2_network_0
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_0    l2_subnet_0    @{SUBNETS_RANGE}[0]

Setup SSH
    Setup Passwordless ssh       ${OS_COMPUTE_1_IP}     ${OS_COMPUTE_2_IP}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    csit
    Neutron Security Group Rule Create    csit    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances For l2_network_0
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_0    ${NET_1_VM_INSTANCES}    sg=csit
    Sleep     60s

Check Vm Instances Have Ip Address
   Show Debugs     @{NET_1_VM_INSTANCES}

Ping Vm Instance1 In l2_network_0
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_0    @{NET1_VM_IPS}[0]

Connectivity Tests From Vm Instance1 In l2_network_0
    [Documentation]    Login to the vm instance and test some operations
    Test Operations From Vm Instance    l2_network_0    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Migrate VMs
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \     Migrate VM      ${vm}

Check Vm Instances Have Ip Address
   Show Debugs     @{NET_1_VM_INSTANCES}

Ping2 Vm Instance1 In l2_network_0
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_0    @{NET1_VM_IPS}[0]

Connectivity2 Tests From Vm Instance1 In l2_network_0
    [Documentation]    Login to the vm instance and test some operations
    Test Operations From Vm Instance    l2_network_0    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance_1

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping From DHCP Should Not Succeed    l2_network_0    @{NET_1_VM_IPS}[0]

Delete Sub Networks In l2_network_0
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_0

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
