*** Settings ***
Documentation       Resource housing Keywords common to several suites for cluster functional testing.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...                 Copyright (c) 2016 Brocade Communications Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This resource holds private state (in suite variables),
...                 which is generated once at Setup with ClusterManagement_Setup KW.
...                 The state includes member indexes, IP addresses and Http (RequestsLibrary) sessions.
...                 Cluster Keywords normally use member index, member list or nothing (all members) as argument.
...
...                 All index lists returned should be sorted numerically, fix if not.
...
...                 Requirements:
...                 odl-jolokia is assumed to be installed.
...
...                 Keywords are ordered as follows:
...                 - Cluster Setup
...                 - Shard state, leader and followers
...                 - Entity Owner, candidates and successors
...                 - Kill, Stop and Start Member
...                 - Isolate and Rejoin Member
...                 - Run Commands On Member
...                 - REST requests and checks on Members
...
...                 TODO: Unify capitalization of Leaders and Followers.

Library             RequestsLibrary    # for Create_Session
Library             Collections
Library             String
Library             ClusterEntities.py
Resource            ${CURDIR}/CompareStream.robot
Resource            ${CURDIR}/KarafKeywords.robot
Resource            ${CURDIR}/SSHKeywords.robot
Resource            ${CURDIR}/TemplatedRequests.robot    # for Get_As_Json_From_Uri
Resource            ${CURDIR}/Utils.robot    # for Run_Command_On_Controller
Resource            ../variables/Variables.robot


*** Variables ***
${RESTCONF_URI}                                 rests
${GC_LOG_PATH}                                  ${KARAF_HOME}/data/log
${JAVA_HOME}                                    ${EMPTY}    # releng/builder scripts should provide correct value
${JOLOKIA_CONF_SHARD_MANAGER_URI}
...                                             jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
${JOLOKIA_OPER_SHARD_MANAGER_URI}
...                                             jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-operational,type=DistributedOperationalDatastore
${JOLOKIA_CONFIG_LOCAL_SHARDS_URI}
...                                             jolokia/read/org.opendaylight.controller:type=DistributedConfigDatastore,Category=ShardManager,name=shard-manager-config/LocalShards
${JOLOKIA_OPER_LOCAL_SHARDS_URI}
...                                             jolokia/read/org.opendaylight.controller:type=DistributedOperationalDatastore,Category=ShardManager,name=shard-manager-operational/LocalShards
${JOLOKIA_READ_URI}                             jolokia/read/org.opendaylight.controller
# Bug 9044 workaround: delete etc/host.key before restart.
@{ODL_DEFAULT_DATA_PATHS}
...                                             tmp/
...                                             data/
...                                             cache/
...                                             snapshots/
...                                             journal/
...                                             segmented-journal/
...                                             etc/opendaylight/current/
...                                             etc/host.key
${RESTCONF_MODULES_DIR}                         ${CURDIR}/../variables/restconf/modules
${SINGLETON_NETCONF_DEVICE_ID_PREFIX}
...                                             KeyedInstanceIdentifier{targetType=interface org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node, path=[org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology, org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology[key=TopologyKey{_topologyId=Uri{_value=topology-netconf}}], org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node[key=NodeKey{_nodeId=Uri{_value=
${SINGLETON_NETCONF_DEVICE_ID_SUFFIX}           }}]]}
${SINGLETON_BGPCEP_DEVICE_ID_SUFFIX}            -service-group
&{SINGLETON_DEVICE_ID_PREFIX}
...                                             bgpcep=${EMPTY}
...                                             netconf=${SINGLETON_NETCONF_DEVICE_ID_PREFIX}
...                                             openflow=${EMPTY}
&{SINGLETON_DEVICE_ID_SUFFIX}
...                                             bgpcep=${SINGLETON_BGPCEP_DEVICE_ID_SUFFIX}
...                                             netconf=${SINGLETON_NETCONF_DEVICE_ID_SUFFIX}
...                                             openflow=${EMPTY}
${SINGLETON_ELECTION_ENTITY_TYPE}               org.opendaylight.mdsal.ServiceEntityType
${SINGLETON_CHANGE_OWNERSHIP_ENTITY_TYPE}       org.opendaylight.mdsal.AsyncServiceCloseEntityType
${NODE_ROLE_INDEX_START}                        1
${NODE_START_COMMAND}                           ${KARAF_HOME}/bin/start
${NODE_STOP_COMMAND}                            ${KARAF_HOME}/bin/stop
${NODE_KARAF_COUNT_COMMAND}                     ps axf | grep org.apache.karaf | grep -v grep | wc -l
${NODE_KILL_COMMAND}
...                                             ps axf | grep org.apache.karaf | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${NODE_FREEZE_COMMAND}
...                                             ps axf | grep org.apache.karaf | grep -v grep | awk '{print \"kill -STOP \" $1}' | sh
${NODE_UNFREEZE_COMMAND}
...                                             ps axf | grep org.apache.karaf | grep -v grep | awk '{print \"kill -CONT \" $1}' | sh


*** Keywords ***
ClusterManagement_Setup
    [Documentation]    Detect repeated call, or detect number of members and initialize derived suite variables.
    ...    Http sessions are created with parameters to not waste time when ODL is no accepting connections properly.
    [Arguments]    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}    ${http_retries}=0
    # Avoid multiple initialization by several downstream libraries.
    ${already_done} =    BuiltIn.Get_Variable_Value    \${ClusterManagement__has_setup_run}    False
    IF    ${already_done}    RETURN
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__has_setup_run}    True
    ${cluster_size} =    BuiltIn.Get_Variable_Value    \${NUM_ODL_SYSTEM}    1
    ${status}    ${possibly_int_of_members} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    BuiltIn.Convert_To_Integer
    ...    ${cluster_size}
    ${int_of_members} =    BuiltIn.Set_Variable_If    '${status}' != 'PASS'    ${1}    ${possibly_int_of_members}
    ClusterManagement__Compute_Derived_Variables
    ...    int_of_members=${int_of_members}
    ...    http_timeout=${http_timeout}
    ...    http_retries=${http_retries}

Check_Cluster_Is_In_Sync
    [Documentation]    Fail if no-sync is detected on a member from list (or any).
    [Arguments]    ${member_index_list}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        ${status} =    Get_Sync_Status_Of_Member    member_index=${index}
        IF    'True' == '${status}'            CONTINUE
        BuiltIn.Fail    Index ${index} has incorrect status: ${status}
    END

