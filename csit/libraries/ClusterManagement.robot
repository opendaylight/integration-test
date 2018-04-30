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
...               All index lists returned should be sorted numerically, fix if not.
...
...               Requirements:
...               odl-jolokia is assumed to be installed.
...
...               Keywords are ordered as follows:
...               - Cluster Setup
...               - Shard state, leader and followers
...               - Entity Owner, candidates and successors
...               - Kill, Stop and Start Member
...               - Isolate and Rejoin Member
...               - Run Commands On Member
...               - REST requests and checks on Members
...
...               TODO: Unify capitalization of Leaders and Followers.
Library           RequestsLibrary    # for Create_Session and To_Json
Library           Collections
Resource          ${CURDIR}/CompareStream.robot
Resource          ${CURDIR}/KarafKeywords.robot
Resource          ${CURDIR}/SSHKeywords.robot
Resource          ${CURDIR}/TemplatedRequests.robot    # for Get_As_Json_From_Uri
Resource          ${CURDIR}/Utils.robot    # for Run_Command_On_Controller
Resource          ../variables/Variables.robot

*** Variables ***
${ENTITY_OWNER_URI}    restconf/operational/entity-owners:entity-owners
${GC_LOG_PATH}    ${KARAF_HOME}/data/log
${JAVA_HOME}      ${EMPTY}    # releng/builder scripts should provide correct value
${JOLOKIA_CONF_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
${JOLOKIA_OPER_SHARD_MANAGER_URI}    jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore
${JOLOKIA_READ_URI}    jolokia/read/org.opendaylight.controller
# Bug 9044 workaround: delete etc/host.key before restart.
@{ODL_DEFAULT_DATA_PATHS}    tmp/    data/    cache/    snapshots/    journal/    etc/opendaylight/current/    etc/host.key
${RESTCONF_MODULES_DIR}    ${CURDIR}/../variables/restconf/modules
${SINGLETON_NETCONF_DEVICE_ID_PREFIX}    /odl-general-entity:entity[odl-general-entity:name='KeyedInstanceIdentifier{targetType=interface org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node, path=[org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology, org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology[key=TopologyKey [_topologyId=Uri [_value=topology-netconf]]], org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node[key=NodeKey [_nodeId=Uri [_value=
${SINGLETON_NETCONF_DEVICE_ID_SUFFIX}    ]]]]}']
${SINGLETON_BGPCEP_DEVICE_ID_PREFIX}    /odl-general-entity:entity[odl-general-entity:name='
${SINGLETON_BGPCEP_DEVICE_ID_SUFFIX}    -service-group']
${SINGLETON_ELECTION_ENTITY_TYPE}    org.opendaylight.mdsal.ServiceEntityType
${SINGLETON_CHANGE_OWNERSHIP_ENTITY_TYPE}    org.opendaylight.mdsal.AsyncServiceCloseEntityType
${NODE_ROLE_INDEX_START}    1
${NODE_START_COMMAND}    ${KARAF_HOME}/bin/start
${NODE_STOP_COMMAND}    ${KARAF_HOME}/bin/stop
${NODE_KARAF_COUNT_COMMAND}    ps axf | grep org.apache.karaf | grep -v grep | wc -l
${NODE_KILL_COMMAND}    ps axf | grep org.apache.karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${NODE_FREEZE_COMMAND}    ps axf | grep org.apache.karaf | grep -v grep | awk '{print \"kill -STOP \" $1}' | sh
${NODE_UNFREEZE_COMMAND}    ps axf | grep org.apache.karaf | grep -v grep | awk '{print \"kill -CONT \" $1}' | sh

*** Keywords ***
ClusterManagement_Setup
    [Arguments]    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}    ${http_retries}=0
    [Documentation]    Detect repeated call, or detect number of members and initialize derived suite variables.
    ...    Http sessions are created with parameters to not waste time when ODL is no accepting connections properly.
    # Avoid multiple initialization by several downstream libraries.
    ${already_done} =    BuiltIn.Get_Variable_Value    \${ClusterManagement__has_setup_run}    False
    BuiltIn.Return_From_Keyword_If    ${already_done}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    True
    ${cluster_size} =    BuiltIn.Get_Variable_Value    \${NUM_ODL_SYSTEM}    1
    ${status}    ${possibly_int_of_members} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Convert_To_Integer    ${cluster_size}
    ${int_of_members} =    BuiltIn.Set_Variable_If    '${status}' != 'PASS'    ${1}    ${possibly_int_of_members}
    ClusterManagement__Compute_Derived_Variables    int_of_members=${int_of_members}    http_timeout=${http_timeout}    http_retries=${http_retries}

Check_Cluster_Is_In_Sync
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Fail if no-sync is detected on a member from list (or any).
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
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
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=True    ${member_index_list}=${EMPTY}    ${verify_restconf}=True    ${http_timeout}=${EMPTY}
    [Documentation]    Get role lists, validate there is one leader, return the leader and list of followers.
    ...    Optionally, issue GET to a simple restconf URL to make sure subsequent operations will not encounter 503.
    ${leader_list}    ${follower_list} =    Get_State_Info_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    validate=True    member_index_list=${member_index_list}
    ...    verify_restconf=${verify_restconf}    http_timeout=${http_timeout}
    ${leader_count} =    BuiltIn.Get_Length    ${leader_list}
    BuiltIn.Run_Keyword_If    ${leader_count} < 1    BuiltIn.Fail    No leader found.
    BuiltIn.Length_Should_Be    ${leader_list}    ${1}    Too many Leaders.
    ${leader} =    Collections.Get_From_List    ${leader_list}    0
    [Return]    ${leader}    ${follower_list}

