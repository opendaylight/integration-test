*** Settings ***
Documentation     Test Suite for ACL Service Recovery: 
...               The Service Recovery Manager provides 
...               common interface to recover services in ODL.
...               This feature will register ACL service for recovery
...               and implement the mechanism to recover ACL service.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot



*** Variables ***
${acl_sr_security_group}    acl_sr_sg
@{acl_sr_networks}       acl_sr_net_1    acl_sr_net_2    acl_sr_net_3
@{acl_sr_subnets}        acl_sr_sub_1    acl_sr_sub_2    acl_sr_sub_3
@{acl_sr_subnet_cidrs}    81.1.1.0/24    82.1.1.0/24    83.1.1.0/24
@{acl_sr_net_1_ports}    acl_sr_net_1_port_1    acl_sr_net_1_port_2
@{acl_sr_net_1_vms}      acl_sr_net_1_vm_1    acl_sr_net_1_vm_2
@{table_ids}      211    244    240

*** Test Cases ***
ACL Service Recovery CLI
    [Documentation]    This test case covers ACL service recovery.
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${count_before}    Set Variable    ${list[0]}
    ${node_id}   OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    ${resp} =      RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${node_id}/flow-node-inventory:table/${table_ids[0]}
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Should Not Contain    ${output}    table=${table_ids[0]}
    ${output} =    Issue_Command_On_Karaf_Console    srm:recover service acl
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${count_after}    Set Variable    ${list[0]}
    Should Be Equal As Numbers    ${count_before}    ${count_after}

ACL Instance Recovery CLI
    [Documentation]    This test case covers ACL instance recovery.
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${count_before}    Set Variable    ${list[0]}
    ${node_id}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    Write Commands Until Expected Prompt    sudo ovs-ofctl del-flows br-int -OOpenflow13 "table=${table_ids[1]},icmp"    ${DEFAULT_LINUX_PROMPT_STRICT}
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Should Not Contain    ${output}    icmp
    ${output} =    OpenStack CLI    openstack security group show ${acl_sr_security_group} | awk '/ id / {print $4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${instance_id} =    Collections.Get from List    ${splitted_output}    0
    ${output} =    Issue_Command_On_Karaf_Console    srm:recover instance acl-instance ${instance_id}
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${count_after}    Set Variable    ${list[0]}
    Should Be Equal As Numbers    ${count_before}    ${count_after}

ACL Interface Recovery CLI
    [Documentation]    This test case covers ACL interface recovery.
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output} =    OpenStack CLI    openstack port show ${acl_sr_net_1_ports[0]} |awk '/ mac_address / {print$4}'
    @{list} =    Split String    ${output}
    ${port_mac}    Set Variable    ${list[0]}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]} | grep ${port_mac}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${count_before}    Set Variable    ${list[0]}
    ${node_id}    OVSDB.Get DPID    ${OS_COMPUTE_1_IP}
    Write Commands Until Expected Prompt    sudo ovs-ofctl del-flows br-int -OOpenflow13 "table=${table_ids[2]},dl_dst=${port_mac}"    ${DEFAULT_LINUX_PROMPT_STRICT}
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Should Not Contain    ${output}    ${port_mac}
    ${output} =    OpenStack CLI    openstack port show ${acl_sr_net_1_ports[0]} |awk '/ id / {print$4}'
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${interface_id} =    Collections.Get from List    ${splitted_output}    0
    ${output} =    Issue_Command_On_Karaf_Console    srm:recover instance acl-interface ${interface_id}
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${count_after}    Set Variable    ${list[0]}
    Should Be Equal As Numbers    ${count_before}    ${count_after}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    OpenStackOperations.Suite Teardown

*** Keywords ***
Start Suite
    [Documentation]    Basic setup.
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${acl_sr_security_group}
    OpenStackOperations.Create Network    @{acl_sr_networks}[0]
    OpenStackOperations.Create SubNet    @{acl_sr_networks}[0]    @{acl_sr_subnets}[0]    ${acl_sr_subnet_cidrs[0]}
    OpenStackOperations.Create Port    @{acl_sr_networks}[0]    ${acl_sr_net_1_ports[0]}    sg=${acl_sr_security_group}
    OpenStackOperations.Create Port    @{acl_sr_networks}[0]    ${acl_sr_net_1_ports[1]}    sg=${acl_sr_security_group}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${acl_sr_net_1_ports}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${acl_sr_net_1_ports[0]}    ${acl_sr_net_1_vms[0]}    ${OS_CMP1_HOSTNAME}    sg=${acl_sr_security_group}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${acl_sr_net_1_ports[1]}    ${acl_sr_net_1_vms[1]}    ${OS_CMP2_HOSTNAME}    sg=${acl_sr_security_group}
