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
Resource          ../../../libraries/FederationUtils.robot

*** Variables ***
@{NETWORKS_NAME}    l2_network_1
@{SUBNETS_NAME}    l2_subnet_1
@{NET_1_VM_INSTANCES}    MyFirstInstance_1
@{SUBNETS_RANGE}    30.0.0.0/24
@{SITES_NAME}     site_a    site_b

*** Test Cases ***
Configure Federation For Sites A And B
    Put Federation Config Data On Specific Site    ${ODL_SYSTEM_1_IP}
    Put Federation Config Data On Specific Site    ${ODL_SYSTEM_2_IP}
    Config Federation Sites

Create Network On Each Site
    [Documentation]    Create same network with neutron request on each site.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Create Networks    ${i}

Create Subnets For l2_network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Create SubNet    l2_network_1    l2_subnet_1    @{SUBNETS_RANGE}[0]    site_index=${i}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Neutron Security Group Create    csit    site_index=${i}
    \    Neutron Security Group Rule Create    csit    site_index=${i}    direction=ingress    port_range_max=65535    port_range_min=1
    \    ...    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    \    Neutron Security Group Rule Create    csit    site_index=${i}    direction=egress    port_range_max=65535    port_range_min=1
    \    ...    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    \    Neutron Security Group Rule Create    csit    site_index=${i}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    \    Neutron Security Group Rule Create    csit    site_index=${i}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    \    Neutron Security Group Rule Create    csit    site_index=${i}    direction=ingress    port_range_max=65535    port_range_min=1
    \    ...    protocol=udp    remote_ip_prefix=0.0.0.0/0
    \    Neutron Security Group Rule Create    csit    site_index=${i}    direction=egress    port_range_max=65535    port_range_min=1
    \    ...    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances For l2_network_1
    [Documentation]    Create Vm instance using flavor and image names for a network.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Create Vm Instances    l2_network_1    ${NET_1_VM_INSTANCES}    sg=csit    site_index=${i}

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}    site_index=1
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}    site_index=2
    : FOR    ${index}    IN RANGE    1    5
    \    # creating 50s pool at 5s interval
    \    ${NET1_VM_IPS_SITE_A}    ${NET1_DHCP_IP_SITE_A}    Verify Ip    1    @{NET_1_VM_INSTANCES}
    \    ${NET1_VM_IPS_SITE_B}    ${NET1_DHCP_IP_SITE_B}    Verify Ip    2    @{NET_1_VM_INSTANCES}
    \    ${status}    ${message}    Run Keyword And Ignore Error    List Should Not Contain Value    ${NET1_VM_IPS_SITE_A}    ${NET1_VM_IPS_SITE_B}
    \    ...    None
    \    Exit For Loop If    '${status}' == 'PASS'
    \    BuiltIn.Sleep    5s
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    Write Commands Until Prompt    nova console-log ${vm}    30s
    Append To List    ${NET1_VM_IPS_SITE_A}    ${NET1_DHCP_IP_SITE_A}
    Append To List    ${NET1_VM_IPS_SITE_B}    ${NET1_DHCP_IP_SITE_B}
    Set Suite Variable    ${NET1_VM_IPS_SITE_A}
    Should Not Contain    ${NET1_VM_IPS_SITE_A}    None
    Set Suite Variable    ${NET1_VM_IPS_SITE_B}
    Should Not Contain    ${NET1_VM_IPS_SITE_B}    None
    [Teardown]    Run Keywords    Show Debugs    @{NET_1_VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Ping Vm Instance1 From Site A To Site B Should Not Succeed
    [Documentation]    Try to ping vms in 2 sites before connecting the sites- should not succeed.
    ${netId}=    Get Network Id    2    l2_network_1
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS_SITE_B}[0]    site_index=1    net_id=${netId}

Ping Vm Instance1 From Site B To Site A Should Not Succeed
    [Documentation]    Try to ping vms in 2 sites before connecting the sites- should not succeed.
    ${netId}=    Get Network Id    1    l2_network_1
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS_SITE_A}[0]    site_index=2    net_id=${netId}

Connect Networks
    [Documentation]    Connect networks between 2 sites.
    Connect Two Networks    1    2    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Ping Vm Instance1 In l2_network_1 From Site A To Site B
    [Documentation]    Check reachability of vm instances by pinging to them from one site to another.
    ${netId}=    Get Network Id    2    l2_network_1
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS_SITE_B}[0]    site_index=1    net_id=${netId}

Ping Vm Instance1 In l2_network_1 From Site B To Site A
    [Documentation]    Check reachability of vm instances by pinging to them from one site to another.
    ${netId}=    Get Network Id    1    l2_network_1
    Ping Vm From DHCP Namespace    l2_network_1    @{NET1_VM_IPS_SITE_A}[0]    site_index=2    net_id=${netId}

Connectivity Tests From Vm Instance1 In Site A To Vm Instance1 In Site B
    [Documentation]    Login to the vm instance using generated key pair.
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS_SITE_A}[0]    ${NET1_VM_IPS_SITE_B}    site_index=1

Connectivity Tests From Vm Instance1 In Site B To Vm Instance1 In Site A
    [Documentation]    Login to the vm instance using generated key pair.
    Test Operations From Vm Instance    l2_network_1    @{NET1_VM_IPS_SITE_B}[0]    ${NET1_VM_IPS_SITE_A}    site_index=2

Disconnect Two Networks
    [Documentation]    disconnect networks between 2 sites.
    Disconnect Two Networks    1    2    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Ping Vm Instance1 From Site A To Site B Should Not Succeed Again
    [Documentation]    Try to ping vms in 2 sites before connecting the sites- should not succeed.
    ${netId}=    Get Network Id    2    l2_network_1
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS_SITE_B}[0]    site_index=1    net_id=${netId}

Ping Vm Instance1 From Site B To Site A Should Not Succeed Again
    [Documentation]    Try to ping vms in 2 sites before connecting the sites- should not succeed.
    ${netId}=    Get Network Id    1    l2_network_1
    Ping From DHCP Should Not Succeed    l2_network_1    @{NET1_VM_IPS_SITE_A}[0]    site_index=2    net_id=${netId}

Delete Vm Instances From Both Sites
    [Documentation]    Delete Vm instances.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Delete Vm Instances    ${i}

Delete SecurityGroup From Both Sites
    [Documentation]    Delete SecurityGroups from each site.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Delete SecurityGroup    csit    site_index=${i}

Delete Sub Networks In l2_network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Delete SubNet    l2_subnet_1    site_index=${i}

Delete Network From Each Site
    [Documentation]    Delete Networks from each site with neutron request.
    ${count}    Get Length    ${SITES_NAME}
    : FOR    ${i}    IN RANGE    1    ${count}+1
    \    Delete Networks    ${i}
