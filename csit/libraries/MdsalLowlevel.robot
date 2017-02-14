*** Settings ***
Documentation     Keywords wrapping controller's odl-mdsal-lowlevel yang model rpcs.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/TemplatedRequests.robot

*** Variables ***
${RPC_DIR}        ${CURDIR}/variables/mdsal/lowlevelrpc
${ADD_SHARD_REPLICA_DIR}     ${RPC_DIR}/add_shard_replica
${BECOME_MODULE_LEADER_DIR}     ${RPC_DIR}/become_module_leader
${BECOME_PREFIX_LEADER_DIR}     ${RPC_DIR}/become_prefix_leader
${DECONFIGURE_ID_INTS_SHARD_DIR}     ${RPC_DIR}/deconfigure_id_ints_shard
${GET_CONSTANT_DIR}     ${RPC_DIR}/get_constant
${GET_CONTEXTED_CONSTANT_DIR}     ${RPC_DIR}/get_contexted_constant
${GET_SINGLETON_CONSTANT_DIR}     ${RPC_DIR}/get_singleton_constant
${IS_CLIENT_ABORTED_DIR}     ${RPC_DIR}/is_client_aborted
${PRODUCE_TRANSACTIONS_DIR}     ${RPC_DIR}/produce_transactions
${PUBLISH_NOTIFICATIONS_DIR}     ${RPC_DIR}/publish_notifications
${REGISTER_BOUND_CONSTANT_DIR}     ${RPC_DIR}/register_bound_constant
${REGISTER_CONSTANT_DIR}     ${RPC_DIR}/register_constant
${REGISTER_DEFAULT_CONSTANT_DIR}     ${RPC_DIR}/register_default_constant
${REGISTER_FLAPPING_SINGLETON_DIR}     ${RPC_DIR}/register_flapping_singleton
${REGISTER_SINGLETON_CONSTANT_DIR}     ${RPC_DIR}/register_singleton_constant
${REMOVE_SHARD_REPLICA_DIR}     ${RPC_DIR}/remove_shard_replica
${SUBSCRIBE_DDTL_DIR}     ${RPC_DIR}/subscribe_ddtl
${SUBSCRIBE_DTCL_DIR}     ${RPC_DIR}/subscribe_dtcl
${SUBSCRIBE_YNL_DIR}     ${RPC_DIR}/subscribe_ynl
${UNREGISTER_BOUND_CONSTANT_DIR}     ${RPC_DIR}/unregister_bound_constant
${UNREGISTER_CONSTANT_DIR}     ${RPC_DIR}/unregister_constant
${UNREGISTER_DEFAULT_CONSTANT_DIR}     ${RPC_DIR}/unregister_default_constant
${UNREGISTER_FLAPPING_SINGLETON_DIR}     ${RPC_DIR}/unregister_flapping_singleton
${UNREGISTER_SINGLETON_CONSTANT_DIR}     ${RPC_DIR}/unregister_singleton_constant
${UNSUBSCRIBE_DDTL_DIR}     ${RPC_DIR}/unsubscribe_ddtl
${UNSUBSCRIBE_DTCL_DIR}     ${RPC_DIR}/unsubscribe_dtcl
${UNSUBSCRIBE_YNL_DIR}     ${RPC_DIR}/unsubscribe_ynl
${WRITE_TRANSACTIONS_DIR}     ${RPC_DIR}/write_transactions

*** Keywords ***
Get_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke get-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${GET_CONSTANT_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_EMPTY}    content_type=${HEADERS_YANG_JSON}    session=${session}
    BuiltIn.Fail    TODO: to format output data 
    BuiltIn.Return_From_Keyword    ${formatted_output}

Get_Contexted_Constant
    [Arguments]    ${member_index}    ${context}
    [Documentation]    Invoke get-contexted-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    CONTEXT=${context}
    ${test} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_CONTEXTED_CONSTANT_DIR}    mapping=${mapping}    session=${session}
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${formatted_output}

Get_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke get-singleton-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${GET_SINGLETON_CONSTANT_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}
    BuiltIn.Fail    TODO: to format output data
    BuiltIn.Return_From_Keyword    ${formatted_output}

Register_Constant
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    Invoke register-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${UNREGISTER_CONSTANT_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Register_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-singleton-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:register-singleton-constant

Unregister_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-singleton-constant rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unregister-singleton-constant

Register_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-flapping-singleton rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:register-flapping-singleton

Unregister_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-flapping-singleton rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unregister-flapping-singleton
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Write_Transactions
    [Arguments]    ${member_index}
    [Documentation]    Invoke write-transactions rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:write-transactions

Produce_Transactions
    [Arguments]    ${member_index}
    [Documentation]    Invoke produce-transactions rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:produce-transactions

Become_Prefix_Leader
    [Arguments]    ${member_index}
    [Documentation]    Invoke become-prefix-leader rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:become-prefix-leader

Become_Module_Leader
    [Arguments]    ${member_index}
    [Documentation]    Invoke become-module-leader rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:become-module-leader

Remove_Shard_Replica
    [Arguments]    ${member_index}
    [Documentation]    Invoke remove-shard-replica rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:remove-shard-replica

Add_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Invoke add-shard-replica rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated     ${ADD_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Deconfigure_Id_Ints_Shard
    [Arguments]    ${member_index}
    [Documentation]    Invoke deconfigure-id-ints-shard rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:deconfigure-id-ints-shard

Is_Client_Aborted
    [Arguments]    ${member_index}
    [Documentation]    Invoke is-client-aborted rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:is-client-aborted
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Subscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Invoke subscribe-dtcl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:subscribe-dtcl
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Unsubscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-dtcl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unsubscribe-dtcl
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Subscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Invoke subscribe-ddtl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:subscribe-ddtl
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Unsubscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-ddtl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unsubscribe-ddtl
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Publish_Notifications
    [Arguments]    ${member_index}
    [Documentation]    Invoke publish-notifications rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:publish-notifications

Subscribe_Ynl
    [Arguments]    ${member_index}
    [Documentation]    Invoke subscribe-ynl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:subscribe-ynl

Unsubscribe_Ynl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-ynl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unsubscribe-ynl
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Register_Bound_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-bound-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:register-bound-constant

Unregister_Bound_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-bound-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unregister-bound-constant

Register_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-default-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:register-default-constant

Unregister_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-default-constant rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unregister-default-constant
