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

*** Variables ***
${VAR_DIR}        ${CURDIR}/../../../variables/carpeople/crud

*** Keywords ***
Add_Several_People
    [Arguments]    ${session}    ${iterations}    ${iter_start}=1
    [Documentation]    Simple loop for issuing add-person RPCs to session, one by one.
    ...    People need to be added via RPC, otherwise buy-car routed RPC will not find registered path.
    ...    See javadocs in RpcProviderRegistry.java
    : FOR    ${i}    IN RANGE    ${iter_start}    ${iter_start}+${iterations}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/add-person    mapping={"i": "${i}"}    session=${session}

Buy_Several_Cars
    [Arguments]    ${session}    ${iterations}    ${iter_start}=1    ${registration_delay}=20s
    [Documentation]    Simple loop for issuing buy-car RPCs to session, one by one.
    ...    This needs to be a separate Keyword mostly just because nested FOR loops are not allowed.
    ...    Actual fact of buying one car is done by inner Keyword.
    : FOR    ${iter}    IN RANGE    ${iter_start}    ${iter_start}+${iterations}
    \    Buy_Single_Car    session=${session}    iteration=${iter}    registration_delay=${registration_delay}

Buy_Single_Car
    [Arguments]    ${session}    ${iteration}=1    ${registration_delay}=20s
    [Documentation]    Each buy-car RPC is routed, which means there is a delay between
    ...    the time add-car RPC is executed and the time member in question registers the route.
    ...    To distinguish functional bugs from performance ones, this Keyword waits up to 20 seconds
    ...    while retrying buy-car requests.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${registration_delay}    1s    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/buy-car    mapping={"i": "${iteration}"}    session=${session}

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
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
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
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${member_index_list}
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${new_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${new_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${new_first_follower_session}    ${first_follower_session}
    BuiltIn.Return_From_Keyword    ${leader}    ${follower_list}
