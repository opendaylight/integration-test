*** Settings ***
Documentation     Keywords wrapping controller's odl-mdsal-lowlevel yang model rpcs.
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
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:register-contact ${constant}    member_index=${member_index}

Unregister_Constant
    [Arguments]    ${member_index}
    [Documentation]    Unregister the get-constant rpc on the given node.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unregister-contact    member_index=${member_index}

Register_Singleton_Constant
    [Arguments]    ${member_index}    ${constant}
    [Documentation]    Register singleton application on given node by executing register-singleton-constant command.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:register-singleton-constant ${constant}    member_index=${member_index}

Unregister_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Unregister singleton application on given node by executing unregister-singleton-constant command.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unregister-singleton-constant    member_index=${member_index}

Register_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Activate flapping application on given node by executing register-flapping-singleton command.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:register-flapping-singleton    member_index=${member_index}

Unregister_Flapping_Singleton
    [Arguments]    ${member_index}
    [Documentation]    Deactivate flapping singleton application by executing unregister-flapping-singleton command.
    ...    Return the successful re-registrations count.
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unregister-flapping-singleton    member_index=${member_index}
    BuiltIn.Run_Keyword_And_Return    Utils.Get_Parameter_Value_From_Output    ${output}    flapCount

Write_Transactions
    [Arguments]    ${member_index}    ${identifier}    ${seconds}    ${trans_per_sec}    ${chained_trans}=${True}
    [Documentation]    Create transactions with given rate for given time for module-based shards.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:write-transactions ${identifier} ${seconds} ${trans_per_sec} ${chained_trans}    member_index=${member_index}

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
    [Documentation]    Subscribe a listener for data changes. Execute subscribe-dtcl command.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:subscribe-dtcl    member_index=${member_index}

Unsubscribe_Dtcl
    [Arguments]    ${member_index}
    [Documentation]    Execute unsubscribe-dtcl command, return copy-matches field as boolean.
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unsubscribe-dtcl    member_index=${member_index}
    ${copy_matches} =   Utils.Get_Parameter_Value_From_Output    ${output}    copyMatches
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Convert_To_Boolean    ${copy_matches}

Unsubscribe_Dtcl_No_Tx
    [Arguments]    ${member_index}
    [Documentation]    Unsubscribe a listener from the data changes. Expect success no notifications received. Return boolean status.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${UNSUBSCRIBE_DTCL_DIR}    session=${session}    additional_allowed_status_codes=${INTERNAL_SERVER_ERROR}
    BuiltIn.Run_Keyword_And_Return    MdsalLowLevel__Parse_Maybe_No_Tx    ${text}

Subscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Subscribe DOMDataTreeListener to listen for the data changes.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:subscribe-ddtl    member_index=${member_index}

Unsubscribe_Ddtl
    [Arguments]    ${member_index}
    [Documentation]    Execute unsubscribe-ddtl command, return copy-matches field as boolean.
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unsubscribe-ddtl    member_index=${member_index}
    ${copy_matches} =   Utils.Get_Parameter_Value_From_Output    ${output}    copyMatches
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Convert_To_Boolean    ${copy_matches}

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
    [Documentation]    Start publishing notifications by executing publish-notifications command.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:start-publish-notifications ${gid} ${seconds} ${notif_per_sec}    member_index=${member_index}

Check_Publish_Notifications
    [Arguments]    ${member_index}    ${gid}
    [Documentation]    Publishing notifications check by executing check-publish-notifications command. Return publising process state details.
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:check-publish-notifications ${gid}    member_index=${member_index}
    ${active} =    Utils.Get_Parameter_Value_From_Output    ${output}    active
    ${active} =    BuiltIn.Convert_To_Boolean    ${active}
    ${publish_count} =    Utils.Get_Parameter_Value_From_Output    ${output}    publishCount
    ${last_error} =    Utils.Get_Parameter_Value_From_Output    ${output}    lastError
    BuiltIn.Return_From_Keyword    ${active}    ${publish_count}    ${last_error}

Subscribe_Ynl
    [Arguments]    ${member_index}    ${gid}
    [Documentation]    Subscribe listener for the notifications with identifier ${gid}.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:subscribe-ynl ${gid}    member_index=${member_index}

Unsubscribe_Ynl
    [Arguments]    ${member_index}    ${gid}
    [Documentation]    Unsubscribe listener for the ${gid} identifier. Return statistics of the publishing process.
    ${output} =    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unsubscribe-ynl ${gid}    member_index=${member_index}
    ${all_not} =    Utils.Get_Parameter_Value_From_Output    ${output}    allNot
    ${id_not} =    Utils.Get_Parameter_Value_From_Output    ${output}    idNot
    ${err_not} =    Utils.Get_Parameter_Value_From_Output    ${output}    errNot
    ${local_number} =    Utils.Get_Parameter_Value_From_Output    ${output}    localNumber
    BuiltIn.Return_From_Keyword    ${all_not}    ${id_not}    ${err_not}    ${local_number}

Register_Bound_Constant
    [Arguments]    ${member_index}    ${context}    ${constant}
    [Documentation]    Execute register-bound-constant command and register get-contexted-constant rpc. The argument ${context} is only the string part
    ...    of the whole instance identifier.
    ${context} =    BuiltIn.Set_Variable    /odl-mdsal-lowlevel-common:rpc-context[odl-mdsal-lowlevel-common:identifier='${context}']
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:register-bound-constant ${context} ${constant}    member_index=${member_index}

Unregister_Bound_Constant
    [Arguments]    ${member_index}    ${context}
    [Documentation]    Execute unregister-bound-constant command and unregister get-contexted-constant rpc. The argument ${context} is only the string part
    ...    of the whole instance identifier.
    ${context} =    BuiltIn.Set_Variable    /odl-mdsal-lowlevel-common:rpc-context[odl-mdsal-lowlevel-common:identifier='${context}']
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:unregister-bound-constant ${context}    member_index=${member_index}

Shutdown_Shard_Replica
    [Arguments]    ${member_index}    ${shard_name}
    [Documentation]    Execute shutdown-shard-replica command.
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    test-app:shutdown-shard-replica ${shard_name}    member_index=${member_index}

Shutdown_Prefix_Shard_Replica
    [Arguments]    ${member_index}    ${shard_prefix}
    [Documentation]    Invoke shutdown-prefix-shard-replica rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${shard_prefix}
    TemplatedRequests.Post_As_Xml_Templated    ${SHUTDOWN_PREFIX_SHARD_REPLICA_DIR}    mapping=${mapping}    session=${session}
