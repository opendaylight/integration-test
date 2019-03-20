*** Settings ***
Documentation     Test Suite for ACL Service Recovery:
...               The Service Recovery Manager provides
...               common interface to recover services in ODL.
...               This feature will register ACL service for recovery
...               and implement the mechanism to recover ACL service.
Suite Setup       Suite Setup
Suite Teardown    Run Keywords    OpenStackOperations.OpenStack Suite Teardown
...               AND    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    INFO    ${TEST_LOG_COMPONENTS}
Test Setup        Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${acl_sr_security_group}    acl_sr_sg
@{acl_sr_networks}    acl_sr_net_1    acl_sr_net_2    acl_sr_net_3
@{acl_sr_subnets}    acl_sr_sub_1    acl_sr_sub_2    acl_sr_sub_3
@{acl_sr_subnet_cidrs}    81.1.1.0/24    82.1.1.0/24    83.1.1.0/24
@{acl_sr_net_1_ports}    acl_sr_net_1_port_1    acl_sr_net_1_port_2
@{acl_sr_net_1_vms}    acl_sr_net_1_vm_1    acl_sr_net_1_vm_2
${TEST_LOG_LEVEL}    trace
@{TEST_LOG_COMPONENTS}    org.opendaylight.netvirt.aclservice    org.opendaylight.genius.interfacemanager    org.opendaylight.genius.srm

*** Test Cases ***
ACL Service Recovery CLI
    [Documentation]    This test case covers ACL service recovery.
    ${count_before} =    OvsManager.Get Dump Flows Count    ${OS_CMP1_CONN_ID}    ${INGRESS_ACL_REMOTE_ACL_TABLE}
    ${node_id} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${node_id}/flow-node-inventory:table/${INGRESS_ACL_REMOTE_ACL_TABLE}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{acl_sr_networks}[0]    @{ACL_SR_NET_1_VM_IPS}[0]
    ${flow_after_delete} =    OvsManager.Get Dump Flows Count    ${OS_CMP1_CONN_ID}    ${INGRESS_ACL_REMOTE_ACL_TABLE}
    BuiltIn.Should Be Equal As Strings    ${flow_after_delete}    0
    ${output} =    Issue_Command_On_Karaf_Console    srm:recover service acl
    BuiltIn.Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Ping Vm From DHCP Namespace    @{acl_sr_networks}[0]    @{ACL_SR_NET_1_VM_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify Flow Counts Are Same    ${count_before}    ${INGRESS_ACL_REMOTE_ACL_TABLE}

ACL Instance Recovery CLI
    [Documentation]    This test case covers ACL instance recovery.
    ${count_before} =    OvsManager.Get Dump Flows Count    ${OS_CMP1_CONN_ID}    ${EGRESS_LEARN_ACL_FILTER_TABLE}
    ${node_id} =    OVSDB.Get DPID    ${OS_CMP1_IP}
    Write Commands Until Expected Prompt    sudo ovs-ofctl del-flows br-int -OOpenflow13 "table=${EGRESS_LEARN_ACL_FILTER_TABLE},icmp"    ${DEFAULT_LINUX_PROMPT_STRICT}
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{acl_sr_networks}[0]    @{ACL_SR_NET_1_VM_IPS}[0]
    ${output} =    OpenStack CLI    openstack security group show ${acl_sr_security_group} | awk '/ id / {print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${instance_id} =    Collections.Get from List    ${splitted_output}    0
    ${output} =    Issue_Command_On_Karaf_Console    srm:recover instance acl-instance ${instance_id}
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Ping Vm From DHCP Namespace    @{acl_sr_networks}[0]    @{ACL_SR_NET_1_VM_IPS}[0]
    Wait Until Keyword Succeeds    30s    5s    OVSDB.Verify Dump Flows For Specific Table    ${OS_CMP1_CONN_ID}    ${EGRESS_LEARN_ACL_FILTER_TABLE}    icmp
    Wait Until Keyword Succeeds    30s    5s    Verify Flow Counts Are Same    ${count_before}    ${EGRESS_LEARN_ACL_FILTER_TABLE}

*** Keywords ***
Verify Flow Counts Are Same
    [Arguments]    ${count_before}    ${table_id}    ${port_mac}=""
    [Documentation]    Verify flows count should be same as before and after for a table id with a given port mac.
    ${count_after} =    OvsManager.Get Dump Flows Count    ${OS_CMP1_CONN_ID}    ${table_id}    port_mac=${port_mac}
    BuiltIn.Should Be Equal As Numbers    ${count_before}    ${count_after}

Suite Setup
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs.
    OpenStackOperations.OpenStack Suite Setup
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}    ${TEST_LOG_COMPONENTS}
    OpenStackOperations.Create Allow All SecurityGroup    ${acl_sr_security_group}
    OpenStackOperations.Create Network    @{acl_sr_networks}[0]
    OpenStackOperations.Create SubNet    @{acl_sr_networks}[0]    @{acl_sr_subnets}[0]    ${acl_sr_subnet_cidrs[0]}
    OpenStackOperations.Create Port    @{acl_sr_networks}[0]    ${acl_sr_net_1_ports[0]}    sg=${acl_sr_security_group}
    OpenStackOperations.Create Port    @{acl_sr_networks}[0]    ${acl_sr_net_1_ports[1]}    sg=${acl_sr_security_group}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${acl_sr_net_1_ports}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${acl_sr_net_1_ports[0]}    ${acl_sr_net_1_vms[0]}    ${OS_CMP1_HOSTNAME}    sg=${acl_sr_security_group}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${acl_sr_net_1_ports[1]}    ${acl_sr_net_1_vms[1]}    ${OS_CMP2_HOSTNAME}    sg=${acl_sr_security_group}
    @{ACL_SR_NET_1_VM_IPS}    ${net1_dhcp_ip} =    OpenStackOperations.Get VM IPs    @{acl_sr_net_1_vms}
    BuiltIn.Set Suite Variable    @{ACL_SR_NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${ACL_SR_NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${net1_dhcp_ip}    None
    OpenStackOperations.Ping Vm From DHCP Namespace    @{acl_sr_networks}[0]    @{ACL_SR_NET_1_VM_IPS}[0]
    OpenStackOperations.Ping Vm From DHCP Namespace    @{acl_sr_networks}[0]    @{ACL_SR_NET_1_VM_IPS}[1]
