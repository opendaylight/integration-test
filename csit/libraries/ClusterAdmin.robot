*** Settings ***
Documentation     Keywords wrapping controller's cluster-admin yang model rpcs.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           XML
Resource          ${CURDIR}/KarafKeywords.robot
Resource          ${CURDIR}/Utils.robot
Resource          ${CURDIR}/ClusterManagement.robot
Resource          ${CURDIR}/TemplatedRequests.robot

*** Variables ***
${CLUSTERADMIN_RPC_DIR}    ${CURDIR}/../variables/mdsal/clusteradmin
${ADD_PREFIX_SHARD_REPLICA_DIR}    ${CLUSTERADMIN_RPC_DIR}/add_prefix_shard_replica
${ADD_SHARD_REPLICA_DIR}    ${CLUSTERADMIN_RPC_DIR}/add_shard_replica
${MAKE_LEADER_LOCAL_DIR}    ${CLUSTERADMIN_RPC_DIR}/make_leader_local
${REMOVE_PREFIX_SHARD_REPLICA_DIR}    ${CLUSTERADMIN_RPC_DIR}/remove_prefix_shard_replica
${REMOVE_SHARD_REPLICA_DIR}    ${CLUSTERADMIN_RPC_DIR}/remove_shard_replica
${GET_SHARD_ROLE_DIR}    ${CLUSTERADMIN_RPC_DIR}/get_shard_role
${GET_PREFIX_SHARD_ROLE_DIR}    ${CLUSTERADMIN_RPC_DIR}/get_prefix_shard_role
${CLUSTER_ADMIN_CMD_SCOPE}    cluster-admin
@{ERROR_INDICATIONS}    Error executing command:    Invocation failed:    # strings that indicate an error occured after cluster-admin command execution

*** Keywords ***
Make_Leader_Local
    [Arguments]    ${member_index}    ${shard_name}    ${shard_type}
    [Documentation]    Makes the node to be a shard leader by executing make-leader-local command.
    ${command} =    BuiltIn.Set_Variable    ${CLUSTER_ADMIN_CMD_SCOPE}:make-leader-local ${shard_name} ${shard_type}
    KarafKeywords.Check_For_No_Elements_On_Karaf_Command_Output_Message    ${command}    ${ERROR_INDICATIONS}    ${member_index}

Add_Prefix_Shard_Replica
    [Arguments]    ${member_index}    ${shard_prefix}    ${ds_type}
    [Documentation]    Add prefix shard replica to given member by invoking add-prefix-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_PREFIX=${shard_prefix}    DATA_STORE_TYPE=${ds_type}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${ADD_PREFIX_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Remove_Prefix_Shard_Replica
    [Arguments]    ${member_index}    ${shard_prefix}    ${member_name}    ${ds_type}
    [Documentation]    Remove prefix shard replica from the given member by invoking remove-prefix-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_PREFIX=${shard_prefix}    MEMBER_NAME=${member_name}    DATA_STORE_TYPE=${ds_type}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${REMOVE_PREFIX_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Add_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}    ${ds_type}
    [Documentation]    Add shard replica to given member by executing add-shard-replica command.
    ${command} =    BuiltIn.Set_Variable    ${CLUSTER_ADMIN_CMD_SCOPE}:add-shard-replica ${shard_name} ${ds_type}
    KarafKeywords.Check_For_No_Elements_On_Karaf_Command_Output_Message    ${command}    ${ERROR_INDICATIONS}    ${member_index}

Remove_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}    ${member_name}    ${ds_type}
    [Documentation]    Remove shard replica from the given member by executing remove-shard-replica command.
    ${command} =    BuiltIn.Set_Variable    ${CLUSTER_ADMIN_CMD_SCOPE}:remove-shard-replica ${shard_name} ${ds_type} ${member_name}
    KarafKeywords.Check_For_No_Elements_On_Karaf_Command_Output_Message    ${command}    ${ERROR_INDICATIONS}    ${member_index}

Get_Shard_Role
    [Arguments]    ${member_index}    ${shard_name}    ${ds_type}
    [Documentation]    Get shard member role.
    ${command} =    BuiltIn.Set_Variable    ${CLUSTER_ADMIN_CMD_SCOPE}:get-shard-role ${shard_name} ${ds_type}
    ${output} =    KarafKeywords.Check_For_No_Elements_On_Karaf_Command_Output_Message    ${command}    ${ERROR_INDICATIONS}    ${member_index}
    BuiltIn.Run_Keyword_And_Return    Utils.Get_Parameter_Value_From_Output    ${output}    role

Get_Prefix_Shard_Role
    [Arguments]    ${member_index}    ${shard_prefix}    ${ds_type}
    [Documentation]    Get prefix shard member role.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_PREFIX=${shard_prefix}    DATA_STORE_TYPE=${ds_type}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_PREFIX_SHARD_ROLE_DIR}    mapping=${mapping}    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${role} =    XML.Get_Element_Text    ${xml}    xpath=role
    BuiltIn.Return_From_Keyword    ${role}
