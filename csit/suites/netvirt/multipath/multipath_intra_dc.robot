*** Settings ***
Documentation     Test suite for MultiPath
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/L2GatewayOperations.robot
Resource          ../../../libraries/MultiPathOperations.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Library           OperatingSystem

*** Variables ***
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6
@{VM_LIST}        NOVA_VM1    NOVA_VM2    NOVA_VM3    NOVA_VM4    NOVA_VM5    NOVA_VM6
${SUBNET_CIDR}    10.10.1.0/24
${SECURITY_GROUP}    custom-sg
@{ALLOWED_IP}     100.100.100.100    110.110.110.110
@{MASK}           32    255.255.255.0
${NO_OF_STATIC_IP}    1
@{OPERATION}      add    delete
@{BUCKET_COUNTS}    0    1    2    3    4    5
${NO_OF_VM_PER_COMPUTE}    3
${NO_OF_PING_PACKETS}    15
@{NO_OF_COMPUTE}    0    1    2    3
@{NETWORKS}       NETWORK1
@{SUBNETS}        SUBNET1
${ROUTERS}        ROUTER1

*** Testcases ***
TC01 Verify Distribution of traffic with 3 VM on Compute1 , 2 VM on Compute2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different Computes with NextHop configured on 3 VM on Compute1 and 2 VM on Compute2
    BuiltIn.Log    Update the Router with MultiPath Route
    @{VM_IP_LIST}    BuiltIn.Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[2]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    MultiPathOperations.Configure_Next_Hops_On_Router    ${ROUTERS}    ${NO_OF_STATIC_IP}    ${VM_IP_LIST}    ${ALLOWED_IP[0]}
    BuiltIn.Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Configure_IP_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Verify_IP_Configured_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}
    BuiltIn.Log    Verify the Routes in controller
    ${CTRL_FIB}    KarafKeywords.Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    BuiltIn.Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    BuiltIn.Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    BuiltIn.Log    Verify the MultiPath flow in all Compute Nodes
    ${GROUP_ID_1}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[3]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[3]}    ${ALLOWED_IP[0]}
    BuiltIn.Log    Verify that the MultiPath Group ID is same in both Compute Nodes
    BuiltIn.Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${LOCAL_VM_PORT_LIST}    BuiltIn.Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}    ${PORT_LIST[2]}
    ${REMOTE_VM_PORT_LIST}    BuiltIn.Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}    ${GROUP_ID_1}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${REMOTE_VM_PORT_LIST}    ${LOCAL_VM_PORT_LIST}    ${GROUP_ID_2}
    ${COMPUTE_NODE_IP}    OpenStackOperations.Verify_Ping_And_Packet_Count    ${NETWORKS[0]}    ${ALLOWED_IP[0]}    ${VM_IP_DICT.${VM_LIST[5]}}    ${NO_OF_PING_PACKETS}    ${NO_OF_COMPUTE[2]}
    MultiPathOperations.Verify_Group_Stats_Packet_Count    ${COMPUTE_NODE_IP}    ${ALLOWED_IP[0]}    ${GROUP_ID_1}

