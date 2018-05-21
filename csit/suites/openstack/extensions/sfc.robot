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
@{NET_1_VMS}      sf1    sf2    sf3    sourcevm    destvm
@{SUBNET_CIDRS}    30.0.0.0/24
@{PORTS}          p1in    p1out    source_vm_port    dest_vm_port

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
    Update Port    p1in    additional_args=--no-security-group
    Update Port    p1in    additional_args=--disable-port-security
    Update Port    p1out    additional_args=--no-security-group
    Update Port    p1out    additional_args=--disable-port-security

Create Vm Instances
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instance With Ports    p1in    p1out    sf1    image=centos7    flavor=ds4G    sg=${SECURITY_GROUP}
    Create Vm Instance With Port And Key    source_vm_port    sourcevm    sg=${SECURITY_GROUP}    image=centos7    flavor=ds4G
    Create Vm Instance With Port And Key    dest_vm_port    destvm    sg=${SECURITY_GROUP}    image=centos7    flavor=ds4G

Check Vm Instances Have Ip Address
    ${SFC1_MAC}    OpenStackOperations.Get Port Mac    p1in
    ${SF1_IP}    OpenStackOperations.Get Port Ip    p1in
    BuiltIn.Wait Until Keyword Succeeds    500s    10s    OpenStackOperations.Get CentOs Instance IP    sf1    ${SFC1_MAC}    ${SF1_IP}
    BuiltIn.Set Suite Variable    ${SF1_IP}
    ${SRC_MAC}    OpenStackOperations.Get Port Mac    source_vm_port
    ${SRC_IP}    OpenStackOperations.Get Port Ip    source_vm_port
    BuiltIn.Wait Until Keyword Succeeds    500s    10s    OpenStackOperations.Get CentOs Instance IP    sourcevm    ${SRC_MAC}    ${SRC_IP}
    ${DEST_MAC}    OpenStackOperations.Get Port Mac    dest_vm_port
    ${DEST_IP}    OpenStackOperations.Get Port Ip    dest_vm_port
    BuiltIn.Wait Until Keyword Succeeds    500s    10s    OpenStackOperations.Get CentOs Instance IP    destvm    ${DEST_MAC}    ${DEST_IP}
    ${NET1_VM_IPS}    BuiltIn.Create List    ${SRC_IP}    ${DEST_IP}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_VM_IPS}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Flow Classifiers For Basic Test
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_80    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 80:80
    OpenStackOperations.Create SFC Flow Classifier    FC_81    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 81:81

Create Port Pair
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    SFPP1    p1in    p1out

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    SFPPG1    SFPP1

Check If Instances Are Ready For Test
    BuiltIn.Wait Until Keyword Succeeds    200s    5s    OpenStackOperations.Check CentOS Instance Is Ready For Login    sf1
    BuiltIn.Wait Until Keyword Succeeds    200s    5s    OpenStackOperations.Check CentOS Instance Is Ready For Login    sourcevm
    BuiltIn.Wait Until Keyword Succeeds    200s    5s    OpenStackOperations.Check CentOS Instance Is Ready For Login    destvm

Start Web Server On Destination VM
    [Documentation]    Start a simple web server on the destination VM
    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    nohup sudo python -m SimpleHTTPServer 80 &
    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    nohup sudo python -m SimpleHTTPServer 81 &

Configure Service Function VMs
    [Documentation]    Enable eth1 and copy/run the vxlan_tool script
    Copy File To CentOS VM Instance    @{NETWORKS}[0]    ${SF1_IP}    /tmp/vxlan_tool.py
    BuiltIn.Comment    Added delay to ensure we can track the packet traversal through the SF
    Execute Command on CentOS VM Instance    @{NETWORKS}[0]    ${SF1_IP}    sudo ifconfig eth1 up

Test Communication From Vm Instance1 In net_1 No SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    200

Create Port Chain For Src->Dest Port 80
    [Documentation]    Create SFC Port Chain using port group and classifier created previously
    OpenStackOperations.Create SFC Port Chain    SFPC1   args=--port-pair-group SFPPG1 --flow-classifier FC_80

Test Communication From Vm Instance1 In net_1 Port 80 via SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    200
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off --block 80
    BuiltIn.Comment    Port 80 communication should fail as the SF blocks the same
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Not Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    200
    BuiltIn.Comment    Test to confirm Port 80 does not get routed through SF
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off --block 81
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    200
    Stop Vxlan Tool in SF    ${SF1_IP}

