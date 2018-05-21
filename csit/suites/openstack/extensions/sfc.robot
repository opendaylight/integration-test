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
@{NET_1_VMS}      sf1    sf2    sf3    source_vm    dest_vm
@{SUBNET_CIDRS}    30.0.0.0/24
@{PORTS}          p1in    p1out    p2in    p2out    p3in    p3out    source_vm_port
...               dest_vm_port

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
    Create Vm Instance With Ports    p1in    p1out    sf1    sg=${SECURITY_GROUP}     image=centos6
    Create Vm Instance With Ports    p2in    p2out    sf2    sg=${SECURITY_GROUP}     image=centos6
    Create Vm Instance With Ports    p3in    p3out    sf3    sg=${SECURITY_GROUP}     image=centos6
    Create Vm Instance With Port    source_vm_port    source_vm    sg=${SECURITY_GROUP}
    Create Vm Instance With Port    dest_vm_port    dest_vm    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    ${NET1_CIRROS_VMS}    BuiltIn.Create List      source_vm      dest_vm
    @{NET1_VM_IPS}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET1_CIRROS_VMS}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_DHCP_IP}    None
    ${SFC1_MAC}     OpenStackOperations.Get Port Mac     p1in 
    ${SFC1_IP}     OpenStackOperations.Get Port Ip     p1in 
    BuiltIn.Wait Until Keyword Succeeds    500s    10s       Get CentOs Instance IP     sf1    ${SFC1_MAC}     ${SFC1_IP}
    ${SFC2_MAC}     OpenStackOperations.Get Port Mac     p2in 
    ${SFC2_IP}     OpenStackOperations.Get Port Ip     p2in 
    BuiltIn.Wait Until Keyword Succeeds    500s    10s       Get CentOs Instance IP     sf2    ${SFC2_MAC}     ${SFC2_IP}
    ${SFC3_MAC}     OpenStackOperations.Get Port Mac     p3in 
    ${SFC3_IP}     OpenStackOperations.Get Port Ip     p3in 
    BuiltIn.Wait Until Keyword Succeeds    500s    10s       Get CentOs Instance IP     sf3    ${SFC3_MAC}     ${SFC3_IP}
    BuiltIn.Set Suite Variable     ${SFC1_IP}
    BuiltIn.Set Suite Variable     ${SFC2_IP}
    BuiltIn.Set Suite Variable     ${SFC3_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Flow Classifiers
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_http    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    80    source_vm_port
    OpenStackOperations.Create SFC Flow Classifier    FC_81      @{NET1_VM_IPS}[1]    @{NET1_VM_IPS}[0]    tcp    81    source_vm_port
    OpenStackOperations.Create SFC Flow Classifier    FC_82      @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    82    source_vm_port
    OpenStackOperations.Create SFC Flow Classifier    FC_83      @{NET1_VM_IPS}[1]    @{NET1_VM_IPS}[0]    tcp    83    source_vm_port
    OpenStackOperations.Create SFC Flow Classifier    FC_84      @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    84    source_vm_port
    OpenStackOperations.Create SFC Flow Classifier    FC_85      @{NET1_VM_IPS}[1]    @{NET1_VM_IPS}[0]    tcp    85    source_vm_port

Create Port Pairs
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    PP1    p1in    p1out
    OpenStackOperations.Create SFC Port Pair    PP2    p2in    p2out
    OpenStackOperations.Create SFC Port Pair    PP3    p3in    p3out

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    PG1    PP1
    OpenStackOperations.Create SFC Port Pair Group    PG2    PP2
    OpenStackOperations.Create SFC Port Pair Group    PG3    PP3

Create Port Chain
    [Documentation]    Create SFC Port Chain using two port groups an classifier created previously
    OpenStackOperations.Create SFC Port Chain    PC1    PG1    FC_http    FC_81
    OpenStackOperations.Create SFC Port Chain    PC2    PG2    FC_82      FC_83
    OpenStackOperations.Create SFC Port Chain    PC3    PG3    FC_84      FC_85

Start Web Server On Destination VM
    [Documentation]    Start a simple web server on the destination VM
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server80" | sudo nc -l -p 80 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server81" | sudo nc -l -p 81 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server82" | sudo nc -l -p 82 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server83" | sudo nc -l -p 83 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server84" | sudo nc -l -p 84 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server85" | sudo nc -l -p 85 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server80" | sudo nc -l -p 80 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server81" | sudo nc -l -p 81 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server82" | sudo nc -l -p 82 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server83" | sudo nc -l -p 83 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server84" | sudo nc -l -p 84 ; done &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 24\r\n\r\nWelcome to web-server85" | sudo nc -l -p 85 ; done &

Configure Service Function VMs
    [Documentation]    Enable eth1 and add static routing between the ports on the SF VMs
    Copy File To CentOS VM Instance      @{NETWORKS}[0]     ${SFC1_IP}     /tmp/vxlan_tool.py
    Copy File To CentOS VM Instance      @{NETWORKS}[0]     ${SFC2_IP}     /tmp/vxlan_tool.py
    Copy File To CentOS VM Instance      @{NETWORKS}[0]     ${SFC3_IP}     /tmp/vxlan_tool.py
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]     ${SFC1_IP}    "sudo ifconfig eth1 up;sudo tc qdisc add dev eth1 root netem delay 600ms"
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]     ${SFC2_IP}    "sudo ifconfig eth1 up;sudo tc qdisc add dev eth1 root netem delay 600ms"
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]     ${SFC3_IP}    "sudo ifconfig eth1 up;sudo tc qdisc add dev eth1 root netem delay 600ms"
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]     ${SFC1_IP}    "nohup sudo python /tmp/vxlan_tool.py --do forward --interface eth0 --output eth1 --verbose off &"
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]     ${SFC2_IP}    "nohup sudo python /tmp/vxlan_tool.py --do forward --interface eth0 --output eth1 --verbose off &"
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]     ${SFC3_IP}    "nohup sudo python /tmp/vxlan_tool.py --do forward --interface eth0 --output eth1 --verbose off &"
  
Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance
    # FIXME need to somehow verify it goes through SFs (flows?)
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${DEST_VM_LIST}
    ${curl_resp_with_time}      OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    time -f "time taken is %e" curl http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp_with_time}    200
    ${last_line}        String.Get Lines Containing String      ${curl_resp_with_time}       "Time taken is"
    ${time_value}        String.Remove String      ${last_line}       "Time taken is "
    BuiltIn.Should Be True      ${time_value} >= 1
    ${curl_resp_with_time}      OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    time -f "time taken is %e" curl http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp_with_time}    200
    ${last_line}        String.Get Lines Containing String      ${curl_resp_with_time}       "Time taken is"
    ${time_value}        String.Remove String      ${last_line}       "Time taken is "
    BuiltIn.Should Be True      ${time_value} < 1
    

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
    OpenStackOperations.Delete SFC Port Pair    PP3
    OpenStackOperations.Delete SFC Flow Classifier    FC_http
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Delete Port    ${port}
    OpenStackOperations.Delete SubNet    l2_subnet_1
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