Get_State_Info_For_Shard
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=False    ${member_index_list}=${EMPTY}    ${verify_restconf}=False    ${http_timeout}=${EMPTY}
    [Documentation]    Return lists of Leader and Follower member indices from a given member index list
    ...    (or from the full list if empty). If \${shard_type} is not 'config', 'operational' is assumed.
    ...    If \${validate}, Fail if raft state is not Leader or Follower (for example on Candidate).
    ...    The biggest difference from Get_Leader_And_Followers_For_Shard
    ...    is that no check on number of Leaders is performed.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    Collections.Sort_List    ${index_list}    # to guarantee return values are also sorted lists
    # TODO: Support alternative capitalization of 'config'?
    ${ds_type} =    BuiltIn.Set_Variable_If    '${shard_type}' != 'config'    operational    config
    ${leader_list} =    BuiltIn.Create_List
    ${follower_list} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${raft_state} =    Get_Raft_State_Of_Shard_At_Member    shard_name=${shard_name}    shard_type=${ds_type}    member_index=${index}    verify_restconf=${verify_restconf}
    \    ...    http_timeout=${http_timeout}
    \    BuiltIn.Run_Keyword_If    'Follower' == '${raft_state}'    Collections.Append_To_List    ${follower_list}    ${index}
    \    ...    ELSE IF    'Leader' == '${raft_state}'    Collections.Append_To_List    ${leader_list}    ${index}
    \    ...    ELSE IF    ${validate}    BuiltIn.Fail    Unrecognized Raft state: ${raft_state}
    [Return]    ${leader_list}    ${follower_list}

Get_Raft_State_Of_Shard_At_Member
    [Arguments]    ${shard_name}    ${shard_type}    ${member_index}    ${verify_restconf}=False    ${http_timeout}=${EMPTY}
    [Documentation]    Send request to Jolokia on indexed member, return extracted Raft status.
    ...    Optionally, check restconf works.
    ${raft_state} =    Get_Raft_Property_From_Shard_Member    RaftState    ${shard_name}    ${shard_type}    ${member_index}    verify_restconf=${verify_restconf}
    ...    http_timeout=${http_timeout}
    [Return]    ${raft_state}

Get_Raft_Property_From_Shard_Member
    [Arguments]    ${property}    ${shard_name}    ${shard_type}    ${member_index}    ${verify_restconf}=False    ${http_timeout}=${EMPTY}
    [Documentation]    Send request to Jolokia on indexed member, return extracted Raft property.
    ...    Optionally, check restconf works.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    # TODO: Does the used URI tend to generate large data which floods log.html?
    BuiltIn.Run_Keyword_If    ${verify_restconf}    TemplatedRequests.Get_As_Json_Templated    session=${session}    folder=${RESTCONF_MODULES_DIR}    verify=False    http_timeout=${http_timeout}
    ${type_class} =    Resolve_Shard_Type_Class    shard_type=${shard_type}
    ${cluster_index} =    Evaluate    ${member_index}+${NODE_ROLE_INDEX_START}-1
    ${uri} =    BuiltIn.Set_Variable    ${JOLOKIA_READ_URI}:Category=Shards,name=member-${cluster_index}-shard-${shard_name}-${shard_type},type=${type_class}
    ${data_text} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${uri}    session=${session}    http_timeout=${http_timeout}
    ${data_object} =    RequestsLibrary.To_Json    ${data_text}
    ${value} =    Collections.Get_From_Dictionary    ${data_object}    value
    ${raft_property} =    Collections.Get_From_Dictionary    ${value}    ${property}
    [Return]    ${raft_property}

Verify_Shard_Leader_Elected
    [Arguments]    ${shard_name}    ${shard_type}    ${new_elected}    ${old_leader}    ${member_index_list}=${EMPTY}    ${verify_restconf}=True
    [Documentation]    Verify new leader was elected or remained the same. Bool paramter ${new_elected} indicates if
    ...    new leader is elected or should remained the same as ${old_leader}
    ${leader}    ${followers}=    Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${member_index_list}    verify_restconf=${verify_restconf}
    BuiltIn.Run_Keyword_If    ${new_elected}    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_leader}    ${leader}
    BuiltIn.Run_Keyword_Unless    ${new_elected}    BuiltIn.Should_Be_Equal_As_numbers    ${old_leader}    ${leader}
    BuiltIn.Return_From_Keyword    ${leader}    ${followers}

Verify_Owner_And_Successors_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${candidate_list}=${EMPTY}    ${after_stop}=False
    [Documentation]    Returns the owner and successors for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    For Boron and beyond, candidates are not removed on node down or isolation,
    ...    so this keyword expects candidates to be all members from Boron on.
    ...    Extra check is done to verify owner and successors are within the ${candidate_list}. This KW is useful when combined with WUKS.
    ...    ${candidate_list} minus owner is returned as ${successor list}.
    ...    Users can still use Get_Owner_And_Successors_For_Device if they are interested in downed candidates,
    ...    or for testing heterogeneous clusters.
    ${index_list} =    List_Indices_Or_All    given_list=${candidate_list}
    ${owner}    ${successor_list} =    Get_Owner_And_Successors_For_Device    device_name=${device_name}    device_type=${device_type}    member_index=${member_index}
    Collections.List_Should_Contain_Value    ${index_list}    ${owner}    Owner ${owner} is not in candidate list ${index_list}
    # In Beryllium or after stopping an instance, the removed instance does not show in the candidate list.
    ${expected_candidate_list_origin} =    BuiltIn.Set_Variable_If    ${after_stop}    ${index_list}    ${ClusterManagement__member_index_list}
    # We do not want to manipulate either origin list.
    ${expected_successor_list} =    BuiltIn.Create_List    @{expected_candidate_list_origin}
    Collections.Remove_Values_From_List    ${expected_successor_list}    ${owner}
    Collections.Lists_Should_Be_Equal    ${expected_successor_list}    ${successor_list}    Successor list ${successor_list} is not the came as expected ${expected_successor_list}
    # User expects the returned successor list to be the provided candidate list minus the owner.
    Collections.Remove_Values_From_List    ${index_list}    ${owner}
    [Return]    ${owner}    ${index_list}

Get_Owner_And_Successors_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of successors for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Successors are those device candidates not elected as owner. The list of successors = (list of candidates) - (owner).
    ...    The returned successor list is sorted numerically.
    ...    Note that "candidate list" definition currently differs between Beryllium and Boron.
    ...    Use Verify_Owner_And_Successors_For_Device if you want the older semantics (inaccessible nodes not present in the list).
    # TODO: somewhere to introduce ${DEFAULT_RESTCONF_DATASTORE_TIMEOUT}. Value may depend on protocol (ask vs tell) and perhaps stream.
    ${owner}    ${candidate_list} =    Get_Owner_And_Candidates_For_Device    device_name=${device_name}    device_type=${device_type}    member_index=${member_index}    http_timeout=${http_timeout}
    ${successor_list} =    BuiltIn.Create_List    @{candidate_list}    # Copy operation is not required, but new variable name requires a line anyway.
    Collections.Remove_Values_From_List    ${successor_list}    ${owner}
    [Return]    ${owner}    ${successor_list}