Get_Sync_Status_Of_Member
    [Documentation]    Obtain IP, two GETs from jolokia URIs, return combined sync status as string.
    [Arguments]    ${member_index}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${conf_text} =    TemplatedRequests.Get_As_Json_From_Uri
    ...    uri=${JOLOKIA_CONF_SHARD_MANAGER_URI}
    ...    session=${session}
    ${conf_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${conf_text}
    IF    'False' == ${conf_status}    RETURN    False
    ${oper_text} =    TemplatedRequests.Get_As_Json_From_Uri
    ...    uri=${JOLOKIA_OPER_SHARD_MANAGER_URI}
    ...    session=${session}
    ${oper_status} =    ClusterManagement__Parse_Sync_Status    shard_manager_text=${oper_text}
    RETURN    ${oper_status}

Verify_Leader_Exists_For_Each_Shard
    [Documentation]    For each shard name, call Get_Leader_And_Followers_For_Shard.
    ...    Not much logic there, but single Keyword is useful when using BuiltIn.Wait_Until_Keyword_Succeeds.
    [Arguments]    ${shard_name_list}    ${shard_type}=operational    ${member_index_list}=${EMPTY}    ${verify_restconf}=True
    FOR    ${shard_name}    IN    @{shard_name_list}
        Get_Leader_And_Followers_For_Shard
        ...    shard_name=${shard_name}
        ...    shard_type=${shard_type}
        ...    validate=True
        ...    member_index_list=${member_index_list}
        ...    verify_restconf=${verify_restconf}
    END

Get_Leader_And_Followers_For_Shard
    [Documentation]    Get role lists, validate there is one leader, return the leader and list of followers.
    ...    Optionally, issue GET to a simple restconf URL to make sure subsequent operations will not encounter 503.
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=True    ${member_index_list}=${EMPTY}    ${verify_restconf}=True    ${http_timeout}=${EMPTY}
    ${leader_list}    ${follower_list} =    Get_State_Info_For_Shard
    ...    shard_name=${shard_name}
    ...    shard_type=${shard_type}
    ...    validate=True
    ...    member_index_list=${member_index_list}
    ...    verify_restconf=${verify_restconf}
    ...    http_timeout=${http_timeout}
    ${leader_count} =    BuiltIn.Get_Length    ${leader_list}
    IF    ${leader_count} < 1    BuiltIn.Fail    No leader found.
    BuiltIn.Length_Should_Be    ${leader_list}    ${1}    Too many Leaders.
    ${leader} =    Collections.Get_From_List    ${leader_list}    0
    RETURN    ${leader}    ${follower_list}

Get_State_Info_For_Shard
    [Documentation]    Return lists of Leader and Follower member indices from a given member index list
    ...    (or from the full list if empty). If \${shard_type} is not 'config', 'operational' is assumed.
    ...    If \${validate}, Fail if raft state is not Leader or Follower (for example on Candidate).
    ...    The biggest difference from Get_Leader_And_Followers_For_Shard
    ...    is that no check on number of Leaders is performed.
    [Arguments]    ${shard_name}=default    ${shard_type}=operational    ${validate}=False    ${member_index_list}=${EMPTY}    ${verify_restconf}=False    ${http_timeout}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    Collections.Sort_List    ${index_list}    # to guarantee return values are also sorted lists
    # TODO: Support alternative capitalization of 'config'?
    ${ds_type} =    BuiltIn.Set_Variable_If    '${shard_type}' != 'config'    operational    config
    ${leader_list} =    BuiltIn.Create_List
    ${follower_list} =    BuiltIn.Create_List
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        ${raft_state} =    Get_Raft_State_Of_Shard_At_Member
        ...    shard_name=${shard_name}
        ...    shard_type=${ds_type}
        ...    member_index=${index}
        ...    verify_restconf=${verify_restconf}
        ...    http_timeout=${http_timeout}
        IF    'Follower' == '${raft_state}'
            Collections.Append_To_List    ${follower_list}    ${index}
        ELSE IF    'Leader' == '${raft_state}'
            Collections.Append_To_List    ${leader_list}    ${index}
        ELSE IF    ${validate}
            BuiltIn.Fail    Unrecognized Raft state: ${raft_state}
        END
    END
    RETURN    ${leader_list}    ${follower_list}

Get_Raft_State_Of_Shard_At_Member
    [Documentation]    Send request to Jolokia on indexed member, return extracted Raft status.
    ...    Optionally, check restconf works.
    [Arguments]    ${shard_name}    ${shard_type}    ${member_index}    ${verify_restconf}=False    ${http_timeout}=${EMPTY}
    ${raft_state} =    Get_Raft_Property_From_Shard_Member
    ...    RaftState
    ...    ${shard_name}
    ...    ${shard_type}
    ...    ${member_index}
    ...    verify_restconf=${verify_restconf}
    ...    http_timeout=${http_timeout}
    RETURN    ${raft_state}

Get_Raft_State_Of_Shard_Of_All_Member_Nodes
    [Documentation]    Get raft state of shard of all member nodes
    [Arguments]    ${shard_name}=default    ${shard_type}=config    ${member_index_list}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    Collections.Sort_List    ${index_list}
    FOR    ${index}    IN    @{index_list}
        ClusterManagement.Get Raft State Of Shard At Member
        ...    shard_name=${shard_name}
        ...    shard_type=${shard_type}
        ...    member_index=${index}
    END

Get_Raft_Property_From_Shard_Member
    [Documentation]    Send request to Jolokia on indexed member, return extracted Raft property.
    ...    Optionally, check restconf works.
    [Arguments]    ${property}    ${shard_name}    ${shard_type}    ${member_index}    ${verify_restconf}=False    ${http_timeout}=${EMPTY}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    # TODO: Does the used URI tend to generate large data which floods log.html?
    IF    ${verify_restconf}
        TemplatedRequests.Get_As_Json_Templated
        ...    session=${session}
        ...    folder=${RESTCONF_MODULES_DIR}
        ...    verify=False
        ...    http_timeout=${http_timeout}
    END
    ${type_class} =    Resolve_Shard_Type_Class    shard_type=${shard_type}
    ${cluster_index} =    Evaluate    ${member_index}+${NODE_ROLE_INDEX_START}-1
    ${uri} =    BuiltIn.Set_Variable
    ...    ${JOLOKIA_READ_URI}:Category=Shards,name=member-${cluster_index}-shard-${shard_name}-${shard_type},type=${type_class}
    ${data_text} =    TemplatedRequests.Get_As_Json_From_Uri
    ...    uri=${uri}
    ...    session=${session}
    ...    http_timeout=${http_timeout}
    ${data_object} =    Utils.Json Parse From String    ${data_text}
    ${value} =    Collections.Get_From_Dictionary    ${data_object}    value
    ${raft_property} =    Collections.Get_From_Dictionary    ${value}    ${property}
    RETURN    ${raft_property}

Verify_Shard_Leader_Elected
    [Documentation]    Verify new leader was elected or remained the same. Bool paramter ${new_elected} indicates if
    ...    new leader is elected or should remained the same as ${old_leader}
    [Arguments]    ${shard_name}    ${shard_type}    ${new_elected}    ${old_leader}    ${member_index_list}=${EMPTY}    ${verify_restconf}=True
    ${leader}    ${followers} =    Get_Leader_And_Followers_For_Shard
    ...    shard_name=${shard_name}
    ...    shard_type=${shard_type}
    ...    member_index_list=${member_index_list}
    ...    verify_restconf=${verify_restconf}
    IF    ${new_elected}
        BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_leader}    ${leader}
    END
    IF    not ${new_elected}
        BuiltIn.Should_Be_Equal_As_numbers    ${old_leader}    ${leader}
    END
    RETURN    ${leader}    ${followers}

Verify_Owner_And_Successors_For_Device
    [Documentation]    Returns the owner and successors for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    For Boron and beyond, candidates are not removed on node down or isolation,
    ...    so this keyword expects candidates to be all members from Boron on.
    ...    Extra check is done to verify owner and successors are within the ${candidate_list}. This KW is useful when combined with WUKS.
    ...    ${candidate_list} minus owner is returned as ${successor list}.
    ...    Users can still use Get_Owner_And_Successors_For_Device if they are interested in downed candidates,
    ...    or for testing heterogeneous clusters.
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${candidate_list}=${EMPTY}    ${after_stop}=False
    ${index_list} =    List_Indices_Or_All    given_list=${candidate_list}
    ${owner}    ${successor_list} =    Get_Owner_And_Successors_For_Device
    ...    device_name=${device_name}
    ...    device_type=${device_type}
    ...    member_index=${member_index}
    Collections.List_Should_Contain_Value
    ...    ${index_list}
    ...    ${owner}
    ...    Owner ${owner} is not in candidate list ${index_list}
    # In Beryllium or after stopping an instance, the removed instance does not show in the candidate list.
    ${expected_candidate_list_origin} =    BuiltIn.Set_Variable_If
    ...    ${after_stop}
    ...    ${index_list}
    ...    ${ClusterManagement__member_index_list}
    # We do not want to manipulate either origin list.
    ${expected_successor_list} =    BuiltIn.Create_List    @{expected_candidate_list_origin}
    Collections.Remove_Values_From_List    ${expected_successor_list}    ${owner}
    Collections.Lists_Should_Be_Equal
    ...    ${expected_successor_list}
    ...    ${successor_list}
    ...    Successor list ${successor_list} is not the came as expected ${expected_successor_list}
    # User expects the returned successor list to be the provided candidate list minus the owner.
    Collections.Remove_Values_From_List    ${index_list}    ${owner}
    RETURN    ${owner}    ${index_list}

