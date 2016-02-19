*** Settings ***
Documentation     FIXME: Add actual documentation text.
...               FIXME: Order keywords, most friendly ones first, fiddly ones last.
Library           RequestsLibrary    # or Create_Session and To_Json
Library           Collections
Library           ${CURDIR}/HsfJson/hsf_json.py
Resource          ${CURDIR}/TemplatedRequests.robot    # for Get_As_Json_From_Uri
Resource          ${CURDIR}/Utils.robot    # for Run_Command_On_Controller

*** Variables ***
${JOLOKIA_CONF_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
${JOLOKIA_OPER_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore
${JOLOKIA_READ_URI}    jolokia/read/org.opendaylight.controller
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}

*** Keywords ***
ClusterManagement_Setup
    [Documentation]    Initialize suite variables and sessions.
    # Avoid multiple initialization by several downstream libraries.
    ${already_done} =    BuiltIn.Get_Variable_Value    \${ClusterManagement__has_setup_run}    False
    BuiltIn.Return_From_Keyword_If    '${already_done}' != 'False'
    # If anything below fails, we still want to avoid retries.
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    True
    ${status}    ${possibly_int_of_members} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Convert_To_Integer    ${NUM_ODL_SYSTEM}
    ${int_of_members} =    BuiltIn.Set_Variable_If    '${status}' != 'PASS'    ${1}    ${possibly_int_of_members}
    @{member_index_list} =    BuiltIn.Create_List
    &{index_to_ip_mapping} =    BuiltIn.Create_Dictionary
    : FOR    ${index}    IN RANGE    1    ${int_of_members+1}
    \    Collections.Append_To_List    ${member_index_list}    ${index}
    \    ${member_ip} =    BuiltIn.Set_Variable    ${ODL_SYSTEM_${index}_IP}
    \    # ${index} is int (not string) so "key=value" syntax does not work in the following line.
    \    Collections.Set_To_Dictionary    ${index_to_ip_mapping}    ${index}    ${member_ip}
    \    # Http session, with ${AUTH}, without headers.
    \    RequestsLibrary.Create_Session    ClusterManagement__session_${index}    http://${member_ip}:${RESTCONFPORT}    auth=${AUTH}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__member_index_list}    ${member_index_list}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__index_to_ip_mapping}    ${index_to_ip_mapping}

ClusterManagement__Given_Or_Internal_Index_List
    [Arguments]    ${given_list}=${EMPTY}
    [Documentation]    Utility to allow \${EMPTY} as default argument value, as the internal list is computed at runtime.
    ${given_length} =    BuiltIn.Get_Length    ${given_list}
    ${return_list} =    BuiltIn.Set_Variable_If    ${given_length} > 0    ${given_list}    ${ClusterManagement__member_index_list}
    [Return]    ${return_list}

Find_Http_Session_For_Member
    [Arguments]    ${member_index}
    [Documentation]    Return RequestsLibrary session alias pointing to node of given index.
    ${session} =    BuiltIn.Set_Variable    ClusterManagement__session_${member_index}
    [Return]    ${session}

Find_Shard_Type_Class
    [Arguments]    ${shard_type}
    [Documentation]    Simple lookup for class name corresponding to desired type.
    BuiltIn.Run_Keyword_If    '${shard_type}' == 'config'    BuiltIn.Return_From_Keyword    DistributedConfigDatastore
    ...    ELSE IF    '${shard_type}' == 'operational'    BuiltIn.Return_From_Keyword    DistributedOperationalDatastore
    BuiltIn.Fail    Unrecognized shard type: ${shard_type}

Get_Raft_State_Of_Shard_At_Member
    [Arguments]    ${shard_type}    ${shard_name}    ${member_index}
    [Documentation]    Send request to Jolokia on indexed member, return extracted Raft status.
    ${type_class} =    Find_Shard_Type_Class    shard_type=${shard_type}
    ${uri} =    BuiltIn.Set_Variable    ${JOLOKIA_READ_URI}:Category=Shards,name=member-${member_index}-shard-${shard_name}-${shard_type},type=${type_class}
    ${session} =    Find_Http_Session_For_Member    member_index=${member_index}
    ${data_text} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${uri}    session=${session}
    ${data_object} =    RequestsLibrary.To_Json    ${data_text}
    ${value} =    Collections.Get_From_Dictionary    ${data_object}    value
    ${raft_state} =    Collections.Get_From_Dictionary    ${value}    RaftState
    [Return]    ${raft_state}

Get_Leaders_And_Followers_For_Shard
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=False    ${member_index_list}=${EMPTY}
    [Documentation]    Return lists of Leader and Follower member indices from a given member index list
    ...    (or from the full list if empty). If \${shard_type} is not 'config', 'operational' is assumed.
    ...    If \${validate}, Fail on unknown raft state.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    # TODO: Support alternative capitalization of 'config'?
    ${ds_type} =    BuiltIn.Set_Variable_If    '${shard_type}' != 'config'    operational    config
    ${leader_list} =    BuiltIn.Create_List
    ${follower_list} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${raft_state} =    Get_Raft_State_Of_Shard_At_Member    shard_type=${ds_type}    shard_name=${shard_name}    member_index=${index}
    \    BuiltIn.Run_Keyword_If    'Follower' == '${raft_state}'    Collections.Append_To_List    ${follower_list}    ${index}
    \    ...    ELSE IF    'Leader' == '${raft_state}'    Collections.Append_To_List    ${leader_list}    ${index}
    \    ...    ELSE IF    ${validate}    BuiltIn.Fail    Unrecognized Raft state: ${raft_state}
    Return_From_Keyword    ${leader_list}    ${follower_list}

Get_Leader_And_Followers_For_Shard
    [Arguments]    ${shard_type}=operational    ${shard_name}=default    ${member_index_list}=${EMPTY}
    [Documentation]    Get state lists, validate there is one leader, return the leader and list of followers.
    # FIXME: Name needs to be more distinguished from the previous keyword.
    # TODO: Unify capitalization of Leaders and Followers.
    ${leader_list}    ${follower_list} =    Get_Leaders_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    validate=True    member_index_list=${member_index_list}
    ${leader_count} =    BuiltIn.Get_Length    ${leader_list}
    BuiltIn.Run_Keyword_If    ${leader_count} < 1    BuiltIn.Fail    No leader found.
    BuiltIn.Length_Should_Be    ${leader_list}    ${1}    Too many Leaders.
    ${leader} =    Collections.Get_From_List    ${leader_list}    0
    [Return]    ${leader}    ${follower_list}

Run_Command_On_Member
    [Arguments]    ${command}    ${member_index}
    [Documentation]    Obtain IP, call Utils and return output. This does not preserve active ssh session.
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    ${output} =    Utils.Run_Command_On_Controller    ${member_ip}    ${command}
    [Return]    ${output}

Run_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    [Documentation]    Cycle through indices (or all), run command on each.
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    Run_Command_On_Member    command=${command}    member_index=${index}

Count_Running_Karafs_On_Member
    [Arguments]    ${member_index}
    [Documentation]    Remotely execute grep for karaf process, return count as string.
    ${command} =    BuiltIn.Set_Variable    ps axf | grep karaf | grep -v grep | wc -l
    ${count} =    Run_Command_On_Member    command=${command}    member_index=${member_index}
    [Return]    ${count}

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

Start_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${wait_for_sync}=True    ${timeout}=300s
    [Documentation]    If the list is empty, start all cluster members. Otherwise, start members based on present indices.
    ${command} =    BuiltIn.Set_Variable    ${KARAF_HOME}/bin/start
    Run_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}
    BuiltIn.Return_From_Keyword_If    not ${wait_for_sync}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    1s    Check_Cluster_Is_In_Sync    member_index_list=${member_index_list}

