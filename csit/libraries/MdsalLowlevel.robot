*** Settings ***
Documentation     Keywords wrapping controller's odl-mdsal-lowlevel yang model rpcs.
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
${LOWLEVEL_RPC_DIR}    ${CURDIR}/../variables/mdsal/lowlevelrpc
${BECOME_PREFIX_LEADER_DIR}    ${LOWLEVEL_RPC_DIR}/become_prefix_leader
${CHECK_PUBLISH_NOTIFICATIONS_DIR}    ${LOWLEVEL_RPC_DIR}/check_publish_notifications
${CREATE_PREFIX_SHARD_DIR}    ${LOWLEVEL_RPC_DIR}/create_prefix_shard
${GET_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/get_constant
${GET_CONTEXTED_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/get_contexted_constant
${GET_SINGLETON_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/get_singleton_constant
${PRODUCE_TRANSACTIONS_DIR}    ${LOWLEVEL_RPC_DIR}/produce_transactions
${REGISTER_BOUND_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/register_bound_constant
${REGISTER_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/register_constant
${REGISTER_FLAPPING_SINGLETON_DIR}    ${LOWLEVEL_RPC_DIR}/register_flapping_singleton
${REGISTER_SINGLETON_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/register_singleton_constant
${REMOVE_PREFIX_SHARD_DIR}    ${LOWLEVEL_RPC_DIR}/remove_prefix_shard
${SHUTDOWN_SHARD_REPLICA_DIR}    ${LOWLEVEL_RPC_DIR}/shutdown_shard_replica
${SHUTDOWN_PREFIX_SHARD_REPLICA_DIR}    ${LOWLEVEL_RPC_DIR}/shutdown_prefix_shard_replica
${START_PUBLISH_NOTIFICATIONS_DIR}    ${LOWLEVEL_RPC_DIR}/start_publish_notifications
${SUBSCRIBE_DDTL_DIR}    ${LOWLEVEL_RPC_DIR}/subscribe_ddtl
${SUBSCRIBE_DTCL_DIR}    ${LOWLEVEL_RPC_DIR}/subscribe_dtcl
${SUBSCRIBE_YNL_DIR}    ${LOWLEVEL_RPC_DIR}/subscribe_ynl
${UNREGISTER_BOUND_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/unregister_bound_constant
${UNREGISTER_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/unregister_constant
${UNREGISTER_FLAPPING_SINGLETON_DIR}    ${LOWLEVEL_RPC_DIR}/unregister_flapping_singleton
${UNREGISTER_SINGLETON_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/unregister_singleton_constant
${UNSUBSCRIBE_DDTL_DIR}    ${LOWLEVEL_RPC_DIR}/unsubscribe_ddtl
${UNSUBSCRIBE_DTCL_DIR}    ${LOWLEVEL_RPC_DIR}/unsubscribe_dtcl
${UNSUBSCRIBE_YNL_DIR}    ${LOWLEVEL_RPC_DIR}/unsubscribe_ynl
${WRITE_TRANSACTIONS_DIR}    ${LOWLEVEL_RPC_DIR}/write_transactions

*** Keywords ***
Get_Constant
    [Arguments]    ${member_index}    ${explicit_status_codes}=${NO_STATUS_CODES}
    [Documentation]    Invoke get-constant rpc on the requested member and return the registered constant unless explicit status code is expected.
    ...    The ${explicit_status_codes} is a list of http status codes for which the rpc call is considered as passed and is used for calls with
    ...    expected failures on odl's side, such as calling the rpc on isolated node etc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_CONSTANT_DIR}    session=${session}    explicit_status_codes=${explicit_status_codes}
    BuiltIn.Return_From_Keyword_If    """${explicit_status_codes}""" != """${NO_STATUS_CODES}"""
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
    [Arguments]    ${member_index}    ${explicit_status_codes}=${NO_STATUS_CODES}
    [Documentation]    Invoke get-singleton-constant rpc on the requested member and return the registered constant unless explicit status code is
    ...    expected. The ${explicit_status_codes} is a list of http status codes for which the rpc call is considered as passed and is used for calls
    ...    with expected failures on odl's side, such as calling the rpc on isolated node etc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${GET_SINGLETON_CONSTANT_DIR}    session=${session}    explicit_status_codes=${explicit_status_codes}
    BuiltIn.Return_From_Keyword_If    """${explicit_status_codes}""" != """${NO_STATUS_CODES}"""
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    BuiltIn.Return_From_Keyword    ${constant}

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
    [Documentation]    Register singleton application on given node by invoking register-singleton-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_SINGLETON_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Unregister singleton application on given node by invoking unregister-singleton-constant rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_SINGLETON_CONSTANT_DIR}    session=${session}

Register_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Activate flapping application on given node by invoking register-flapping-singleton rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_FLAPPING_SINGLETON_DIR}    session=${session}

Unregister_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Deactivate flapping singleton application by invoking unregister-flapping-singleton rpc.
    ...    Return the successful re-registrations count.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_FLAPPING_SINGLETON_DIR}    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${count} =    XML.Get_Element_Text    ${xml}    xpath=flap-count
    BuiltIn.Return_From_Keyword    ${count}

Write_Transactions
    [Arguments]    ${member_index}    ${identifier}    ${seconds}    ${trans_per_sec}    ${chained_trans}=${True}
    [Documentation]    Create transactions with given rate for given time for module-based shards.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    ID=${identifier}    DURATION=${seconds}    RATE=${trans_per_sec}    CHAINED_FLAG=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${WRITE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Produce_Transactions
    [Arguments]    ${member_index}    ${seconds}    ${trans_per_sec}    ${isolated_trans}=${True}
    [Documentation]    Create transactions with given rate for given time for prefix-based shards.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SECONDS=${seconds}    TPS=${trans_per_sec}    ISOLATED_TRANSACTIONS=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${PRODUCE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Create_Prefix_Shard
    [Arguments]    ${member_index}    ${prefix}    ${replicas}
    [Documentation]    Create prefix based shard. ${replicas} is a list of cluster node indexes, taken e.g. from ClusterManagement.List_Indices_Or_All.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${replicas_str}    BuiltIn.Set_Variable    ${EMPTY}
    FOR    ${replica}    IN    @{replicas}
        ${replicas_str}    BuiltIn.Set_Variable    ${replicas_str}<replicas>member-${replica}</replicas>
    END
    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}    REPLICAS=${replicas_str}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${CREATE_PREFIX_SHARD_DIR}    mapping=${mapping}    session=${session}

Remove_Prefix_Shard
    [Arguments]    ${member_index}    ${prefix}
    [Documentation]    Remove prefix based shard.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${REMOVE_PREFIX_SHARD_DIR}    mapping=${mapping}    session=${session}

Become_Prefix_Leader
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Given node ask to become a shard leader.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}    ID=prefix-0
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${BECOME_PREFIX_LEADER_DIR}    mapping=${mapping}    session=${session}

Subscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Subscribe a listener for data changes. Invoke subscribe-dtcl rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_DTCL_DIR}    session=${session}

Unsubscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-dtcl rpc, return copy-matches field as boolean.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DTCL_DIR}    session=${session}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Matches    ${text}

Unsubscribe_Dtcl_No_Tx
    [Arguments]    ${member_index}
    [Documentation]    Unsubscribe a listener from the data changes. Expect success no notifications received. Return boolean status.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DTCL_DIR}    session=${session}    additional_allowed_status_codes=${INTERNAL_SERVER_ERROR}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Maybe_No_Tx    ${text}

Subscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Subscribe DOMDataTreeListener to listen for the data changes.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_DDTL_DIR}    session=${session}

Unsubscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Invoke unsubscribe-ddtl rpc, return copy-matches field as boolean.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DDTL_DIR}    session=${session}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Matches    ${text}

Unsubscribe_Ddtl_No_Tx
    [Arguments]    ${member_index}
    [Documentation]    Unsubscribe a listener from the data changes. Expect success no notifications received. Return boolean status.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DDTL_DIR}    session=${session}    additional_allowed_status_codes=${INTERNAL_SERVER_ERROR}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Maybe_No_Tx    ${text}

