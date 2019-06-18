*** Settings ***
Documentation     This library is useful to check flows for a given IP, verify the group stats packet count and add/delete TEP Ports
Library           SSHLibrary
Resource          DevstackUtils.robot
Resource          OpenStackOperations.robot
Resource          OVSDB.robot
Resource          Utils.robot
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
${TEP_COMMIT}     tep:commit

*** Keywords ***
Generate_Next_Hops
    [Arguments]    ${ip}    ${mask}    @{vm_ip_list}
    [Documentation]    Keyword for generating router next hop entries
    @{next_hop_list} =    BuiltIn.Create List    @{EMPTY}
    : FOR    ${vm_ip}    IN    @{vm_ip_list}
    \    Collections.Append To List    ${next_hop_list}    --route destination=${ip}/${mask},gateway=${vm_ip}
    [Return]    @{next_hop_list}

Configure_Next_Hops_On_Router
    [Arguments]    ${router_name}    ${no_of_static_ip}    ${vm_list_1}    ${static_ip_1}    ${vm_list_2}={empty}    ${static_ip_2}=${empty}
    ...    ${mask}=32
    [Documentation]    Keyword for configuring generated Next Hop Routes on specified Router for the specified IPs
    @{next_hop_list_1} =    MultiPathOperations.Generate_Next_Hops    ${static_ip_1}    ${mask}    @{vm_list_1}
    @{next_hop_list_2} =    BuiltIn.Run Keyword If    ${no_of_static_ip}==${2}    MultiPathOperations.Generate_Next_Hops    ${static_ip_2}    ${mask}    @{vm_list_2}
    ${routes_1} =    BuiltIn.Catenate    @{next_hop_list_1}
    ${routes_2} =    BuiltIn.Catenate    @{next_hop_list_2}
    ${final_route} =    BuiltIn.Set Variable If    ${no_of_static_ip}==${2}    ${routes_1} ${routes_2}    ${routes_1}
    OpenStackOperations.Update Router    ${router_name}    ${final_route}
    OpenStackOperations.Show Router    ${router_name}

Verify_Flows_In_Compute_Node
    [Arguments]    ${compute_ip}    ${expected_local_bucket_entry}    ${expected_remote_bucket_entry}    ${static_ip}
    [Documentation]    Verify flows w.r.t the specified IP and the corresponding local bucket entry and remote bucket entry
    ${ovs_flow} =    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_FLOWS} | grep table=${L3_TABLE}
    ${ovs_group} =    Utils.Run Command On Remote System    ${compute_ip}    ${DUMP_GROUPS}
    ${match}    ${group_id} =    BuiltIn.Should Match Regexp    ${ovs_flow}    table=${L3_TABLE}.*nw_dst=${static_ip}.*group:(\\d+)
    ${multi_path_group_id} =    BuiltIn.Should Match Regexp    ${ovs_group}    group_id=${group_id},type=select.*
    ${actual_local_bucket_entry} =    String.Get Regexp Matches    ${multi_path_group_id}    bucket=actions=group:(\\d+)
    BuiltIn.Length Should Be    ${actual_local_bucket_entry}    ${expected_local_bucket_entry}
    ${actual_remote_bucket_entry} =    String.Get Regexp Matches    ${multi_path_group_id}    resubmit
    BuiltIn.Length Should Be    ${actual_remote_bucket_entry}    ${expected_remote_bucket_entry}
    [Return]    ${group_id}