Get_Owner_And_Successors_For_Device
    [Documentation]    Returns the owner and a list of successors for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Successors are those device candidates not elected as owner. The list of successors = (list of candidates) - (owner).
    ...    The returned successor list is sorted numerically.
    ...    Note that "candidate list" definition currently differs between Beryllium and Boron.
    ...    Use Verify_Owner_And_Successors_For_Device if you want the older semantics (inaccessible nodes not present in the list).
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    # TODO: somewhere to introduce ${DEFAULT_RESTCONF_DATASTORE_TIMEOUT}. Value may depend on protocol (ask vs tell) and perhaps stream.
    ${owner}    ${candidate_list} =    Get_Owner_And_Candidates_For_Device
    ...    device_name=${device_name}
    ...    device_type=${device_type}
    ...    member_index=${member_index}
    ...    http_timeout=${http_timeout}
    # Copy operation is not required, but new variable name requires a line anyway.
    ${successor_list} =    BuiltIn.Create_List
    ...    @{candidate_list}
    Collections.Remove_Values_From_List    ${successor_list}    ${owner}
    RETURN    ${owner}    ${successor_list}

Get_Owner_And_Candidates_For_Device_Rpc
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ...    The returned candidate list is sorted numerically.
    ...    Note that "candidate list" definition currently differs between Beryllium and Boron.
    ...    It is recommended to use Get_Owner_And_Successors_For_Device instead of this keyword, see documentation there.
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    BuiltIn.Comment    TODO: Can this implementation be changed to call Get_Owner_And_Candidates_For_Type_And_Id?
    ${index} =    BuiltIn.Convert_To_Integer    ${member_index}
    ${ip} =    Resolve_IP_Address_For_Member    member_index=${index}
    ${entity_type} =    BuiltIn.Set_Variable_If
    ...    '${device_type}' == 'netconf'
    ...    netconf-node/${device_name}
    ...    ${device_type}
    ${url} =    BuiltIn.Catenate    SEPARATOR=    http://    ${ip}    :8181/    ${RESTCONF_URI}
    ${entity_result} =    ClusterEntities.Get_Entity    ${url}    ${entity_type}    ${device_name}
    ${entity_candidates} =    Collections.Get_From_Dictionary    ${entity_result}    candidates
    ${entity_owner} =    Collections.Get_From_Dictionary    ${entity_result}    owner
    BuiltIn.Should_Not_Be_Empty    ${entity_owner}    No owner found for ${device_name}
    ${owner} =    String.Replace_String    ${entity_owner}    member-    ${EMPTY}
    ${owner} =    BuiltIn.Convert_To_Integer    ${owner}
    ${candidate_list} =    BuiltIn.Create_List
    FOR    ${entity_candidate}    IN    @{entity_candidates}
        ${candidate} =    String.Replace_String    ${entity_candidate}    member-    ${EMPTY}
        ${candidate} =    BuiltIn.Convert_To_Integer    ${candidate}
        Collections.Append_To_List    ${candidate_list}    ${candidate}
    END
    Collections.Sort_List    ${candidate_list}
    RETURN    ${owner}    ${candidate_list}

Get_Owner_And_Candidates_For_Device_Singleton
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    # Normalize device type to the lowercase as in ${SINGLETON_DEVICE_ID_PREFIX} & ${SINGLETON_DEVICE_ID_SUFFIX}
    ${device_type} =    String.Convert To Lower Case    ${device_type}
    # Set device ID prefix
    Collections.Dictionary Should Contain Key    ${SINGLETON_DEVICE_ID_PREFIX}    ${device_type}
    ${device_id_prefix} =    Collections.Get From Dictionary    ${SINGLETON_DEVICE_ID_PREFIX}    ${device_type}
    Log    ${device_id_prefix}
    # Set device ID suffix
    Collections.Dictionary Should Contain Key    ${SINGLETON_DEVICE_ID_SUFFIX}    ${device_type}
    ${device_id_suffix} =    Collections.Get From Dictionary    ${SINGLETON_DEVICE_ID_SUFFIX}    ${device_type}
    Log    ${device_id_suffix}
    # Set device ID
    ${id} =    BuiltIn.Set_Variable    ${device_id_prefix}${device_name}${device_id_suffix}
    Log    ${id}
    # Get election entity type results
    ${type} =    BuiltIn.Set_Variable    ${SINGLETON_ELECTION_ENTITY_TYPE}
    ${owner_1}    ${candidate_list_1} =    Get_Owner_And_Candidates_For_Type_And_Id
    ...    ${type}
    ...    ${id}
    ...    ${member_index}
    ...    http_timeout=${http_timeout}
    # Get change ownership entity type results
    ${type} =    BuiltIn.Set_Variable    ${SINGLETON_CHANGE_OWNERSHIP_ENTITY_TYPE}
    ${owner_2}    ${candidate_list_2} =    Get_Owner_And_Candidates_For_Type_And_Id
    ...    ${type}
    ...    ${id}
    ...    ${member_index}
    ...    http_timeout=${http_timeout}
    # Owners must be same, if not, there is still some election or change ownership in progress
    BuiltIn.Should_Be_Equal_As_Integers    ${owner_1}    ${owner_2}    Owners for device ${device_name} are not same
    RETURN    ${owner_1}    ${candidate_list_1}

Get_Owner_And_Candidates_For_Device
    [Documentation]    Returns the owner and a list of candidates for the SB device ${device_name} of type ${device_type}. Request is sent to member ${member_index}.
    ...    If parsing as singleton failed, kw try to parse data in old way (without singleton).
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ...    The returned candidate list is sorted numerically.
    ...    Note that "candidate list" definition currently differs between Beryllium and Boron.
    ...    It is recommended to use Get_Owner_And_Successors_For_Device instead of this keyword, see documentation there.
    [Arguments]    ${device_name}    ${device_type}    ${member_index}    ${http_timeout}=${EMPTY}
    # Try singleton
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    Get_Owner_And_Candidates_For_Device_Singleton
    ...    device_name=${device_name}
    ...    device_type=${device_type}
    ...    member_index=${member_index}
    ...    http_timeout=${http_timeout}
    IF    "${status}"=="PASS"    RETURN    ${results}
    # If singleton failed, try parsing in old way
    ${status}    ${results} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    Get_Owner_And_Candidates_For_Device_Rpc
    ...    device_name=${device_name}
    ...    device_type=${device_type}
    ...    member_index=${member_index}
    ...    http_timeout=${http_timeout}
    # previous 3 lines (BuilIn.Return.., # If singleton..., ${status}....) could be deleted when old way will not be supported anymore
    IF    '${status}'=='FAIL'
        BuiltIn.Fail    Could not parse owner and candidates for device ${device_name}
    END
    RETURN    @{results}

Check_Old_Owner_Stays_Elected_For_Device
    [Documentation]    Verify the owner remain the same as ${old_owner}
    [Arguments]    ${device_name}    ${device_type}    ${old_owner}    ${node_to_ask}    ${http_timeout}=${EMPTY}
    ${owner}    ${candidates} =    Get_Owner_And_Candidates_For_Device
    ...    ${device_name}
    ...    ${device_type}
    ...    ${node_to_ask}
    ...    http_timeout=${http_timeout}
    BuiltIn.Should_Be_Equal_As_numbers    ${old_owner}    ${owner}
    RETURN    ${owner}    ${candidates}

