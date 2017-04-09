*** Settings ***
Documentation     Test suite to verify LBaaS configuration and packet flows.
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
@{VM_INSTANCES}    webserver
@{SUBNETS_RANGE}    30.0.0.0/24

*** Test Cases ***
Create VXLAN Network (network_1)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[0]

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Add Allow All Rules
    [Documentation]    Allow all packets for this suite
    Neutron Security Group Create    sg-lbaas
    Neutron Security Group Rule Create    sg-lbaas    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-lbaas    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-lbaas    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-lbaas    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-lbaas    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-lbaas    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0

Create Vm Instances
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM_INSTANCES}    sg=sg-lbaas

Check Vm Instances Have Ip Address
    [Documentation]    Test case to verify that all created VMs are ready and have received their ip addresses.
    ...    We are polling first and longest on the last VM created assuming that if it's received it's address
    ...    already the other instances should have theirs already or at least shortly thereafter.
    # first, ensure all VMs are in ACTIVE state.    if not, we can just fail the test case and not waste time polling
    # for dhcp addresses
    : FOR    ${vm}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    15s    5s    Verify VM Is ACTIVE    ${vm}
    ${status}    ${message}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    60s    5s    Collect VM IP Addresses
    ...    true    @{VM_INSTANCES}
    ${NET1_VM_IPS}    ${NET1_DHCP_IP}    Collect VM IP Addresses    false    @{VM_INSTANCES}
    ${VM_INSTANCES}=    Collections.Combine Lists    ${VM_INSTANCES}
    ${VM_IPS}=    Collections.Combine Lists    ${NET1_VM_IPS}
    ${LOOP_COUNT}    Get Length    ${VM_INSTANCES}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{VM_INSTANCES}[${index}]    30s
    Set Suite Variable    ${NET1_VM_IPS}
    Should Not Contain    ${NET1_VM_IPS}    None
    Should Not Contain    ${NET1_DHCP_IP}    None
    [Teardown]    Run Keywords    Show Debugs    @{VM_INSTANCES}
    ...    AND    Get Test Teardown Debugs

Create Load Balancer
    Create LBaaS Load Balancer    test-lb

Create Listener
    Create LBaaS Listener    test-lb-listener-http    test-lb    HTTP    80

Create Pool
    Create LBaaS Pool    test-lb-pool-http    test-lb-listener-http    HTTP    ROUND_ROBIN

Create Member
    Create LBaaS Member    member1    test-lb-pool-http    private-subnet    @{VM_IPS}[0]    80

Create Health Monitor
    Create LBaaS Health Monitor    test-lb-monitor    test-lb-pool-http    HTTP    5    2    10

Start Web Server On Destination VM
    [Documentation]    Start a simple web server on the destination VM
    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[4]    while true; do echo -e "HTTP/1.0 200 OK\r\n\r\nWelcome to $(hostname)" | sudo nc -l -p 80 ; done&

# Need to add tests using VIP - can add curl from DHCP to VIP, and/or add a floating IP to VIP and test curl to that
# Should also add multiple members

Delete All LBaaS Objects
    [Documentation]    Delete all previously created LBaaS objects
    Delete LBaaS Health Monitor    test-lb-monitor
    Delete LBaaS Member    member1
    Delete LBaaS Pool    test-lb-pool-http
    Delete LBaaS Listener    test-lb-listener-http
    Delete LBaaS Load Balancer    test-lb

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_1

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
