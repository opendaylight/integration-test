*** Settings ***
Documentation     Resource housing Keywords common to several suites for cluster functional testing.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...               Copyright (c) 2016 Brocade Communications Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This resource holds private state (in suite variables),
...               which is generated once at Setup with ClusterManagement_Setup KW.
...               The state includes member indexes, IP addresses and Http (RequestsLibrary) sessions.
...               Cluster Keywords normally use member index, member list or nothing (all members) as argument.
...
...               Requirements:
...               odl-jolokia is assumed to be installed.
...
...               Keywords are ordered as follows:
...               - Cluster Setup
...               - Shard state, leader and followers
...               - Entity Owner, candidates and successors
...               - Kill and Start Member
...               - Isolate and Rejoin Member
...               - Run Commands On Member
...               - REST requests and checks on Members
...
...               TODO: Unify capitalization of Leaders and Followers.
Library           RequestsLibrary    # for Create_Session and To_Json
Library           Collections
Resource          ${CURDIR}/TemplatedRequests.robot    # for Get_As_Json_From_Uri
Resource          ${CURDIR}/Utils.robot    # for Run_Command_On_Controller

*** Variables ***
${JAVA_HOME}      ${EMPTY}    # releng/builder scripts should provide correct value
${JOLOKIA_CONF_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
${JOLOKIA_OPER_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore
${JOLOKIA_READ_URI}    jolokia/read/org.opendaylight.controller
${ENTITY_OWNER_URI}    restconf/operational/entity-owners:entity-owners
${RESTCONF_MODULES_DIR}    ${CURDIR}/../variables/restconf/modules

*** Keywords ***
ClusterManagement_Setup
    [Documentation]    Detect repeated call, or detect number of members and initialize derived suite variables.
    # Avoid multiple initialization by several downstream libraries.
    ${already_done} =    BuiltIn.Get_Variable_Value    \${ClusterManagement__has_setup_run}    False
    BuiltIn.Return_From_Keyword_If    ${already_done}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    True
    ${cluster_size} =    BuiltIn.Get_Variable_Value    \${NUM_ODL_SYSTEM}    1
    ${status}    ${possibly_int_of_members} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Convert_To_Integer    ${cluster_size}
    ${int_of_members} =    BuiltIn.Set_Variable_If    '${status}' != 'PASS'    ${1}    ${possibly_int_of_members}
    ClusterManagement__Compute_Derived_Variables    int_of_members=${int_of_members}

Check_Cluster_Is_In_Sync
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Fail if no-sync is detected on a member from list (or any).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${status} =    Get_Sync_Status_Of_Member    member_index=${index}
    \    BuiltIn.Continue_For_Loop_If    'True' == '${status}'
    \    BuiltIn.Fail    Index ${index} has incorrect status: ${status}

Get_Sync_Status_Of_Member
    [Arguments]    ${member_index}
    [Documentation]    Obtain IP, two GETs from jolokia URIs, return combined sync status as string.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${conf_text} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${JOLOKIA_CONF_SHARD_MANAGER_URI}    session=${session}
    ${conf_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${conf_text}
    BuiltIn.Return_From_Keyword_If    'False' == ${conf_status}    False
    ${oper_text} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${JOLOKIA_OPER_SHARD_MANAGER_URI}    session=${session}
    ${oper_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${oper_text}
    [Return]    ${oper_status}

Verify_Leader_Exists_For_Each_Shard
    [Arguments]    ${shard_name_list}    ${shard_type}=operational    ${member_index_list}=${EMPTY}    ${verify_restconf}=True
    [Documentation]    For each shard name, call Get_Leader_And_Followers_For_Shard.
    ...    Not much logic there, but single Keyword is useful when using BuiltIn.Wait_Until_Keyword_Succeeds.
    : FOR    ${shard_name}    IN    @{shard_name_list}
    \    Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    validate=True    member_index_list=${member_index_list}    verify_restconf=${verify_restconf}

Get_Leader_And_Followers_For_Shard
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=True    ${member_index_list}=${EMPTY}    ${verify_restconf}=True
    [Documentation]    Get role lists, validate there is one leader, return the leader and list of followers.
    ...    Optionally, issue GET to a simple restconf URL to make sure subsequent operations will not encounter 503.
    ${leader_list}    ${follower_list} =    Get_State_Info_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    validate=True    member_index_list=${member_index_list}
    ...    verify_restconf=${verify_restconf}
    ${leader_count} =    BuiltIn.Get_Length    ${leader_list}
    BuiltIn.Run_Keyword_If    ${leader_count} < 1    BuiltIn.Fail    No leader found.
    BuiltIn.Length_Should_Be    ${leader_list}    ${1}    Too many Leaders.
    ${leader} =    Collections.Get_From_List    ${leader_list}    0
    [Return]    ${leader}    ${follower_list}

Get_State_Info_For_Shard
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=False    ${member_index_list}=${EMPTY}    ${verify_restconf}=False
    [Documentation]    Return lists of Leader and Follower member indices from a given member index list
    ...    (or from the full list if empty). If \${shard_type} is not 'config', 'operational' is assumed.
    ...    If \${validate}, Fail if raft state is not Leader or Follower (for example on Candidate).
    ...    The biggest difference from Get_Leader_And_Followers_For_Shard
    ...    is that no check on number of Leaders is performed.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    # TODO: Support alternative capitalization of 'config'?
    ${ds_type} =    BuiltIn.Set_Variable_If    '${shard_type}' != 'config'    operational    config
    ${leader_list} =    BuiltIn.Create_List
    ${follower_list} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${raft_state} =    Get_Raft_State_Of_Shard_At_Member    shard_name=${shard_name}    shard_type=${ds_type}    member_index=${index}    verify_restconf=${verify_restconf}
    \    BuiltIn.Run_Keyword_If    'Follower' == '${raft_state}'    Collections.Append_To_List    ${follower_list}    ${index}
    \    ...    ELSE IF    'Leader' == '${raft_state}'    Collections.Append_To_List    ${leader_list}    ${index}
    \    ...    ELSE IF    ${validate}    BuiltIn.Fail    Unrecognized Raft state: ${raft_state}
    [Return]    ${leader_list}    ${follower_list}

Get_Raft_State_Of_Shard_At_Member
    [Arguments]    ${shard_name}    ${shard_type}    ${member_index}    ${verify_restconf}=False
    [Documentation]    Send request to Jolokia on indexed member, return extracted Raft status.
    ...    Optionally, check restconf works.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    # TODO: Does the used URI tend to generate large data which floods log.html?
    BuiltIn.Run_Keyword_If    ${verify_restconf}    TemplatedRequests.Get_As_Json_Templated    session=${session}    folder=${RESTCONF_MODULES_DIR}    verify=False
    ${type_class} =    Resolve_Shard_Type_Class    shard_type=${shard_type}
    ${uri} =    BuiltIn.Set_Variable    ${JOLOKIA_READ_URI}:Category=Shards,name=member-${member_index}-shard-${shard_name}-${shard_type},type=${type_class}
    ${data_text} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${uri}    session=${session}
    ${data_object} =    RequestsLibrary.To_Json    ${data_text}
    ${value} =    Collections.Get_From_Dictionary    ${data_object}    value
    ${raft_state} =    Collections.Get_From_Dictionary    ${value}    RaftState
    [Return]    ${raft_state}

Verify_Owner_And_Successors_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${candidate_list}=${EMPTY}
    [Documentation]    Returns the owner and successors for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Extra check is done to verify owner and successors are within the ${candidate_list}. This KW is useful when combined with WUKS.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${candidate_list}
    ${owner}    ${successor_list} =    Get_Owner_And_Successors_For_Device    device_name=${device_name}    device_type=${device_type}    member_index=${member_index}
    Collections.List_Should_Contain_Value    ${index_list}    ${owner}    Owner ${owner} is not in candidate list ${index_list}
    ${expected_successor_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${expected_successor_list}    ${owner}
    Collections.Lists_Should_Be_Equal    ${expected_successor_list}    ${successor_list}    Successor list ${successor_list} is not in candidate list ${index_list}
    [Return]    ${owner}    ${successor_list}

Get_Owner_And_Successors_For_device
    [Arguments]    ${device_name}    ${device_type}    ${member_index}
    [Documentation]    Returns the owner and a list of successors for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Successors are those device candidates not elected as owner. The list of successors = (list of candidates) - (owner).
    ${owner}    ${candidate_list} =    Get_Owner_And_Candidates_For_Device    device_name=${device_name}    device_type=${device_type}    member_index=${member_index}
    ${successor_list} =    BuiltIn.Create_List    @{candidate_list}
    Collections.Remove_Values_From_List    ${successor_list}    ${owner}
    [Return]    ${owner}    ${successor_list}

Get_Owner_And_Candidates_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${member_index}
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${data} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${ENTITY_OWNER_URI}    session=${session}
    ${candidate_list} =    BuiltIn.Create_List
    ${entity_type} =    BuiltIn.Set_Variable_If    '${device_type}' == 'netconf'    netconf-node/${device_name}    ${device_type}
    ${clear_data} =    BuiltIn.Run_Keyword_If    '${device_type}' == 'openflow' or '${device_type}' == 'netconf'    Extract_OpenFlow_Device_Data    ${data}
    ...    ELSE IF    '${device_type}' == 'ovsdb'    Extract_Ovsdb_Device_Data    ${data}
    ...    ELSE    Fail    Not recognized device type: ${device_type}
    ${json} =    RequestsLibrary.To_Json    ${clear_data}
    ${entity_type_list} =    Collections.Get_From_Dictionary    &{json}[entity-owners]    entity-type
    ${entity_type_index} =    Utils.Get_Index_From_List_Of_Dictionaries    ${entity_type_list}    type    ${entity_type}
    BuiltIn.Should_Not_Be_Equal    ${entity_type_index}    -1    No Entity Owner found for ${device_type}
    ${entity_list} =    Collections.Get_From_Dictionary    @{entity_type_list}[${entity_type_index}]    entity
    ${entity_index} =    Utils.Get_Index_From_List_Of_Dictionaries    ${entity_list}    id    ${device_name}
    BuiltIn.Should Not Be Equal    ${entity_index}    -1    Device ${device_name} not found in Entity Owner ${device_type}
    ${entity_owner} =    Collections.Get_From_Dictionary    @{entity_list}[${entity_index}]    owner
    BuiltIn.Should_Not_Be_Empty    ${entity_owner}    No owner found for ${device_name}
    ${owner} =    String.Replace_String    ${entity_owner}    member-    ${EMPTY}
    ${owner} =    BuiltIn.Convert_To_Integer    ${owner}
    ${entity_candidates_list} =    Collections.Get_From_Dictionary    @{entity_list}[${entity_index}]    candidate
    : FOR    ${entity_candidate}    IN    @{entity_candidates_list}
    \    ${candidate} =    String.Replace_String    &{entity_candidate}[name]    member-    ${EMPTY}
    \    ${candidate} =    BuiltIn.Convert_To_Integer    ${candidate}
    \    Collections.Append_To_List    ${candidate_list}    ${candidate}
    [Return]    ${owner}    ${candidate_list}

Extract_OpenFlow_Device_Data
    [Arguments]    ${data}
    [Documentation]    Remove superfluous OpenFlow device data from Entity Owner printout.
    ${clear_data} =    String.Replace_String    ${data}    /general-entity:entity[general-entity:name='    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    ']    ${EMPTY}
    Log    ${clear_data}
    [Return]    ${clear_data}

Extract_Ovsdb_Device_Data
    [Arguments]    ${data}
    [Documentation]    Remove superfluous OVSDB device data from Entity Owner printout.
    ${clear_data} =    String.Replace_String    ${data}    /network-topology:network-topology/network-topology:topology[network-topology:topology-id='ovsdb:1']/network-topology:node[network-topology:node-id='    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    ']    ${EMPTY}
    Log    ${clear_data}
    [Return]    ${clear_data}

Kill_Single_Member
    [Arguments]    ${member}    ${confirm}=True
    [Documentation]    Convenience keyword that kills the specified member of the cluster.
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Kill_Members_From_List_Or_All    ${index_list}    ${confirm}

Kill_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${confirm}=True
    [Documentation]    If the list is empty, kill all ODL instances. Otherwise, kill members based on present indices.
    ...    If \${confirm} is True, sleep 1 second and verify killed instances are not there anymore.
    ${command} =    BuiltIn.Set_Variable    ps axf | grep karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
    Run_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}
    BuiltIn.Return_From_Keyword_If    not ${confirm}
    # TODO: Convert to WUKS with configurable timeout if it turns out 1 second is not enough.
    BuiltIn.Sleep    1s    Kill -9 closes open files, which may take longer than ssh overhead, but not long enough to warrant WUKS.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    Verify_Karaf_Is_Not_Running_On_Member    member_index=${index}

Start_Single_Member
    [Arguments]    ${member}    ${wait_for_sync}=True    ${timeout}=300s
    [Documentation]    Convenience keyword that starts the specified member of the cluster.
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Start_Members_From_List_Or_All    ${index_list}    ${wait_for_sync}    ${timeout}

Start_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${wait_for_sync}=True    ${timeout}=300s    ${karaf_home}=${WORKSPACE}${/}${BUNDLEFOLDER}    ${export_java_home}=${JAVA_HOME}
    [Documentation]    If the list is empty, start all cluster members. Otherwise, start members based on present indices.
    ...    If ${wait_for_sync}, wait for cluster sync on listed members.
    ...    Optionally karaf_home can be overriden. Optionally specific JAVA_HOME is used for starting.
    ${base_command} =    BuiltIn.Set_Variable    ${karaf_home}/bin/start
    ${command} =    BuiltIn.Set_Variable_If    "${export_java_home}"    export JAVA_HOME="${export_java_home}"; ${base_command}    ${base_command}
    Run_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}
    BuiltIn.Return_From_Keyword_If    not ${wait_for_sync}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    1s    Check_Cluster_Is_In_Sync    member_index_list=${member_index_list}
    # TODO: Do we also want to check Shard Leaders here?

Clean_Journals_And_Snapshots_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${karaf_home}=${WORKSPACE}${/}${BUNDLEFOLDER}
    [Documentation]    Delete journal and snapshots directories on every node listed (or all).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    ${command} =    Set Variable    rm -rf "${karaf_home}/journal" "${karaf_home}/snapshots"
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Run_Command_On_Member    command=${command}    member_index=${index}

Verify_Karaf_Is_Not_Running_On_Member
    [Arguments]    ${member_index}
    [Documentation]    Fail if non-zero karaf instances are counted on member of given index.
    ${count} =    Count_Running_Karafs_On_Member    member_index=${member_index}
    BuiltIn.Should_Be_Equal    0    ${count}    Found running Karaf count: ${count}

Verify_Single_Karaf_Is_Running_On_Member
    [Arguments]    ${member_index}
    [Documentation]    Fail if number of karaf instances on member of given index is not one.
    ${count} =    Count_Running_Karafs_On_Member    member_index=${member_index}
    BuiltIn.Should_Be_Equal    1    ${count}    Wrong number of Karafs running: ${count}

Count_Running_Karafs_On_Member
    [Arguments]    ${member_index}
    [Documentation]    Remotely execute grep for karaf process, return count as string.
    ${command} =    BuiltIn.Set_Variable    ps axf | grep karaf | grep -v grep | wc -l
    ${count} =    Run_Command_On_Member    command=${command}    member_index=${member_index}
    [Return]    ${count}

Isolate_Member_From_List_Or_All
    [Arguments]    ${isolate_member_index}    ${member_index_list}=${EMPTY}
    [Documentation]    If the list is empty, isolate member from all ODL instances. Otherwise, isolate member based on present indices.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    ${source} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${isolate_member_index}
    : FOR    ${index}    IN    @{index_list}
    \    ${destination} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
    \    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -I OUTPUT -p all --source ${source} --destination ${destination} -j DROP
    \    BuiltIn.Run_Keyword_If    "${index}" != "${isolate_member_index}"    Run_Command_On_Member    command=${command}    member_index=${isolate_member_index}
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Run_Command_On_Member    command=${command}    member_index=${isolate_member_index}
    BuiltIn.Log    ${output}

Rejoin_Member_From_List_Or_All
    [Arguments]    ${rejoin_member_index}    ${member_index_list}=${EMPTY}
    [Documentation]    If the list is empty, rejoin member from all ODL instances. Otherwise, rejoin member based on present indices.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    ${source} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${rejoin_member_index}
    : FOR    ${index}    IN    @{index_list}
    \    ${destination} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
    \    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -D OUTPUT -p all --source ${source} --destination ${destination} -j DROP
    \    BuiltIn.Run_Keyword_If    "${index}" != "${rejoin_member_index}"    Run_Command_On_Member    command=${command}    member_index=${rejoin_member_index}
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Run_Command_On_Member    command=${command}    member_index=${rejoin_member_index}
    BuiltIn.Log    ${output}

Flush_Iptables_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    If the list is empty, flush IPTables in all ODL instances. Otherwise, flush member based on present indices.
    ${command} =    BuiltIn.Set_Variable    sudo iptables -v -F
    ${output} =    Run_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}

Run_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    [Documentation]    Cycle through indices (or all), run command on each.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    Run_Command_On_Member    command=${command}    member_index=${index}

Run_Command_On_Member
    [Arguments]    ${command}    ${member_index}
    [Documentation]    Obtain IP, call Utils and return output. This does not preserve active ssh session.
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    ${output} =    Utils.Run_Command_On_Controller    ${member_ip}    ${command}
    [Return]    ${output}

Put_As_Json_And_Check_Member_List_Or_All
    [Arguments]    ${uri}    ${data}    ${member_index}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a PUT with the supplied uri ${uri} and body ${data} to member ${member_index}.
    ...    Then check data is replicated in all or some members defined in ${member_index_list}.
    ${response_text} =    Put_As_Json_To_Member    uri=${uri}    data=${data}    member_index=${member_index}
    Wait Until Keyword Succeeds    5s    1s    Check_Json_Member_List_Or_All    uri=${uri}    expected_data=${data}    member_index_list=${member_index_list}
    [Return]    ${response_text}

Put_As_Json_To_Member
    [Arguments]    ${uri}    ${data}    ${member_index}
    [Documentation]    Send a PUT with the supplied uri and data to member ${member_index}.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Put_As_Json_To_Uri    uri=${uri}    data=${data}    session=${session}
    [Return]    ${response_text}

Post_As_Json_To_Member
    [Arguments]    ${uri}    ${data}    ${member_index}
    [Documentation]    Send a POST with the supplied uri and data to member ${member_index}.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Post_As_Json_To_Uri    uri=${uri}    data=${data}    session=${session}
    [Return]    ${response_text}

Delete_And_Check_Member_List_Or_All
    [Arguments]    ${uri}    ${member_index}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a DELETE with the supplied uri to the member ${member_index}.
    ...    Then check the data is removed from all members in ${member_index_list}.
    ${response_text} =    Delete_From_Member    ${uri}    ${member_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    5s    1s    Check_No_Content_Member_List_Or_All    uri=${uri}    member_index_list=${member_index_list}
    [Return]    ${response_text}

Delete_From_Member
    [Arguments]    ${uri}    ${member_index}
    [Documentation]    Send a DELETE with the supplied uri to member ${member_index}.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Delete_From_Uri    uri=${uri}    session=${session}
    [Return]    ${response_text}

Check_Json_Member_List_Or_All
    [Arguments]    ${uri}    ${expected_data}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check received data is = ${expected data}.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${data} =    Get_From_Member    uri=${uri}    member_index=${index}
    \    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_data}    ${data}

Check_Item_Occurrence_Member_List_Or_All
    [Arguments]    ${uri}    ${dictionary}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check received for occurrences of items expressed in a dictionary ${dictionary}.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${data} =    Get_From_Member    uri=${uri}    member_index=${index}
    \    Utils.Check Item Occurrence    ${data}    ${dictionary}

Check_No_Content_Member_List_Or_All
    [Arguments]    ${uri}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check there is no content.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${session} =    Resolve_Http_Session_For_Member    member_index=${index}
    \    Utils.No_Content_From_URI    ${session}    ${uri}

Get_From_Member
    [Arguments]    ${uri}    ${member_index}    ${access}=${ACCEPT_EMPTY}
    [Documentation]    Send a GET with the supplied uri to member ${member_index}.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Get_From_Uri    uri=${uri}    accept=${access}    session=${session}
    [Return]    ${response_text}

Resolve_Http_Session_For_Member
    [Arguments]    ${member_index}
    [Documentation]    Return RequestsLibrary session alias pointing to node of given index.
    ${session} =    BuiltIn.Set_Variable    ClusterManagement__session_${member_index}
    [Return]    ${session}

Resolve_Shard_Type_Class
    [Arguments]    ${shard_type}
    [Documentation]    Simple lookup for class name corresponding to desired type.
    BuiltIn.Run_Keyword_If    '${shard_type}' == 'config'    BuiltIn.Return_From_Keyword    DistributedConfigDatastore
    ...    ELSE IF    '${shard_type}' == 'operational'    BuiltIn.Return_From_Keyword    DistributedOperationalDatastore
    BuiltIn.Fail    Unrecognized shard type: ${shard_type}

ClusterManagement__Build_List
    [Arguments]    ${member}
    ${member_int} =    BuiltIn.Convert_To_Integer    ${member}
    ${index_list} =    BuiltIn.Create_List    ${member_int}
    [Return]    ${index_list}

ClusterManagement__Parse_Sync_Status
    [Arguments]    ${shard_manager_text}
    [Documentation]    Return sync status parsed out of given text. Called twice by Get_Sync_Status_Of_Member.
    BuiltIn.Log    ${shard_manager_text}
    ${manager_object} =    RequestsLibrary.To_Json    ${shard_manager_text}
    ${value_object} =    Collections.Get_From_Dictionary    dictionary=${manager_object}    key=value
    ${sync_status} =    Collections.Get_From_Dictionary    dictionary=${value_object}    key=SyncStatus
    [Return]    ${sync_status}

ClusterManagement__Given_Or_Internal_Index_List
    [Arguments]    ${given_list}=${EMPTY}
    [Documentation]    Utility to allow \${EMPTY} as default argument value, as the internal list is computed at runtime.
    ${given_length} =    BuiltIn.Get_Length    ${given_list}
    ${return_list} =    BuiltIn.Set_Variable_If    ${given_length} > 0    ${given_list}    ${ClusterManagement__member_index_list}
    [Return]    ${return_list}

ClusterManagement__Compute_Derived_Variables
    [Arguments]    ${int_of_members}
    [Documentation]    Construct index list, session list and IP mapping, publish them as suite variables.
    @{member_index_list} =    BuiltIn.Create_List
    @{session_list} =    BuiltIn.Create_List
    &{index_to_ip_mapping} =    BuiltIn.Create_Dictionary
    : FOR    ${index}    IN RANGE    1    ${int_of_members+1}
    \    ClusterManagement__Include_Member_Index    ${index}    ${member_index_list}    ${session_list}    ${index_to_ip_mapping}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__member_index_list}    ${member_index_list}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__index_to_ip_mapping}    ${index_to_ip_mapping}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__session_list}    ${session_list}

ClusterManagement__Include_Member_Index
    [Arguments]    ${index}    ${member_index_list}    ${session_list}    ${index_to_ip_mapping}
    [Documentation]    Add a corresponding item based on index into the last three arguments.
    ...    Create the Http session whose alias is added to list.
    Collections.Append_To_List    ${member_index_list}    ${index}
    ${member_ip} =    BuiltIn.Set_Variable    ${ODL_SYSTEM_${index}_IP}
    # ${index} is int (not string) so "key=value" syntax does not work in the following line.
    Collections.Set_To_Dictionary    ${index_to_ip_mapping}    ${index}    ${member_ip}
    # Http session, with ${AUTH}, without headers.
    ${session_alias} =    Resolve_Http_Session_For_Member    member_index=${index}
    RequestsLibrary.Create_Session    ${session_alias}    http://${member_ip}:${RESTCONFPORT}    auth=${AUTH}    max_retries=0
    Collections.Append_To_List    ${session_list}    ${session_alias}
