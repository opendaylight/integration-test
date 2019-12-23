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
@{NET_1_VMS}      sf1    sourcevm    destvm
@{NON_SF_VMS}     sourcevm    destvm
@{SUBNET_CIDRS}    30.0.0.0/24
@{PORTS}          p1in    p1out    source_vm_port    dest_vm_port
${NC_COMMAND}     nc -zv -w 5
${RES_SUCCESS}    open
${RES_FAILURE}    Operation timed out
${WEBSERVER_80}    (python -m SimpleHTTPServer 80 > /dev/null 2>&1 &)
${WEBSERVER_81}    (python -m SimpleHTTPServer 81 > /dev/null 2>&1 &)
${WEBSERVER_82}    (python -m SimpleHTTPServer 82 > /dev/null 2>&1 &)
${WEBSERVER_83}    (python -m SimpleHTTPServer 83 > /dev/null 2>&1 &)
${WEBSERVER_84}    (python -m SimpleHTTPServer 84 > /dev/null 2>&1 &)
${WEBSERVER_85}    (python -m SimpleHTTPServer 85 > /dev/null 2>&1 &)
${WEBSERVER_100}    (python -m SimpleHTTPServer 100 > /dev/null 2>&1 &)
${WEBSERVER_101}    (python -m SimpleHTTPServer 101 > /dev/null 2>&1 &)
${WEBSERVER_102}    (python -m SimpleHTTPServer 102 > /dev/null 2>&1 &)
${WEBSERVER_103}    (python -m SimpleHTTPServer 103 > /dev/null 2>&1 &)
${WEBSERVER_CMDS}    ${WEBSERVER_80} && ${WEBSERVER_81} && ${WEBSERVER_82} && ${WEBSERVER_83} && ${WEBSERVER_84} && ${WEBSERVER_85} && ${WEBSERVER_100} && ${WEBSERVER_101} && ${WEBSERVER_102} && ${WEBSERVER_103}
${CLOUD_IMAGE}    "https://artifacts.opnfv.org/sfc/images/sfc_nsh_fraser.qcow2"
${CLOUD_IMAGE_NAME}    sfc_nsh_fraser
${CLOUD_FLAVOR_NAME}    sfc_nsh_fraser
@{NETVIRT_DIAG_SERVICES}    OPENFLOW    IFM    ITM    DATASTORE    ELAN
${ETH_IN}         eth0
${ETH_OUT}        eth1
${CLOUD_IMAGE_USER}    root
${CLOUD_IMAGE_PASS}    opnfv
${CLOULD_IMAGE_CONSOLE}    root

*** Test Cases ***
Create Flow Classifiers For Basic Test
    [Documentation]    Create SFC Flow Classifier for TCP traffic between source VM and destination VM
    OpenStackOperations.Create SFC Flow Classifier    FC_80    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 80:80
    OpenStackOperations.Create SFC Flow Classifier    FC_81    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 81:81
    OpenStackOperations.Create SFC Flow Classifier    FC_83_85    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 83:85

Create Port Pair
    [Documentation]    Create SFC Port Pairs
    OpenStackOperations.Create SFC Port Pair    SFPP1    p1in    p1out

Create Port Pair Groups
    [Documentation]    Create SFC Port Pair Groups
    OpenStackOperations.Create SFC Port Pair Group    SFPPG1    SFPP1

