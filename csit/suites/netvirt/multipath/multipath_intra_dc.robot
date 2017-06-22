*** Settings ***
Documentation     Test suite for MultiPath
Suite Setup       Create Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
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
@{NETWORKS}       network_1
@{SUBNETS}        subnet_1
${ROUTERS}        router_1
@{PORT_LIST}      port_1    port_2    port_3    port_4    port_5    port_6
@{VM_LIST}        vm_1    vm_2    vm_3    vm_4    vm_5    vm_6
${SUBNET_CIDR}    10.10.1.0/24
${SECURITY_GROUP}    multipath-sg
@{ALLOWED_IP}     100.100.100.100    110.110.110.110
@{MASK}           32    255.255.255.0
${NO_OF_STATIC_IP}    1
@{OPERATION}      add    delete
@{BUCKET_COUNTS}    0    1    2    3    4    5
${NO_OF_VM_PER_COMPUTE}    3
${NO_OF_PING_PACKETS}    15
@{NO_OF_COMPUTE}    0    1    2    3

*** Testcases ***
TC01 Verify Distribution of traffic with 3 VM on Compute1 , 2 VM on Compute2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different Computes with NextHop configured on 3 VM on Compute1 and 2 VM on Compute2
    BuiltIn.Log    Update the Router with MultiPath Route
    @{vm_ip_list}    BuiltIn.Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[2]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    MultiPathOperations.Configure_Next_Hops_On_Router    ${ROUTERS}    ${NO_OF_STATIC_IP}    ${vm_ip_list}    ${ALLOWED_IP[0]}
    : FOR    ${vm_ip}    IN    @{vm_ip_list}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Configure_IP_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Verify_IP_Configured_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    ${ctrl_fib}    KarafKeywords.Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    BuiltIn.Should Match Regexp    ${ctrl_fib}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    BuiltIn.Should Match Regexp    ${ctrl_fib}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    ${group_id_1}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[3]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${group_id_2}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[3]}    ${ALLOWED_IP[0]}
    BuiltIn.Log    Verify that the MultiPath Group ID is same in both Compute Nodes
    BuiltIn.Should Be Equal As Strings    ${group_id_1}    ${group_id_2}
    ${local_vm_port_list}    BuiltIn.Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}    ${PORT_LIST[2]}
    ${remote_vm_port_list}    BuiltIn.Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${local_vm_port_list}    ${remote_vm_port_list}    ${group_id_1}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${remote_vm_port_list}    ${local_vm_port_list}    ${group_id_2}
    ${compute_node_ip}    OpenStackOperations.Verify_Packet_Count_Before_And_After_Ping    ${NETWORKS[0]}    ${ALLOWED_IP[0]}    ${VM_IP_DICT.${VM_LIST[5]}}    ${NO_OF_PING_PACKETS}    ${NO_OF_COMPUTE[2]}
    MultiPathOperations.Verify_Group_Stats_Packet_Count    ${compute_node_ip}    ${ALLOWED_IP[0]}    ${group_id_1}