Get_Owner_And_Candidates_For_Device_Old
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ...    The returned candidate list is sorted numerically.
    ...    Note that "candidate list" definition currently differs between Beryllium and Boron.
    ...    It is recommended to use Get_Owner_And_Successors_For_Device instead of this keyword, see documentation there.
    BuiltIn.Comment    TODO: Can this implementation be changed to call Get_Owner_And_Candidates_For_Type_And_Id?
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${data} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${ENTITY_OWNER_URI}    session=${session}    http_timeout=${http_timeout}
    ${candidate_list} =    BuiltIn.Create_List
    ${entity_type} =    BuiltIn.Set_Variable_If    '${device_type}' == 'netconf'    netconf-node/${device_name}    ${device_type}
    ${clear_data} =    BuiltIn.Run_Keyword_If    '${device_type}' == 'openflow' or '${device_type}' == 'netconf'    Extract_OpenFlow_Device_Data    ${data}
    ...    ELSE IF    '${device_type}' == 'ovsdb'    Extract_Ovsdb_Device_Data    ${data}
    ...    ELSE IF    '${device_type}' == 'org.opendaylight.mdsal.ServiceEntityType'    Extract_Service_Entity_Type    ${data}
    ...    ELSE    Fail    Not recognized device type: ${device_type}
    ${json} =    RequestsLibrary.To_Json    ${clear_data}
    ${entity_type_list} =    Collections.Get_From_Dictionary    &{json}[entity-owners]    entity-type
    ${entity_type_index} =    Utils.Get_Index_From_List_Of_Dictionaries    ${entity_type_list}    type    ${entity_type}
    BuiltIn.Should_Not_Be_Equal_As_Integers    ${entity_type_index}    -1    No Entity Owner found for ${device_type}
    ${entity_list} =    Collections.Get_From_Dictionary    @{entity_type_list}[${entity_type_index}]    entity
    ${entity_index} =    Utils.Get_Index_From_List_Of_Dictionaries    ${entity_list}    id    ${device_name}
    BuiltIn.Should_Not_Be_Equal_As_Integers    ${entity_index}    -1    Device ${device_name} not found in Entity Owner ${device_type}
    ${entity_owner} =    Collections.Get_From_Dictionary    @{entity_list}[${entity_index}]    owner
    BuiltIn.Should_Not_Be_Empty    ${entity_owner}    No owner found for ${device_name}
    ${owner} =    String.Replace_String    ${entity_owner}    member-    ${EMPTY}
    ${owner} =    BuiltIn.Convert_To_Integer    ${owner}
    ${entity_candidates_list} =    Collections.Get_From_Dictionary    @{entity_list}[${entity_index}]    candidate
    : FOR    ${entity_candidate}    IN    @{entity_candidates_list}
    \    ${candidate} =    String.Replace_String    &{entity_candidate}[name]    member-    ${EMPTY}
    \    ${candidate} =    BuiltIn.Convert_To_Integer    ${candidate}
    \    Collections.Append_To_List    ${candidate_list}    ${candidate}
    Collections.Sort_List    ${candidate_list}
    [Return]    ${owner}    ${candidate_list}

Get_Owner_And_Candidates_For_Device_Singleton
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Parsing method is selected by device type
    ...    Separate kw for every supported device type must be defined
    BuiltIn.Keyword_Should_Exist    Get_Owner_And_Candidates_For_Device_Singleton_${device_type}
    BuiltIn.Run_Keyword_And_Return    Get_Owner_And_Candidates_For_Device_Singleton_${device_type}    ${device_name}    ${member_index}    http_timeout=${http_timeout}

Get_Owner_And_Candidates_For_Device_Singleton_Netconf
    [Arguments]    ${device_name}    ${member_index}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type netconf. Request is sent to member ${member_index}.
    ...    Parsing method is set as netconf (using netconf device id prefix and suffix)
    # Get election entity type results
    ${type} =    BuiltIn.Set_Variable    ${SINGLETON_ELECTION_ENTITY_TYPE}
    ${id} =    BuiltIn.Set_Variable    ${SINGLETON_NETCONF_DEVICE_ID_PREFIX}${device_name}${SINGLETON_NETCONF_DEVICE_ID_SUFFIX}
    ${owner_1}    ${candidate_list_1} =    Get_Owner_And_Candidates_For_Type_And_Id    ${type}    ${id}    ${member_index}    http_timeout=${http_timeout}
    # Get change ownership entity type results
    ${type} =    BuiltIn.Set_Variable    ${SINGLETON_CHANGE_OWNERSHIP_ENTITY_TYPE}
    ${id} =    BuiltIn.Set_Variable    ${SINGLETON_NETCONF_DEVICE_ID_PREFIX}${device_name}${SINGLETON_NETCONF_DEVICE_ID_SUFFIX}
    ${owner_2}    ${candidate_list_2} =    Get_Owner_And_Candidates_For_Type_And_Id    ${type}    ${id}    ${member_index}    http_timeout=${http_timeout}
    # Owners must be same, if not, there is still some election or change ownership in progress
    BuiltIn.Should_Be_Equal_As_Integers    ${owner_1}    ${owner_2}    Owners for device ${device_name} are not same
    [Return]    ${owner_1}    ${candidate_list_1}

