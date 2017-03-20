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
@{NETWORKS_NAME}    l2_network_1    l2_network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1    MyThirdInstance_1
@{NET_2_VM_INSTANCES}    MyFirstInstance_2    MySecondInstance_2    MyThirdInstance_2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
${network1_vlan_id}    1235

*** Test Cases ***
Create VLAN Network @{NETWORKS_NAME}[0]
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[0]    --provider:network_type=vlan --provider:physical_network=${PUBLIC_PHYSICAL_NETWORK} --provider:segmentation_id=${network1_vlan_id}

Create VXLAN Network @{NETWORKS_NAME}[1]
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[1]

Create Subnets For l2_network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Create Subnets For l2_network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    csit
    Neutron Security Group Rule Create    csit    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    csit    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances For l2_network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_1    ${NET_1_VM_INSTANCES}    sg=csit

Create Vm Instances For l2_network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_2    ${NET_2_VM_INSTANCES}    sg=csit

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    : FOR    ${index}    IN RANGE    1    5
    \    # creating 50s pool at 5s interval
    \    ${NET1_VM_IPS}    @{NET1_DHCP_IP}    Verify VMs Received DHCP Lease    @{NET_1_VM_INSTANCES}
    \    ${NET2_VM_IPS}    @{NET2_DHCP_IP}    Verify VMs Received DHCP Lease    @{NET_2_VM_INSTANCES}
    \    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}    ${NET2_VM_IPS}    ${NET1_DHCP_IP}    ${NET2_DHCP_IP}
    \    ${status}    ${message}    Run Keyword And Ignore Error    List Should Not Contain Value    ${VM_IPS}    None
    \    Exit For Loop If    '${status}' == 'PASS'
    \    BuiltIn.Sleep    5s
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    \    Write Commands Until Prompt    nova console-log ${vm}    30s
    Append To List    ${NET1_VM_IPS}    @{NET1_DHCP_IP}[0]
    Set Suite Variable    ${NET1_VM_IPS}
    Append To List    ${NET2_VM_IPS}    @{NET2_DHCP_IP}[0]
    Set Suite Variable    ${NET2_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET2_VM_IPS}    None
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Ping Vm Instance1 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[0]

Ping Vm Instance2 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[1]

Ping Vm Instance3 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS}[2]

Ping Vm Instance1 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    @{NET2_VM_IPS}[0]

Ping Vm Instance2 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    @{NET2_VM_IPS}[1]

Ping Vm Instance3 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    @{NET2_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In l2_network_1
    [Documentation]    Login to the vm instance and test some operations
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[0]    ${NET1_VM_IPS}

Connectivity Tests From Vm Instance2 In l2_network_1
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[1]    ${NET1_VM_IPS}

Connectivity Tests From Vm Instance3 In l2_network_1
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS}[2]    ${NET1_VM_IPS}

Connectivity Tests From Vm Instance1 In l2_network_2
    [Documentation]    Login to the vm instance and test operations
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[0]    ${NET2_VM_IPS}

Connectivity Tests From Vm Instance2 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[1]    ${NET2_VM_IPS}

Connectivity Tests From Vm Instance3 In l2_network_2
    [Documentation]    Login to the vm instance using generated key pair.
    Test Operations From Vm Instance    l2_network_2    @{NET2_VM_IPS}[2]    ${NET2_VM_IPS}

Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance_1

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping From DHCP Should Not Succeed    l2_network_1    @{NET_1_VM_IPS}[0]

Delete Vm Instances In l2_network_1
    [Documentation]    Delete Vm instances using instance names in l2_network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In l2_network_2
    [Documentation]    Delete Vm instances using instance names in l2_network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Delete Sub Networks In l2_network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_1

Delete Sub Networks In l2_network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