MdsalLowLevel__Parse_Matches
    [Arguments]    ${text}
    [Documentation]    Interpret the \${text} as XML response to an unsubscribe call and return copy-matches as boolean.
    ${xml} =    XML.Parse_Xml    ${text}
    ${matches} =    XML.Get_Element_Text    ${xml}    xpath=copy-matches
    ${matches} =    BuiltIn.Convert_To_Boolean    ${matches}
    BuiltIn.Return_From_Keyword    ${matches}

MdsalLowLevel__Parse_Maybe_No_Tx
    [Arguments]    ${text}
    [Documentation]    Attempt to parse the \${text} as successful unsubscribe. If that fails, extract the error message and expect no notifications.
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    MdsalLowLevel__Parse_Matches    ${text}
    BuiltIn.Return_From_Keyword_If    "${status}" == "PASS"    ${message}
    ${xml} =    XML.Parse_Xml    ${text}
    ${message} =    XML.Get_Element_Text    ${xml}    xpath=error/error-message
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Should_Contain    ${message}    listener has not received
    BuiltIn.Return_From_Keyword_If    "${status}" == "PASS"    ${TRUE}
    [Return]    ${FALSE}

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

Shutdown_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Invoke shutdown-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated    ${SHUTDOWN_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}

Shutdown_Prefix_Shard_Replica
    [Arguments]    ${member_index}    ${shard_prefix}
    [Documentation]    Invoke shutdown-prefix-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${shard_prefix}
    TemplatedRequests.Post_As_Xml_Templated    ${SHUTDOWN_PREFIX_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}