Get_Owner_And_Candidates_For_Device_Singleton_Bgpcep
    [Arguments]    ${device_name}    ${member_index}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name}. Request is sent to member ${member_index}.
    # Get election entity type results
    ${type} =    BuiltIn.Set_Variable    ${SINGLETON_ELECTION_ENTITY_TYPE}
    ${id} =    BuiltIn.Set_Variable    ${SINGLETON_BGPCEP_DEVICE_ID_PREFIX}${device_name}${SINGLETON_BGPCEP_DEVICE_ID_SUFFIX}
    ${owner_1}    ${candidate_list_1} =    Get_Owner_And_Candidates_For_Type_And_Id    ${type}    ${id}    ${member_index}    http_timeout=${http_timeout}
    # Get change ownership entity type results
    ${type} =    BuiltIn.Set_Variable    ${SINGLETON_CHANGE_OWNERSHIP_ENTITY_TYPE}
    ${id} =    BuiltIn.Set_Variable    ${SINGLETON_BGPCEP_DEVICE_ID_PREFIX}${device_name}${SINGLETON_BGPCEP_DEVICE_ID_SUFFIX}
    ${owner_2}    ${candidate_list_2} =    Get_Owner_And_Candidates_For_Type_And_Id    ${type}    ${id}    ${member_index}    http_timeout=${http_timeout}
    # Owners must be same, if not, there is still some election or change ownership in progress
    BuiltIn.Should_Be_Equal_As_Integers    ${owner_1}    ${owner_2}    Owners for device ${device_name} are not same
    [Return]    ${owner_1}    ${candidate_list_1}

Get_Owner_And_Candidates_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    If parsing as singleton failed, kw try to parse data in old way (without singleton).
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ...    The returned candidate list is sorted numerically.
    ...    Note that "candidate list" definition currently differs between Beryllium and Boron.
    ...    It is recommended to use Get_Owner_And_Successors_For_Device instead of this keyword, see documentation there.
    # Try singleton
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    Get_Owner_And_Candidates_For_Device_Singleton    device_name=${device_name}    device_type=${device_type}    member_index=${member_index}
    ...    http_timeout=${http_timeout}
    BuiltIn.Return_From_Keyword_If    "${status}"=="PASS"    ${results}
    # If singleton failed, try parsing in old way
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error    Get_Owner_And_Candidates_For_Device_Old    device_name=${device_name}    device_type=${device_type}    member_index=${member_index}
    ...    http_timeout=${http_timeout}
    # previous 3 lines (BuilIn.Return.., # If singleton..., ${status}....) could be deleted when old way will not be supported anymore
    BuiltIn.Run_Keyword_If    '${status}'=='FAIL'    BuiltIn.Fail    Could not parse owner and candidates for device ${device_name}
    [Return]    @{results}

Check_Old_Owner_Stays_Elected_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${old_owner}    ${node_to_ask}    ${http_timeout}=${EMPTY}
    [Documentation]    Verify the owner remain the same as ${old_owner}
    ${owner}    ${candidates} =    Get_Owner_And_Candidates_For_Device    ${device_name}    ${device_type}    ${node_to_ask}    http_timeout=${http_timeout}
    BuiltIn.Should_Be_Equal_As_numbers    ${old_owner}    ${owner}
    BuiltIn.Return_From_Keyword    ${owner}    ${candidates}

Check_New_Owner_Got_Elected_For_Device
    [Arguments]    ${device_name}    ${device_type}    ${old_owner}    ${node_to_ask}    ${http_timeout}=${EMPTY}
    [Documentation]    Verify new owner was elected comparing to ${old_owner}
    ${owner}    ${candidates} =    Get_Owner_And_Candidates_For_Device    ${device_name}    ${device_type}    ${node_to_ask}    http_timeout=${http_timeout}
    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_owner}    ${owner}
    BuiltIn.Return_From_Keyword    ${owner}    ${candidates}

Get_Owner_And_Candidates_For_Type_And_Id
    [Arguments]    ${type}    ${id}    ${member_index}    ${require_candidate_list}=${EMPTY}    ${http_timeout}=${EMPTY}
    [Documentation]    Returns the owner and a list of candidates for entity specified by ${type} and ${id}
    ...    Request is sent to member ${member_index}.
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ...    Bear in mind that for Boron and beyond, candidates are not removed on node down or isolation.
    ...    If ${require_candidate_list} is not \${EMPTY}, check whether the actual list of candidates matches.
    ...    Note that differs from "given list" semantics used in other keywords,
    ...    namely you cannot use \${EMPTY} to stand for "full list" in this keyword.
    BuiltIn.Comment    TODO: Find a way to unify and deduplicate code blocks in Get_Owner_And_Candidates_* keywords.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${data} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${ENTITY_OWNER_URI}    session=${session}    http_timeout=${http_timeout}
    ${candidate_list} =    BuiltIn.Create_List
    ${json} =    RequestsLibrary.To_Json    ${data}
    ${entity_type_list} =    Collections.Get_From_Dictionary    &{json}[entity-owners]    entity-type
    ${entity_type_index} =    Utils.Get_Index_From_List_Of_Dictionaries    ${entity_type_list}    type    ${type}
    BuiltIn.Should_Not_Be_Equal_As_Integers    ${entity_type_index}    -1    No Entity Owner found for ${type}
    ${entity_list} =    Collections.Get_From_Dictionary    @{entity_type_list}[${entity_type_index}]    entity
    ${entity_index} =    Utils.Get_Index_From_List_Of_Dictionaries    ${entity_list}    id    ${id}
    BuiltIn.Should Not_Be_Equal_As_Integers    ${entity_index}    -1    Id ${id} not found in Entity Owner ${type}
    ${entity_owner} =    Collections.Get_From_Dictionary    @{entity_list}[${entity_index}]    owner
    BuiltIn.Should_Not_Be_Empty    ${entity_owner}    No owner found for type=${type} id=${id}
    ${owner} =    String.Replace_String    ${entity_owner}    member-    ${EMPTY}
    ${owner} =    BuiltIn.Convert_To_Integer    ${owner}
    ${entity_candidates_list} =    Collections.Get_From_Dictionary    @{entity_list}[${entity_index}]    candidate
    : FOR    ${entity_candidate}    IN    @{entity_candidates_list}
    \    ${candidate} =    String.Replace_String    &{entity_candidate}[name]    member-    ${EMPTY}
    \    ${candidate} =    BuiltIn.Convert_To_Integer    ${candidate}
    \    Collections.Append_To_List    ${candidate_list}    ${candidate}
    Collections.Sort_List    ${candidate_list}
    BuiltIn.Comment    TODO: Separate check lines into Verify_Owner_And_Candidates_For_Type_And_Id
    BuiltIn.Run_Keyword_If    """${require_candidate_list}"""    BuiltIn.Should_Be_Equal    ${require_candidate_list}    ${candidate_list}    Candidate list does not match: ${candidate_list} is not ${require_candidate_list}
    [Return]    ${owner}    ${candidate_list}

