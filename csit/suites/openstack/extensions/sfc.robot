*** Settings ***
Documentation     Test suite to verify SFC configuration and packet flows.
Suite Setup       Suite Setup
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
@{NET_1_VMS}      sf1    sourcevm    destvm
@{NON_SF_VMS}     sourcevm    destvm
@{SUBNET_CIDRS}    30.0.0.0/24
@{PORTS}          p1in    p1out    source_vm_port    dest_vm_port
${CURL_COMMAND}    curl -v --connect-timeout 20 --local-port 2000
${HTTP_SUCCESS}    200 OK
${WEBSERVER_80}    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server80" | sudo nc -l -p 80 ; done
${WEBSERVER_81}    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server81" | sudo nc -l -p 81 ; done
${WEBSERVER_82}    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server82" | sudo nc -l -p 82 ; done
@{NETVIRT_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    ELAN

*** Test Cases ***
Create Neutron Ports
    [Documentation]    Precreate neutron ports to be used for SFC VMs
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port}    sg=${SECURITY_GROUP}
    Update Port    p1in    additional_args=--no-security-group
    Update Port    p1in    additional_args=--disable-port-security
    Update Port    p1out    additional_args=--no-security-group
    Update Port    p1out    additional_args=--disable-port-security

Create Vm Instances
    [Documentation]    Create Vm instances using flavor and image names for testing.
    BuiltIn.Comment    Create 3 instances with ubuntu image
    OpenStackOperations.Add New Image From Url    "https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img"    ubuntu
    OpenStackOperations.Create New Flavor For Testing    ubuntu    2048    4
    OpenStackOperations.Generate And Add Keypair To OpenStack    sfctest    odlsfctest
    OpenStackOperations.Create Vm Instance With Ports And Key On Compute Node    p1in    p1out    sf1    ${OS_CMP1_HOSTNAME}    image=ubuntu    flavor=ubuntu
    ...    sg=${SECURITY_GROUP}    keyname=sfctest
    OpenStackOperations.Create Vm Instance With Port On Compute Node    source_vm_port    sourcevm    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    dest_vm_port    destvm    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    OpenStackOperations.Poll VM Is ACTIVE    sf1
    OpenStackOperations.Poll VM Is ACTIVE    sourcevm
    OpenStackOperations.Poll VM Is ACTIVE    destvm
    ${SFC1_MAC}    OpenStackOperations.Get Port Mac    p1in
    ${SF1_IP}    OpenStackOperations.Get Port Ip    p1in
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Agent    @{NETWORKS}[0]    ${SFC1_MAC}    ${SF1_IP}
    ${SRC_MAC}    OpenStackOperations.Get Port Mac    source_vm_port
    ${SRC_IP}    OpenStackOperations.Get Port Ip    source_vm_port
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Agent    @{NETWORKS}[0]    ${SRC_MAC}    ${SRC_IP}
    ${DEST_MAC}    OpenStackOperations.Get Port Mac    dest_vm_port
    ${DEST_IP}    OpenStackOperations.Get Port Ip    dest_vm_port
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Agent    @{NETWORKS}[0]    ${DEST_MAC}    ${DEST_IP}
    BuiltIn.Comment    If the Tests reach this point, all the Instances are reachable.
    ${NET1_VM_IPS}    BuiltIn.Create List    ${SRC_IP}    ${DEST_IP}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Set Suite Variable    ${SF1_IP}
    OpenStackOperations.View Vm Console    ${NON_SF_VMS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Flow Classifiers For Basic Test
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_80    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 80:80 --source-port 2000
    OpenStackOperations.Create SFC Flow Classifier    FC_81    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 81:81 --source-port 2000

Create Port Pair
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    SFPP1    p1in    p1out

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    SFPPG1    SFPP1

Check If Instances Are Ready For Test
    OpenStackOperations.View Vm Console    ${NON_SF_VMS}
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If NonCirros Instance Is Ready For Ssh Login    @{NETWORKS}[0]    ${SF1_IP}    user=ubuntu
    ...    idfile=/tmp/odlsfctest
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Cirros Instance Is Ready For Ssh Login    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Cirros Instance Is Ready For Ssh Login    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Start Web Server On Destination VM
    [Documentation]    Start a simple web server on the destination VM
    BuiltIn.Comment    Run Web server Scripts on destination vm listening to 80,81 and 82 ports
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_80} &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_81} &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_82} &
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Configure Service Function VMs
    [Documentation]    Enable ens3 and copy/run the vxlan_tool script
    BuiltIn.Comment    Get vxlan_tool script
    OpenstackOperations.Download File On Openstack Node    ${OS_CNTL_CONN_ID}    "https://git.opendaylight.org/gerrit/gitweb?p=sfc.git;a=blob_plain;f=sfc-test/nsh-tools/vxlan_tool.py;hb=refs/changes/22/74222/1"    vxlan_tool.py
    BuiltIn.Comment    Copy vxlan_tool script to SFC VM
    OpenStackOperations.Copy File To NonCirros VM Instance    @{NETWORKS}[0]    ${SF1_IP}    /tmp/vxlan_tool.py    user=ubuntu    idfile=/tmp/odlsfctest
    BuiltIn.Comment    Bring up the second Interface for egress
    Execute Command on NonCirros VM Instance    @{NETWORKS}[0]    ${SF1_IP}    sudo ifconfig ens3 up    user=ubuntu    idfile=/tmp/odlsfctest
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Test Communication From Vm Instance1 In net_1 No SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Create Port Chain For Src->Dest Port 80
    [Documentation]    Create SFC Port Chain using port group and classifier created previously
    OpenStackOperations.Create SFC Port Chain    SFPC1    args=--port-pair-group SFPPG1 --flow-classifier FC_80

