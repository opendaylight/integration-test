*** Settings ***
Documentation     Keywords wrapping controller's odl-mdsal-lowlevel yang model rpcs.
...
...               This is just an initial skeleton implementation, calls are debugged. Multiple
...               changes will follow as suites will be implemented.
...               This suite should be preferably merged before any suite to avoid conflicting
...               situations while suites will be implementing.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           XML
Resource          ${CURDIR}/ClusterManagement.robot
Resource          ${CURDIR}/TemplatedRequests.robot

*** Variables ***
${RPC_DIR}        ${CURDIR}/../variables/mdsal/lowlevelrpc
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
    [Arguments]    ${member_index}    ${explicit_status_codes}=${NO_STATUS_CODES}
    [Documentation]    Invoke get-constant rpc on the requested member and return the registered constant.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_CONSTANT_DIR}    session=${session}    explicit_status_codes=${explicit_status_codes}
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    BuiltIn.Return_From_Keyword    ${constant}

Get_Contexted_Constant
    [Arguments]    ${member_index}    ${context}
    [Documentation]    TODO: more desctiptive comment than: Invoke get-contexted-constant rpc.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONTEXT=${context}
    ${test} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_CONTEXTED_CONSTANT_DIR}    mapping=${mapping}    session=${session}
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${formatted_output}

Get_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke get-singleton-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${GET_SINGLETON_CONSTANT_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}
    BuiltIn.Fail    TODO: to format output data
    BuiltIn.Return_From_Keyword    ${formatted_output}

Register_Constant
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    Register the get-constant rpc on the requested node with given constant.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Constant
    [Arguments]    ${member_index}
    [Documentation]    Unregister the get-constant rpc on the given node.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_CONSTANT_DIR}    session=${session}

Register_Singleton_Constant
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    TODO: more desctiptive comment than: Invoke register-singleton-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_SINGLETON_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unregister-singleton-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${UNREGISTER_SINGLETON_CONSTANT_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Register_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke register-flapping-singleton rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${REGISTER_FLAPPING_SINGLETON_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Unregister_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unregister-flapping-singleton rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${UNREGISTER_FLAPPING_SINGLETON_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Write_Transactions
    [Arguments]    ${member_index}    ${seconds}    ${trans_per_sec}    ${chained_trans}=${True}
    [Documentation]    TODO: more desctiptive comment than: Invoke write-transactions rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SECONDS=${seconds}    TPS=${trans_per_sec}    CHAINED_TRANSACTIONS=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${WRITE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Produce_Transactions
    [Arguments]    ${member_index}    ${seconds}    ${trans_per_sec}    ${isolated_trans}=${True}
    [Documentation]    TODO: more desctiptive comment than: Invoke produce-transactions rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SECONDS=${seconds}    TPS=${trans_per_sec}    ISOLATED_TRANSACTIONS=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${PRODUCE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Become_Prefix_Leader
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    TODO: more desctiptive comment than: Invoke become-prefix-leader rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${BECOME_PREFIX_LEADER_DIR}    mapping=${mapping}    session=${session}

Become_Module_Leader
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    TODO: more desctiptive comment than: Invoke become-module-leader rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${BECOME_MODULE_LEADER_DIR}    mapping=${mapping}    session=${session}

Remove_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    TODO: more desctiptive comment than: Invoke remove-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated    ${REMOVE_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Add_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    TODO: more desctiptive comment than: Invoke add-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated    ${ADD_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Deconfigure_Id_Ints_Shard
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke deconfigure-id-ints-shard rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${DECONFIGURE_ID_INTS_SHARD_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Is_Client_Aborted
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke is-client-aborted rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${IS_CLIENT_ABORTED_SHARD_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Subscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke subscribe-dtcl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${SUBSCRIBE_DTCL_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Unsubscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unsubscribe-dtcl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${UNSUBSCRIBE_DTCL_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Subscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke subscribe-ddtl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${SUBSCRIBE_DDTL_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Unsubscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unsubscribe-ddtl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${UNSUBSCRIBE_DDTL_DIR}    base_name=location    extension=uri
    ${text} =    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}

Publish_Notifications
    [Arguments]    ${member_index}    ${seconds}    ${notif_per_sec}
    [Documentation]    TODO: more desctiptive comment than: Invoke publish-notifications rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SECONDS=${seconds}    NPS=${notif_per_sec}
    TemplatedRequests.Post_As_Xml_Templated    ${PUBLISH_NOTIFICATIONS_DIR}    mapping=${mapping}    session=${session}

Subscribe_Ynl
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke subscribe-ynl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}

Unsubscribe_Ynl
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unsubscribe-ynl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}

Register_Bound_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke register-bound-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_BOUND_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Bound_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unregister-bound-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_BOUND_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Register_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke register-default-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_DEFAULT_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unregister-default-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${uri} =    TemplatedRequests.Resolve_Text_From_Template_Folder    folder=${UNREGISTER_DEFAULT_CONSTANT_DIR}    base_name=location    extension=uri
    TemplatedRequests.Post_To_Uri    uri=${uri}    data=${EMPTY}    accept=${ACCEPT_JSON}    content_type=${HEADERS_YANG_JSON}    session=${session}