Extract_Service_Entity_Type
    [Arguments]    ${data}
    [Documentation]    Remove superfluous device data from Entity Owner printout.
    ${clear_data} =    String.Replace_String    ${data}    /odl-general-entity:entity[odl-general-entity:name='    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    -service-group']    ${EMPTY}
    Log    ${clear_data}
    [Return]    ${clear_data}

Extract_OpenFlow_Device_Data
    [Arguments]    ${data}
    [Documentation]    Remove superfluous OpenFlow device data from Entity Owner printout.
    ${clear_data} =    String.Replace_String    ${data}    org.opendaylight.mdsal.ServiceEntityType    openflow
    ${clear_data} =    String.Replace_String    ${clear_data}    /odl-general-entity:entity[odl-general-entity:name='    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    /general-entity:entity[general-entity:name='    ${EMPTY}
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
    [Arguments]    ${member}    ${original_index_list}=${EMPTY}    ${confirm}=True
    [Documentation]    Convenience keyword that kills the specified member of the cluster.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member}
    ${index_list} =    ClusterManagement__Build_List    ${member}
    ${member_ip} =    Return_Member_IP    ${member}
    KarafKeywords.Log_Message_To_Controller_Karaf    Killing ODL${member} ${member_ip}
    ${updated_index_list} =    Kill_Members_From_List_Or_All    ${index_list}    ${original_index_list}    ${confirm}
    [Return]    ${updated_index_list}