Test Communication From Vm Instance1 In net_1 Port 80 via SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 80
    BuiltIn.Comment    Port 80 communication should fail as the SF blocks the same
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Not Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    BuiltIn.Comment    Test to confirm Port 81 is not blocked
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 81
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Update Port Chain To Use Flow Classifier For Port 81
    [Documentation]    Update Port Chain to use FC_82 and FC_83 instead of FC_80 and FC_81
    OpenStackOperations.Update SFC Port Chain With A New Flow Classifier    SFPC1    FC_81
    OpenStackOperations.Update SFC Port Chain Removing A Flow Classifier    SFPC1    FC_80

Test Communication From Vm Instance1 In net_1 Port 81 via SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 81
    BuiltIn.Comment    Port 81 communication should fail as the SF blocks the same
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Not Contain    ${curl_resp}    ${HTTP_SUCCESS}
    BuiltIn.Comment    Test to confirm Port 80 does not continue to get routed through SF
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 80
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Delete And Recreate Port Chain And Flow Classifiers For Symmetric Test
    OpenStackOperations.Create SFC Flow Classifier    FC_SYM    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 82:82 --source-port 2000 --logical-destination-port dest_vm_port
    OpenStackOperations.Delete SFC Port Chain    SFPC1
    OpenStackOperations.Create SFC Port Chain    SFPSYM    args=--port-pair-group SFPPG1 --flow-classifier FC_SYM --chain-parameters symmetric=true

Test Communication From Vm Instance1 For Symmetric Chain
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:82
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    BuiltIn.Comment    Test to confirm the SRC->DEST is routed through SF
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 82
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:82
    BuiltIn.Should Not Contain    ${curl_resp}    ${HTTP_SUCCESS}
    BuiltIn.Comment    Test to confirm DEST->SRC path SFC traversal
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off --block 2000
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:82
    BuiltIn.Should Not Contain    ${curl_resp}    ${HTTP_SUCCESS}
    BuiltIn.Comment    Test to confirm the Normalcy restored
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:82
    BuiltIn.Should Contain    ${curl_resp}    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Delete Configurations
    [Documentation]    Delete all elements that were created in the test case section. These are done
    ...    in a local keyword so this can be called as part of the Suite Teardown. When called as part
    ...    of the Suite Teardown, all steps will be attempted. This prevents robot framework from bailing
    ...    on the rest of a test case if one step intermittently has trouble and fails. The goal is to attempt
    ...    to leave the test environment as clean as possible upon completion of this suite.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    OpenStackOperations.Delete SFC Port Chain    SFPSYM
    OpenStackOperations.Delete SFC Port Pair Group    SFPPG1
    OpenStackOperations.Delete SFC Port Pair    SFPP1
    OpenStackOperations.Delete SFC Flow Classifier    FC_80
    OpenStackOperations.Delete SFC Flow Classifier    FC_81
    OpenStackOperations.Delete SFC Flow Classifier    FC_SYM
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Delete Port    ${port}
    OpenStackOperations.Delete SubNet    l2_subnet_1
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

*** Keywords ***
Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    BuiltIn.Comment    We require more disk space for the SFC VM
    LiveMigration.Setup Live Migration In Compute Nodes
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Get Suite Debugs

Start Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}    ${args}=${EMPTY}
    [Documentation]    Starts the tool in the SF VM's
    Execute Command on NonCirros VM Instance    ${network}    ${sf_vm_ip}    nohup sudo python3 /tmp/vxlan_tool.py ${args} &    user=ubuntu    idfile=/tmp/odlsfctest

Stop Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}
    [Documentation]    Starts the tool in the SF VM's
    Execute Command on NonCirros VM Instance    ${network}    ${sf_vm_ip}    sudo pkill python3    user=ubuntu    idfile=/tmp/odlsfctest