Update Port Chain To Use Flow Classifier For Port 81
    [Documentation]    Update Port Chain to use FC_82 and FC_83 instead of FC_80 and FC_81
    OpenStackOperations.Update SFC Port Chain With A New Flow Classifier    SFPC1    FC_81
    OpenStackOperations.Update SFC Port Chain Removing A Flow Classifier    SFPC1    FC_80

Test Communication From Vm Instance1 In net_1 Port 81 via SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    200
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off --block 81
    BuiltIn.Comment    Port 80 communication should fail as the SF blocks the same
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Not Contain    ${curl_resp}    200
    BuiltIn.Comment    Test to confirm Port 80 does not get routed through SF
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off --block 80
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    200
    Stop Vxlan Tool in SF    ${SF1_IP}

Delete SFC Components
    OpenStackOperations.Delete SFC Port Chain    SFPC1
    OpenStackOperations.Delete SFC Port Pair Group    SFPPG1
    OpenStackOperations.Delete SFC Port Pair    SFPP1
    OpenStackOperations.Delete SFC Flow Classifier    FC_80
    OpenStackOperations.Delete SFC Flow Classifier    FC_81

Create Flow Classifiers For Symmetric Test
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_80    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 80:80
    OpenStackOperations.Create SFC Flow Classifier    FC_81    @{NET1_VM_IPS}[1]    @{NET1_VM_IPS}[0]    tcp    dest_vm_port    args=--source-port 80:80

Create Port Pair Reverse The Ingress and Egress
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    SFPP1    p1in    p1out
    OpenStackOperations.Create SFC Port Pair    SFPP2    p1out    p1in

Create Port Pair Groups Reversed Port Pair
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    SFPPG1    SFPP1
    OpenStackOperations.Create SFC Port Pair Group    SFPPG2    SFPP2

Create Port Chain For SRC->DEST and DEST->SRC
    [Documentation]    Create SFC Port Chain using port group and classifier created previously
    OpenStackOperations.Create SFC Port Chain   SFPC1    args=--port-pair-group SFPPG1 --flow-classifier FC_80
    OpenStackOperations.Create SFC Port Chain   SFPC2     args=--port-pair-group SFPPG2 --flow-classifier FC_81

Test Communication From Vm Instance1 For Symmetric Chain
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth1 --output eth0 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    200
    BuiltIn.Comment    Test to confirm the Forward Chain
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off --block 80
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth1 --output eth0 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Not Contain    ${curl_resp}    200
    BuiltIn.Comment    Test to confirm the things are back to normal if unblocked
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth1 --output eth0 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Not Contain    ${curl_resp}    200
    BuiltIn.Comment    Test to confirm the Reverse Chain
    Stop Vxlan Tool in SF    ${SF1_IP}
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth0 --output eth1 --verbose off
    Start Vxlan Tool in SF    ${SF1_IP}    args=--do forward --interface eth1 --output eth0 --verbose off --block 80
    ${curl_resp}    OpenStackOperations.Execute Command on CentOS VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    curl -v http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Not Contain    ${curl_resp}    200
    Stop Vxlan Tool in SF    ${SF1_IP}

Delete Configurations
    [Documentation]    Delete all elements that were created in the test case section. These are done
    ...    in a local keyword so this can be called as part of the Suite Teardown. When called as part
    ...    of the Suite Teardown, all steps will be attempted. This prevents robot framework from bailing
    ...    on the rest of a test case if one step intermittently has trouble and fails. The goal is to attempt
    ...    to leave the test environment as clean as possible upon completion of this suite.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    OpenStackOperations.Delete SFC Port Chain    SFPC1
    OpenStackOperations.Delete SFC Port Pair Group    SFPPG1
    OpenStackOperations.Delete SFC Port Pair    SFPP1
    OpenStackOperations.Delete SFC Flow Classifier    FC_80
    OpenStackOperations.Delete SFC Flow Classifier    FC_81
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Delete Port    ${port}
    OpenStackOperations.Delete SubNet    l2_subnet_1
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

*** Keywords ***
Start Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}    ${args}=${EMPTY}
    [Documentation]    Starts the tool in the SF VM's
    Execute Command on CentOS VM Instance    ${network}    ${sf_vm_ip}    nohup sudo python /tmp/vxlan_tool.py ${args} &

Kill Vxlan Tool in SF VM
    [Arguments]    ${network}    ${sf_vm_ip}
    [Documentation]    Starts the tool in the SF VM's
    Execute Command on CentOS VM Instance    ${network}    ${sf_vm_ip}    sudo pkill vxlan_tool.py