Kill_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${original_index_list}=${EMPTY}    ${confirm}=True
    [Documentation]    If the list is empty, kill all ODL instances. Otherwise, kill members based on \${kill_index_list}
    ...    If \${confirm} is True, sleep 1 second and verify killed instances are not there anymore.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member_index_list}
    ${kill_index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${index_list} =    List_Indices_Or_All    given_list=${original_index_list}
    Run_Bash_Command_On_List_Or_All    command=${NODE_KILL_COMMAND}    member_index_list=${member_index_list}
    ${updated_index_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${updated_index_list}    @{kill_index_list}
    BuiltIn.Return_From_Keyword_If    not ${confirm}    ${updated_index_list}
    # TODO: Convert to WUKS with configurable timeout if it turns out 1 second is not enough.
    BuiltIn.Sleep    1s    Kill -9 closes open files, which may take longer than ssh overhead, but not long enough to warrant WUKS.
    : FOR    ${index}    IN    @{kill_index_list}
    \    Verify_Karaf_Is_Not_Running_On_Member    member_index=${index}
    Run_Bash_Command_On_List_Or_All    command=netstat -pnatu | grep 2550
    [Return]    ${updated_index_list}

Stop_Single_Member
    [Arguments]    ${member}    ${original_index_list}=${EMPTY}    ${confirm}=True
    [Documentation]    Convenience keyword that stops the specified member of the cluster.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member}
    ${index_list} =    ClusterManagement__Build_List    ${member}
    ${updated_index_list} =    Stop_Members_From_List_Or_All    ${index_list}    ${original_index_list}    ${confirm}
    [Return]    ${updated_index_list}

Stop_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${original_index_list}=${EMPTY}    ${confirm}=True    ${timeout}=120s
    [Documentation]    If the list is empty, stops all ODL instances. Otherwise stop members based on \${stop_index_list}
    ...    If \${confirm} is True, verify stopped instances are not there anymore.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member_index_list}
    ${stop_index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${index_list} =    List_Indices_Or_All    given_list=${original_index_list}
    Run_Bash_Command_On_List_Or_All    command=${NODE_STOP_COMMAND}    member_index_list=${member_index_list}
    ${updated_index_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${updated_index_list}    @{stop_index_list}
    BuiltIn.Return_From_Keyword_If    not ${confirm}    ${updated_index_list}
    : FOR    ${index}    IN    @{stop_index_list}
    \    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    2s    Verify_Karaf_Is_Not_Running_On_Member    member_index=${index}
    Run_Bash_Command_On_List_Or_All    command=netstat -pnatu | grep 2550
    [Return]    ${updated_index_list}

Start_Single_Member
    [Arguments]    ${member}    ${wait_for_sync}=True    ${timeout}=300s
    [Documentation]    Convenience keyword that starts the specified member of the cluster.
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Start_Members_From_List_Or_All    ${index_list}    ${wait_for_sync}    ${timeout}

Start_Members_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${wait_for_sync}=True    ${timeout}=300s    ${karaf_home}=${EMPTY}    ${export_java_home}=${EMPTY}    ${gc_log_dir}=${EMPTY}
    [Documentation]    If the list is empty, start all cluster members. Otherwise, start members based on present indices.
    ...    If ${wait_for_sync}, wait for cluster sync on listed members.
    ...    Optionally karaf_home can be overriden. Optionally specific JAVA_HOME is used for starting.
    ...    Garbage collection is unconditionally logged to files. TODO: Make that reasonable conditional?
    ${base_command} =    BuiltIn.Set_Variable_If    """${karaf_home}""" != ""    ${karaf_home}/bin/start    ${NODE_START_COMMAND}
    ${command} =    BuiltIn.Set_Variable_If    """${export_java_home}""" != ""    export JAVA_HOME="${export_java_home}"; ${base_command}    ${base_command}
    ${epoch} =    DateTime.Get_Current_Date    time_zone=UTC    result_format=epoch    exclude_millis=False
    ${gc_filepath} =    BuiltIn.Set_Variable_If    """${karaf_home}""" != ""    ${karaf_home}/data/log/gc_${epoch}.log    ${GC_LOG_PATH}/gc_${epoch}.log
    ${gc_options} =    BuiltIn.Set_Variable_If    "docker" not in """${node_start_command}"""    -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${gc_filepath}    ${EMPTY}
    Run_Bash_Command_On_List_Or_All    command=${command} ${gc_options}    member_index_list=${member_index_list}
    BuiltIn.Return_From_Keyword_If    not ${wait_for_sync}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    10s    Check_Cluster_Is_In_Sync    member_index_list=${member_index_list}
    # TODO: Do we also want to check Shard Leaders here?
    [Teardown]    Run_Bash_Command_On_List_Or_All    command=netstat -pnatu | grep 2550

Freeze_Single_Member
    [Arguments]    ${member}
    [Documentation]    Convenience keyword that stops the specified member of the cluster by freezing the jvm.
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Freeze_Or_Unfreeze_Members_From_List_Or_All    ${NODE_FREEZE_COMMAND}    ${index_list}

Unfreeze_Single_Member
    [Arguments]    ${member}    ${wait_for_sync}=True    ${timeout}=60s
    [Documentation]    Convenience keyword that "continues" the specified member of the cluster by unfreezing the jvm.
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Freeze_Or_Unfreeze_Members_From_List_Or_All    ${NODE_UNFREEZE_COMMAND}    ${index_list}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    10s    Check_Cluster_Is_In_Sync

Freeze_Or_Unfreeze_Members_From_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    [Documentation]    If the list is empty, stops/runs all ODL instances. Otherwise stop/run members based on \${stop_index_list}
    ...    For command parameter only ${NODE_FREEZE_COMMAND} and ${NODE_UNFREEZE_COMMAND} should be used
    ${freeze_index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    Run_Bash_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}

Clean_Journals_Data_And_Snapshots_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${karaf_home}=${KARAF_HOME}
    [Documentation]    Delete journal and snapshots directories on every node listed (or all).
    ...    BEWARE: If only a subset of members is cleaned, this causes RetiredGenerationException in Carbon after the affected node re-start.
    ...    See https://bugs.opendaylight.org/show_bug.cgi?id=8138
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${command} =    Set Variable    rm -rf "${karaf_home}/journal" "${karaf_home}/snapshots" "${karaf_home}/data"
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Run_Bash_Command_On_Member    command=${command}    member_index=${index}

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
    ${command} =    BuiltIn.Set_Variable    ${NODE_KARAF_COUNT_COMMAND}
    ${count} =    Run_Bash_Command_On_Member    command=${command}    member_index=${member_index}
    [Return]    ${count}

Isolate_Member_From_List_Or_All
    [Arguments]    ${isolate_member_index}    ${member_index_list}=${EMPTY}    ${protocol}=all    ${port}=${EMPTY}
    [Documentation]    If the list is empty, isolate member from all ODL instances. Otherwise, isolate member based on present indices.
    ...    The KW will return a list of available members: \${updated index_list}=\${member_index_list}-\${isolate_member_index}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${source} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${isolate_member_index}
    ${dport} =    BuiltIn.Set_Variable_If    '${port}' != '${EMPTY}'    --dport ${port}    ${EMPTY}
    : FOR    ${index}    IN    @{index_list}
    \    ${destination} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
    \    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -I OUTPUT -p ${protocol} ${dport} --source ${source} --destination ${destination} -j DROP
    \    BuiltIn.Run_Keyword_If    "${index}" != "${isolate_member_index}"    Run_Bash_Command_On_Member    command=${command}    member_index=${isolate_member_index}
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Run_Bash_Command_On_Member    command=${command}    member_index=${isolate_member_index}
    BuiltIn.Log    ${output}
    ${updated_index_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${updated_index_list}    ${isolate_member_index}
    [Return]    ${updated_index_list}

Rejoin_Member_From_List_Or_All
    [Arguments]    ${rejoin_member_index}    ${member_index_list}=${EMPTY}    ${protocol}=all    ${port}=${EMPTY}    ${timeout}=60s
    [Documentation]    If the list is empty, rejoin member from all ODL instances. Otherwise, rejoin member based on present indices.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${source} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${rejoin_member_index}
    ${dport} =    BuiltIn.Set_Variable_If    '${port}' != '${EMPTY}'    --dport ${port}    ${EMPTY}
    : FOR    ${index}    IN    @{index_list}
    \    ${destination} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
    \    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -D OUTPUT -p ${protocol} ${dport} --source ${source} --destination ${destination} -j DROP
    \    BuiltIn.Run_Keyword_If    "${index}" != "${rejoin_member_index}"    Run_Bash_Command_On_Member    command=${command}    member_index=${rejoin_member_index}
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Run_Bash_Command_On_Member    command=${command}    member_index=${rejoin_member_index}
    BuiltIn.Log    ${output}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    10s    Check_Cluster_Is_In_Sync

Flush_Iptables_From_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    If the list is empty, flush IPTables in all ODL instances. Otherwise, flush member based on present indices.
    ${command} =    BuiltIn.Set_Variable    sudo iptables -v -F
    ${output} =    Run_Bash_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}

Check_Bash_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}    ${return_success_only}=False    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    [Documentation]    Cycle through indices (or all), run bash command on each, using temporary SSH session and restoring the previously active one.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    Check_Bash_Command_On_Member    command=${command}    member_index=${index}    return_success_only=${return_success_only}    log_on_success=${log_on_success}    log_on_failure=${log_on_failure}
    \    ...    stderr_must_be_empty=${stderr_must_be_empty}

Check_Bash_Command_On_Member
    [Arguments]    ${command}    ${member_index}    ${return_success_only}=False    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    [Documentation]    Open SSH session, call SSHKeywords.Execute_Command_Passes, close session, restore previously active session and return output.
    BuiltIn.Run_Keyword_And_Return    SSHKeywords.Run_Keyword_Preserve_Connection    Check_Unsafely_Bash_Command_On_Member    ${command}    ${member_index}    return_success_only=${return_success_only}    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

Check_Unsafely_Bash_Command_On_Member
    [Arguments]    ${command}    ${member_index}    ${return_success_only}=False    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    [Documentation]    Obtain Ip address, open session, call SSHKeywords.Execute_Command_Passes, close session and return output. This affects which SSH session is active.
    ${member_ip} =    Resolve_Ip_Address_For_Member    ${member_index}
    BuiltIn.Run_Keyword_And_Return    SSHKeywords.Run_Unsafely_Keyword_Over_Temporary_Odl_Session    ${member_ip}    Execute_Command_Passes    ${command}    return_success_only=${return_success_only}    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}    stderr_must_be_empty=${stderr_must_be_empty}

Run_Bash_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    [Documentation]    Cycle through indices (or all), run command on each.
    # TODO: Migrate callers to Check_Bash_Command_*
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    Run_Bash_Command_On_Member    command=${command}    member_index=${index}