Check_New_Owner_Got_Elected_For_Device
    [Documentation]    Verify new owner was elected comparing to ${old_owner}
    [Arguments]    ${device_name}    ${device_type}    ${old_owner}    ${node_to_ask}    ${http_timeout}=${EMPTY}
    ${owner}    ${candidates} =    Get_Owner_And_Candidates_For_Device
    ...    ${device_name}
    ...    ${device_type}
    ...    ${node_to_ask}
    ...    http_timeout=${http_timeout}
    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_owner}    ${owner}
    RETURN    ${owner}    ${candidates}

Get_Owner_And_Candidates_For_Type_And_Id
    [Documentation]    Returns the owner and a list of candidates for entity specified by ${type} and ${id}
    ...    Request is sent to member ${member_index}.
    ...    Candidates are all members that register to own a device, so the list of candiates includes the owner.
    ...    Bear in mind that for Boron and beyond, candidates are not removed on node down or isolation.
    ...    If ${require_candidate_list} is not \${EMPTY}, check whether the actual list of candidates matches.
    ...    Note that differs from "given list" semantics used in other keywords,
    ...    namely you cannot use \${EMPTY} to stand for "full list" in this keyword.
    [Arguments]    ${type}    ${id}    ${member_index}    ${require_candidate_list}=${EMPTY}    ${http_timeout}=${EMPTY}
    BuiltIn.Comment    TODO: Find a way to unify and deduplicate code blocks in Get_Owner_And_Candidates_* keywords.
    ${owner}    ${candidates} =    Get_Owner_And_Candidates_For_Device_Rpc
    ...    ${id}
    ...    ${type}
    ...    ${member_index}
    ...    http_timeout=${http_timeout}
    RETURN    ${owner}    ${candidates}

