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
Resource          ../../../libraries/LiveMigration.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${SECURITY_GROUP}    sg-sfc
@{NETWORKS}       network_1
@{SUBNETS}        l2_subnet_1
@{NET_1_VMS}      sf1    sourcevm    destvm    sf2
@{NON_SF_VMS}     sourcevm    destvm
@{SUBNET_CIDRS}    30.0.0.0/24
@{PORTS}          p1in    p1out    source_vm_port    dest_vm_port     p2in      p2out
${CURL_COMMAND}    curl -v --connect-timeout 25
${HTTP_SUCCESS}    200 OK
${HTTP_FAILURE}    connect() timed out!
${WEBSERVER_80}    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server80" | sudo nc -l -p 80 ; done
${WEBSERVER_81}    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server81" | sudo nc -l -p 81 ; done
${WEBSERVER_82}    while true; do echo -e "HTTP/1.0 200 OK\r\nContent-Length: 21\r\n\r\nWelcome to web-server82" | sudo nc -l -p 82 ; done
${CLOUD_IMAGE}    "https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img"
${CLOUD_IMAGE_NAME}    ubuntu
${CLOUD_FLAVOR_NAME}    ubuntu
${CLOUD_USER_NAME}    ubuntu
${VXLAN_TOOL_URL}    "https://git.opendaylight.org/gerrit/gitweb?p=sfc.git;a=blob_plain;f=sfc-test/nsh-tools/vxlan_tool.py;h=1445292405bc17516d03e4a448ac2e0f65d38e79;hb=HEAD"
@{NETVIRT_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    ELAN

*** Test Cases ***
Create Flow Classifiers For Basic Test
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_80    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 80:80
    OpenStackOperations.Create SFC Flow Classifier    FC_81    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 81:81

Create Port Pair
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    SFPP1    p1in    p1out
    OpenStackOperations.Create SFC Port Pair    SFPP2    p2in    p2out

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    SFPPG1    SFPP1
    OpenStackOperations.Create SFC Port Pair Group    SFPPG2    SFPP2

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
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]    ${HTTP_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 80
    BuiltIn.Comment    Port 80 communication should fail as the SF blocks the same
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]    ${HTTP_FAILURE}
    BuiltIn.Comment    Test to confirm Port 81 is not blocked
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 81
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]    ${HTTP_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81    ${HTTP_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Update Port Chain To Use Flow Classifier For Port 81
    [Documentation]    Update Port Chain to use FC_82 and FC_83 instead of FC_80 and FC_81
    OpenStackOperations.Set SFC Port Chain     SFPC1    args=--flow-classifier FC_81 --port-pair-group SFPPG2
    OpenStackOperations.Unset SFC Port Chain    SFPC1    args=--flow-classifier FC_80 --port-pair-group SFPPG1

Test Communication From Vm Instance1 In net_1 Port 81 via SF
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]    ${HTTP_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81    ${HTTP_SUCCESS}
    ...    cmd_timeout=60s
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 81
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]    ${HTTP_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81    ${HTTP_FAILURE}
    ...    cmd_timeout=60s
    BuiltIn.Comment    Port 81 communication should fail as the SF blocks the same
    BuiltIn.Comment    Test to confirm Port 80 does not continue to get routed through SF
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 80
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]    ${HTTP_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} http://@{NET1_VM_IPS}[1]:81    ${HTTP_SUCCESS}
    ...    cmd_timeout=60s
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Delete And Recreate Port Chain And Flow Classifiers For Symmetric Test
    OpenStackOperations.Create SFC Flow Classifier    FC_SYM    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 82:82 --source-port 2000 --logical-destination-port dest_vm_port
    OpenStackOperations.Delete SFC Port Chain    SFPC1
    OpenStackOperations.Delete SFC Port Chain    SFPC2
    OpenStackOperations.Create SFC Port Chain    SFPSYM    args=--port-pair-group SFPPG1 --port-pair-group SFPPG2 --flow-classifier FC_SYM --chain-parameters symmetric=true

Test Communication From Vm Instance1 For Symmetric Chain
    [Documentation]    Login to the source VM instance, and send a HTTP GET using curl to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for curl to be higher.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    Wait Until Keyword Succeeds    8x    20s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} --local-port 2000 -m 60 http://@{NET1_VM_IPS}[1]:82    ${HTTP_SUCCESS}
    ...    cmd_timeout=80s
    BuiltIn.Comment    Test to confirm the SRC->DEST Port 82 is routed through SF
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off --block 82
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    Wait Until Keyword Succeeds    8x    20s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} --local-port 2000 -m 60 http://@{NET1_VM_IPS}[1]:82    ${HTTP_FAILURE}
    ...    cmd_timeout=80s
    BuiltIn.Comment    Test to confirm DEST->SRC Port 2000 path SFC traversal
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens3 --output ens2 --verbose off --block 2000
    Wait Until Keyword Succeeds    8x    20s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} --local-port 2000 -m 60 http://@{NET1_VM_IPS}[1]:82    ${HTTP_FAILURE}
    ...    cmd_timeout=80s
    BuiltIn.Comment    Test to confirm the Normalcy restored
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens2 --output ens3 --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF2_IP}    args=--do forward --interface ens3 --output ens2 --verbose off
    Wait Until Keyword Succeeds    8x    20s    Access Http And Check Status    @{NETWORKS}[0]    ${CURL_COMMAND} --local-port 2000 -m 60 http://@{NET1_VM_IPS}[1]:82    ${HTTP_SUCCESS}
    ...    cmd_timeout=80s
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
    OpenStackOperations.Delete SFC Port Pair Group    SFPPG2
    OpenStackOperations.Delete SFC Port Pair    SFPP1
    OpenStackOperations.Delete SFC Port Pair    SFPP2
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
    Create Basic Networks
    Create Ports For Testing
    Create Instances For Testing
    Check Vm Instances Have Ip Address And Ready For Test
    Start Applications on VM Instances For Test