Run_Bash_Command_On_Member
    [Arguments]    ${command}    ${member_index}
    [Documentation]    Obtain IP, call Utils and return output. This keeps previous ssh session active.
    # TODO: Migrate callers to Check_Bash_Command_*
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    ${output} =    SSHKeywords.Run_Keyword_Preserve_Connection    Utils.Run_Command_On_Controller    ${member_ip}    ${command}
    Log    ${output}
    [Return]    ${output}

Run_Karaf_Command_On_List_Or_All
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}    ${timeout}=10s
    [Documentation]    Cycle through indices (or all), run karaf command on each.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${index}
    \    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    ${command}    ${member_ip}    timeout=${timeout}

Run_Karaf_Command_On_Member
    [Arguments]    ${command}    ${member_index}    ${timeout}=10s
    [Documentation]    Obtain IP address, call KarafKeywords and return output. This does not preserve active ssh session.
    ...    This keyword is not used by Run_Karaf_Command_On_List_Or_All, but returned output may be useful.
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    ${output} =    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    ${command}    controller=${member_ip}    timeout=${timeout}
    [Return]    ${output}

Install_Feature_On_List_Or_All
    [Arguments]    ${feature_name}    ${member_index_list}=${EMPTY}    ${timeout}=60s
    [Documentation]    Attempt installation on each member from list (or all). Then look for failures.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${status_list} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{index_list}
    \    ${status}    ${text} =    BuiltIn.Run_Keyword_And_Ignore_Error    Install_Feature_On_Member    feature_name=${feature_name}    member_index=${index}
    \    ...    timeout=${timeout}
    \    BuiltIn.Log    ${text}
    \    Collections.Append_To_List    ${status_list}    ${status}
    : FOR    ${status}    IN    @{status_list}
    \    BuiltIn.Run_Keyword_If    "${status}" != "PASS"    BuiltIn.Fail    ${feature_name} installation failed, see log.

Install_Feature_On_Member
    [Arguments]    ${feature_name}    ${member_index}    ${timeout}=60s
    [Documentation]    Run feature:install karaf command, fail if installation was not successful. Return output.
    ${status}    ${output} =    BuiltIn.Run_Keyword_And_Ignore_Error    Run_Karaf_Command_On_Member    command=feature:install ${feature_name}    member_index=${member_index}    timeout=${timeout}
    BuiltIn.Run_Keyword_If    "${status}" != "PASS"    BuiltIn.Fail    Failed to install ${feature_name}: ${output}
    BuiltIn.Should_Not_Contain    ${output}    Can't install    Failed to install ${feature_name}: ${output}
    [Return]    ${output}

With_Ssh_To_List_Or_All_Run_Keyword
    [Arguments]    ${member_index_list}    ${keyword_name}    @{args}    &{kwargs}
    [Documentation]    For each index in given list (or all): activate SSH connection, run given Keyword, close active connection. Return None.
    ...    Beware that in order to avoid "got positional argument after named arguments", first two arguments in the call should not be named.
    BuiltIn.Comment    This keyword is experimental and there is high risk of being replaced by another approach.
    # TODO: For_Index_From_List_Or_All_Run_Keyword applied to With_Ssh_To_Member_Run_Keyword?
    # TODO: Imagine another keyword, using ScalarClosures and adding member index as first argument for each call. Worth it?
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${member_index}    IN    @{index_list}
    \    ${member_ip} =    Resolve_IP_Address_For_Member    ${member_index}
    \    SSHKeywords.Run_Unsafely_Keyword_Over_Temporary_Odl_Session    ${member_ip}    ${keyword_name}    @{args}    &{kwargs}

Safe_With_Ssh_To_List_Or_All_Run_Keyword
    [Arguments]    ${member_index_list}    ${keyword_name}    @{args}    &{kwargs}
    [Documentation]    Remember active ssh connection index, call With_Ssh_To_List_Or_All_Run_Keyword, return None. Restore the conection index on teardown.
    SSHKeywords.Run_Keyword_Preserve_Connection    With_Ssh_To_List_Or_All_Run_Keyword    ${member_index_list}    ${keyword_name}    @{args}    &{kwargs}

Clean_Directories_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${directory_list}=${EMPTY}    ${karaf_home}=${KARAF_HOME}    ${tmp_dir}=${EMPTY}
    [Documentation]    Clear @{directory_list} or @{ODL_DEFAULT_DATA_PATHS} for members in given list or all. Return None.
    ...    If \${tmp_dir} is nonempty, use that location to preserve data/log/.
    ...    This is intended to return Karaf (offline) to the state it was upon the first boot.
    ${path_list} =    Builtin.Set Variable If    "${directory_list}" == "${EMPTY}"    ${ODL_DEFAULT_DATA_PATHS}    ${directory_list}
    BuiltIn.Run_Keyword_If    """${tmp_dir}""" != ""    Check_Bash_Command_On_List_Or_All    mkdir -p '${tmp_dir}' && rm -vrf '${tmp_dir}/log' && mv -vf '${karaf_home}/data/log' '${tmp_dir}/'    ${member_index_list}
    Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${member_index_list}    ClusterManagement__Clean_Directories    ${path_list}    ${karaf_home}
    BuiltIn.Run_Keyword_If    """${tmp_dir}""" != ""    Check_Bash_Command_On_List_Or_All    mkdir -p '${karaf_home}/data' && rm -vrf '${karaf_home}/log' && mv -vf '${tmp_dir}/log' '${karaf_home}/data/'    ${member_index_list}

Store_Karaf_Log_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${dst_dir}=/tmp    ${karaf_home}=${KARAF_HOME}
    [Documentation]    Saves karaf.log to the ${dst_dir} for members in given list or all. Return None.
    Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${member_index_list}    SSHKeywords.Execute_Command_Should_Pass    cp ${karaf_home}/data/log/karaf.log ${dst_dir}

Restore_Karaf_Log_On_List_Or_All
    [Arguments]    ${member_index_list}=${EMPTY}    ${src_dir}=/tmp    ${karaf_home}=${KARAF_HOME}
    [Documentation]    Places stored karaf.log to the ${karaf_home}/data/log for members in given list or all. Return None.
    Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${member_index_list}    SSHKeywords.Execute_Command_Should_Pass    cp ${src_dir}/karaf.log ${karaf_home}/data/log/

