*** Settings ***
Documentation       Keywords wrapping controller's odl-mdsal-lowlevel yang model rpcs.
...
...                 Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html

Library             XML
Resource            ${CURDIR}/ClusterManagement.robot
Resource            ${CURDIR}/TemplatedRequests.robot


*** Variables ***
${LOWLEVEL_RPC_DIR}                     ${CURDIR}/../variables/mdsal/lowlevelrpc
${BECOME_PREFIX_LEADER_DIR}             ${LOWLEVEL_RPC_DIR}/become_prefix_leader
${CHECK_PUBLISH_NOTIFICATIONS_DIR}      ${LOWLEVEL_RPC_DIR}/check_publish_notifications
${CREATE_PREFIX_SHARD_DIR}              ${LOWLEVEL_RPC_DIR}/create_prefix_shard
${GET_CONSTANT_DIR}                     ${LOWLEVEL_RPC_DIR}/get_constant
${GET_CONTEXTED_CONSTANT_DIR}           ${LOWLEVEL_RPC_DIR}/get_contexted_constant
${GET_SINGLETON_CONSTANT_DIR}           ${LOWLEVEL_RPC_DIR}/get_singleton_constant
${PRODUCE_TRANSACTIONS_DIR}             ${LOWLEVEL_RPC_DIR}/produce_transactions
${REGISTER_BOUND_CONSTANT_DIR}          ${LOWLEVEL_RPC_DIR}/register_bound_constant
${REGISTER_CONSTANT_DIR}                ${LOWLEVEL_RPC_DIR}/register_constant
${REGISTER_FLAPPING_SINGLETON_DIR}      ${LOWLEVEL_RPC_DIR}/register_flapping_singleton
${REGISTER_SINGLETON_CONSTANT_DIR}      ${LOWLEVEL_RPC_DIR}/register_singleton_constant
${REMOVE_PREFIX_SHARD_DIR}              ${LOWLEVEL_RPC_DIR}/remove_prefix_shard
${SHUTDOWN_SHARD_REPLICA_DIR}           ${LOWLEVEL_RPC_DIR}/shutdown_shard_replica
${SHUTDOWN_PREFIX_SHARD_REPLICA_DIR}    ${LOWLEVEL_RPC_DIR}/shutdown_prefix_shard_replica
${START_PUBLISH_NOTIFICATIONS_DIR}      ${LOWLEVEL_RPC_DIR}/start_publish_notifications
${SUBSCRIBE_DDTL_DIR}                   ${LOWLEVEL_RPC_DIR}/subscribe_ddtl
${SUBSCRIBE_DTCL_DIR}                   ${LOWLEVEL_RPC_DIR}/subscribe_dtcl
${SUBSCRIBE_YNL_DIR}                    ${LOWLEVEL_RPC_DIR}/subscribe_ynl
${UNREGISTER_BOUND_CONSTANT_DIR}        ${LOWLEVEL_RPC_DIR}/unregister_bound_constant
${UNREGISTER_CONSTANT_DIR}              ${LOWLEVEL_RPC_DIR}/unregister_constant
${UNREGISTER_FLAPPING_SINGLETON_DIR}    ${LOWLEVEL_RPC_DIR}/unregister_flapping_singleton
${UNREGISTER_SINGLETON_CONSTANT_DIR}    ${LOWLEVEL_RPC_DIR}/unregister_singleton_constant
${UNSUBSCRIBE_DDTL_DIR}                 ${LOWLEVEL_RPC_DIR}/unsubscribe_ddtl
${UNSUBSCRIBE_DTCL_DIR}                 ${LOWLEVEL_RPC_DIR}/unsubscribe_dtcl
${UNSUBSCRIBE_YNL_DIR}                  ${LOWLEVEL_RPC_DIR}/unsubscribe_ynl
${WRITE_TRANSACTIONS_DIR}               ${LOWLEVEL_RPC_DIR}/write_transactions


