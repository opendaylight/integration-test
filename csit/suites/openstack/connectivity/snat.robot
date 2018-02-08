*** Settings ***
Documentation     Test Migration of NAPT switch
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           String
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SECURITY_GROUP}    l3_ext_sg
${NETWORK}        l3_ext_net
${SUBNET}         l3_ext_sub
@{ROUTERS}        l3_ext_router_1    l3_ext_router_2
@{SNAT_VMS}       snat_vm_1
${SUBNET_CIDR}    41.0.0.0/24
&{OS_NODES}
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${EXTERNAL_GATEWAY}    10.10.10.250
${EXTERNAL_PNF}    10.10.10.253
${EXTERNAL_SUBNET}    10.10.10.0/24
${EXTERNAL_SUBNET_ALLOCATION_POOL}    start=10.10.10.2,end=10.10.10.249
#${EXTERNAL_INTERNET_ADDR}    10.9.9.9
${EXTERNAL_NET_NAME}    external-net
${EXTERNAL_SUBNET_NAME}    external-subnet
${CONTAINERS}    False

*** Test Cases ***
Get OS nodes
    [Documentation]    Set all the variables needed for later phases
    ${OS_CMP1_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP1_IP}
    ${OS_CMP2_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP2_IP}
    ${OS_ODL1_HOSTNAME} =    Get Node Name From Ip    ${ODL_SYSTEM_1_IP}
    ${OS_ODL2_HOSTNAME} =    Get Node Name From Ip    ${ODL_SYSTEM_2_IP}
    ${OS_ODL3_HOSTNAME} =    Get Node Name From Ip    ${ODL_SYSTEM_3_IP}
    BuiltIn.Set Suite Variable    ${OS_CNTL_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_CMP1_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_CMP2_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_ODL1_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_ODL2_HOSTNAME}
    BuiltIn.Set Suite Variable    ${OS_ODL3_HOSTNAME}
    ${OS_CMP1_SHORT} =    Fetch From Left    ${OS_CMP1_HOSTNAME}    .
    ${OS_CMP2_SHORT} =    Fetch From Left    ${OS_CMP2_HOSTNAME}    .
    ${OS_ODL1__SHORT} =    Fetch From Left    ${OS_ODL1_HOSTNAME}    .
    ${OS_ODL2__SHORT} =    Fetch From Left    ${OS_ODL2_HOSTNAME}    .
    ${OS_ODL3__SHORT} =    Fetch From Left    ${OS_ODL3_HOSTNAME}    .
    Set To Dictionary    ${OS_NODES}    ${OS_CMP1_SHORT}    ${OS_COMPUTE_1_IP}    ${OS_CMP2_SHORT}    ${OS_COMPUTE_2_IP}    ${OS_ODL1__SHORT}
    ...    ${ODL_SYSTEM_1_IP}    ${OS_ODL3__SHORT}    ${ODL_SYSTEM_2_IP}    ${OS_ODL3__SHORT}    ${ODL_SYSTEM_3_IP}
    BuiltIn.Set Suite Variable    ${OS_NODES}
    @{compute_nodes} =    Create List    ${OS_CMP1_HOSTNAME}    ${OS_CMP2_HOSTNAME}
    Set Suite Variable    ${compute_nodes}

Add SSH/ICMP Allow Rule
    [Documentation]    Allow SSH/ICMP traffic for this suite
    OpenStackOperations.Create Allow SSH/ICMP SecurityGroup Rule    ${SECURITY_GROUP}

Create External Network And Subnet
    OpenStackOperations.Create Network    ${EXTERNAL_NET_NAME}    --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    OpenStackOperations.Update Network    ${EXTERNAL_NET_NAME}    --external
    OpenStackOperations.Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${EXTERNAL_SUBNET}    --gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}

Create Private Network
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    ${NETWORK}

Create Subnet For Private Network
    [Documentation]    Create Sub Net for the Network with neutron request.
    OpenStackOperations.Create SubNet    ${NETWORK}    ${SUBNET}    ${SUBNET_CIDR}

Create Routers
    [Documentation]    Create Router and Add Interface to the subnets.
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}

Add Router Gateway To Router
    [Documentation]    OpenStackOperations.Add Router Gateway
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Add Router Gateway    ${router}    ${EXTERNAL_NET_NAME}

