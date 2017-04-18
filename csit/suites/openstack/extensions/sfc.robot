*** Settings ***
Documentation     Test suite to verify SFC configuration and packet flows.
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
@{VM_INSTANCES}    sf1    sf2    sf3    source_vm    dest_vm
@{SUBNETS_RANGE}    30.0.0.0/24
@{PORTS}          p1in    p1out    p2in    p2out    p3in    p3out    source_vm_port
...               dest_vm_port

*** Test Cases ***
Create VXLAN Network (network_1)
    [Documentation]    Create Network with neutron request.
    Create Network    @{NETWORKS_NAME}[0]

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Add Allow All Rules
    [Documentation]    Allow all packets for this suite
    Neutron Security Group Create    sg-sfc
    Neutron Security Group Rule Create    sg-sfc    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-sfc    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-sfc    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-sfc    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-sfc    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-sfc    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Documentation]    Precreate neutron ports to be used for SFC VMs
    : FOR    ${port}    IN    @{PORTS}
    \    Create Port    @{NETWORKS_NAME}[0]    ${port}    sg=sg-sfc

Create Vm Instances
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instance With Ports    p1in    p1out    sf1    sg=sg-sfc
    Create Vm Instance With Ports    p2in    p2out    sf2    sg=sg-sfc
    Create Vm Instance With Ports    p3in    p3out    sf3    sg=sg-sfc
    Create Vm Instance With Port    source_vm_port    source_vm    sg=sg-sfc
    Create Vm Instance With Port    dest_vm_port    dest_vm    sg=sg-sfc

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

Create Flow Classifiers
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    Create SFC Flow Classifier    FC_http    @{NET1_VM_IPS}[3]    @{NET1_VM_IPS}[4]    tcp    80    source_vm_port

Create Port Pairs
    [Documentation]    Create SFC Port Pairs
    Create SFC Port Pair    PP1    p1in    p1out
    Create SFC Port Pair    PP2    p2in    p2out
    Create SFC Port Pair    PP3    p3in    p3out

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    Create SFC Port Pair Group With Two Pairs    PG1    PP1    PP2
    Create SFC Port Pair Group    PG2    PP3

Create Port Chain
    [Documentation]    Create SFC Port Chain using two port groups an classifier created previously
    Create SFC Port Chain    PC1    PG1    PG2    FC_http

Start Web Server On Destination VM
    [Documentation]    Start a simple web server on the destination VM
    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[4]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server" | sudo nc -l -p 80 ; done &

Add Static Routing On Service Function VMs
    [Documentation]    Enable eth1 and add static routing between the ports on the SF VMs
    : FOR    ${INDEX}    IN RANGE    0    2
    \    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[${INDEX}]    sudo sh -c 'echo "auto eth1" >> /etc/network/interfaces'
    \    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[${INDEX}]    sudo sh -c 'echo "iface eth1 inet dhcp" >> /etc/network/interfaces'
    \    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[${INDEX}]    sudo /etc/init.d/S40network restart
    \    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[${INDEX}]    sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
    \    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[${INDEX}]    sudo ip route add @{NET1_VM_IPS}[3] dev eth0
    \    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[${INDEX}]    sudo ip route add @{NET1_VM_IPS}[4] dev eth1

Connectivity Tests From Vm Instance1 In network_1
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance
    # FIXME need to somehow verify it goes through SFs (flows?)
    ${DEST_VM_LIST}    Create List    @{NET1_VM_IPS}[4]
    Test Operations From Vm Instance    network_1    @{NET1_VM_IPS}[3]    ${DEST_VM_LIST}
    Execute Command on VM Instance    @{NETWORKS_NAME}[0]    @{NET1_VM_IPS}[3]    curl http://@{NET1_VM_IPS}[4]

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete All SFC Objects
    [Documentation]    Delete all previously created SFC objects
    Delete SFC Port Chain    PC1
    Delete SFC Port Pair Group    PG1
    Delete SFC Port Pair Group    PG2
    Delete SFC Port Pair    PP1
    Delete SFC Port Pair    PP2
    Delete SFC Port Pair    PP3
    Delete SFC Flow Classifier    FC_http

Delete Neutron Ports
    [Documentation]    Delete neutron ports that were used for SFC VMs
    : FOR    ${port}    IN    @{PORTS}
    \    Delete Port    ${port}

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_1

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