*** Keywords ***
Get_Constant
    [Documentation]    Invoke get-constant rpc on the requested member and return the registered constant unless explicit status code is expected.
    ...    The ${explicit_status_codes} is a list of http status codes for which the rpc call is considered as passed and is used for calls with
    ...    expected failures on odl's side, such as calling the rpc on isolated node etc.
    [Arguments]    ${member_index}    ${explicit_status_codes}=${NO_STATUS_CODES}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${GET_CONSTANT_DIR}
    ...    session=${session}
    ...    explicit_status_codes=${explicit_status_codes}
    IF    """${explicit_status_codes}""" != """${NO_STATUS_CODES}"""    RETURN
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    RETURN    ${constant}

Get_Contexted_Constant
    [Documentation]    Invoke get-contexted-constant rpc on the requested member and return the registered constant. The argument ${context} is only the string part
    ...    of the whole instance identifier. The ${explicit_status_codes} is a list of http status codes for which the rpc call is considered as passed and is used for
    ...    calls with expected failures on odl's side, such as calling the rpc on isolated node etc.
    [Arguments]    ${member_index}    ${context}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    CONTEXT=${context}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${GET_CONTEXTED_CONSTANT_DIR}
    ...    mapping=${mapping}
    ...    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    RETURN    ${constant}

Get_Singleton_Constant
    [Documentation]    Invoke get-singleton-constant rpc on the requested member and return the registered constant unless explicit status code is
    ...    expected. The ${explicit_status_codes} is a list of http status codes for which the rpc call is considered as passed and is used for calls
    ...    with expected failures on odl's side, such as calling the rpc on isolated node etc.
    [Arguments]    ${member_index}    ${explicit_status_codes}=${NO_STATUS_CODES}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${GET_SINGLETON_CONSTANT_DIR}
    ...    session=${session}
    ...    explicit_status_codes=${explicit_status_codes}
    IF    """${explicit_status_codes}""" != """${NO_STATUS_CODES}"""    RETURN
    ${xml} =    XML.Parse_Xml    ${text}
    ${constant} =    XML.Get_Element_Text    ${xml}    xpath=constant
    RETURN    ${constant}

Register_Constant
    [Documentation]    Register the get-constant rpc on the requested node with given constant.
    [Arguments]    ${member_index}    ${constant}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_CONSTANT_DIR}    mapping=${mapping}    session=${session}

Unregister_Constant
    [Documentation]    Unregister the get-constant rpc on the given node.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_CONSTANT_DIR}    session=${session}

Register_Singleton_Constant
    [Documentation]    Register singleton application on given node by invoking register-singleton-constant rpc.
    [Arguments]    ${member_index}    ${constant}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    CONSTANT=${constant}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${REGISTER_SINGLETON_CONSTANT_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Unregister_Singleton_Constant
    [Documentation]    Unregister singleton application on given node by invoking unregister-singleton-constant rpc.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_SINGLETON_CONSTANT_DIR}    session=${session}

Register_Flapping_Singleton
    [Documentation]    Activate flapping application on given node by invoking register-flapping-singleton rpc.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${REGISTER_FLAPPING_SINGLETON_DIR}    session=${session}

Unregister_Flapping_Singleton
    [Documentation]    Deactivate flapping singleton application by invoking unregister-flapping-singleton rpc.
    ...    Return the successful re-registrations count.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNREGISTER_FLAPPING_SINGLETON_DIR}    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${count} =    XML.Get_Element_Text    ${xml}    xpath=flap-count
    RETURN    ${count}