Test Communication From Vm Instance1 In net_1 No SF
    [Documentation]    Login to the source VM instance, and send a nc req to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for nc to be higher.
    ${DEST_VM_LIST}    BuiltIn.Create List    @{NET1_VM_IPS}[1]
    ${nc_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} @{NET1_VM_IPS}[1] 80    user=${CLOUD_IMAGE_USER}    password=${CLOUD_IMAGE_PASS}
    ...    console=${CLOULD_IMAGE_CONSOLE}
    BuiltIn.Should Contain    ${nc_resp}    ${RES_SUCCESS}
    ${nc_resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} @{NET1_VM_IPS}[1] 81    user=${CLOUD_IMAGE_USER}    password=${CLOUD_IMAGE_PASS}
    ...    console=${CLOULD_IMAGE_CONSOLE}
    BuiltIn.Should Contain    ${nc_resp}    ${RES_SUCCESS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Create Port Chain For Src->Dest Port 80
    [Documentation]    Create SFC Port Chain using port group and classifier created previously
    OpenStackOperations.Create SFC Port Chain    SFPC1    args=--port-pair-group SFPPG1 --flow-classifier FC_80

Test Communication From Vm Instance1 In net_1 Port 80 via SF
    [Documentation]    Login to the source VM instance, and send a nc req to the destination VM instance, If the SF handles the traffic, there will be delay causing the time for nc to be higher.
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    81    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 80
    BuiltIn.Comment    Port 80 communication should fail as the SF blocks the same
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_FAILURE}
    BuiltIn.Comment    Test to confirm Port 81 is not blocked
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    81    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 81
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    81    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Update Port Chain To Use Flow Classifier For Port 81
    [Documentation]    Update Port Chain to use FC_81 instead of FC_80
    OpenStackOperations.Update SFC Port Chain With A New Flow Classifier    SFPC1    FC_81
    OpenStackOperations.Update SFC Port Chain Removing A Flow Classifier    SFPC1    FC_80

Test Communication From Vm Instance1 In net_1 Port 81 via SF
    [Documentation]    Login to the source VM instance, and send a nc req to the destination VM instance.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    81    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 81
    BuiltIn.Comment    Port 81 communication should fail as the SF blocks the same
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    81    ${RES_FAILURE}
    BuiltIn.Comment    Test to confirm Port 80 does not continue to get routed through SF
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 80
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    81    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Get Test Teardown Debugs For SFC
    ...    AND    OpenStackOperations.Exit From Vm Console

Update Port Chain To Use Flow Classifier For Port Range 83-85
    [Documentation]    Update Port Chain to use FC_83_85
    OpenStackOperations.Update SFC Port Chain With A New Flow Classifier    SFPC1    FC_83_85

Test Communication From Vm Instance1 In net_1 Port 84 And 85 via SF
    [Documentation]    Login to the source VM instance, and send a nc req to the destination VM instance.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    84    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    85    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 83
    BuiltIn.Comment    Port 83 communication should fail as the SF blocks the same
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    83    ${RES_FAILURE}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    84    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    85    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 84
    BuiltIn.Comment    Port 84 communication should fail as the SF blocks the same
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    84    ${RES_FAILURE}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    85    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 85
    BuiltIn.Comment    Port 85 communication should fail as the SF blocks the same
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    84    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    85    ${RES_FAILURE}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 80
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    80    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    84    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND}
    ...    85    ${RES_SUCCESS}

Update Port Chain To Use Flow Classifier For Input Port Range 101-103
    [Documentation]    Update Port Chain to use FC_101_103
    BuiltIn.Comment    Removing and Deleting Existing Conflicting Flow Classifiers
    OpenStackOperations.Update SFC Port Chain Removing A Flow Classifier    SFPC1    FC_81
    OpenStackOperations.Update SFC Port Chain Removing A Flow Classifier    SFPC1    FC_83_85
    OpenStackOperations.Delete SFC Flow Classifier    FC_80
    OpenStackOperations.Delete SFC Flow Classifier    FC_81
    OpenStackOperations.Delete SFC Flow Classifier    FC_83_85
    OpenStackOperations.Create SFC Flow Classifier    FC_101_103    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--source-port 101:103
    OpenStackOperations.Update SFC Port Chain With A New Flow Classifier    SFPC1    FC_101_103

Test Communication From Vm Instance1 In net_1 Port 100 And 102 via SF
    [Documentation]    Login to the source VM instance, and send a nc req to the destination VM instance.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 80
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 100
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 101
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 102
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 103
    ...    83    ${RES_SUCCESS}
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 83
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 80
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 100
    ...    83    ${RES_SUCCESS}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 101
    ...    83    ${RES_FAILURE}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 102
    ...    83    ${RES_FAILURE}
    Wait Until Keyword Succeeds    3x    10s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 103
    ...    83    ${RES_FAILURE}