ClusterManagement__Clean_Directories
    [Arguments]    ${relative_path_list}    ${karaf_home}
    [Documentation]    For each relative path, remove files with respect to ${karaf_home}. Return None.
    : FOR    ${relative_path}    IN    @{relative_path_list}
    \    SSHLibrary.Execute_Command    rm -rf ${karaf_home}${/}${relative_path}

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
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${data} =    Get_From_Member    uri=${uri}    member_index=${index}
    \    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_data}    ${data}

Check_Item_Occurrence_Member_List_Or_All
    [Arguments]    ${uri}    ${dictionary}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check received for occurrences of items expressed in a dictionary ${dictionary}.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${data} =    Get_From_Member    uri=${uri}    member_index=${index}
    \    Utils.Check Item Occurrence    ${data}    ${dictionary}

Check_No_Content_Member_List_Or_All
    [Arguments]    ${uri}    ${member_index_list}=${EMPTY}
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check there is no content.
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${session} =    Resolve_Http_Session_For_Member    member_index=${index}
    \    Utils.No_Content_From_URI    ${session}    ${uri}

Get_From_Member
    [Arguments]    ${uri}    ${member_index}    ${access}=${ACCEPT_EMPTY}
    [Documentation]    Send a GET with the supplied uri to member ${member_index}.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Get_From_Uri    uri=${uri}    accept=${access}    session=${session}
    [Return]    ${response_text}

Resolve_IP_Address_For_Member
    [Arguments]    ${member_index}
    [Documentation]    Return node IP address of given index.
    ${ip_address} =    Collections.Get From Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_index}
    [Return]    ${ip_address}

Resolve_IP_Address_For_Members
    [Arguments]    ${member_index_list}
    [Documentation]    Return a list of IP address of given indexes.
    ${member_ip_list} =    BuiltIn.Create_List
    : FOR    ${index}    IN    @{member_index_list}
    \    ${ip_address} =    Collections.Get From Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${index}
    \    Collections.Append_To_List    ${member_ip_list}    ${ip_address}
    [Return]    ${member_ip_list}

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

List_All_Indices
    [Documentation]    Create a new list of all indices.
    BuiltIn.Run_Keyword_And_Return    List_Indices_Or_All

List_Indices_Or_All
    [Arguments]    ${given_list}=${EMPTY}
    [Documentation]    Utility to allow \${EMPTY} as default argument value, as the internal list is computed at runtime.
    ...    This keyword always returns a (shallow) copy of given or default list,
    ...    so operations with the returned list should not affect other lists.
    ...    Also note that this keyword does not consider empty list to be \${EMPTY}.
    ${return_list_reference} =    BuiltIn.Set_Variable_If    """${given_list}""" != ""    ${given_list}    ${ClusterManagement__member_index_list}
    ${return_list_copy} =    BuiltIn.Create_List    @{return_list_reference}
    [Return]    ${return_list_copy}

List_Indices_Minus_Member
    [Arguments]    ${member_index}    ${member_index_list}=${EMPTY}
    [Documentation]    Create a new list which contains indices from ${member_index_list} (or all) without ${member_index}.
    ${index_list} =    List_Indices_Or_All    ${member_index_list}
    Collections.Remove Values From List    ${index_list}    ${member_index}
    [Return]    ${index_list}

ClusterManagement__Compute_Derived_Variables
    [Arguments]    ${int_of_members}    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}    ${http_retries}=0
    [Documentation]    Construct index list, session list and IP mapping, publish them as suite variables.
    @{member_index_list} =    BuiltIn.Create_List
    @{session_list} =    BuiltIn.Create_List
    &{index_to_ip_mapping} =    BuiltIn.Create_Dictionary
    : FOR    ${index}    IN RANGE    1    ${int_of_members+1}
    \    ClusterManagement__Include_Member_Index    ${index}    ${member_index_list}    ${session_list}    ${index_to_ip_mapping}    http_timeout=${http_timeout}
    \    ...    http_retries=${http_retries}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__member_index_list}    ${member_index_list}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__index_to_ip_mapping}    ${index_to_ip_mapping}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__session_list}    ${session_list}

ClusterManagement__Include_Member_Index
    [Arguments]    ${index}    ${member_index_list}    ${session_list}    ${index_to_ip_mapping}    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}    ${http_retries}=0
    [Documentation]    Add a corresponding item based on index into the last three arguments.
    ...    Create the Http session whose alias is added to list.
    Collections.Append_To_List    ${member_index_list}    ${index}
    ${member_ip} =    BuiltIn.Set_Variable    ${ODL_SYSTEM_${index}_IP}
    # ${index} is int (not string) so "key=value" syntax does not work in the following line.
    Collections.Set_To_Dictionary    ${index_to_ip_mapping}    ${index}    ${member_ip}
    # Http session, with ${AUTH}, without headers.
    ${session_alias} =    Resolve_Http_Session_For_Member    member_index=${index}
    RequestsLibrary.Create_Session    ${session_alias}    http://${member_ip}:${RESTCONFPORT}    auth=${AUTH}    timeout=${http_timeout}    max_retries=${http_retries}
    Collections.Append_To_List    ${session_list}    ${session_alias}

Sync_Status_Should_Be_False
    [Arguments]    ${controller_index}
    [Documentation]    Verify that cluster node is not in sync with others
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    BuiltIn.Should_Not_Be_True    ${status}

Sync_Status_Should_Be_True
    [Arguments]    ${controller_index}
    [Documentation]    Verify that cluster node is in sync with others
    ${status}    Get_Sync_Status_Of_Member    ${controller_index}
    BuiltIn.Should_Be_True    ${status}

Return_Member_IP
    [Arguments]    ${member_index}
    [Documentation]    Return the IP address of the member given the member_index.
    ${member_int} =    BuiltIn.Convert_To_Integer    ${member_index}
    ${member_ip} =    Collections.Get_From_Dictionary    dictionary=${ClusterManagement__index_to_ip_mapping}    key=${member_int}
    [Return]    ${member_ip}

Check Diagstatus On Cluster
    [Arguments]    @{controller_indexes}
    : FOR    ${controller_index}    IN    @{controller_indexes}
    \    ${controller_ip} =    ClusterManagement.Return Member Ip    ${controller_index}
    \    Utils.Check Diagstatus    ${controller_ip}
