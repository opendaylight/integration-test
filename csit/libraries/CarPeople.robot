*** Settings ***
Documentation     Resource housing Keywords common to tests which interact with car/people models.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This resource expects ${VAR_DIR} variable to be set, it is a base folder
...               containing sub-folders for TemplatedRequests data files.
Resource          ${CURDIR}/TemplatedRequests.robot

*** Keywords ***
Add_Several_People
    [Arguments]    ${session}    ${iterations}    ${iter_start}=1    ${rpc_name}=add-person
    [Documentation]    Simple loop for issuing add-person RPCs to session, one by one.
    ...    People need to be added via RPC, otherwise buy-car routed RPC will not find registered path.
    ...    See javadocs in RpcProviderRegistry.java
    : FOR    ${i}    IN RANGE    ${iter_start}    ${iter_start}+${iterations}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/${rpc_name}    mapping={"i": "${i}"}    session=${session}

Buy_Several_Cars
    [Arguments]    ${session}    ${iterations}    ${iter_start}=1    ${rpc_name}=buy-car
    [Documentation]    Simple loop for issuing buy-car RPCs to session, one by one.
    : FOR    ${i}    IN RANGE    ${iter_start}    ${iter_start}+${iterations}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/${rpc_name}    mapping={"i": "${i}"}    session=${session}

Set_Variables_For_Shard
    [Arguments]    ${shard_name}
    [Documentation]    Get leader and followers for given shard name,
    ...    set several suite variables related to member indices and sessions.
    ...    TODO: car-people shard name causes dash in variable names. Should we convert to underscores?
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=config
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_index}    ${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_indices}    ${follower_list}
    ${leader_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${leader}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_leader_session}    ${leader_session}
    ${sessions} =    BuiltIn.Create_List
    : FOR    ${follower_index}    IN    @{follower_list}
    \    ${follower_session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${follower_index}
    \    Collections.Append_To_List    ${sessions}    ${follower_session}
    BuiltIn.Set_Suite_Variable    \${${shard_name}_follower_sessions}    ${sessions}
    ${first_follower_session} =    Collections.Get_From_List    ${sessions}    0
    BuiltIn.Set_Suite_Variable    \${${shard_name}_first_follower_session}    ${first_follower_session}
