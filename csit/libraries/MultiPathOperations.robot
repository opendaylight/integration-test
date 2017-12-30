*** Settings ***
Documentation     This library is useful to check flows for a given IP, get VM MAC, \ verify the group stats packet count and add/delete Tep Ports
Library           SSHLibrary
Resource          DevstackUtils.robot
Resource          OpenStackOperations.robot
Resource          OVSDB.robot
Resource          Utils.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
${TABLE_21}       table=21

*** Keywords ***
Verify_Flows_In_Compute_Node
    [Arguments]    ${compute_ip}    ${expected_local_bucket_entry}    ${expected_remote_bucket_entry}    ${static_ip}
    [Documentation]    Verify flows w.r.t the specified IP and the corresponding local bucket entry and remote bucket entry
    ${ovs_flow}    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_FLOWS} | grep ${TABLE_21}
    ${ovs_group}    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_GROUPS}
    ${match}    ${group_id}    BuiltIn.Should Match Regexp    ${ovs_flow}    ${TABLE_21}.*nw_dst=${static_ip}.*group:(\\d+)
    ${multi_path_group_id}    BuiltIn.Should Match Regexp    ${ovs_group}    group_id=${group_id},type=select.*
    ${actual_local_bucket_entry}    String.Get Regexp Matches    ${multi_path_group_id}    bucket=actions=group:(\\d+)
    BuiltIn.Length Should Be    ${actual_local_bucket_entry}    ${expected_local_bucket_entry}
    ${actual_remote_bucket_entry}    String.Get Regexp Matches    ${multi_path_group_id}    resubmit
    BuiltIn.Length Should Be    ${actual_remote_bucket_entry}    ${expected_remote_bucket_entry}
    [Return]    ${group_id}

Verify_Group_Stats_Packet_Count
    [Arguments]    ${compute_ip}    ${static_ip}    ${group_id}
    [Documentation]    Verify that the total number of ping packets in dump group stats is equal to sum of the bucket packet count
    ${ovs_group_stat}    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_GROUP_STATS}
    ${multi_path_group_stat}    ${multi_path_group_packet_count}    BuiltIn.Should Match Regexp    ${ovs_group_stat}    group_id=${group_id}.*,packet_count=(\\d+).*
    ${bucket_packet_count}    String.Get Regexp Matches    ${multi_path_group_stat}    :packet_count=(..)    1
    ${total_of_bucket_packet_count}    BuiltIn.Set Variable    ${0}
    : FOR    ${count}    IN    ${bucket_packet_count}
    \    ${total_of_bucket_packet_count}    BuiltIn.Evaluate    ${total_of_bucket_packet_count}+int(${COUNT})
    BuiltIn.Should Be Equal As Strings    ${multi_path_group_packet_count}    ${total_of_bucket_packet_count}

Generate_Next_Hops
    [Arguments]    ${ip}    ${mask}    @{vm_ip_list}
    [Documentation]    Keyword for generating router next hop entries
    @{next_hop_list}    BuiltIn.Create List
    : FOR    ${vm_ip}    IN    @{vm_ip_list}
    \    Collections.Append To List    ${next_hop_list}    --route destination=${ip}/${mask},gateway=${vm_ip}
    [Return]    @{next_hop_list}

Configure_Next_Hops_On_Router
    [Arguments]    ${router_name}    ${no_of_static_ip}    ${vm_list_1}    ${static_ip_1}    ${vm_list_2}={empty}    ${static_ip_2}=${empty}
    ...    ${mask}=32
    [Documentation]    Keyword for configuring generated Next Hop Routes on specified Router for the specified IPs
    @{next_hop_list_1}    MultiPathOperations.Generate_Next_Hops    ${static_ip_1}    ${mask}    @{vm_list_1}
    @{next_hop_list_2}    BuiltIn.Run Keyword If    ${no_of_static_ip}==${2}    MultiPathOperations.Generate_Next_Hops    ${static_ip_2}    ${mask}    @{vm_list_2}
    ${routes_1}    BuiltIn.Catenate    @{next_hop_list_1}
    ${routes_2}    BuiltIn.Catenate    @{next_hop_list_2}
    ${final_route}    BuiltIn.Set Variable If    ${no_of_static_ip}==${2}    ${routes_1} ${routes_2}    ${routes_1}
    OpenStackOperations.Update Router    ${router_name}    ${final_route}
    OpenStackOperations.Show Router    ${router_name}    -D

Tep_Port_Operations
    [Arguments]    ${operation}    ${no_of_compute}
    [Documentation]    Keyword to add/delete TEP Port for specified number of compute nodes
    ${first_two_octets}    ${third_octet}    ${last_octet}    String.Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet_1}    BuiltIn.Set Variable    ${first_two_octets}.0.0/16
    : FOR    ${val}    IN RANGE    ${no_of_compute}
    \    ${compute_num}    BuiltIn.Evaluate    ${val}+1
    \    ${compute_node_id}    OVSDB.Get DPID    ${OS_COMPUTE_${compute_num}_IP}
    \    ${node_adapter}    OVSDB.Get Ethernet Adapter    ${OS_COMPUTE_${compute_num}_IP}
    \    KarafKeywords.Issue_Command_On_Karaf_Console    tep:${operation} ${compute_node_id} ${node_adapter} 0 ${OS_COMPUTE_${compute_num}_IP} ${subnet_1} null TZA
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:commit
    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}

Verify_VM_Mac
    [Arguments]    ${compute_ip}    ${static_ip}    ${local_vm_port_list}    ${remote_vm_port_list}    ${group_id}
    [Documentation]    Keyword to verify VM MAC in respective compute node dump groups
    ${local_vm_mac_list}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    MultiPathOperations.Get_VM_Mac    ${local_vm_port_list}
    ${remote_vm_mac_list}    BuiltIn.Wait Until Keyword Succeeds    30s    10s    MultiPathOperations.Get_VM_Mac    ${remote_vm_port_list}
    ${ovs_group}    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_GROUPS}
    ${multi_path_group_id}    BuiltIn.Should Match Regexp    ${ovs_group}    group_id=${group_id}.*
    : FOR    ${vm_mac}    IN    @{remote_vm_mac_list}
    \    BuiltIn.Should Contain    ${multi_path_group_id}    ${vm_mac}
    ${local_groups}    String.Get Regexp Matches    ${multi_path_group_id}    :15(\\d+)
    : FOR    ${vm_mac}    ${local_group_id}    IN ZIP    ${local_vm_mac_list}    ${local_groups}
    \    ${val}    ${group_num}    String.Split String    ${local_group_id}    :
    \    ${match}    BuiltIn.Should Match Regexp    ${ovs_group}    group_id=${group_num}.*bucket=actions.*
    \    BuiltIn.Run Keyword and Ignore Error    BuiltIn.Should Contain    ${match}    ${vm_mac}

Get_VM_Mac
    [Arguments]    ${vm_port_name_list}    ${conn_id}=${devstack_conn_id}
    [Documentation]    Keyword to return the VM MAC ID wrt given port list
    ${mac_addr_list}    BuiltIn.Create List
    : FOR    ${port_name}    IN    @{vm_port_name_list}
    \    ${rc}    ${output}=    OperatingSystem.Run And Return Rc And Output    openstack port list | grep ${port_name} | awk '{print $6}'
    \    BuiltIn.Log    ${output}
    \    Collections.Append To List    ${mac_addr_list}    ${output}
    \    BuiltIn.Should Not Be True    ${rc}
    [Return]    ${mac_addr_list}