Extract_Service_Entity_Type
    [Documentation]    Remove superfluous device data from Entity Owner printout.
    [Arguments]    ${data}
    ${clear_data} =    String.Replace_String
    ...    ${data}
    ...    /odl-general-entity:entity[odl-general-entity:name='
    ...    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    -service-group']    ${EMPTY}
    Log    ${clear_data}
    RETURN    ${clear_data}

Extract_OpenFlow_Device_Data
    [Documentation]    Remove superfluous OpenFlow device data from Entity Owner printout.
    [Arguments]    ${data}
    ${clear_data} =    String.Replace_String    ${data}    org.opendaylight.mdsal.ServiceEntityType    openflow
    ${clear_data} =    String.Replace_String
    ...    ${clear_data}
    ...    /odl-general-entity:entity[odl-general-entity:name='
    ...    ${EMPTY}
    ${clear_data} =    String.Replace_String
    ...    ${clear_data}
    ...    /general-entity:entity[general-entity:name='
    ...    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    ']    ${EMPTY}
    Log    ${clear_data}
    RETURN    ${clear_data}

Extract_Ovsdb_Device_Data
    [Documentation]    Remove superfluous OVSDB device data from Entity Owner printout.
    [Arguments]    ${data}
    ${clear_data} =    String.Replace_String
    ...    ${data}
    ...    /network-topology:network-topology/network-topology:topology[network-topology:topology-id='ovsdb:1']/network-topology:node[network-topology:node-id='
    ...    ${EMPTY}
    ${clear_data} =    String.Replace_String    ${clear_data}    ']    ${EMPTY}
    Log    ${clear_data}
    RETURN    ${clear_data}

Kill_Single_Member
    [Documentation]    Convenience keyword that kills the specified member of the cluster.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member}
    [Arguments]    ${member}    ${original_index_list}=${EMPTY}    ${confirm}=True
    ${index_list} =    ClusterManagement__Build_List    ${member}
    ${member_ip} =    Return_Member_IP    ${member}
    KarafKeywords.Log_Message_To_Controller_Karaf    Killing ODL${member} ${member_ip}
    ${updated_index_list} =    Kill_Members_From_List_Or_All    ${index_list}    ${original_index_list}    ${confirm}
    RETURN    ${updated_index_list}

Kill_Members_From_List_Or_All
    [Documentation]    If the list is empty, kill all ODL instances. Otherwise, kill members based on \${kill_index_list}
    ...    If \${confirm} is True, sleep 1 second and verify killed instances are not there anymore.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member_index_list}
    [Arguments]    ${member_index_list}=${EMPTY}    ${original_index_list}=${EMPTY}    ${confirm}=True
    ${kill_index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${index_list} =    List_Indices_Or_All    given_list=${original_index_list}
    Run_Bash_Command_On_List_Or_All    command=${NODE_KILL_COMMAND}    member_index_list=${member_index_list}
    ${updated_index_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${updated_index_list}    @{kill_index_list}
    IF    not ${confirm}    RETURN    ${updated_index_list}
    # TODO: Convert to WUKS with configurable timeout if it turns out 1 second is not enough.
    BuiltIn.Sleep
    ...    1s
    ...    Kill -9 closes open files, which may take longer than ssh overhead, but not long enough to warrant WUKS.
    FOR    ${index}    IN    @{kill_index_list}
        Verify_Karaf_Is_Not_Running_On_Member    member_index=${index}
    END
    Run_Bash_Command_On_List_Or_All    command=netstat -pnatu | grep 2550
    RETURN    ${updated_index_list}

Stop_Single_Member
    [Documentation]    Convenience keyword that stops the specified member of the cluster.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member}
    [Arguments]    ${member}    ${original_index_list}=${EMPTY}    ${confirm}=True    ${msg}=${EMPTY}
    ${index_list} =    ClusterManagement__Build_List    ${member}
    ${member_ip} =    Return_Member_IP    ${member}
    ${msg} =    Builtin.Set Variable If
    ...    "${msg}" == "${EMPTY}"
    ...    Stopping ODL${member} ${member_ip}
    ...    Stopping ODL${member} ${member_ip}, ${msg}
    KarafKeywords.Log_Message_To_Controller_Karaf    ${msg}
    ${updated_index_list} =    Stop_Members_From_List_Or_All    ${index_list}    ${original_index_list}    ${confirm}
    RETURN    ${updated_index_list}

Stop_Members_From_List_Or_All
    [Documentation]    If the list is empty, stops all ODL instances. Otherwise stop members based on \${stop_index_list}
    ...    If \${confirm} is True, verify stopped instances are not there anymore.
    ...    The KW will return a list of available members: \${updated index_list}=\${original_index_list}-\${member_index_list}
    [Arguments]    ${member_index_list}=${EMPTY}    ${original_index_list}=${EMPTY}    ${confirm}=True    ${timeout}=360s
    Sleep    60s
    ${stop_index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${index_list} =    List_Indices_Or_All    given_list=${original_index_list}
    Run_Bash_Command_On_List_Or_All    command=${NODE_STOP_COMMAND}    member_index_list=${member_index_list}
    ${updated_index_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${updated_index_list}    @{stop_index_list}
    IF    not ${confirm}    RETURN    ${updated_index_list}
    FOR    ${index}    IN    @{stop_index_list}
        BuiltIn.Wait Until Keyword Succeeds
        ...    ${timeout}
        ...    2s
        ...    Verify_Karaf_Is_Not_Running_On_Member
        ...    member_index=${index}
    END
    Run_Bash_Command_On_List_Or_All    command=netstat -pnatu | grep 2550
    RETURN    ${updated_index_list}

Start_Single_Member
    [Documentation]    Convenience keyword that starts the specified member of the cluster.
    [Arguments]    ${member}    ${wait_for_sync}=True    ${timeout}=300s    ${msg}=${EMPTY}    ${check_system_status}=False    ${verify_restconf}=True
    ...    ${service_list}=${EMPTY_LIST}
    ${index_list} =    ClusterManagement__Build_List    ${member}
    ${member_ip} =    Return_Member_IP    ${member}
    ${msg} =    Builtin.Set Variable If
    ...    "${msg}" == "${EMPTY}"
    ...    Starting ODL${member} ${member_ip}
    ...    Starting ODL${member} ${member_ip}, ${msg}
    KarafKeywords.Log_Message_To_Controller_Karaf    ${msg}
    Start_Members_From_List_Or_All
    ...    ${index_list}
    ...    ${wait_for_sync}
    ...    ${timeout}
    ...    check_system_status=${check_system_status}
    ...    verify_restconf=${verify_restconf}
    ...    service_list=${service_list}

Start_Members_From_List_Or_All
    [Documentation]    If the list is empty, start all cluster members. Otherwise, start members based on present indices.
    ...    If ${wait_for_sync}, wait for cluster sync on listed members.
    ...    Optionally karaf_home can be overriden. Optionally specific JAVA_HOME is used for starting.
    ...    Garbage collection is unconditionally logged to files. TODO: Make that reasonable conditional?
    [Arguments]    ${member_index_list}=${EMPTY}    ${wait_for_sync}=True    ${timeout}=360s    ${karaf_home}=${EMPTY}    ${export_java_home}=${EMPTY}    ${gc_log_dir}=${EMPTY}
    ...    ${check_system_status}=False    ${verify_restconf}=True    ${service_list}=${EMPTY_LIST}
    ${base_command} =    BuiltIn.Set_Variable_If
    ...    """${karaf_home}""" != ""
    ...    ${karaf_home}/bin/start
    ...    ${NODE_START_COMMAND}
    ${command} =    BuiltIn.Set_Variable_If
    ...    """${export_java_home}""" != ""
    ...    export JAVA_HOME="${export_java_home}"; ${base_command}
    ...    ${base_command}
    ${epoch} =    DateTime.Get_Current_Date    time_zone=UTC    result_format=epoch    exclude_millis=False
    ${gc_filepath} =    BuiltIn.Set_Variable_If
    ...    """${karaf_home}""" != ""
    ...    ${karaf_home}/data/log/gc_${epoch}.log
    ...    ${GC_LOG_PATH}/gc_${epoch}.log
    ${gc_options} =    BuiltIn.Set_Variable_If
    ...    "docker" not in """${node_start_command}"""
    ...    -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${gc_filepath}
    ...    ${EMPTY}
    Run_Bash_Command_On_List_Or_All    command=${command} ${gc_options}    member_index_list=${member_index_list}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    ${timeout}
    ...    10s
    ...    Verify_Members_Are_Ready
    ...    ${member_index_list}
    ...    ${wait_for_sync}
    ...    ${verify_restconf}
    ...    ${check_system_status}
    ...    ${service_list}
    [Teardown]    Run_Bash_Command_On_List_Or_All    command=netstat -pnatu | grep 2550

Verify_Members_Are_Ready
    [Documentation]    Verifies the specified readiness conditions for the given listed members after startup.
    ...    If ${verify_cluster_sync}, verifies the datastores have synced with the rest of the cluster.
    ...    If ${verify_restconf}, verifies RESTCONF is available.
    ...    If ${verify_system_status}, verifies the system services are OPERATIONAL.
    [Arguments]    ${member_index_list}    ${verify_cluster_sync}    ${verify_restconf}    ${verify_system_status}    ${service_list}
    IF    ${verify_cluster_sync}
        Check_Cluster_Is_In_Sync    ${member_index_list}
    END
    IF    ${verify_restconf}
        Verify_Restconf_Is_Available    ${member_index_list}
    END
    # for backward compatibility, some consumers might not be passing @{service_list}, but since we can't set a list to a default
    # value, we need to check here if it's empty in order to skip the check which would throw an error
    IF    ${verify_system_status} and ("${service_list}" != "[[]]")
        ClusterManagement.Check Status Of Services Is OPERATIONAL    @{service_list}
    END

Verify_Restconf_Is_Available
    [Arguments]    ${member_index_list}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        ${session} =    Resolve_Http_Session_For_Member    member_index=${index}
        TemplatedRequests.Get_As_Json_Templated    session=${session}    folder=${RESTCONF_MODULES_DIR}    verify=False
    END

Freeze_Single_Member
    [Documentation]    Convenience keyword that stops the specified member of the cluster by freezing the jvm.
    [Arguments]    ${member}
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Freeze_Or_Unfreeze_Members_From_List_Or_All    ${NODE_FREEZE_COMMAND}    ${index_list}

Unfreeze_Single_Member
    [Documentation]    Convenience keyword that "continues" the specified member of the cluster by unfreezing the jvm.
    [Arguments]    ${member}    ${wait_for_sync}=True    ${timeout}=60s
    ${index_list} =    ClusterManagement__Build_List    ${member}
    Freeze_Or_Unfreeze_Members_From_List_Or_All    ${NODE_UNFREEZE_COMMAND}    ${index_list}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    10s    Check_Cluster_Is_In_Sync

Freeze_Or_Unfreeze_Members_From_List_Or_All
    [Documentation]    If the list is empty, stops/runs all ODL instances. Otherwise stop/run members based on \${stop_index_list}
    ...    For command parameter only ${NODE_FREEZE_COMMAND} and ${NODE_UNFREEZE_COMMAND} should be used
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    ${freeze_index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    Run_Bash_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}

Clean_Journals_Data_And_Snapshots_On_List_Or_All
    [Documentation]    Delete journal and snapshots directories on every node listed (or all).
    ...    BEWARE: If only a subset of members is cleaned, this causes RetiredGenerationException in Carbon after the affected node re-start.
    ...    See https://bugs.opendaylight.org/show_bug.cgi?id=8138
    [Arguments]    ${member_index_list}=${EMPTY}    ${karaf_home}=${KARAF_HOME}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${command} =    Set Variable    rm -rf "${karaf_home}/"*journal "${karaf_home}/snapshots" "${karaf_home}/data"
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        Run_Bash_Command_On_Member    command=${command}    member_index=${index}
    END

Verify_Karaf_Is_Not_Running_On_Member
    [Documentation]    Fail if non-zero karaf instances are counted on member of given index.
    [Arguments]    ${member_index}
    ${count} =    Count_Running_Karafs_On_Member    member_index=${member_index}
    BuiltIn.Should_Be_Equal    0    ${count}    Found running Karaf count: ${count}

Verify_Single_Karaf_Is_Running_On_Member
    [Documentation]    Fail if number of karaf instances on member of given index is not one.
    [Arguments]    ${member_index}
    ${count} =    Count_Running_Karafs_On_Member    member_index=${member_index}
    BuiltIn.Should_Be_Equal    1    ${count}    Wrong number of Karafs running: ${count}

Count_Running_Karafs_On_Member
    [Documentation]    Remotely execute grep for karaf process, return count as string.
    [Arguments]    ${member_index}
    ${command} =    BuiltIn.Set_Variable    ${NODE_KARAF_COUNT_COMMAND}
    ${count} =    Run_Bash_Command_On_Member    command=${command}    member_index=${member_index}
    RETURN    ${count}

Isolate_Member_From_List_Or_All
    [Documentation]    If the list is empty, isolate member from all ODL instances. Otherwise, isolate member based on present indices.
    ...    The KW will return a list of available members: \${updated index_list}=\${member_index_list}-\${isolate_member_index}
    [Arguments]    ${isolate_member_index}    ${member_index_list}=${EMPTY}    ${protocol}=all    ${port}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${source} =    Collections.Get_From_Dictionary
    ...    ${ClusterManagement__index_to_ip_mapping}
    ...    ${isolate_member_index}
    ${dport} =    BuiltIn.Set_Variable_If    '${port}' != '${EMPTY}'    --dport ${port}    ${EMPTY}
    FOR    ${index}    IN    @{index_list}
        ${destination} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
        ${command} =    BuiltIn.Set_Variable
        ...    sudo /sbin/iptables -I OUTPUT -p ${protocol} ${dport} --source ${source} --destination ${destination} -j DROP
        IF    "${index}" != "${isolate_member_index}"
            Run_Bash_Command_On_Member    command=${command}    member_index=${isolate_member_index}
        END
    END
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Run_Bash_Command_On_Member    command=${command}    member_index=${isolate_member_index}
    BuiltIn.Log    ${output}
    ${updated_index_list} =    BuiltIn.Create_List    @{index_list}
    Collections.Remove_Values_From_List    ${updated_index_list}    ${isolate_member_index}
    RETURN    ${updated_index_list}

Rejoin_Member_From_List_Or_All
    [Documentation]    If the list is empty, rejoin member from all ODL instances. Otherwise, rejoin member based on present indices.
    [Arguments]    ${rejoin_member_index}    ${member_index_list}=${EMPTY}    ${protocol}=all    ${port}=${EMPTY}    ${timeout}=60s
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${source} =    Collections.Get_From_Dictionary
    ...    ${ClusterManagement__index_to_ip_mapping}
    ...    ${rejoin_member_index}
    ${dport} =    BuiltIn.Set_Variable_If    '${port}' != '${EMPTY}'    --dport ${port}    ${EMPTY}
    FOR    ${index}    IN    @{index_list}
        ${destination} =    Collections.Get_From_Dictionary    ${ClusterManagement__index_to_ip_mapping}    ${index}
        ${command} =    BuiltIn.Set_Variable
        ...    sudo /sbin/iptables -D OUTPUT -p ${protocol} ${dport} --source ${source} --destination ${destination} -j DROP
        IF    "${index}" != "${rejoin_member_index}"
            Run_Bash_Command_On_Member    command=${command}    member_index=${rejoin_member_index}
        END
    END
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Run_Bash_Command_On_Member    command=${command}    member_index=${rejoin_member_index}
    BuiltIn.Log    ${output}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    10s    Check_Cluster_Is_In_Sync

Flush_Iptables_From_List_Or_All
    [Documentation]    If the list is empty, flush IPTables in all ODL instances. Otherwise, flush member based on present indices.
    [Arguments]    ${member_index_list}=${EMPTY}
    ${command} =    BuiltIn.Set_Variable    sudo iptables -v -F
    ${output} =    Run_Bash_Command_On_List_Or_All    command=${command}    member_index_list=${member_index_list}

Check_Bash_Command_On_List_Or_All
    [Documentation]    Cycle through indices (or all), run bash command on each, using temporary SSH session and restoring the previously active one.
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}    ${return_success_only}=False    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        Check_Bash_Command_On_Member
        ...    command=${command}
        ...    member_index=${index}
        ...    return_success_only=${return_success_only}
        ...    log_on_success=${log_on_success}
        ...    log_on_failure=${log_on_failure}
        ...    stderr_must_be_empty=${stderr_must_be_empty}
    END

Check_Bash_Command_On_Member
    [Documentation]    Open SSH session, call SSHKeywords.Execute_Command_Passes, close session, restore previously active session and return output.
    [Arguments]    ${command}    ${member_index}    ${return_success_only}=False    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    BuiltIn.Run_Keyword_And_Return
    ...    SSHKeywords.Run_Keyword_Preserve_Connection
    ...    Check_Unsafely_Bash_Command_On_Member
    ...    ${command}
    ...    ${member_index}
    ...    return_success_only=${return_success_only}
    ...    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}
    ...    stderr_must_be_empty=${stderr_must_be_empty}

Check_Unsafely_Bash_Command_On_Member
    [Documentation]    Obtain Ip address, open session, call SSHKeywords.Execute_Command_Passes, close session and return output. This affects which SSH session is active.
    [Arguments]    ${command}    ${member_index}    ${return_success_only}=False    ${log_on_success}=True    ${log_on_failure}=True    ${stderr_must_be_empty}=True
    ${member_ip} =    Resolve_Ip_Address_For_Member    ${member_index}
    BuiltIn.Run_Keyword_And_Return
    ...    SSHKeywords.Run_Unsafely_Keyword_Over_Temporary_Odl_Session
    ...    ${member_ip}
    ...    Execute_Command_Passes
    ...    ${command}
    ...    return_success_only=${return_success_only}
    ...    log_on_success=${log_on_success}
    ...    log_on_failure=${log_on_failure}
    ...    stderr_must_be_empty=${stderr_must_be_empty}

Run_Bash_Command_On_List_Or_All
    [Documentation]    Cycle through indices (or all), run command on each.
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}
    # TODO: Migrate callers to Check_Bash_Command_*
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        Run_Bash_Command_On_Member    command=${command}    member_index=${index}
    END

Run_Bash_Command_On_Member
    [Documentation]    Obtain IP, call Utils and return output. This keeps previous ssh session active.
    [Arguments]    ${command}    ${member_index}
    # TODO: Migrate callers to Check_Bash_Command_*
    ${member_ip} =    Collections.Get_From_Dictionary
    ...    dictionary=${ClusterManagement__index_to_ip_mapping}
    ...    key=${member_index}
    ${output} =    SSHKeywords.Run_Keyword_Preserve_Connection
    ...    Utils.Run_Command_On_Controller
    ...    ${member_ip}
    ...    ${command}
    Log    ${output}
    RETURN    ${output}

Run_Karaf_Command_On_List_Or_All
    [Documentation]    Cycle through indices (or all), run karaf command on each.
    [Arguments]    ${command}    ${member_index_list}=${EMPTY}    ${timeout}=10s
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        ${member_ip} =    Collections.Get_From_Dictionary
        ...    dictionary=${ClusterManagement__index_to_ip_mapping}
        ...    key=${index}
        KarafKeywords.Safe_Issue_Command_On_Karaf_Console    ${command}    ${member_ip}    timeout=${timeout}
    END

Run_Karaf_Command_On_Member
    [Documentation]    Obtain IP address, call KarafKeywords and return output. This does not preserve active ssh session.
    ...    This keyword is not used by Run_Karaf_Command_On_List_Or_All, but returned output may be useful.
    [Arguments]    ${command}    ${member_index}    ${timeout}=10s
    ${member_ip} =    Collections.Get_From_Dictionary
    ...    dictionary=${ClusterManagement__index_to_ip_mapping}
    ...    key=${member_index}
    ${output} =    KarafKeywords.Safe_Issue_Command_On_Karaf_Console
    ...    ${command}
    ...    controller=${member_ip}
    ...    timeout=${timeout}
    RETURN    ${output}

Install_Feature_On_List_Or_All
    [Documentation]    Attempt installation on each member from list (or all). Then look for failures.
    [Arguments]    ${feature_name}    ${member_index_list}=${EMPTY}    ${timeout}=60s
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${status_list} =    BuiltIn.Create_List
    FOR    ${index}    IN    @{index_list}
        ${status}    ${text} =    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    Install_Feature_On_Member
        ...    feature_name=${feature_name}
        ...    member_index=${index}
        ...    timeout=${timeout}
        BuiltIn.Log    ${text}
        Collections.Append_To_List    ${status_list}    ${status}
    END
    FOR    ${status}    IN    @{status_list}
        IF    "${status}" != "PASS"
            BuiltIn.Fail    ${feature_name} installation failed, see log.
        END
    END

Install_Feature_On_Member
    [Documentation]    Run feature:install karaf command, fail if installation was not successful. Return output.
    [Arguments]    ${feature_name}    ${member_index}    ${timeout}=60s
    ${status}    ${output} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    Run_Karaf_Command_On_Member
    ...    command=feature:install ${feature_name}
    ...    member_index=${member_index}
    ...    timeout=${timeout}
    IF    "${status}" != "PASS"
        BuiltIn.Fail    Failed to install ${feature_name}: ${output}
    END
    BuiltIn.Should_Not_Contain    ${output}    Can't install    Failed to install ${feature_name}: ${output}
    RETURN    ${output}

With_Ssh_To_List_Or_All_Run_Keyword
    [Documentation]    For each index in given list (or all): activate SSH connection, run given Keyword, close active connection. Return None.
    ...    Beware that in order to avoid "got positional argument after named arguments", first two arguments in the call should not be named.
    [Arguments]    ${member_index_list}    ${keyword_name}    @{args}    &{kwargs}
    BuiltIn.Comment    This keyword is experimental and there is high risk of being replaced by another approach.
    # TODO: For_Index_From_List_Or_All_Run_Keyword applied to With_Ssh_To_Member_Run_Keyword?
    # TODO: Imagine another keyword, using ScalarClosures and adding member index as first argument for each call. Worth it?
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${member_index}    IN    @{index_list}
        ${member_ip} =    Resolve_IP_Address_For_Member    ${member_index}
        SSHKeywords.Run_Unsafely_Keyword_Over_Temporary_Odl_Session
        ...    ${member_ip}
        ...    ${keyword_name}
        ...    @{args}
        ...    &{kwargs}
    END

Safe_With_Ssh_To_List_Or_All_Run_Keyword
    [Documentation]    Remember active ssh connection index, call With_Ssh_To_List_Or_All_Run_Keyword, return None. Restore the conection index on teardown.
    [Arguments]    ${member_index_list}    ${keyword_name}    @{args}    &{kwargs}
    SSHKeywords.Run_Keyword_Preserve_Connection
    ...    With_Ssh_To_List_Or_All_Run_Keyword
    ...    ${member_index_list}
    ...    ${keyword_name}
    ...    @{args}
    ...    &{kwargs}

Clean_Directories_On_List_Or_All
    [Documentation]    Clear @{directory_list} or @{ODL_DEFAULT_DATA_PATHS} for members in given list or all. Return None.
    ...    If \${tmp_dir} is nonempty, use that location to preserve data/log/.
    ...    This is intended to return Karaf (offline) to the state it was upon the first boot.
    [Arguments]    ${member_index_list}=${EMPTY}    ${directory_list}=${EMPTY}    ${karaf_home}=${KARAF_HOME}    ${tmp_dir}=${EMPTY}
    ${path_list} =    Builtin.Set Variable If
    ...    "${directory_list}" == "${EMPTY}"
    ...    ${ODL_DEFAULT_DATA_PATHS}
    ...    ${directory_list}
    IF    """${tmp_dir}""" != ""
        Check_Bash_Command_On_List_Or_All
        ...    mkdir -p '${tmp_dir}' && rm -vrf '${tmp_dir}/log' && mv -vf '${karaf_home}/data/log' '${tmp_dir}/'
        ...    ${member_index_list}
    END
    Safe_With_Ssh_To_List_Or_All_Run_Keyword
    ...    ${member_index_list}
    ...    ClusterManagement__Clean_Directories
    ...    ${path_list}
    ...    ${karaf_home}
    IF    """${tmp_dir}""" != ""
        Check_Bash_Command_On_List_Or_All
        ...    mkdir -p '${karaf_home}/data' && rm -vrf '${karaf_home}/log' && mv -vf '${tmp_dir}/log' '${karaf_home}/data/'
        ...    ${member_index_list}
    END

Store_Karaf_Log_On_List_Or_All
    [Documentation]    Saves karaf.log to the ${dst_dir} for members in given list or all. Return None.
    [Arguments]    ${member_index_list}=${EMPTY}    ${dst_dir}=/tmp    ${karaf_home}=${KARAF_HOME}
    Safe_With_Ssh_To_List_Or_All_Run_Keyword
    ...    ${member_index_list}
    ...    SSHKeywords.Execute_Command_Should_Pass
    ...    cp ${karaf_home}/data/log/karaf.log ${dst_dir}

Restore_Karaf_Log_On_List_Or_All
    [Documentation]    Places stored karaf.log to the ${karaf_home}/data/log for members in given list or all. Return None.
    [Arguments]    ${member_index_list}=${EMPTY}    ${src_dir}=/tmp    ${karaf_home}=${KARAF_HOME}
    Safe_With_Ssh_To_List_Or_All_Run_Keyword
    ...    ${member_index_list}
    ...    SSHKeywords.Execute_Command_Should_Pass
    ...    cp ${src_dir}/karaf.log ${karaf_home}/data/log/

ClusterManagement__Clean_Directories
    [Documentation]    For each relative path, remove files with respect to ${karaf_home}. Return None.
    [Arguments]    ${relative_path_list}    ${karaf_home}
    FOR    ${relative_path}    IN    @{relative_path_list}
        SSHLibrary.Execute_Command    rm -rf ${karaf_home}${/}${relative_path}
    END

Put_As_Json_And_Check_Member_List_Or_All
    [Documentation]    Send a PUT with the supplied uri ${uri} and body ${data} to member ${member_index}.
    ...    Then check data is replicated in all or some members defined in ${member_index_list}.
    [Arguments]    ${uri}    ${data}    ${member_index}    ${member_index_list}=${EMPTY}
    ${response_text} =    Put_As_Json_To_Member    uri=${uri}    data=${data}    member_index=${member_index}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    Check_Json_Member_List_Or_All
    ...    uri=${uri}?content=config
    ...    expected_data=${data}
    ...    member_index_list=${member_index_list}
    RETURN    ${response_text}

Put_As_Json_To_Member
    [Documentation]    Send a PUT with the supplied uri and data to member ${member_index}.
    [Arguments]    ${uri}    ${data}    ${member_index}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Put_As_Json_To_Uri    uri=${uri}    data=${data}    session=${session}
    RETURN    ${response_text}

Post_As_Json_To_Member
    [Documentation]    Send a POST with the supplied uri and data to member ${member_index}.
    [Arguments]    ${uri}    ${data}    ${member_index}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Post_As_Json_To_Uri    uri=${uri}    data=${data}    session=${session}
    RETURN    ${response_text}

Delete_And_Check_Member_List_Or_All
    [Documentation]    Send a DELETE with the supplied uri to the member ${member_index}.
    ...    Then check the data is removed from all members in ${member_index_list}.
    [Arguments]    ${uri}    ${member_index}    ${member_index_list}=${EMPTY}
    ${response_text} =    Delete_From_Member    ${uri}    ${member_index}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    5s
    ...    1s
    ...    Check_No_Content_Member_List_Or_All
    ...    uri=${uri}
    ...    member_index_list=${member_index_list}
    RETURN    ${response_text}

Delete_From_Member
    [Documentation]    Send a DELETE with the supplied uri to member ${member_index}.
    [Arguments]    ${uri}    ${member_index}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Delete_From_Uri    uri=${uri}    session=${session}
    RETURN    ${response_text}

Check_Json_Member_List_Or_All
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check received data is = ${expected data}.
    [Arguments]    ${uri}    ${expected_data}    ${member_index_list}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        ${data} =    Get_From_Member    uri=${uri}    member_index=${index}
        TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_data}    ${data}
    END

Check_Item_Occurrence_Member_List_Or_All
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check received for occurrences of items expressed in a dictionary ${dictionary}.
    [Arguments]    ${uri}    ${dictionary}    ${member_index_list}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        ${data} =    Get_From_Member    uri=${uri}    member_index=${index}
        Utils.Check Item Occurrence    ${data}    ${dictionary}
    END

Check_No_Content_Member_List_Or_All
    [Documentation]    Send a GET with the supplied uri to all or some members defined in ${member_index_list}.
    ...    Then check there is no content.
    [Arguments]    ${uri}    ${member_index_list}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    FOR    ${index}    IN    @{index_list}
        ${session} =    Resolve_Http_Session_For_Member    member_index=${index}
        Utils.No_Content_From_URI    ${session}    ${uri}
    END

Get_From_Member
    [Documentation]    Send a GET with the supplied uri to member ${member_index}.
    [Arguments]    ${uri}    ${member_index}    ${access}=${ACCEPT_EMPTY}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${response_text} =    TemplatedRequests.Get_From_Uri    uri=${uri}    accept=${access}    session=${session}
    RETURN    ${response_text}

Resolve_IP_Address_For_Member
    [Documentation]    Return node IP address of given index.
    [Arguments]    ${member_index}
    ${ip_address} =    Collections.Get From Dictionary
    ...    dictionary=${ClusterManagement__index_to_ip_mapping}
    ...    key=${member_index}
    RETURN    ${ip_address}

Resolve_IP_Address_For_Members
    [Documentation]    Return a list of IP address of given indexes.
    [Arguments]    ${member_index_list}
    ${member_ip_list} =    BuiltIn.Create_List
    FOR    ${index}    IN    @{member_index_list}
        ${ip_address} =    Collections.Get From Dictionary
        ...    dictionary=${ClusterManagement__index_to_ip_mapping}
        ...    key=${index}
        Collections.Append_To_List    ${member_ip_list}    ${ip_address}
    END
    RETURN    ${member_ip_list}

Resolve_Http_Session_For_Member
    [Documentation]    Return RequestsLibrary session alias pointing to node of given index.
    [Arguments]    ${member_index}
    ${session} =    BuiltIn.Set_Variable    ClusterManagement__session_${member_index}
    RETURN    ${session}

Resolve_Shard_Type_Class
    [Documentation]    Simple lookup for class name corresponding to desired type.
    [Arguments]    ${shard_type}
    IF    '${shard_type}' == 'config'
        RETURN    DistributedConfigDatastore
    ELSE IF    '${shard_type}' == 'operational'
        RETURN    DistributedOperationalDatastore
    END
    BuiltIn.Fail    Unrecognized shard type: ${shard_type}

ClusterManagement__Build_List
    [Arguments]    ${member}
    ${member_int} =    BuiltIn.Convert_To_Integer    ${member}
    ${index_list} =    BuiltIn.Create_List    ${member_int}
    RETURN    ${index_list}

ClusterManagement__Parse_Sync_Status
    [Documentation]    Return sync status parsed out of given text. Called twice by Get_Sync_Status_Of_Member.
    [Arguments]    ${shard_manager_text}
    BuiltIn.Log    ${shard_manager_text}
    ${manager_object} =    Utils.Json Parse From String    ${shard_manager_text}
    ${value_object} =    Collections.Get_From_Dictionary    dictionary=${manager_object}    key=value
    ${sync_status} =    Collections.Get_From_Dictionary    dictionary=${value_object}    key=SyncStatus
    RETURN    ${sync_status}

List_All_Indices
    [Documentation]    Create a new list of all indices.
    BuiltIn.Run_Keyword_And_Return    List_Indices_Or_All

List_Indices_Or_All
    [Documentation]    Utility to allow \${EMPTY} as default argument value, as the internal list is computed at runtime.
    ...    This keyword always returns a (shallow) copy of given or default list,
    ...    so operations with the returned list should not affect other lists.
    ...    Also note that this keyword does not consider empty list to be \${EMPTY}.
    [Arguments]    ${given_list}=${EMPTY}
    ${return_list_reference} =    BuiltIn.Set_Variable_If
    ...    """${given_list}""" != ""
    ...    ${given_list}
    ...    ${ClusterManagement__member_index_list}
    ${return_list_copy} =    BuiltIn.Create_List    @{return_list_reference}
    RETURN    ${return_list_copy}

List_Indices_Minus_Member
    [Documentation]    Create a new list which contains indices from ${member_index_list} (or all) without ${member_index}.
    [Arguments]    ${member_index}    ${member_index_list}=${EMPTY}
    ${index_list} =    List_Indices_Or_All    ${member_index_list}
    Collections.Remove Values From List    ${index_list}    ${member_index}
    RETURN    ${index_list}

ClusterManagement__Compute_Derived_Variables
    [Documentation]    Construct index list, session list and IP mapping, publish them as suite variables.
    [Arguments]    ${int_of_members}    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}    ${http_retries}=0
    @{member_index_list} =    BuiltIn.Create_List
    @{session_list} =    BuiltIn.Create_List
    &{index_to_ip_mapping} =    BuiltIn.Create_Dictionary
    FOR    ${index}    IN RANGE    1    ${int_of_members+1}
        ClusterManagement__Include_Member_Index
        ...    ${index}
        ...    ${member_index_list}
        ...    ${session_list}
        ...    ${index_to_ip_mapping}
        ...    http_timeout=${http_timeout}
        ...    http_retries=${http_retries}
    END
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__member_index_list}    ${member_index_list}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__index_to_ip_mapping}    ${index_to_ip_mapping}
    BuiltIn.Set_Suite_Variable    \${ClusterManagement__session_list}    ${session_list}