Delete And Recreate Port Chain And Flow Classifiers For Symmetric Test
    OpenStackOperations.Create SFC Flow Classifier    FC_SYM    @{NET1_VM_IPS}[0]    @{NET1_VM_IPS}[1]    tcp    source_vm_port    args=--destination-port 82:82 --source-port 2000 --logical-destination-port dest_vm_port
    OpenStackOperations.Delete SFC Port Chain    SFPC1
    OpenStackOperations.Create SFC Port Chain    SFPSYM    args=--port-pair-group SFPPG1 --flow-classifier FC_SYM --chain-parameters symmetric=true

Test Communication From Vm Instance1 For Symmetric Chain
    [Documentation]    Login to the source VM instance, and send a nc req to the destination VM instance.
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_OUT} --output ${ETH_IN} --verbose off
    Wait Until Keyword Succeeds    8x    20s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 2000
    ...    82    ${RES_SUCCESS}
    BuiltIn.Comment    Test to confirm the SRC->DEST Port 82 is routed through SF
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off --block 82
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_OUT} --output ${ETH_IN} --verbose off
    Wait Until Keyword Succeeds    8x    20s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 2000
    ...    82    ${RES_FAILURE}
    BuiltIn.Comment    Test to confirm DEST->SRC Port 2000 path SFC traversal
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_OUT} --output ${ETH_IN} --verbose off --block 2000
    Wait Until Keyword Succeeds    8x    20s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 2000
    ...    82    ${RES_FAILURE}
    BuiltIn.Comment    Test to confirm the Normalcy restored
    Stop Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_IN} --output ${ETH_OUT} --verbose off
    Start Vxlan Tool in SF    @{NETWORKS}[0]    ${SF1_IP}    args=--do forward --interface ${ETH_OUT} --output ${ETH_IN} --verbose off
    Wait Until Keyword Succeeds    8x    20s    Check Network Reachability    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    ${NC_COMMAND} -p 2000
    ...    82    ${RES_SUCCESS}
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
    FOR    ${vm}    IN    @{NET_1_VMS}
        OpenStackOperations.Delete Vm Instance    ${vm}
    END
    OpenStackOperations.Delete SFC Port Chain    SFPSYM
    OpenStackOperations.Delete SFC Port Pair Group    SFPPG1
    OpenStackOperations.Delete SFC Port Pair    SFPP1
    OpenStackOperations.Delete SFC Flow Classifier    FC_101_103
    OpenStackOperations.Delete SFC Flow Classifier    FC_SYM
    FOR    ${port}    IN    @{PORTS}
        OpenStackOperations.Delete Port    ${port}
    END
    OpenStackOperations.Delete SubNet    l2_subnet_1
    FOR    ${network}    IN    @{NETWORKS}
        OpenStackOperations.Delete Network    ${network}
    END
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
    FOR    ${port}    IN    @{PORTS}
        OpenStackOperations.Create Port    @{NETWORKS}[0]    ${port}    sg=${SECURITY_GROUP}
    END
    OpenStackOperations.Update Port    p1in    additional_args=--no-security-group
    OpenStackOperations.Update Port    p1in    additional_args=--disable-port-security
    OpenStackOperations.Update Port    p1out    additional_args=--no-security-group
    OpenStackOperations.Update Port    p1out    additional_args=--disable-port-security
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    source_vm_port    additional_args=--no-security-group
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    source_vm_port    additional_args=--disable-port-security
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    dest_vm_port    additional_args=--no-security-group
    CompareStream.Run_Keyword_If_Equals    oxygen    OpenStackOperations.Update Port    dest_vm_port    additional_args=--disable-port-security
    OpenStackOperations.Get Suite Debugs