Create Basic Networks
    BuiltIn.Comment    Create Network For Testing
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    BuiltIn.Comment    Create Subnet For Testing
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    BuiltIn.Comment    Create Neutron Ports with no port security for SFC Tests
    OpenStackOperations.Get Suite Debugs

Create Ports For Testing
    : FOR    ${port}    IN    @{PORTS}
    \    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port}    sg=${SECURITY_GROUP}
    OpenStackOperations.Update Port    p1in    additional_args=--no-security-group
    OpenStackOperations.Update Port    p1in    additional_args=--disable-port-security
    OpenStackOperations.Update Port    p1out    additional_args=--no-security-group
    OpenStackOperations.Update Port    p1out    additional_args=--disable-port-security
    OpenStackOperations.Update Port    p2in    additional_args=--no-security-group
    OpenStackOperations.Update Port    p2in    additional_args=--disable-port-security
    OpenStackOperations.Update Port    p2out    additional_args=--no-security-group
    OpenStackOperations.Update Port    p2out    additional_args=--disable-port-security
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    source_vm_port    additional_args=--no-security-group
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    source_vm_port    additional_args=--disable-port-security
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    dest_vm_port    additional_args=--no-security-group
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    dest_vm_port    additional_args=--disable-port-security
    OpenStackOperations.Get Suite Debugs

Create Instances For Testing
    ${SF_COMP_HOST} =    BuiltIn.Set Variable If    2 < ${NUM_OS_SYSTEM}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}
    BuiltIn.Comment    Create one ubuntu instance and two cirros instances
    OpenStackOperations.Add New Image From Url    ${CLOUD_IMAGE}    ${CLOUD_IMAGE_NAME}
    OpenStackOperations.Create Flavor    ${CLOUD_FLAVOR_NAME}    2048    4
    OpenStackOperations.Generate And Add Keypair    sfctest    odlsfctest
    OpenStackOperations.Create Vm Instance With Ports And Key On Compute Node    p1in    p1out    sf1    ${SF_COMP_HOST}    image=${CLOUD_IMAGE_NAME}    flavor=${CLOUD_FLAVOR_NAME}
    OpenStackOperations.Create Vm Instance With Ports And Key On Compute Node    p2in    p2out    sf2    ${SF_COMP_HOST}    image=${CLOUD_IMAGE_NAME}    flavor=${CLOUD_FLAVOR_NAME}
    ...    sg=${SECURITY_GROUP}    keyname=sfctest
    OpenStackOperations.Create Vm Instance With Port On Compute Node    source_vm_port    sourcevm    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}    flavor=cirros256
    OpenStackOperations.Create Vm Instance With Port On Compute Node    dest_vm_port    destvm    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}    flavor=cirros256
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs

Check Vm Instances Have Ip Address And Ready For Test
    OpenStackOperations.Poll VM Is ACTIVE    sf1
    OpenStackOperations.Poll VM Is ACTIVE    sourcevm
    OpenStackOperations.Poll VM Is ACTIVE    destvm
    ${sfc1_mac}    OpenStackOperations.Get Port Mac    p1in
    ${SF1_IP}    OpenStackOperations.Get Port Ip    p1in
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Namespace    @{NETWORKS}[0]    ${sfc1_mac}    ${SF1_IP}
    ${sfc2_mac}    OpenStackOperations.Get Port Mac    p2in
    ${SF2_IP}    OpenStackOperations.Get Port Ip    p2in
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Namespace    @{NETWORKS}[0]    ${sfc2_mac}    ${SF2_IP}
    ${src_mac}    OpenStackOperations.Get Port Mac    source_vm_port
    ${src_ip}    OpenStackOperations.Get Port Ip    source_vm_port
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Namespace    @{NETWORKS}[0]    ${src_mac}    ${src_ip}
    ${dest_mac}    OpenStackOperations.Get Port Mac    dest_vm_port
    ${dest_ip}    OpenStackOperations.Get Port Ip    dest_vm_port
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Namespace    @{NETWORKS}[0]    ${dest_mac}    ${dest_ip}
    BuiltIn.Comment    If the Tests reach this point, all the Instances are reachable.
    ${NET1_VM_IPS}    BuiltIn.Create List    ${src_ip}    ${dest_ip}
    BuiltIn.Set Suite Variable    @{NET1_VM_IPS}
    BuiltIn.Set Suite Variable    ${SF1_IP}
    BuiltIn.Set Suite Variable    ${SF2_IP}
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using PublicKey    @{NETWORKS}[0]    ${SF1_IP}    user=ubuntu
    ...    idfile=/tmp/odlsfctest    console=ubuntu
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using PublicKey    @{NETWORKS}[0]    ${SF2_IP}    user=ubuntu
    ...    idfile=/tmp/odlsfctest    console=ubuntu
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using Password    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using Password    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs

Start Applications on VM Instances For Test
    BuiltIn.Comment    Run Web server Scripts on destination vm listening to 80,81 and 82 ports
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_80} &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_81} &
    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_82} &
    BuiltIn.Comment    Get vxlan_tool script
    Utils.Download File On Openstack Node    ${OS_CNTL_CONN_ID}    vxlan_tool.py    ${VXLAN_TOOL_URL}
    BuiltIn.Comment    Copy vxlan_tool script to SFC VM
    OpenStackOperations.Copy File To VM Instance With PublicKey Auth    @{NETWORKS}[0]    ${SF1_IP}    /tmp/vxlan_tool.py    user=${CLOUD_USER_NAME}    idfile=/tmp/odlsfctest
    BuiltIn.Comment    Bring up the second Interface for egress
    Execute Command on VM Instance with PublicKey Auth    @{NETWORKS}[0]    ${SF1_IP}    sudo ifconfig ens3 up    user=${CLOUD_USER_NAME}    idfile=/tmp/odlsfctest    console=ubuntu
    BuiltIn.Comment    Copy vxlan_tool script to SFC VM
    OpenStackOperations.Copy File To VM Instance With PublicKey Auth    @{NETWORKS}[0]    ${SF2_IP}    /tmp/vxlan_tool.py    user=${CLOUD_USER_NAME}    idfile=/tmp/odlsfctest
    BuiltIn.Comment    Bring up the second Interface for egress
    Execute Command on VM Instance with PublicKey Auth    @{NETWORKS}[0]    ${SF2_IP}    sudo ifconfig ens3 up    user=${CLOUD_USER_NAME}    idfile=/tmp/odlsfctest    console=ubuntu

Start Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}    ${args}=${EMPTY}
    [Documentation]    Starts the tool in the SF VM's
    Execute Command on VM Instance with PublicKey Auth    ${network}    ${sf_vm_ip}    nohup sudo python3 /tmp/vxlan_tool.py ${args} &    user=ubuntu    idfile=/tmp/odlsfctest    console=ubuntu

Stop Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}
    [Documentation]    Starts the tool in the SF VM's
    Execute Command on VM Instance With PublicKey Auth    ${network}    ${sf_vm_ip}    sudo pkill python3    user=ubuntu    idfile=/tmp/odlsfctest    console=ubuntu

Access Http And Check Status
    [Arguments]    ${vm_ip}    ${curl_command}    ${ret_code}    ${cmd_timeout}=30s
    ${curl_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${curl_command}    cmd_timeout=${cmd_timeout}
    BuiltIn.Should Contain    ${curl_resp}    ${ret_code}