ClusterManagement__Include_Member_Index
    [Documentation]    Add a corresponding item based on index into the last three arguments.
    ...    Create the Http session whose alias is added to list.
    [Arguments]    ${index}    ${member_index_list}    ${session_list}    ${index_to_ip_mapping}    ${http_timeout}=${DEFAULT_TIMEOUT_HTTP}    ${http_retries}=0
    Collections.Append_To_List    ${member_index_list}    ${index}
    ${member_ip} =    BuiltIn.Set_Variable    ${ODL_SYSTEM_${index}_IP}
    # ${index} is int (not string) so "key=value" syntax does not work in the following line.
    Collections.Set_To_Dictionary    ${index_to_ip_mapping}    ${index}    ${member_ip}
    # Http session, with ${AUTH}, without headers.
    ${session_alias} =    Resolve_Http_Session_For_Member    member_index=${index}
    RequestsLibrary.Create_Session
    ...    ${session_alias}
    ...    http://${member_ip}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    timeout=${http_timeout}
    ...    max_retries=${http_retries}
    Collections.Append_To_List    ${session_list}    ${session_alias}

Sync_Status_Should_Be_False
    [Documentation]    Verify that cluster node is not in sync with others
    [Arguments]    ${controller_index}
    ${status} =    Get_Sync_Status_Of_Member    ${controller_index}
    BuiltIn.Should_Not_Be_True    ${status}