Create Instances For Testing
    ${SF_COMP_HOST} =    BuiltIn.Set Variable If    2 < ${NUM_OS_SYSTEM}    ${OS_CMP2_HOSTNAME}    ${OS_CMP1_HOSTNAME}
    OpenStackOperations.Add New Image From Url    ${CLOUD_IMAGE}    ${CLOUD_IMAGE_NAME}
    OpenStackOperations.Create Flavor    ${CLOUD_FLAVOR_NAME}    512    1
    OpenStackOperations.Create Vm Instance With Ports On Compute Node    p1in    p1out    sf1    ${SF_COMP_HOST}    image=${CLOUD_IMAGE_NAME}    flavor=${CLOUD_FLAVOR_NAME}
    ...    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    source_vm_port    sourcevm    ${OS_CMP1_HOSTNAME}    image=${CLOUD_IMAGE_NAME}    flavor=${CLOUD_FLAVOR_NAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    dest_vm_port    destvm    ${OS_CMP1_HOSTNAME}    image=${CLOUD_IMAGE_NAME}    flavor=${CLOUD_FLAVOR_NAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs

Check Vm Instances Have Ip Address And Ready For Test
    OpenStackOperations.Poll VM Is ACTIVE    sf1
    OpenStackOperations.Poll VM Is ACTIVE    sourcevm
    OpenStackOperations.Poll VM Is ACTIVE    destvm
    ${sfc1_mac}    OpenStackOperations.Get Port Mac    p1in
    ${SF1_IP}    OpenStackOperations.Get Port Ip    p1in
    BuiltIn.Wait Until Keyword Succeeds    500s    60s    OpenStackOperations.Verify If Instance Is Arpingable From Dhcp Namespace    @{NETWORKS}[0]    ${sfc1_mac}    ${SF1_IP}
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
    BuiltIn.Set Suite Variable    ${OS_SYSTEM_PROMPT}    \#
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using Password    @{NETWORKS}[0]    ${SF1_IP}    user=${CLOUD_IMAGE_USER}
    ...    password=${CLOUD_IMAGE_PASS}    console=${CLOULD_IMAGE_CONSOLE}
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using Password    @{NETWORKS}[0]    @{NET1_VM_IPS}[0]    user=${CLOUD_IMAGE_USER}
    ...    password=${CLOUD_IMAGE_PASS}    console=${CLOULD_IMAGE_CONSOLE}
    BuiltIn.Wait Until Keyword Succeeds    300s    60s    OpenStackOperations.Check If Instance Is Ready For Ssh Login Using Password    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    user=${CLOUD_IMAGE_USER}
    ...    password=${CLOUD_IMAGE_PASS}    console=${CLOULD_IMAGE_CONSOLE}
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs

Start Applications on VM Instances For Test
    BuiltIn.Comment    Run Web server Scripts on destination vm listening to 80,81 and 82 ports
    ${resp}    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET1_VM_IPS}[1]    ${WEBSERVER_CMDS} && (echo done)    user=${CLOUD_IMAGE_USER}    password=${CLOUD_IMAGE_PASS}
    ...    console=${CLOULD_IMAGE_CONSOLE}
    BuiltIn.Should Contain    ${resp}    done

Start Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}    ${args}=${EMPTY}
    [Documentation]    Starts the tool in the SF VM's
    OpenStackOperations.Execute Command on VM Instance    ${network}    ${sf_vm_ip}    nohup python vxlan_tool.py ${args} &    user=${CLOUD_IMAGE_USER}    password=${CLOUD_IMAGE_PASS}    console=${CLOULD_IMAGE_CONSOLE}

Stop Vxlan Tool in SF
    [Arguments]    ${network}    ${sf_vm_ip}
    [Documentation]    Starts the tool in the SF VM's
    OpenStackOperations.Execute Command on VM Instance    ${network}    ${sf_vm_ip}    pkill python    user=${CLOUD_IMAGE_USER}    password=${CLOUD_IMAGE_PASS}    console=${CLOULD_IMAGE_CONSOLE}

Check Network Reachability
    [Arguments]    ${net_name}    ${source_vm_ip}    ${command}    ${port}    ${ret_code}    ${cmd_timeout}=30s
    ${nc_resp}    OpenStackOperations.Execute Command on VM Instance    ${net_name}    ${source_vm_ip}    ${command} @{NET1_VM_IPS}[1] ${port}    cmd_timeout=${cmd_timeout}    user=${CLOUD_IMAGE_USER}
    ...    password=${CLOUD_IMAGE_PASS}    console=${CLOULD_IMAGE_CONSOLE}
    BuiltIn.Should Contain    ${nc_resp}    ${ret_code}
