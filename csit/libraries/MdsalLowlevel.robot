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

*** Keywords ***
Get_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke get-constant rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_T}:get-constant
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Get_Contexted_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke get-contexted-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_T}:get-contexted-constant
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Get_Singleton_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke get-singleton-constant rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_T}:get-singleton-constant
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Register_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke register-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:register-constant

Unregister_Constant
    [Arguments]    ${member_index}
    [Documentation]    Invoke unregister-constant rpc.
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:unregister-constant

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
    [Arguments]    ${member_index}
    [Documentation]    Invoke add-shard-replica rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    TemplatedRequests.Post_As_Json_To_Uri    ${member_index}    ${URL_PREFIX_C}:add-shard-replica

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
