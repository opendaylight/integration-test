*** Settings ***
Documentation     Test suite to verify SFC configuration and packet flows.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
...               AND    OpenStackOperations.Get Test Teardown Debugs For SFC
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${SECURITY_GROUP}    sg-sfc
@{NETWORKS}       network_1
@{SUBNETS}        l2_subnet_1
@{NET_1_VMS}      sf1    sf2    source_vm    dest_vm
@{SUBNET_CIDRS}    30.0.0.0/24
@{PORTS}          sf1_port    sf2_port    source_vm_port    dest_vm_port

*** Test Cases ***
Create VXLAN Network net_1
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[0]

Create Subnets For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]

Add Allow All Rules
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Neutron Ports
    [Documentation]    Precreate neutron ports to be used for SFC VMs
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port}    sg=${SECURITY_GROUP}

Create Vm Instances
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instance With Port    sf1_port    sf1    sg=${SECURITY_GROUP}
    Create Vm Instance With Port    sf2_port    sf2    sg=${SECURITY_GROUP}
    Create Vm Instance With Port    source_vm_port    source_vm    sg=${SECURITY_GROUP}
    Create Vm Instance With Port    dest_vm_port    dest_vm    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET1_VM_IPS}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Flow Classifiers
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_http    @{NET1_VM_IPS}[2]    @{NET1_VM_IPS}[3]    tcp    80    source_vm_port
    OpenStackOperations.Create SFC Flow Classifier    FC_http_alt    @{NET1_VM_IPS}[2]    @{NET1_VM_IPS}[3]    tcp    82    source_vm_port

Create Port Pairs
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    PP1    sf1_port    sf1_port
    OpenStackOperations.Create SFC Port Pair    PP2    sf2_port    sf2_port

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    PG1    PP1
    OpenStackOperations.Create SFC Port Pair Group    PG2    PP2

Create Port Chain
    [Documentation]    Create SFC Port Chain using two port groups an classifier created previously
    OpenStackOperations.Create SFC Port Chain    PC1    PG1    PG2    FC_http

Start Web Server On Destination VM
    [Documentation]    Start a simple web servers on the destination VM
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[3]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server80" | sudo nc -l -p 80 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[3]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server82" | sudo nc -l -p 82 ; done &

Add Static Routing On Service Function VMs
    [Documentation]    Enable eth1 and add static routing between the ports on the SF VMs
    [Tags]    exclude
    : FOR    ${index}    IN RANGE    0    1
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[${index}]    sudo sh -c 'echo "auto eth1" >> /etc/network/interfaces'
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[${index}]    sudo sh -c 'echo "iface eth1 inet dhcp" >> /etc/network/interfaces'
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[${index}]    sudo /etc/init.d/S40network restart
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[${index}]    sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[${index}]    sudo ip route add @{NET1_VM_IPS}[2] dev eth0
    \    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[${index}]    sudo ip route add @{NET1_VM_IPS}[3] dev eth1

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance
    # FIXME need to somehow verify it goes through SFs (flows?)
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[3]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    ${DEST_VM_LIST}
    ${CURL_OP}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    curl -v --connect-timeout 20 http://@{NET1_VM_IPS}[3]:82
    BuiltIn.Should Contain    ${CURL_OP}    server82
    ${CURL_OP}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    curl -v --connect-timeout 20 http://@{NET1_VM_IPS}[3]
    BuiltIn.Should Not Contain    ${CURL_OP}    server80

Add New Flow Classifier To Port Chain
    OpenStackOperations. Modify SFC Port Chain Add Flow Classifier    PC1    FC_http_alt

Connectivity Tests From Vm Instance1 In net_1 After Adding Flow Classifier To Port Chain
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance
    # FIXME need to somehow verify it goes through SFs (flows?)
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[3]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    ${DEST_VM_LIST}
    ${CURL_OP}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    curl -v --connect-timeout 20 http://@{NET1_VM_IPS}[3]
    BuiltIn.Should Not Contain    ${CURL_OP}    server80
    ${CURL_OP}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    curl -v --connect-timeout 20 http://@{NET1_VM_IPS}[3]:82
    BuiltIn.Should Not Contain    ${CURL_OP}    server82

Remove Flow Classifier From Port Chain
    OpenStackOperations. Modify SFC Port Chain Remove Flow Classifier    PC1    FC_http

Connectivity Tests From Vm Instance1 In net_1 After Removing Flow Classifier From Port Chain
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance
    # FIXME need to somehow verify it goes through SFs (flows?)
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[3]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    ${DEST_VM_LIST}
    ${CURL_OP}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    curl -v --connect-timeout 20 http://@{NET1_VM_IPS}[3]
    BuiltIn.Should Contain    ${CURL_OP}    web-server80
    ${CURL_OP}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[2]    curl -v --connect-timeout 20 http://@{NET1_VM_IPS}[3]:82
    BuiltIn.Should Not Contain    ${CURL_OP}    web-server82

Delete Configurations
    [Documentation]    Delete all elements that were created in the test case section. These are done
    ...    in a local keyword so this can be called as part of the Suite Teardown. When called as part
    ...    of the Suite Teardown, all steps will be attempted. This prevents robot framework from bailing
    ...    on the rest of a test case if one step intermittently has trouble and fails. The goal is to attempt
    ...    to leave the test environment as clean as possible upon completion of this suite.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    OpenStackOperations.Delete SFC Port Chain    PC1
    OpenStackOperations.Delete SFC Port Pair Group    PG1
    OpenStackOperations.Delete SFC Port Pair Group    PG2
    OpenStackOperations.Delete SFC Port Pair    PP1
    OpenStackOperations.Delete SFC Port Pair    PP2
    OpenStackOperations.Delete SFC Flow Classifier    FC_http
    OpenStackOperations.Delete SFC Flow Classifier    FC_http_alt
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Delete Port    ${port}
    OpenStackOperations.Delete SubNet    l2_subnet_1
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
