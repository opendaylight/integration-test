*** Settings ***
Documentation     Test Suit for ACL Service Recovery
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    sg
@{NETWORKS}       net_1    net_2    net_3
@{SUBNETS}        sub_1    sub_2    sub_3
@{SUBNET_CIDRS}    81.1.1.0/24    82.1.1.0/24    83.1.1.0/24
@{NET_1_PORTS}    net_1_port_1    net_1_port_2
@{NET_2_PORTS}    net_2_port_1    net_2_port_2
@{NET_3_PORTS}    net_3_port_1    net_3_port_2
@{NET_1_VMS}      net_1_vm_1    net_1_vm_2
@{NET_2_VMS}      net_2_vm_1    net_2_vm_2
@{NET_3_VMS}      net_3_vm_1    net_3_vm_2
@{table_ids}      211    244    240

*** Test Cases ***
Create Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    ${SUBNET_CIDRS[0]}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${NET_1_PORTS[0]}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    ${NET_1_PORTS[1]}    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${NET_1_PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_1_PORTS[0]}    ${NET_1_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${NET_1_PORTS[1]}    ${NET_1_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    Builtin.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    @{NET_1_MACS} =    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Get Ports MacAddr    ${NET_1_PORTS}
    Builtin.Set Suite Variable    @{NET_1_MACS}
	
ACL Service Recovery CLI
    [Documentation]    This test case covers ACL service recovery. 
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${count_before}    Set Variable    ${list[0]}
    ${node_id}    Genius.Get Dpn Ids    ${OS_CMP1_CONN_ID}
    ${resp}=      RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${node_id}/flow-node-inventory:table/${table_ids[0]}
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Should Not Contain    ${output}    table=${table_ids[0]}
    ${output}=    Issue_Command_On_Karaf_Console    srm:recover service acl
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[0]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${count_after}    Set Variable    ${list[0]}
    Should Be Equal As Numbers    ${count_before}    ${count_after}

ACL Instance Recovery CLI
    [Documentation]    This test case covers ACL instance recovery.
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${count_before}    Set Variable    ${list[0]}
    ${node_id}    Genius.Get Dpn Ids    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl del-flows br-int -OOpenflow13 "table=${table_ids[1]},icmp"    ${DEFAULT_LINUX_PROMPT_STRICT}
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Should Not Contain    ${output}    icmp
    ${output}=    Write Commands Until Expected Prompt    openstack security group show ${SECURITY_GROUP} | awk '/ id / {print $4}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${instance_id} =    Collections.Get from List    ${splitted_output}    0
    ${output}=    Issue_Command_On_Karaf_Console    srm:recover instance acl-instance ${instance_id}
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[1]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${count_after}    Set Variable    ${list[0]}
    Should Be Equal As Numbers    ${count_before}    ${count_after}

ACL Interface Recovery CLI
    [Documentation]    This test case covers ACL interface recovery.
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output}=    Write Commands Until Expected Prompt    openstack port show ${NET_1_PORTS[0]} |awk '/ mac_address / {print$4}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${port_mac}    Set Variable    ${list[0]}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]} | grep ${port_mac}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${count_before}    Set Variable    ${list[0]}
    ${node_id}    Genius.Get Dpn Ids    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl del-flows br-int -OOpenflow13 "table=${table_ids[2]},dl_dst=${port_mac}"    ${DEFAULT_LINUX_PROMPT_STRICT}
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Should Not Contain    ${output}    ${port_mac}
    ${output}=    Write Commands Until Expected Prompt    openstack port show ${NET_1_PORTS[0]} |awk '/ id / {print$4}'    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${splitted_output} =    String.Split String    ${output}    ${EMPTY}
    ${interface_id} =    Collections.Get from List    ${splitted_output}    0
    ${output}=    Issue_Command_On_Karaf_Console    srm:recover instance acl-interface ${interface_id}
    Should Contain    ${output}    RPC call to recover was successful
    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
    SSHLibrary.Switch Connection    ${OS_CMP1_CONN_ID}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_ids[2]} | wc -l    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list}=    Split String    ${output}
    ${count_after}    Set Variable    ${list[0]}
    Should Be Equal As Numbers    ${count_before}    ${count_after}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
    ...    AND    Multiple Testsuite Cleanup

*** Keywords ***
Multiple Testsuite Cleanup
    [Documentation]    Delete network,subnet and port
    OpenStackOperations.Get Test Teardown Debugs
    OpenStackOperations.Delete Vm Instance    ${NET_1_VMS[0]}
    OpenStackOperations.Delete Vm Instance    ${NET_1_VMS[1]}
    OpenStackOperations.Delete Port    ${NET_1_PORTS[0]}
    OpenStackOperations.Delete Port    ${NET_1_PORTS[1]}
    OpenStackOperations.Delete SubNet    @{SUBNETS}[1]
    OpenStackOperations.Delete SubNet    @{SUBNETS}[2]
    OpenStackOperations.Delete Network    @{NETWORKS}[1]
    OpenStackOperations.Delete Network    @{NETWORKS}[2]
