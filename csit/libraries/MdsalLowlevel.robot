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
${CHECK_PUBLISH_NOTIFICATIONS_DIR}    ${RPC_DIR}/check_publish_notifications
${DECONFIGURE_ID_INTS_SHARD_DIR}    ${RPC_DIR}/deconfigure_id_ints_shard
${GET_CONSTANT_DIR}    ${RPC_DIR}/get_constant
${GET_CONTEXTED_CONSTANT_DIR}    ${RPC_DIR}/get_contexted_constant
${GET_SINGLETON_CONSTANT_DIR}    ${RPC_DIR}/get_singleton_constant
${IS_CLIENT_ABORTED_DIR}    ${RPC_DIR}/is_client_aborted
${PRODUCE_TRANSACTIONS_DIR}    ${RPC_DIR}/produce_transactions
${REGISTER_BOUND_CONSTANT_DIR}    ${RPC_DIR}/register_bound_constant
${REGISTER_CONSTANT_DIR}    ${RPC_DIR}/register_constant
${REGISTER_DEFAULT_CONSTANT_DIR}    ${RPC_DIR}/register_default_constant
${REGISTER_FLAPPING_SINGLETON_DIR}    ${RPC_DIR}/register_flapping_singleton
${REGISTER_SINGLETON_CONSTANT_DIR}    ${RPC_DIR}/register_singleton_constant
${REMOVE_SHARD_REPLICA_DIR}    ${RPC_DIR}/remove_shard_replica
${START_PUBLISH_NOTIFICATIONS_DIR}    ${RPC_DIR}/start_publish_notifications
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
    [Documentation]    Invoke get-constant rpc on the requested member and return the registered constant. The ${explicit_status_codes} is a list
    ...    of http status codes for which the rpc call is considered as passed and is used for calls with expected failures on odl's side, such as
    ...    calling the rpc on isolated node etc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_CONSTANT_DIR}    session=${session}    explicit_status_codes=${explicit_status_codes}
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    BuiltIn.Return_From_Keyword    ${constant}

Get_Contexted_Constant
    [Arguments]    ${member_index}    ${context}
    [Documentation]    Invoke get-contexted-constant rpc on the requested member and return the registered constant. The argument ${context} is only the string part
    ...    of the whole instance identifier. The ${explicit_status_codes} is a list of http status codes for which the rpc call is considered as passed and is used for
    ...    calls with expected failures on odl's side, such as calling the rpc on isolated node etc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONTEXT=${context}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_CONTEXTED_CONSTANT_DIR}    mapping=${mapping}    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    BuiltIn.Return_From_Keyword    ${constant}

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

Start_Publish_Notifications
    [Arguments]    ${member_index}    ${gid}    ${seconds}    ${notif_per_sec}
    [Documentation]    Start publishing notifications by invoking publish-notifications rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    ID=${gid}    DURATION=${seconds}    RATE=${notif_per_sec}
    TemplatedRequests.Post_As_Xml_Templated    ${START_PUBLISH_NOTIFICATIONS_DIR}    mapping=${mapping}    session=${session}

Check_Publish_Notifications
    [Arguments]    ${member_index}    ${gid}
    [Documentation]    Publishing notifications check by invoking check-publish-notifications rpc. Return publising process state details.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    ID=${gid}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${CHECK_PUBLISH_NOTIFICATIONS_DIR}    mapping=${mapping}    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${active} =    XML.Get_Element_Text    ${xml}    xpath=active
    ${active} =    BuiltIn.Convert_To_Boolean    ${active}
    ${status}    ${publish_count}=    BuiltIn.Run_Keyword_And_Ignore_Error    XML.Get_Element_Text    ${xml}    xpath=publish-count
    BuiltIn.Run_Keyword_If    """${status}""" == """FAIL""" and """${publish_count}""" != """No element matching 'publish-count' found."""    BuiltIn.Fail    ${publish_count}
    ${publish_count}    BuiltIn.Set_Variable_If    """${status}""" == """FAIL"""    ${EMPTY}    ${publish_count}
    ${status}    ${last_error}=    BuiltIn.Run_Keyword_And_Ignore_Error    XML.Get_Element_Text    ${xml}    xpath=last-error
    BuiltIn.Run_Keyword_If    """${status}""" == """FAIL""" and """${last_error}""" != """No element matching 'last-error' found."""    BuiltIn.Fail    ${last_error}
    ${last_error}    BuiltIn.Set_Variable_If    """${status}""" == """FAIL"""    ${EMPTY}    ${last_error}
    BuiltIn.Return_From_Keyword    ${active}    ${publish_count}    ${last_error}

Subscribe_Ynl
    [Arguments]    ${member_index}    ${gid}
    [Documentation]    Subscribe listener for the notifications with identifier ${gid}.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    ID=${gid}
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}

Unsubscribe_Ynl
    [Arguments]    ${member_index}    ${gid}
    [Documentation]    Unsubscribe listener for the ${gid} identifier. Return statistics of the publishing process.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    ID=${gid}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${all_not} =    XML.Get_Element_Text    ${xml}    xpath=all-not
    ${id_not} =    XML.Get_Element_Text    ${xml}    xpath=id-not
    ${err_not} =    XML.Get_Element_Text    ${xml}    xpath=err-not
    ${local_number} =    XML.Get_Element_Text    ${xml}    xpath=local-number
    BuiltIn.Return_From_Keyword    ${all_not}    ${id_not}    ${err_not}    ${local_number}

Register_Bound_Constant
    [Arguments]    ${member_index}    ${context}    ${constant}
    [Documentation]    Invoke register-bound-constant rpc and register get-contexted-constant rpc. The argument ${context} is only the string part
    ...    of the whole instance identifier.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONTEXT=${context}    CONSTANT=${constant}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_BOUND_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Bound_Constant
    [Arguments]    ${member_index}    ${context}
    [Documentation]    Invoke unregister-bound-constant rpc and unregister get-contexted-constant rpc. The argument ${context} is only the string part
    ...    of the whole instance identifier.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONTEXT=${context}
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_BOUND_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Register_Default_Constant
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    TODO: more desctiptive comment than: Invoke register-default-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_DEFAULT_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Default_Constant
    [Arguments]    ${member_index}
    [Documentation]    TODO: more desctiptive comment than: Invoke unregister-default-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_DEFAULT_CONSTANT_DIR}    session=${session}
