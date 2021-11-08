*** Settings ***
Documentation     Resource housing Keywords common to tests which interact with car/people models.
...
...               Copyright (c) 2016-2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This resource is tightly coupled with "crud" cluster suite,
...               as it is not straightforward to allow ${VAR_DIR} customization.
Resource          ${CURDIR}/TemplatedRequests.robot
Resource          ${CURDIR}/KarafKeywords.robot

*** Variables ***
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Keywords ***
Add_Several_People
    [Arguments]    ${member_index}    ${iterations}    ${iter_start}=1
    [Documentation]    Simple loop for issuing add-person RPCs to session, one by one.
    ...    People need to be added via RPC, otherwise buy-car routed RPC will not find registered path.
    ...    See javadocs in RpcProviderRegistry.java
    FOR    ${i}    IN RANGE    ${iter_start}    ${iter_start}+${iterations}
        ${person_id} =    BuiltIn.Set_Variable    localhost/people/person_id_${i}
        ${gender} =    BuiltIn.Set_Variable    gender_${i}
        ${age} =    BuiltIn.Set_Variable    ${i}
        ${address} =    BuiltIn.Set_Variable    address_${i}
        ${constact} =    BuiltIn.Set_Variable    contact_${i}
        ${command} =    BuiltIn.Set_Variable    ${CLUSTER_TEST_APP_CMD_SCOPE}:add-person ${person_id} ${gender} ${age} ${address} ${constact}
        ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    command=${command}    member_index=${member_index}
        BuiltIn.Should_Not_Start_With    ${output}    ${INVOCATION_FAILED}
    END

Buy_Several_Cars
    [Arguments]    ${member_index}    ${iterations}    ${iter_start}=1    ${registration_delay}=20s
    [Documentation]    Simple loop for issuing buy-car RPCs to session, one by one.
    ...    This needs to be a separate Keyword mostly just because nested FOR loops are not allowed.
    ...    Actual fact of buying one car is done by inner Keyword.
    FOR    ${iter}    IN RANGE    ${iter_start}    ${iter_start}+${iterations}
        BuiltIn.Wait_Until_Keyword_Succeeds    ${registration_delay}    1s    Buy_Single_Car    member_index=${member_index}    iteration=${iter}    registration_delay=${registration_delay}
    END

Buy_Single_Car
    [Arguments]    ${member_index}    ${iteration}=1    ${registration_delay}=20s
    [Documentation]    Each buy-car RPC is routed, which means there is a delay between
    ...    the time add-car RPC is executed and the time member in question registers the route.
    ...    To distinguish functional bugs from performance ones, this Keyword waits up to 20 seconds
    ...    while retrying buy-car requests.
    ${person_ref} =    BuiltIn.Set_Variable    /people:people/people:person\\[people:id='"'localhost/people/person_id_${iteration}'"'\\]
    ${car_id} =    BuiltIn.Set_Variable    localhost/cars/car_id_${iteration}
    ${person_id} =    BuiltIn.Set_Variable    localhost/people/person_id_${iteration}
    ${command} =    BuiltIn.Set_Variable    ${CLUSTER_TEST_APP_CMD_SCOPE}:buy-car ${person_ref} ${car_id} ${person_id}
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    command=${command}    member_index=${member_index}
    BuiltIn.Should_Not_Contain    ${output}    ${INVOCATION_FAILED}
    BuiltIn.Should_Not_Contain    ${output}    Error executing command:

Set_Variables_For_Shard
    [Arguments]    ${shard_name}    ${shard_type}=config
    [Documentation]    Get leader and followers for given shard name and
    ...    set several suite variables related to member indices and sessions.
    ...    ClusterManagement Resource is assumed to be initialized.
    ...    TODO: car-people shard name causes dash in variable names. Should we convert to underscores?
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_index}    ${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_indices}    ${follower_list}
    ${first_follower_index} =    Collections.Get_From_List    ${follower_list}    0
    BuiltIn.Set_Suite_Variable    \${${shard_name}_first_follower_index}    ${first_follower_index}
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    FOR    ${follower_index}    IN    @{follower_list}
        ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
        Collections.Append_To_List    ${sessions}    ${follower_session}
    END
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${${shard_name}_first_follower_session}    ${first_follower_session}

Set_Tmp_Variables_For_Shard_For_Nodes
    [Arguments]    ${member_index_list}    ${shard_name}=car    ${shard_type}=config
    [Documentation]    Get current leader and followers for given shard. Can be used for less nodes than full odl configuration.
    ...    Variable names do not contain neither node nor shard names, so the variables are only suitable for temporary use, as indicated by Tmp in the keyword name.
    ...    This keyword sets the following suite variables:
    ...    ${new_leader_session} - http session for the leader node
    ...    ${new_follower_sessions} - list of http sessions for the follower nodes
    ...    ${new_first_follower_session} - http session for the first follower node
    ...    ${new_leader_index} - index of the shard leader
    ...    ${new_followers_list} - list of followers indexes
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${member_index_list}
    BuiltIn.Set_Suite_Variable    \${new_leader_index}    ${leader}
    BuiltIn.Set_Suite_Variable    \${new_followers_list}    ${follower_list}
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${new_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    FOR    ${follower_index}    IN    @{follower_list}
        ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
        Collections.Append_To_List    ${sessions}    ${follower_session}
    END
    BuiltIn.Set_Suite_Variable    \${new_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${new_first_follower_session}    ${first_follower_session}
    BuiltIn.Return_From_Keyword    ${leader}    ${follower_list}
