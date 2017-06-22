*** Settings ***
Documentation     Test suite for MultiPath
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/L2GatewayOperations.robot
Resource          ../../../libraries/MultiPathKeywords.robot
Library           OperatingSystem

*** Variables ***
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6    PORT7
...               PORT8
@{VM_LIST}        NOVA_VM1    NOVA_VM2    NOVA_VM3    NOVA_VM4    NOVA_VM5    NOVA_VM6    NOVA_VM7
...               NOVA_VM8
${NETWORK_NAME}    Network1
${SUBNET_NAME}    Subnet1
${ROUTER_NAME}    Router1
${SUBNET_CIDR}    10.10.1.0/24
${SECURITY_GROUP}    custom-sg
@{ALLOWED_IP}     100.100.100.100    110.110.110.110
@{MASK}           32    24
${NO_OF_STATIC_IP}    1
${NO_OF_PING_PACKETS}    15
@{OPERATION}      add    delete
@{BUCKET_COUNTS}    0    1    2    3    4    5
${FIB_SHOW}       fib-show
${TEP_SHOW_STATE}    tep:show-state

*** Testcases ***
TC01 Verify Distribution of traffic with 3 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different CSSs with NextHop configured on 3 VM on CSS1 and 2 VM on CSS2
    Log    Update the Router with MultiPath Route
    @{VM_IP_LIST}    Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[2]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    Configure_Next_Hop_on_Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_IP_LIST}
    Log    Configure Ip on Sub Interface and Verify the IP
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Configure_IP_on_Sub_Interface    ${NETWORK_NAME}    ${ALLOWED_IP[0]}    ${VM_IP}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_on_Sub_Interface    ${NETWORK_NAME}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    Log    Verify the MP flow in all Compute Nodes
    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[3]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[3]}    ${ALLOWED_IP[0]}
    ${LOCAL_VM_PORT_LIST}    Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}    ${PORT_LIST[2]}
    ${REMOTE_VM_PORT_LIST}    Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    Verify_VM_MAC_in_groups    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}
    Verify_VM_MAC_in_groups    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${REMOTE_VM_PORT_LIST}    ${LOCAL_VM_PORT_LIST}
    Verify_Ping_and_Packet_Count    ${NETWORK_NAME}    ${ALLOWED_IP[0]}    ${VM_LIST[5]}

TC02 Verify Distribution of traffic - 2 VM on CSS1 , 2 VM on CSS2
    [Documentation]    Verify The CSC should support MP traffic splitting on L3VPN within DC across VMs located on different CSSs with NextHop configured on 2 VM on CSS1 and 2 VM on CSS2
    Log    Update the Router with MultiPath Route
    @{VM_IP_LIST}    Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    Configure_Next_Hop_on_Router    ${ROUTER_NAME}    ${NO_OF_STATIC_IP}    ${VM_IP_LIST}
    Log    Configure Ip on Sub Interface and Verify the IP
    : FOR    ${VM_IP}    IN    @{VM_IP_LIST}
    \    Configure_IP_on_Sub_Interface    ${NETWORK_NAME}    ${ALLOWED_IP[0]}    ${VM_IP}    ${MASK[1]}
    \    Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_on_Sub_Interface    ${NETWORK_NAME}    ${ALLOWED_IP[0]}
    \    ...    ${VM_IP}
    Log    Verify the Routes in controller
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    Should Match Regexp    ${CTRL_FIB}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    Wait Until Keyword Succeeds    100s    20s    Run Keyword    Execute Command on VM Instance    ${NETWORK_NAME}    ${VM_IP_DICT.${VM_LIST[2]}}
    ...    sudo ifconfig eth0:0 ${ALLOWED_IP[0]} netmask 255.255.255.0 down
    Log    Verify the MP flow in all Compute Nodes
    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${LOCAL_VM_PORT_LIST}    Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}
    ${REMOTE_VM_PORT_LIST}    Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    Verify_VM_MAC_in_groups    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${LOCAL_VM_PORT_LIST}    ${REMOTE_VM_PORT_LIST}
    Verify_VM_MAC_in_groups    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${REMOTE_VM_PORT_LIST}    ${LOCAL_VM_PORT_LIST}
    Verify_Ping_and_Packet_Count    ${NETWORK_NAME}    ${ALLOWED_IP[0]}    ${VM_LIST[5]}

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
    [Documentation]    Create networks,subnets,ports,VMs,tep ports
    : FOR    ${COMPUTE_NUM}    IN    1    2    3
    \    Tep_Port_Operations    ${OPERATION[0]}    ${OS_COMPUTE_${COMPUTE_NUM}_IP}
    ${TEP_SHOW_OUTPUT}    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${TEP_SHOW_OUTPUT}
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp
    Create Network    ${NETWORK_NAME}
    Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_CIDR}
    ${ADD_ARG}    Catenate    --security-group    ${SECURITY_GROUP}
    : FOR    ${PORT_NAME}    IN    @{PORT_LIST}
    \    Create Port    ${NETWORK_NAME}    ${PORT_NAME}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP}
    Log    "Creating VMs on Compute 1"
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_LIST[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_LIST[1]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_LIST[2]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Log    "Creating VMs on Compute 2"
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_LIST[3]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_LIST[4]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_LIST[5]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Log to Console    "Creating VMs on Compute 3"
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_LIST[6]}    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_LIST[7]}    ${OS_COMPUTE_3_IP}    sg=${SECURITY_GROUP}
    Create Router    ${ROUTER_NAME}
    Add Router Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    &{VM_IP_DICT}    Create Dictionary
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    ${VM_IP}    Wait Until Keyword Succeeds    30s    2s    Verify Nova VM IP    ${VM_NAME}
    \    Set To Dictionary    ${VM_IP_DICT}    ${VM_NAME}=${VM_IP[0]}
    Log    ${VM_IP_DICT}
    Set Global Variable    ${VM_IP_DICT}
    ${CTRL_FIB}    Issue Command On Karaf Console    ${FIB_SHOW}
    Log    ${CTRL_FIB}
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    Should Contain    ${CTRL_FIB}    ${VM_IP_DICT.${VM_NAME}}

Delete Setup
    [Documentation]    Clean the config created
    : FOR    ${VM_NAME}    IN    @{VM_LIST}
    \    Run Keyword And Ignore Error    Delete Vm Instance    ${VM_NAME}
    : FOR    ${PORT_NAME}    IN    @{PORT_LIST}
    \    Run Keyword And Ignore Error    Delete Port    ${PORT_NAME}
    Run Keyword And Ignore Error    Update Router    ${ROUTER_NAME}    --no-routes
    Run Keyword And Ignore Error    Remove Interface    ${ROUTER_NAME}    ${SUBNET_NAME}
    Run Keyword And Ignore Error    Delete Router    ${ROUTER_NAME}
    Run Keyword And Ignore Error    Delete SubNet    ${SUBNET_NAME}
    Run Keyword And Ignore Error    Delete Network    ${NETWORK_NAME}
    : FOR    ${COMPUTE_NUM}    IN    1    2    3
    \    Tep_Port_Operations    ${OPERATION[1]}    ${OS_COMPUTE_${COMPUTE_NUM}_IP}