Write_Transactions
    [Documentation]    Create transactions with given rate for given time for module-based shards.
    [Arguments]    ${member_index}    ${identifier}    ${seconds}    ${trans_per_sec}    ${chained_trans}=${True}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary
    ...    ID=${identifier}
    ...    DURATION=${seconds}
    ...    RATE=${trans_per_sec}
    ...    CHAINED_FLAG=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${WRITE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Produce_Transactions
    [Documentation]    Create transactions with given rate for given time for prefix-based shards.
    [Arguments]    ${member_index}    ${seconds}    ${trans_per_sec}    ${isolated_trans}=${True}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary
    ...    SECONDS=${seconds}
    ...    TPS=${trans_per_sec}
    ...    ISOLATED_TRANSACTIONS=${chained_trans}
    TemplatedRequests.Post_As_Xml_Templated    ${PRODUCE_TRANSACTIONS_DIR}    mapping=${mapping}    session=${session}

Create_Prefix_Shard
    [Documentation]    Create prefix based shard. ${replicas} is a list of cluster node indexes, taken e.g. from ClusterManagement.List_Indices_Or_All.
    [Arguments]    ${member_index}    ${prefix}    ${replicas}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${replicas_str} =    BuiltIn.Set_Variable    ${EMPTY}
    FOR    ${replica}    IN    @{replicas}
        ${replicas_str} =    BuiltIn.Set_Variable    ${replicas_str}<replicas>member-${replica}</replicas>
    END
    &{mapping} =    BuiltIn.Create_Dictionary    PREFIX=${prefix}    REPLICAS=${replicas_str}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${CREATE_PREFIX_SHARD_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Remove_Prefix_Shard
    [Documentation]    Remove prefix based shard.
    [Arguments]    ${member_index}    ${prefix}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    PREFIX=${prefix}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${REMOVE_PREFIX_SHARD_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Become_Prefix_Leader
    [Documentation]    Given node ask to become a shard leader.
    [Arguments]    ${member_index}    ${shard_name}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}    ID=prefix-0
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${BECOME_PREFIX_LEADER_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Subscribe_Dtcl
    [Documentation]    Subscribe a listener for data changes. Invoke subscribe-dtcl rpc.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_DTCL_DIR}    session=${session}

Unsubscribe_Dtcl
    [Documentation]    Invoke unsubscribe-dtcl rpc, return copy-matches field as boolean.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DTCL_DIR}    session=${session}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Matches    ${text}

Unsubscribe_Dtcl_No_Tx
    [Documentation]    Unsubscribe a listener from the data changes. Expect success no notifications received. Return boolean status.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${UNSUBSCRIBE_DTCL_DIR}
    ...    session=${session}
    ...    additional_allowed_status_codes=${INTERNAL_SERVER_ERROR}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Maybe_No_Tx    ${text}

Subscribe_Ddtl
    [Documentation]    Subscribe DOMDataTreeListener to listen for the data changes.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_DDTL_DIR}    session=${session}

Unsubscribe_Ddtl
    [Documentation]    Invoke unsubscribe-ddtl rpc, return copy-matches field as boolean.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DDTL_DIR}    session=${session}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Matches    ${text}

Unsubscribe_Ddtl_No_Tx
    [Documentation]    Unsubscribe a listener from the data changes. Expect success no notifications received. Return boolean status.
    [Arguments]    ${member_index}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${UNSUBSCRIBE_DDTL_DIR}
    ...    session=${session}
    ...    additional_allowed_status_codes=${INTERNAL_SERVER_ERROR}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Maybe_No_Tx    ${text}

MdsalLowLevel__Parse_Matches
    [Documentation]    Interpret the \${text} as XML response to an unsubscribe call and return copy-matches as boolean.
    [Arguments]    ${text}
    ${xml} =    XML.Parse_Xml    ${text}
    ${matches} =    XML.Get_Element_Text    ${xml}    xpath=copy-matches
    ${matches} =    BuiltIn.Convert_To_Boolean    ${matches}
    RETURN    ${matches}

MdsalLowLevel__Parse_Maybe_No_Tx
    [Documentation]    Attempt to parse the \${text} as successful unsubscribe. If that fails, extract the error message and expect no notifications.
    [Arguments]    ${text}
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error    MdsalLowLevel__Parse_Matches    ${text}
    IF    "${status}" == "PASS"    RETURN    ${message}
    ${xml} =    XML.Parse_Xml    ${text}
    ${message} =    XML.Get_Element_Text    ${xml}    xpath=error/error-message
    ${status}    ${message} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    BuiltIn.Should_Contain
    ...    ${message}
    ...    listener has not received
    IF    "${status}" == "PASS"    RETURN    ${TRUE}
    RETURN    ${FALSE}