TC02 Verify Distribution of traffic with 2 VM on Compute1 , 2 VM on Compute2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different Computes with NextHop configured on 2 VM on Compute1 and 2 VM on Compute2
    BuiltIn.Log    Update the Router with MultiPath Route
    OpenStackOperations.Update Router    ${ROUTERS}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTERS}    -D
    @{VM_IP_LIST}    BuiltIn.Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    MultiPathOperations.Configure_Next_Hops_On_Router    ${ROUTERS}    ${NO_OF_STATIC_IP}    ${VM_IP_LIST}    ${ALLOWED_IP[0]}
    BuiltIn.Log    Configure Ip on Sub Interface and Verify the IP
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Configure_IP_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Verify_IP_Configured_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}
    BuiltIn.Log    Verify the Routes in controller
    ${CTRL_FIB}    KarafKeywords.Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    BuiltIn.Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    BuiltIn.Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    100s    20s    OpenStackOperations.Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_DICT.${VM_LIST[2]}}    sudo ifconfig eth0:0 ${ALLOWED_IP[0]} netmask ${MASK[1]} down
    BuiltIn.Log    Verify the MultiPath flow in all Compute Nodes
    ${GROUP_ID_1}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    BuiltIn.Log    Verify that the MultiPath Group ID is same in both Compute Nodes
    BuiltIn.Should Be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${LOCAL_VM_PORT_LIST}    BuiltIn.Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}
    ${REMOTE_VM_PORT_LIST}    BuiltIn.Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}    ${GROUP_ID_1}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${REMOTE_VM_PORT_LIST}    ${LOCAL_VM_PORT_LIST}    ${GROUP_ID_2}
    ${COMPUTE_NODE_IP}    OpenStackOperations.Verify_Ping_And_Packet_Count    ${NETWORKS[0]}    ${ALLOWED_IP[0]}    ${VM_IP_DICT.${VM_LIST[5]}}    ${NO_OF_PING_PACKETS}
    MultiPathOperations.Verify_Group_Stats_Packet_Count    ${COMPUTE_NODE_IP}    ${ALLOWED_IP[0]}    ${GROUP_ID_1}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    SSHLibrary.Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports,VMs,TEP Ports
    BuiltIn.Log    Adding TEP Ports
    MultiPathOperations.Tep_Port_Operations    ${OPERATION[0]}    ${NO_OF_COMPUTE[2]}
    ${TEP_SHOW_OUTPUT}    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    ${NETWORKS[0]}
    OpenStackOperations.Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR}
    : FOR    ${PORT_NAME}    IN    @{PORT_LIST}
    \    OpenStackOperations.Create Port    ${NETWORKS[0]}    ${PORT_NAME}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP}
    BuiltIn.Log    "Creating VMs on Compute 1 and Compute 2"
    : FOR    ${Index}    IN RANGE    ${NO_OF_VM_PER_COMPUTE}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}+${NO_OF_VM_PER_COMPUTE}]}    ${VM_LIST[${Index}+${NO_OF_VM_PER_COMPUTE}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Router    ${ROUTERS}
    OpenStackOperations.Add Router Interface    ${ROUTERS}    ${SUBNETS[0]}
    &{VM_IP_DICT}    BuiltIn.Create Dictionary
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    ${VM_IP}    BuiltIn.Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Nova VM IP    ${VM_NAME}
    \    Collections.Set To Dictionary    ${VM_IP_DICT}    ${VM_NAME}=${VM_IP[0]}
    BuiltIn.Log    ${VM_IP_DICT}
    BuiltIn.Set Global Variable    ${VM_IP_DICT}
    ${CTRL_FIB}    KarafKeywords.Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    BuiltIn.Should Contain    ${CTRL_FIB}    ${VM_IP_DICT.${VM_NAME}}

Delete Setup
    [Documentation]    Clean the config created
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    OpenStackOperations.Delete Vm Instance    ${VM_NAME}
    : FOR    ${PORT_NAME}    IN    @{PORT_LIST}
    \    OpenStackOperations.Delete Port    ${PORT_NAME}
    ${VMS}    OpenStackOperations.List Nova VMs
    ${PORTS}    OpenStackOperations.List Ports
    : FOR    ${VM_NAME}    ${PORT_NAME}    IN ZIP    ${VM_LIST}    ${PORT_LIST}
    \    BuiltIn.Should Not Contain    ${VMS}    ${VM_NAME}
    \    BuiltIn.Should Not Contain    ${PORTS}    ${PORT_NAME}
    OpenStackOperations.Update Router    ${ROUTERS}    ${RT_CLEAR}
    OpenStackOperations.Remove Interface    ${ROUTERS}    ${SUBNETS[0]}
    OpenStackOperations.Delete Router    ${ROUTERS}
    OpenStackOperations.Delete SubNet    ${SUBNETS[0]}
    OpenStackOperations.Delete Network    ${NETWORKS[0]}
    OpenStackOperations.Delete All Security Group Rules    ${SECURITY_GROUP}
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}
    BuiltIn.Log    Deleting TEP Ports
    MultiPathOperations.Tep_Port_Operations    ${OPERATION[1]}    ${NO_OF_COMPUTE[2]}