ClusterManagement__Parse_Sync_Status
    [Arguments]    ${shard_manager_text}
    [Documentation]    Return sync status parsed out of given text.
    BuiltIn.Log    ${shard_manager_text}
    ${manager_object} =    RequestsLibrary.To_Json    ${shard_manager_text}
    ${value_object} =    Collections.Get_From_Dictionary    dictionary=${manager_object}    key=value
    ${sync_status} =    Collections.Get_From_Dictionary    dictionary=${value_object}    key=SyncStatus
    [Return]    ${sync_status}

Get_Sync_Status_Of_Member
    [Arguments]    ${member_index}
    [Documentation]    Obtain IP, two GETs from jolokia URIs, return combined sync status as string.
    ${session} =    Find_Http_Session_For_Member    member_index=${member_index}
    ${conf_text} =    Get_As_Json_From_Uri    uri=${JOLOKIA_CONF_SHARD_MANAGER_URI}    session=${session}
    ${conf_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${conf_text}
    BuiltIn.Return_From_Keyword_If    'False' == ${conf_status}    False
    ${oper_text} =    Get_As_Json_From_Uri    uri=${JOLOKIA_OPER_SHARD_MANAGER_URI}    session=${session}
    ${oper_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${oper_text}
    [Return]    ${oper_status}

Check_Cluster_Is_In_Sync
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Fail if no-sync is detected on a member from list (or any).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${status} =    Get_Sync_Status_Of_Member    member_index=${index}
    \    # Previous line may have failed already. If not, check status.
    \    BuiltIn.Continue_For_Loop_If    'True' == '${status}'
    \    BuiltIn.Fail    Index ${index} has incorrect status: ${status}

Clean_Journals_And_Snapshots_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Delete journal and snapshots directories on every node listed (or all).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    ${command} =    Set Variable    rm -rf "${KARAF_HOME}/journal" "${KARAF_HOME}/snapshots"
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Run_Command_On_Member    command=${command}    member_index=${index}

Dummy_Keyword
    # From here onwards, everything is the same as in ClusterKeywords.
    #
    #
    #Check Item Occurrence At URI In Cluster
    #    [Arguments]    ${controller_index_list}    ${dictionary_item_occurrence}    ${uri}
    #    [Documentation]    Send a GET with the supplied ${uri} to all cluster instances in ${controller_index_list}
    #    ...    and check for occurrences of items expressed in a dictionary ${dictionary_item_occurrence}.
    #    : FOR    ${i}    IN    @{controller_index_list}
    #    ${data}    Get Data From URI    controller${i}    ${uri}
    #    Log    ${data}
    #    Check Item Occurrence    ${data}    ${dictionary_item_occurrence}
    #
    #Expect No Leader
    #    [Arguments]    ${shard_name}
    #    [Documentation]    No leader is elected in the car shard
    #    ${leader}    GetLeader    ${shard_name}    ${3}    ${1}
    # ${1}    # ${RESTCONFPORT}
    #    ...    ${CURRENT_CAR_LEADER}
    #    Should Be Equal As Strings    ${leader}    None
    #
    #Show Cluster Configuation Files
    #    [Arguments]    @{controllers}
    #    [Documentation]    Prints out the cluster configuration files for one or more controllers.
    #    Log    controllers: @{controllers}
    #    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/akka.conf
    #    : FOR    ${ip}    IN    @{controllers}
    #    Run Command On Remote System    ${ip}    ${cmd}
    #    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/modules.conf
    #    : FOR    ${ip}    IN    @{controllers}
    #    Run Command On Remote System    ${ip}    ${cmd}
    #    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/module-shards.conf
    #    : FOR    ${ip}    IN    @{controllers}
    #    Run Command On Remote System    ${ip}    ${cmd}
    #    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/jolokia.xml
    #    : FOR    ${ip}    IN    @{controllers}
    #    Run Command On Remote System    ${ip}    ${cmd}
    #    ${cmd} =    Set Variable    cat ${KARAF_HOME}/etc/initial/org.apache.karaf.management.cfg
    #    : FOR    ${ip}    IN    @{controllers}
    #    Run Command On Remote System    ${ip}    ${cmd}
    #    ${cmd} =    Set Variable    cat ${KARAF_HOME}/etc/org.apache.karaf.features.cfg
    #    : FOR    ${ip}    IN    @{controllers}
    #    Run Command On Remote System    ${ip}    ${cmd}
    #
    #Isolate a Controller From Cluster
    #    [Arguments]    ${isolated controller}    @{controllers}
    #    [Documentation]    Use IPTables to isolate one controller from the cluster.
    #    ...    On the isolated controller it blocks IP traffic to and from each of the other controllers.
    #    : FOR    ${controller}    IN    @{controllers}
    #    ${other controller}=    Evaluate    "${isolated controller}" != "${controller}"
    #    Run Keyword If    ${other controller}    Isolate One Controller From Another    ${isolated controller}    ${controller}
    #
    #Rejoin a Controller To Cluster
    #    [Arguments]    ${isolated controller}    @{controllers}
    #    [Documentation]    Use IPTables to rejoin one controller to the cluster.
    #    ...    On the isolated controller it unblocks IP traffic to and from each of the other controllers.
    #    : FOR    ${controller}    IN    @{controllers}
    #    ${other controller}=    Evaluate    "${isolated controller}" != "${controller}"
    #    Run Keyword If    ${other controller}    Rejoin One Controller To Another    ${isolated controller}    ${controller}
    #
    #Isolate One Controller From Another
    #    [Arguments]    ${isolated controller}    ${controller}
    #    [Documentation]    Inserts an IPTable rule to disconnect one controller from another controller in the cluster.
    #    Modify IPTables    ${isolated controller}    ${controller}    -I
    #
    #Rejoin One Controller To Another
    #    [Arguments]    ${isolated controller}    ${controller}
    #    [Documentation]    Deletes an IPTable rule, allowing one controller to reconnect to another controller in the cluster.
    #    Modify IPTables    ${isolated controller}    ${controller}    -D
    #
    #Modify IPTables
    #    [Arguments]    ${isolated controller}    ${controller}    ${rule type}
    #    [Documentation]    Adds a rule, usually inserting or deleting an entry between two controllers.
    #    ${base string}    Set Variable    sudo iptables ${rule type} OUTPUT -p all --source
    #    ${cmd string}    Catenate    ${base string}    ${isolated controller} --destination ${controller} -j DROP
    #    Run Command On Remote System    ${isolated controller}    ${cmd string}
    #    ${cmd string}    Catenate    ${base string}    ${controller} --destination ${isolated controller} -j DROP
    #    Run Command On Remote System    ${isolated controller}    ${cmd string}
    #    ${cmd string}    Set Variable    sudo iptables -L -n
    #    ${return string}=    Run Command On Remote System    ${isolated controller}    ${cmd string}
    #    #If inserting rules:
    #    Run Keyword If    "${rule type}" == '-I'    Should Match Regexp    ${return string}    [\s\S]*DROP *all *-- *${isolated controller} *${controller}[\s\S]*
    #    Run Keyword If    "${rule type}" == '-I'    Should Match Regexp    ${return string}    [\s\S]*DROP *all *-- *${controller} *${isolated controller}[\s\S]*
    #    #If deleting rules:
    #    Run Keyword If    "${rule type}" == '-D'    Should Match Regexp    ${return string}    (?![\s\S]*DROP *all *-- *${isolated controller} *${controller}[\s\S]*)
    #    Run Keyword If    "${rule type}" == '-D'    Should Match Regexp    ${return string}    (?![\s\S]*DROP *all *-- *${controller} *${isolated controller}[\s\S]*)
    #
    #Rejoin All Isolated Controllers
    #    [Arguments]    @{controllers}
    #    [Documentation]    Wipe all IPTables rules from all controllers, thus rejoining all controllers.
    #    : FOR    ${isolated controller}    IN    @{controllers}
    #    Flush IPTables    ${isolated controller}
    #
    #Flush IPTables
    #    [Arguments]    ${isolated controller}
    #    [Documentation]    This keyword is generally not called from a test case but supports a complete wipe of all rules on
    #    ...    all contollers.
    #    ${cmd string}    Set Variable    sudo iptables -v -F
    #    ${return string}=    Run Command On Remote System    ${isolated controller}    ${cmd string}
    #    Log    return: ${return string}
    #    Should Contain    ${return string}    Flushing chain `INPUT'
    #    Should Contain    ${return string}    Flushing chain `FORWARD'
    #    Should Contain    ${return string}    Flushing chain `OUTPUT'
    #
