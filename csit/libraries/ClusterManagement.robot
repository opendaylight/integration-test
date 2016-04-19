*** Settings ***
Documentation     Resource housing Keywords common to several suites for cluster functional testing.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This resource holds private state (in suite variables),
...               which is generated once at Setup.
...               The state includes IP addresses and Http (RequestsLibrary) sessions.
...               Most functionality deals with stopping/starting controllers
...               and finding leaders/followers for a Shard.
...
...               odl-jolokia is assumed to be installed.
...
...               Keywords are ordered from friendly ones to fiddly ones.
...               TODO: Figure out more deterministic but still user-friendly ordering.
...
...               TODO: Unify capitalization of Leaders and Followers.
...
...               TODO: Move Keywords related to iptables manipulation from ClusterKeywords
...               here, or to separate Resource.
Library           RequestsLibrary    # for Create_Session and To_Json
Library           Collections
Resource          ${CURDIR}/TemplatedRequests.robot    # for Get_As_Json_From_Uri
Resource          ${CURDIR}/Utils.robot    # for Run_Command_On_Controller

*** Variables ***
${JOLOKIA_CONF_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
${JOLOKIA_OPER_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore
${JOLOKIA_READ_URI}    jolokia/read/org.opendaylight.controller
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}
${RESTCONF_MODULES_DIR}    ${CURDIR}/../variables/restconf/modules

*** Keywords ***
ClusterManagement_Setup
    [Documentation]    Detect repeated call, or detect number of members and initialize derived suite variables.
    # Avoid multiple initialization by several downstream libraries.
    ${already_done} =    BuiltIn.Get_Variable_Value    \${ClusterManagement__has_setup_run}    False
    BuiltIn.Return_From_Keyword_If    ${already_done}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    True
    ${status}    ${possibly_int_of_members} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Convert_To_Integer    ${NUM_ODL_SYSTEM}
    ${int_of_members} =    BuiltIn.Set_Variable_If    '${status}' != 'PASS'    ${1}    ${possibly_int_of_members}
    ClusterManagement__Compute_Derived_Variables    int_of_members=${int_of_members}

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

ClusterManagement__Build_List
    [Arguments]    ${member}
    ${member_int}=    BuiltIn.Convert_To_Integer    ${member}
    ${index_list}=    BuiltIn.Create_List    ${member_int}
    [Return]    ${index_list}

Kill_Single_Member
    [Arguments]    ${member}    ${confirm}=True
    [Documentation]    Convenience keyword that kills the specified member of the cluster.
    ${index_list}=    ClusterManagement__Build_List    ${member}
    Kill_Members_From_List_Or_All    ${index_list}    ${confirm}

Clean_Journals_And_Snapshots_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Delete journal and snapshots directories on every node listed (or all).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    ${command} =    Set Variable    rm -rf "${KARAF_HOME}/journal" "${KARAF_HOME}/snapshots"
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Run_Command_On_Member    command=${command}    member_index=${index}

Start_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${wait_for_sync}=True    ${timeout}=300s
    [Documentation]    If the list is empty, start all cluster members. Otherwise, start members based on present indices.
    ...    If ${wait_for_sync}, wait for cluster sync on listed members.
    ${command} =    BuiltIn.Set_Variable    ${KARAF_HOME}/bin/start
    Run_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}
    BuiltIn.Return_From_Keyword_If    not ${wait_for_sync}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    1s    Check_Cluster_Is_In_Sync    member_index_list=${member_index_list}
    # TODO: Do we also want to check Shard Leaders here?

Start_Single_Member
    [Arguments]    ${member}    ${wait_for_sync}=True    ${timeout}=300s
    [Documentation]    Convenience keyword that starts the specified member of the cluster.
    ${index_list}=    ClusterManagement__Build_List    ${member}
    Start_Members_From_List_Or_All    ${index_list}    ${wait_for_sync}    ${timeout}

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

Resolve_Http_Session_For_Member
    [Arguments]    ${member_index}
    [Documentation]    Return RequestsLibrary session alias pointing to node of given index.
    ${session} =    BuiltIn.Set_Variable    ClusterManagement__session_${member_index}
    [Return]    ${session}

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

Check_Cluster_Is_In_Sync
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Fail if no-sync is detected on a member from list (or any).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${status} =    Get_Sync_Status_Of_Member    member_index=${index}
    \    # The previous line may have failed already. If not, check status.
    \    BuiltIn.Continue_For_Loop_If    'True' == '${status}'
    \    BuiltIn.Fail    Index ${index} has incorrect status: ${status}

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

Run_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    [Documentation]    Cycle through indices (or all), run command on each.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    Run_Command_On_Member    command=${command}    member_index=${index}

Get_Sync_Status_Of_Member
    [Arguments]    ${member_index}
    [Documentation]    Obtain IP, two GETs from jolokia URIs, return combined sync status as string.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${conf_text} =    Get_As_Json_From_Uri    uri=${JOLOKIA_CONF_SHARD_MANAGER_URI}    session=${session}
    ${conf_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${conf_text}
    BuiltIn.Return_From_Keyword_If    'False' == ${conf_status}    False
    ${oper_text} =    Get_As_Json_From_Uri    uri=${JOLOKIA_OPER_SHARD_MANAGER_URI}    session=${session}
    ${oper_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${oper_text}
    [Return]    ${oper_status}

Run_Command_On_Member
    [Arguments]    ${command}    ${member_index}
    [Documentation]    Obtain IP, call Utils and return output. This does not preserve active ssh session.
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    ${output} =    Utils.Run_Command_On_Controller    ${member_ip}    ${command}
    [Return]    ${output}

Count_Running_Karafs_On_Member
    [Arguments]    ${member_index}
    [Documentation]    Remotely execute grep for karaf process, return count as string.
    ${command} =    BuiltIn.Set_Variable    ps axf | grep karaf | grep -v grep | wc -l
    ${count} =    Run_Command_On_Member    command=${command}    member_index=${member_index}
    [Return]    ${count}

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

Resolve_Shard_Type_Class
    [Arguments]    ${shard_type}
    [Documentation]    Simple lookup for class name corresponding to desired type.
    BuiltIn.Run_Keyword_If    '${shard_type}' == 'config'    BuiltIn.Return_From_Keyword    DistributedConfigDatastore
    ...    ELSE IF    '${shard_type}' == 'operational'    BuiltIn.Return_From_Keyword    DistributedOperationalDatastore
    BuiltIn.Fail    Unrecognized shard type: ${shard_type}

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
