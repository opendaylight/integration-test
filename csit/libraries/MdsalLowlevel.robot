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
${ADD_SHARD_REPLICA_DIR}    ${RPC_DIR}/add_shard_replica
${BECOME_MODULE_LEADER_DIR}    ${RPC_DIR}/become_module_leader
${BECOME_PREFIX_LEADER_DIR}    ${RPC_DIR}/become_prefix_leader
${DECONFIGURE_ID_INTS_SHARD_DIR}    ${RPC_DIR}/deconfigure_id_ints_shard
${GET_CONSTANT_DIR}    ${RPC_DIR}/get_constant
${GET_CONTEXTED_CONSTANT_DIR}    ${RPC_DIR}/get_contexted_constant
${GET_SINGLETON_CONSTANT_DIR}    ${RPC_DIR}/get_singleton_constant
${IS_CLIENT_ABORTED_DIR}    ${RPC_DIR}/is_client_aborted
${PRODUCE_TRANSACTIONS_DIR}    ${RPC_DIR}/produce_transactions
${PUBLISH_NOTIFICATIONS_DIR}    ${RPC_DIR}/publish_notifications
${REGISTER_BOUND_CONSTANT_DIR}    ${RPC_DIR}/register_bound_constant
${REGISTER_CONSTANT_DIR}    ${RPC_DIR}/register_constant
${REGISTER_DEFAULT_CONSTANT_DIR}    ${RPC_DIR}/register_default_constant
${REGISTER_FLAPPING_SINGLETON_DIR}    ${RPC_DIR}/register_flapping_singleton
${REGISTER_SINGLETON_CONSTANT_DIR}    ${RPC_DIR}/register_singleton_constant
${REMOVE_SHARD_REPLICA_DIR}    ${RPC_DIR}/remove_shard_replica
${SUBSCRIBE_DDTL_DIR}    ${RPC_DIR}/subscribe_ddtl
${SUBSCRIBE_DTCL_DIR}    ${RPC_DIR}/subscribe_dtcl
${SUBSCRIBE_YNL_DIR}    ${RPC_DIR}/subscribe_ynl
${UNREGISTER_BOUND_CONSTANT_DIR}    ${RPC_DIR}/unregister_bound_constant
${UNREGISTER_CONSTANT_DIR}    ${RPC_DIR}/unregister_constant
${UNREGISTER_DEFAULT_CONSTANT_DIR}    ${RPC_DIR}/unregister_default_constant
${UNREGISTER_FLAPPING_SINGLETON_DIR}    ${RPC_DIR}/unregister_flapping_singleton
${UNREGISTER_SINGLETON_CONSTANT_DIR}    ${RPC_DIR}/unregister_singleton_constant
${UNSUBSCRIBE_DDTL_DIR}    ${RPC_DIR}/unsubscribe_ddtl
${UNSUBSCRIBE_DTCL_DIR}    ${RPC_DIR}/unsubscribe_dtcl
${UNSUBSCRIBE_YNL_DIR}    ${RPC_DIR}/unsubscribe_ynl
${WRITE_TRANSACTIONS_DIR}    ${RPC_DIR}/write_transactions

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
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    Invoke register-singleton-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_SINGLETON_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-singleton-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${UNREGISTER_SINGLETON_CONSTANT_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Register_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-flapping-singleton rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${REGISTER_FLAPPING_SINGLETON_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Unregister_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-flapping-singleton rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${UNREGISTER_FLAPPING_SINGLETON_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Write_Transactions
    [Arguments]    ${member_index}    ${seconds}    ${trans_per_sec}    ${chained_trans}=${True}
    [Documentation]    Invoke write-transactions rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SECONDS=${seconds}    TPS=${trans_per_sec}    CHAINED_TRANSACTIONS=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${WRITE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Produce_Transactions
    [Arguments]    ${member_index}    ${seconds}    ${trans_per_sec}    ${isolated_trans}=${True}
    [Documentation]    Invoke produce-transactions rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SECONDS=${seconds}    TPS=${trans_per_sec}    ISOLATED_TRANSACTIONS=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${PRODUCE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Become_Prefix_Leader
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Invoke become-prefix-leader rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SHARD_NAME=${shard_name}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${BECOME_PREFIX_LEADER_DIR}    mapping=${mapping}    session=${session}

Become_Module_Leader
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Invoke become-module-leader rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SHARD_NAME=${shard_name}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${BECOME_MODULE_LEADER_DIR}    mapping=${mapping}    session=${session}

Remove_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Invoke remove-shard-replica rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated    ${REMOVE_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Add_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Invoke add-shard-replica rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated    ${ADD_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Deconfigure_Id_Ints_Shard
    [Arguments]    ${member_index}
    [Documentation]    Invoke deconfigure-id-ints-shard rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${DECONFIGURE_ID_INTS_SHARD_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Is_Client_Aborted
    [Arguments]    ${member_index}
    [Documentation]    Invoke is-client-aborted rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${IS_CLIENT_ABORTED_SHARD_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Subscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Invoke subscribe-dtcl rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${SUBSCRIBE_DTCL_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Unsubscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-dtcl rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${UNSUBSCRIBE_DTCL_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Subscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Invoke subscribe-ddtl rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${SUBSCRIBE_DDTL_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Unsubscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-ddtl rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${UNSUBSCRIBE_DDTL_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Publish_Notifications
    [Arguments]    ${member_index}    ${seconds}    ${notif_per_sec}
    [Documentation]    Invoke publish-notifications rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary    SECONDS=${seconds}    NPS=${notif_per_sec}
    TemplatedRequests.Post_As_Xml_Templated    ${PUBLISH_NOTIFICATIONS_DIR}    mapping=${mapping}    session=${session}

Subscribe_Ynl
    [Arguments]    ${member_index}
    [Documentation]    Invoke subscribe-ynl rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}

Unsubscribe_Ynl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-ynl rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}

Register_Bound_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-bound-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_BOUND_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Bound_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-bound-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_BOUND_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Register_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-default-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    Create Dictionary
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_DEFAULT_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-default-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    Resolve_Text_From_Template_Folder    folder=${UNREGISTER_DEFAULT_CONSTANT_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}