Start_Publish_Notifications
    [Documentation]    Start publishing notifications by invoking publish-notifications rpc.
    [Arguments]    ${member_index}    ${gid}    ${seconds}    ${notif_per_sec}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    ID=${gid}    DURATION=${seconds}    RATE=${notif_per_sec}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${START_PUBLISH_NOTIFICATIONS_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Check_Publish_Notifications
    [Documentation]    Publishing notifications check by invoking check-publish-notifications rpc. Return publising process state details.
    [Arguments]    ${member_index}    ${gid}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    ID=${gid}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${CHECK_PUBLISH_NOTIFICATIONS_DIR}
    ...    mapping=${mapping}
    ...    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${active} =    XML.Get_Element_Text    ${xml}    xpath=active
    ${active} =    BuiltIn.Convert_To_Boolean    ${active}
    ${status}    ${publish_count} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    XML.Get_Element_Text
    ...    ${xml}
    ...    xpath=publish-count
    IF    """${status}""" == """FAIL""" and """${publish_count}""" != """No element matching 'publish-count' found."""
        BuiltIn.Fail    ${publish_count}
    END
    ${publish_count} =    BuiltIn.Set_Variable_If    """${status}""" == """FAIL"""    ${EMPTY}    ${publish_count}
    ${status}    ${last_error} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    XML.Get_Element_Text
    ...    ${xml}
    ...    xpath=last-error
    IF    """${status}""" == """FAIL""" and """${last_error}""" != """No element matching 'last-error' found."""
        BuiltIn.Fail    ${last_error}
    END
    ${last_error} =    BuiltIn.Set_Variable_If    """${status}""" == """FAIL"""    ${EMPTY}    ${last_error}
    RETURN    ${active}    ${publish_count}    ${last_error}

Subscribe_Ynl
    [Documentation]    Subscribe listener for the notifications with identifier ${gid}.
    [Arguments]    ${member_index}    ${gid}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    ID=${gid}
    TemplatedRequests.Post_As_Xml_Templated    ${SUBSCRIBE_YNL_DIR}    mapping=${mapping}    session=${session}

Unsubscribe_Ynl
    [Documentation]    Unsubscribe listener for the ${gid} identifier. Return statistics of the publishing process.
    [Arguments]    ${member_index}    ${gid}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    ID=${gid}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${UNSUBSCRIBE_YNL_DIR}
    ...    mapping=${mapping}
    ...    session=${session}
    ${xml} =    XML.Parse_Xml    ${text}
    ${all_not} =    XML.Get_Element_Text    ${xml}    xpath=all-not
    ${id_not} =    XML.Get_Element_Text    ${xml}    xpath=id-not
    ${err_not} =    XML.Get_Element_Text    ${xml}    xpath=err-not
    ${local_number} =    XML.Get_Element_Text    ${xml}    xpath=local-number
    RETURN    ${all_not}    ${id_not}    ${err_not}    ${local_number}

Register_Bound_Constant
    [Documentation]    Invoke register-bound-constant rpc and register get-contexted-constant rpc. The argument ${context} is only the string part
    ...    of the whole instance identifier.
    [Arguments]    ${member_index}    ${context}    ${constant}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    CONTEXT=${context}    CONSTANT=${constant}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated
    ...    ${REGISTER_BOUND_CONSTANT_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Unregister_Bound_Constant
    [Documentation]    Invoke unregister-bound-constant rpc and unregister get-contexted-constant rpc. The argument ${context} is only the string part
    ...    of the whole instance identifier.
    [Arguments]    ${member_index}    ${context}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    CONTEXT=${context}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${UNREGISTER_BOUND_CONSTANT_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Shutdown_Shard_Replica
    [Documentation]    Invoke shutdown-shard-replica rpc.
    [Arguments]    ${member_index}    ${shard_name}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${SHUTDOWN_SHARD_REPLICA_DIR}
    ...    mapping=${mapping}
    ...    session=${session}

Shutdown_Prefix_Shard_Replica
    [Documentation]    Invoke shutdown-prefix-shard-replica rpc.
    [Arguments]    ${member_index}    ${shard_prefix}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping} =    BuiltIn.Create_Dictionary    PREFIX=${shard_prefix}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${SHUTDOWN_PREFIX_SHARD_REPLICA_DIR}
    ...    mapping=${mapping}
    ...    session=${session}