Sync_Status_Should_Be_True
    [Documentation]    Verify that cluster node is in sync with others
    [Arguments]    ${controller_index}
    ${status} =    Get_Sync_Status_Of_Member    ${controller_index}
    BuiltIn.Should_Be_True    ${status}

Return_Member_IP
    [Documentation]    Return the IP address of the member given the member_index.
    [Arguments]    ${member_index}
    ${member_int} =    BuiltIn.Convert_To_Integer    ${member_index}
    ${member_ip} =    Collections.Get_From_Dictionary
    ...    dictionary=${ClusterManagement__index_to_ip_mapping}
    ...    key=${member_int}
    RETURN    ${member_ip}

Check Service Status
    [Documentation]    Issues the karaf shell command showSvcStatus to verify the ready and service states are the same as the arguments passed
    [Arguments]    ${odl_ip}    ${system_ready_state}    ${service_state}    @{service_list}
    IF    ${NUM_ODL_SYSTEM} > 1
        ${service_status_output} =    KarafKeywords.Issue_Command_On_Karaf_Console
        ...    showSvcStatus -n ${odl_ip}
        ...    ${odl_ip}
        ...    ${KARAF_SHELL_PORT}
    ELSE
        ${service_status_output} =    KarafKeywords.Issue_Command_On_Karaf_Console
        ...    showSvcStatus
        ...    ${odl_ip}
        ...    ${KARAF_SHELL_PORT}
    END
    BuiltIn.Should Contain    ${service_status_output}    ${system_ready_state}
    FOR    ${service}    IN    @{service_list}
        BuiltIn.Should Match Regexp    ${service_status_output}    ${service} +: ${service_state}
    END

Check Status Of Services Is OPERATIONAL
    [Documentation]    This keyword will verify whether all the services are operational in all the ODL nodes
    [Arguments]    @{service_list}
    FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
        ClusterManagement.Check Service Status    ${ODL_SYSTEM_${i+1}_IP}    ACTIVE    OPERATIONAL    @{service_list}
    END
