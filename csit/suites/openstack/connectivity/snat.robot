*** Settings ***
Documentation     Test Migration of NAPT switch
Suite Setup       Run Keywords    OpenStackOperations.OpenStack Suite Setup    Get OS nodes
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
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{CMP_NODES_HOSTNAMES}
&{OS_NODES}
@{ROUTERS}        l3_ext_router_1    l3_ext_router_2
@{SNAT_VMS}       snat_vm_1
@{SNAT_VM_IPS}

*** Test Cases ***
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

Check Migration
    &{router} =    Get Router On Compute
    Launch An Instance    ${router}
    @{SNAT_VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{SNAT_VMS}
    BuiltIn.Should Not Contain    ${SNAT_VM_IPS}    None
    Check Connectivity from the instance to external PNF    ${SNAT_VM_IPS}
    Verify Migration    ${router}
    [Teardown]    Run Keywords    Allow Traffic on all compute nodes

*** Keywords ***
Get OS nodes
    [Documentation]    Set all the variables needed for later phases
    ${OS_CMP_1_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP1_IP}
    ${OS_CMP_2_HOSTNAME} =    OpenStackOperations.Get Hypervisor Hostname From IP    ${OS_CMP2_IP}
    ${OS_CNTL_1_HOSTNAME} =    Get Node Name From Ip    ${OS_CNTL_1_IP}
    ${OS_CNTL_2_HOSTNAME} =    Get Node Name From Ip    ${OS_CNTL_2_IP}
    ${OS_CNTL_3_HOSTNAME} =    Get Node Name From Ip    ${OS_CNTL_3_IP}
    ${OS_CMP_1_SHORT} =    Fetch From Left    ${OS_CMP_1_HOSTNAME}    .
    ${OS_CMP_2_SHORT} =    Fetch From Left    ${OS_CMP_2_HOSTNAME}    .
    ${OS_CNTL_1__SHORT} =    Fetch From Left    ${OS_CNTL_1_HOSTNAME}    .
    ${OS_CNTL_2__SHORT} =    Fetch From Left    ${OS_CNTL_2_HOSTNAME}    .
    ${OS_CNTL_3__SHORT} =    Fetch From Left    ${OS_CNTL_3_HOSTNAME}    .
    Collections.Set To Dictionary    ${OS_NODES}    ${OS_CMP_1_SHORT}    ${OS_CMP_2_IP}    ${OS_CMP_2_SHORT}    ${OS_CMP_2_IP}    ${OS_CNTL_1__SHORT}
    ...    ${OS_CNTL_1_IP}    ${OS_CNTL_2__SHORT}    ${OS_CNTL_2_IP}    ${OS_CNTL_2_SHORT}    ${OS_CNTL_3_IP}
    @{CMP_NODES_HOSTNAMES} =    Create List    ${OS_CMP_1_HOSTNAME}    ${OS_CMP_2_HOSTNAME}
    BuiltIn.Set Suite Variable    ${CMP_NODES_HOSTNAMES}

Launch An Instance
    [Arguments]    ${router}
    [Documentation]    Launch an instance on a node other than NAPT switch
    Remove Values From List    ${CMP_NODES_HOSTNAMES}    ${router.router_node_long_name}
    OpenStackOperations.Add Router Interface    ${router.router_name}    ${SUBNET}
    OpenStackOperations.Create Vm Instance On Compute Node    ${NETWORK}    @{SNAT_VMS}[0]    @{CMP_NODES_HOSTNAMES}[0]    sg=${SECURITY_GROUP}

Check Connectivity from the instance to external PNF
    [Arguments]    ${SNAT_VM_IPS}
    [Documentation]    Check connecitivy from the instance without Floating IP to an external PNF
    ${EXTERNAL_IPS} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    ${NETWORK}    @{SNAT_VM_IPS}[0]    ${EXTERNAL_IPS}

Verify Migration
    [Arguments]    ${router}
    [Documentation]    Verify that the NAPT switch moved to a different node
    Block Egress OpenFlow Traffic on NAPT switch node    ${router}
    ${result} =    Wait Until Keyword Succeeds    120s    5s    Check Router Migrated    ${router}

Check Router Migrated
    [Arguments]    ${router}
    [Documentation]    Check that the Node IP of that NAPT switch is different from the one
    ${new_router_node_ip} =    Get NAPT Switch Node    ${router.router_id}
    BuiltIn.Should Not Contain    ${new_router_node_ip}    ${router.router_node_ip}

Block Egress OpenFlow Traffic on NAPT switch node
    [Arguments]    ${router}
    [Documentation]    Block port Egress OpenFlow Traffic (Port ${ODL_OF_PORT_6653}) on the node that holds the NAPT switch to force migration of the router
    Utils.Modify Iptables On Remote System    ${OS_NODES['${router.router_node_short_name}']}    -I OUTPUT 1 -p tcp --dport ${ODL_OF_PORT_6653} -j DROP

Get Node Name From Ip
    [Arguments]    ${ip}
    [Documentation]    Get Node Name From IP by looking at the first controller hosts file
    ${output} =    Utils.Run Command On Controller    ${ODL_SYSTEM_1_IP}    sudo getent hosts ${ip} | awk '{print $2}'
    [Return]    ${output}

Get NAPT Switch Node
    [Arguments]    ${router_id}
    [Documentation]    Get NAPT Switch Node of a router
    ${output} =    Run Keyword If    ${CONTAINERS}==True    @{DISPLAY_NAPT_CMD_CONTAINERS}
    ...    ELSE    Run Keyword    @{DISPLAY_NAPT_CMD}
    # Get the Node IP that holds the NAPT switch for the router
    ${match}    ${node_ip} =    Should Match Regexp    ${output}    ${router_id}\\s+\\S+\\s+(\\S+)
    [Return]    ${node_ip}

Get Router On Compute
    [Documentation]    Get the the Node Name of the router that is on a compute node
    : FOR    ${router_name}    IN    @{ROUTERS}
    \    ${router_id} =    OpenStackOperations.Get Router Id    ${router_name}
    \    ${router_node_ip} =    Get NAPT Switch Node    ${router_id}
    \    ${router_node_name} =    Get Node Name From Ip    ${router_node_ip}
    \    ${router_node_short_name} =    Fetch From Left    ${router_node_name}    .
    \    ${cmp1}    ${domain_name} =    Split String    ${OS_CMP1_HOSTNAME}    .    1
    \    ${router_node_long_name} =    Set Variable    ${router_node_short_name}.${domain_name}
    \    ${count} =    Get Match Count    ${CMP_NODES_HOSTNAMES}    ${router_node_long_name}
    \    Run Keyword If    "${count}" == "1"    Exit For Loop
    &{router} =    Builtin.Create Dictionary    router_name=${router_name}    router_id=${router_id}    router_node_ip=${router_node_ip}    router_node_short_name=${router_node_short_name}    router_node_long_name=${router_node_long_name}
    [Return]    ${router}

Allow Traffic on all compute nodes
    [Documentation]    Remove IPTables rules that we blocked
    : FOR    ${node}    IN    ${OS_CMP1_IP}    ${OS_CMP2_IP}
    \    Utils.Modify Iptables On Remote System    ${node}    -D OUTPUT -p tcp --dport ${ODL_OF_PORT_6653} -j DROP
