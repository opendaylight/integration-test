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

*** Testcases ***
TC01 Verify Distribution of traffic with 3 VM on Compute1 , 2 VM on Compute2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different Computes with NextHop configured on 3 VM on Compute1 and 2 VM on Compute2
    Log    Update the Router with MultiPath Route
    @{VM_IP_LIST}    Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[2]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    Configure_Next_Hops_On_Router    ${ROUTERS}    ${NO_OF_STATIC_IP}    ${VM_IP_LIST}    ${ALLOWED_IP[0]}
    Log    Configure IP on Sub Interface and Verify the IP
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    Log    Verify the MultiPath flow in all Compute Nodes
    ${GROUP_ID_1}    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[3]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[3]}    ${ALLOWED_IP[0]}
    Log    Verify that the MultiPath Group ID is same in both Compute Nodes
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${LOCAL_VM_PORT_LIST}    Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}    ${PORT_LIST[2]}
    ${REMOTE_VM_PORT_LIST}    Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    Verify_VM_Mac    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}    ${GROUP_ID_1}
    Verify_VM_Mac    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${REMOTE_VM_PORT_LIST}    ${LOCAL_VM_PORT_LIST}    ${GROUP_ID_2}
    ${COMPUTE_NODE_IP}    Verify_Ping_And_Packet_Count    ${NETWORKS[0]}    ${ALLOWED_IP[0]}    ${VM_IP_DICT.${VM_LIST[5]}}    ${NO_OF_PING_PACKETS}
    Verify_Group_Stats_Packet_Count    ${COMPUTE_NODE_IP}    ${ALLOWED_IP[0]}    ${GROUP_ID_1}

TC02 Verify Distribution of traffic with 2 VM on Compute1 , 2 VM on Compute2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different Computes with NextHop configured on 2 VM on Compute1 and 2 VM on Compute2
    Log    Update the Router with MultiPath Route
    Update Router    ${ROUTERS}    ${RT_CLEAR}
    Show Router    ${ROUTERS}    -D
    @{VM_IP_LIST}    Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    Configure_Next_Hops_On_Router    ${ROUTERS}    ${NO_OF_STATIC_IP}    ${VM_IP_LIST}    ${ALLOWED_IP[0]}
    Log    Configure Ip on Sub Interface and Verify the IP
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    Wait Until Keyword Succeeds    100s    20s    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_DICT.${VM_LIST[2]}}    sudo ifconfig eth0:0 ${ALLOWED_IP[0]} netmask ${MASK[1]} down
    Log    Verify the MultiPath flow in all Compute Nodes
    ${GROUP_ID_1}    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${GROUP_ID_2}    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Log    Verify that the MultiPath Group ID is same in both Compute Nodes
    Should be Equal As Strings    ${GROUP_ID_1}    ${GROUP_ID_2}
    ${LOCAL_VM_PORT_LIST}    Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}
    ${REMOTE_VM_PORT_LIST}    Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    Verify_VM_Mac    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}    ${GROUP_ID_1}
    Verify_VM_Mac    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${REMOTE_VM_PORT_LIST}    ${LOCAL_VM_PORT_LIST}    ${GROUP_ID_2}
    ${COMPUTE_NODE_IP}    Verify_Ping_And_Packet_Count    ${NETWORKS[0]}    ${ALLOWED_IP[0]}    ${VM_IP_DICT.${VM_LIST[5]}}    ${NO_OF_PING_PACKETS}
    Verify_Group_Stats_Packet_Count    ${COMPUTE_NODE_IP}    ${ALLOWED_IP[0]}    ${GROUP_ID_1}

*** Keywords ***
Start Suite
    [Documentation]    Run at start of the suite
    DevstackUtils.Devstack Suite Setup
    Create Setup

End Suite
    [Documentation]    Run at end of the suite
    Delete Setup
    Close All Connections

Create Setup
    [Documentation]    Create networks,subnets,ports,VMs,TEP Ports
    Log    Adding TEP Ports
    Tep_Port_Operations    ${OPERATION[0]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}
    ${TEP_SHOW_OUTPUT}    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Network    ${NETWORKS[0]}
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR}
    : FOR    ${PORT_NAME}    IN    @{PORT_LIST}
    \    Create Port    ${NETWORKS[0]}    ${PORT_NAME}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP}
    Log    "Creating VMs on Compute 1 and Compute 2"
    : FOR    ${Index}    IN RANGE    ${NO_OF_VM_PER_COMPUTE}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    \    Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}+${NO_OF_VM_PER_COMPUTE}]}    ${VM_LIST[${Index}+${NO_OF_VM_PER_COMPUTE}]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Router    ${ROUTERS}
    Add Router Interface    ${ROUTERS}    ${SUBNETS[0]}
    &{VM_IP_DICT}    Create Dictionary
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    ${VM_IP}    Wait Until Keyword Succeeds    30s    2s    Verify Nova VM IP    ${VM_NAME}
    \    Set To Dictionary    ${VM_IP_DICT}    ${VM_NAME}=${VM_IP[0]}
    Log    ${VM_IP_DICT}
    Set Global Variable    ${VM_IP_DICT}
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    Should Contain    ${CTRL_FIB}    ${VM_IP_DICT.${VM_NAME}}

Delete Setup
    [Documentation]    Clean the config created
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    Delete Vm Instance    ${VM_NAME}
    : FOR    ${PORT_NAME}    IN    @{PORT_LIST}
    \    Delete Port    ${PORT_NAME}
    ${VMS}    List Nova VMs
    ${PORTS}    List Ports
    : FOR    ${VM_NAME}    ${PORT_NAME}    IN ZIP    ${VM_LIST}    ${PORT_LIST}
    \    Should Not Contain    ${VMS}    ${VM_NAME}
    \    Should Not Contain    ${PORTS}    ${PORT_NAME}
    Update Router    ${ROUTERS}    ${RT_CLEAR}
    Remove Interface    ${ROUTERS}    ${SUBNETS[0]}
    Delete Router    ${ROUTERS}
    Delete SubNet    ${SUBNETS[0]}
    Delete Network    ${NETWORKS[0]}
    Delete All Security Group Rules    ${SECURITY_GROUP}
    Delete SecurityGroup    ${SECURITY_GROUP}
    Log    Deleting TEP Ports
    Tep_Port_Operations    ${OPERATION[1]}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}    ${OS_COMPUTE_3_IP}
