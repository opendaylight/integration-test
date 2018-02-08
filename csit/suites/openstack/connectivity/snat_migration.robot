*** Settings ***
Documentation     Test Migration of NAPT switch
Suite Setup       Run Keywords    OpenStackOperations.OpenStack Suite Setup    Create Resources
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           SSHLibrary
Library           String
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${NETWORK}        l3_snatm_net_1
&{OS_NODES}
@{ROUTERS}        l3_snatm_1    l3_snatm_2
${SECURITY_GROUP}    l3_snatm_sg
@{SNAT_VMS}       snat_vm_1
@{SNAT_VM_IPS}

*** Test Cases ***
Check Migration
    &{router} =    Get Router On Compute
    Launch An Instance    ${router}
    @{SNAT_VM_IPS}    ${DHCP_IP} =    OpenStackOperations.Get VM IPs    @{SNAT_VMS}
    BuiltIn.Should Not Contain    ${SNAT_VM_IPS}    None
    Check Connectivity from the instance to external PNF    ${SNAT_VM_IPS}
    Verify Migration    ${router}
    [Teardown]    Builtin.Run Keywords    Allow Traffic on all compute nodes    OpenStackOperations.Get Test Teardown Debugs

*** Keywords ***
Create Resources
    [Documentation]    Create Security group rules for SSH and ICMP, Create internal and external networks, Create routers and set their gateways
    OpenStackOperations.Create Allow SSH/ICMP SecurityGroup Rule    ${SECURITY_GROUP}
    OpenStackOperations.Create External Network And Subnet
    OpenStackOperations.Create Network    ${NETWORK}
    OpenStackOperations.Create SubNet    ${NETWORK}    ${SUBNET}    ${SUBNET_CIDR}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Add Router Gateway    ${router}    ${EXTERNAL_NET_NAME}

Launch An Instance
    [Arguments]    ${router}
    [Documentation]    Launch an instance on a node other than NAPT switch
    Collections.Remove Values From List    ${CMP_NODES_HOSTNAMES}    ${router.router_node_long_name}
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
    ${result} =    Wait Until Keyword Succeeds    15s    5s    Check Router Migrated    ${router}

Check Router Migrated
    [Arguments]    ${router}
    [Documentation]    Check that the Node IP of that NAPT switch is different from the one
    ${new_router_node_ip} =    Get NAPT Switch Node    ${router.router_id}
    BuiltIn.Should Not Contain    ${new_router_node_ip}    ${router.router_node_ip}

Block Egress OpenFlow Traffic on NAPT switch node
    [Arguments]    ${router}
    [Documentation]    Block port Egress OpenFlow Traffic (Port ${ODL_OF_PORT_6653}) on the node that holds the NAPT switch to force migration of the router
    Utils.Modify Iptables On Remote System    ${OS_NODES['${router.router_node_short_name}']}    -I OUTPUT 1 -p tcp --dport ${ODL_OF_PORT_6653} -j DROP

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