TC02 Verify Distribution of traffic with 2 VM on Compute1 , 2 VM on Compute2
    [Documentation]    Verify The CSC should support MultiPath traffic splitting on L3VPN within DC across VMs located on different Computes with NextHop configured on 2 VM on Compute1 and 2 VM on Compute2
    OpenStackOperations.Update Router    ${ROUTERS}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTERS}    -D
    @{vm_ip_list}    BuiltIn.Create List    ${VM_IP_DICT.${VM_LIST[0]}}    ${VM_IP_DICT.${VM_LIST[1]}}    ${VM_IP_DICT.${VM_LIST[3]}}    ${VM_IP_DICT.${VM_LIST[4]}}
    MultiPathOperations.Configure_Next_Hops_On_Router    ${ROUTERS}    ${NO_OF_STATIC_IP}    ${vm_ip_list}    ${ALLOWED_IP[0]}
    : FOR    ${vm_ip}    IN    @{vm_ip_list}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Configure_IP_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}    ${MASK[1]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    OpenStackOperations.Verify_IP_Configured_On_Sub_Interface    ${NETWORKS[0]}    ${ALLOWED_IP[0]}
    \    ...    ${vm_ip}
    ${ctrl_fib}    KarafKeywords.Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    BuiltIn.Should Match Regexp    ${ctrl_fib}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_1_IP}
    BuiltIn.Should Match Regexp    ${ctrl_fib}    ${ALLOWED_IP[0]}\/${MASK[0]}\\s+${OS_COMPUTE_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    100s    20s    OpenStackOperations.Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_DICT.${VM_LIST[2]}}    sudo ifconfig eth0:0 ${ALLOWED_IP[0]} netmask ${MASK[1]} down
    ${group_id_1}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_1_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    ${group_id_2}    MultiPathOperations.Verify_Flows_In_Compute_Node    ${OS_COMPUTE_2_IP}    ${BUCKET_COUNTS[2]}    ${BUCKET_COUNTS[2]}    ${ALLOWED_IP[0]}
    BuiltIn.Log    Verify that the MultiPath Group ID is same in both Compute Nodes
    BuiltIn.Should Be Equal As Strings    ${group_id_1}    ${group_id_2}
    ${local_vm_port_list}    BuiltIn.Create List    ${PORT_LIST[0]}    ${PORT_LIST[1]}
    ${remote_vm_port_list}    BuiltIn.Create List    ${PORT_LIST[3]}    ${PORT_LIST[4]}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_1_IP}    ${ALLOWED_IP[0]}    ${local_vm_port_list}    ${remote_vm_port_list}    ${group_id_1}
    MultiPathOperations.Verify_VM_Mac    ${OS_COMPUTE_2_IP}    ${ALLOWED_IP[0]}    ${remote_vm_port_list}    ${local_vm_port_list}    ${group_id_2}
    ${compute_node_ip}    OpenStackOperations.Verify_Packet_Count_Before_And_After_Ping    ${NETWORKS[0]}    ${ALLOWED_IP[0]}    ${VM_IP_DICT.${VM_LIST[5]}}    ${NO_OF_PING_PACKETS}    ${NO_OF_COMPUTE[2]}
    MultiPathOperations.Verify_Group_Stats_Packet_Count    ${compute_node_ip}    ${ALLOWED_IP[0]}    ${group_id_1}

*** Keywords ***
Create Setup
    [Documentation]    Create networks,subnets,ports,VMs
    OpenStackOperations.OpenStack Suite Setup
    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    ${NETWORKS[0]}
    OpenStackOperations.Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR}
    : FOR    ${port_name}    IN    @{PORT_LIST}
    \    OpenStackOperations.Create Port    ${NETWORKS[0]}    ${port_name}    sg=${SECURITY_GROUP}    allowed_address_pairs=@{ALLOWED_IP}
    : FOR    ${Index}    IN RANGE    ${NO_OF_VM_PER_COMPUTE}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}]}    ${VM_LIST[${Index}]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${PORT_LIST[${Index}+${NO_OF_VM_PER_COMPUTE}]}    ${VM_LIST[${Index}+${NO_OF_VM_PER_COMPUTE}]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Router    ${ROUTERS}
    OpenStackOperations.Add Router Interface    ${ROUTERS}    ${SUBNETS[0]}
    &{VM_IP_DICT}    BuiltIn.Create Dictionary
    : FOR    ${vm_name}    IN    @{VM_LIST}
    \    ${vm_ip}    BuiltIn.Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Nova VM IP    ${vm_name}
    \    Collections.Set To Dictionary    ${VM_IP_DICT}    ${vm_name}=${vm_ip}
    BuiltIn.Set Global Variable    ${VM_IP_DICT}
    ${ctrl_fib}    KarafKeywords.Issue_Command_On_Karaf_Console    ${FIB_SHOW}
    : FOR    ${vm_name}    IN    @{VM_LIST}
    \    BuiltIn.Should Contain    ${ctrl_fib}    ${VM_IP_DICT.${vm_name}}