Launch an instance
    [Documentation]    Launch an instance on a node other than NAPT switch
    ${router}    ${router_id}    ${router_node_ip}    ${router_node_short_name}    ${router_node_long_name} =    Get Router On Compute
    BuiltIn.Set Suite Variable    ${router_id}
    BuiltIn.Set Suite Variable    ${router_node_short_name}
    BuiltIn.Set Suite Variable    ${router_node_long_name}
    BuiltIn.Set Suite Variable    ${router_node_ip}
    Remove Values From List    ${compute_nodes}    ${router_node_long_name}
    OpenStackOperations.Add Router Interface    ${router}    ${SUBNET}
    OpenStackOperations.Create Vm Instance On Compute Node    ${NETWORK}    @{SNAT_VMS}[0]    @{compute_nodes}[0]    sg=${SECURITY_GROUP}
    @{SNAT_VM_IPS} =    OpenStackOperations.Get VM IPs    @{SNAT_VMS}
    BuiltIn.Set Suite Variable    @{SNAT_VM_IPS}
    BuiltIn.Should Not Contain    @{SNAT_VM_IPS}[0]    None

Check Connectivity from the instance to external PNF
    [Documentation]    Check connecitivy from the instance without Floating IP to an external PNF
    ${EXTERNAL_IPS}=    BuiltIn.Create List    ${EXTERNAL_PNF}
    BuiltIn.Set Suite Variable    ${EXTERNAL_IPS}
    OpenStackOperations.Test Operations From Vm Instance    ${NETWORK}    @{SNAT_VM_IPS}[0]    ${EXTERNAL_IPS}

Verify Migration
    [Documentation]    Verify that the NAPT switch moved to a different node
    [Setup]    Block Traffic on NAPT switch node
    ${result} =    Wait Until Keyword Succeeds    5x    20s    Check Router Migrated
    [Teardown]    Run Keywords    Allow Traffic on all compute nodes

*** Keywords ***
Check Router Migrated
    ${new_router_node_ip} =    Get NAPT Switch Node    ${router_id}
    BuiltIn.Should Not Contain    ${new_router_node_ip}    ${router_node_ip}

Block Traffic on NAPT switch node
    [Documentation]    Block port 6653 on the node that holds the NAPT switch
    Utils.Modify Iptables On Remote System    ${OS_NODES['${router_node_shortname}']}    -I OUTPUT 1 -p tcp --dport 6653 -j DROP

Get Node Name From Ip
    [Arguments]    ${ip}
    [Documentation]    Get Node Name From IP by looking at the first controller hosts file
    Get ControlNode Connection
    ${command} =    BuiltIn.Set Variable    sudo getent hosts ${ip} | awk '{print $2}'
    ${output} =    Utils.Run Command On Controller    ${ODL_SYSTEM_1_IP}    cmd=${command}
    [Return]    ${output}
Get NAPT Switch Node
    [Arguments]    ${router_id}
    [Documentation]    Get NAPT Switch Node of a router
    Get ControlNode Connection
    ${output} =    Run Keyword If    ${CONTAINERS}==True    @{DISPLAY_NAPT_CMD_CONTAINERS}
    ...            ELSE    Run Keyword    @{DISPLAY_NAPT_CMD}
    ${match}    ${node_ip} =    Should Match Regexp    ${output}    ${router_id}\\s+\\S+\\s+(\\S+)
    [Return]    ${node_ip}

Get Router On Compute
    [Documentation]    Get the the Node Name of the router that is on a compute node
    : FOR    ${router}    IN    @{ROUTERS}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router}
    \    ${router_node_ip} =    Get NAPT Switch Node    ${router_id}
    \    ${router_node_name} =    Get Node Name From Ip    ${router_node_ip}
    \    ${router_node_short_name} =    Fetch From Left    ${router_node_name}    .
    \    ${cmp1}    ${domain_name} =    Split String    ${OS_CMP1_HOSTNAME}    .    1
    \    ${router_node_long_name} =    Set Variable    ${router_node_short_name}.${domain_name}
    \    ${count} =    Get Match Count    ${compute_nodes}    ${router_node_long_name}
    \    Run Keyword If    "${count}" == "1"    Exit For Loop
    [Return]    ${router}    ${router_id}    ${router_node_ip}    ${router_node_short_name}    ${router_node_long_name}

Allow Traffic on all compute nodes
    [Documentation]    Remove IPTables rules that we blocked
    : FOR    ${node}    IN    ${OS_CMP1_IP}    ${OS_CMP2_IP}
    \    Utils.Modify Iptables On Remote System    ${node}    -D OUTPUT -p tcp --dport 6653 -j DROP
