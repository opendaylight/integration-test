*** Settings ***
Documentation     Keywords wrapping controller's odl-mdsal-lowlevel yang model rpcs.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           RequestsLibrary

*** Variables ***
${MODULE_CONTROL}    odl-mdsal-lowlevel-control
${MODULE_TARGET}    odl-mdsal-lowlevel-target
${URL_PREFIX_C}    /restconf/operations/${MODULE_CONTROL}
${URL_PREFIX_T}    /restconf/operations/${MODULE_TARGET}

*** Keywords ***
Rpc_Get_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke get-constant rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_T}:get-constant
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Get_Contexted_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke get-contexted-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_T}:get-contexted-constant
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Get_Singleton_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke get-singleton-constant rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_T}:get-singleton-constant
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Register_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke register-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:register-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Unregister_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke unregister-constant rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unregister-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Register_Singleton_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke register-singleton-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:register-singleton-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Unregister_Singleton_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke unregister-singleton-constant rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unregister-singleton-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Register_Flapping_Singleton
    [Arguments]    ${session}
    [Documentation]    Invoke register-flapping-singleton rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:register-flapping-singleton
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Unregister_Flapping_Singleton
    [Arguments]    ${session}
    [Documentation]    Invoke unregister-flapping-singleton rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unregister-flapping-singleton
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Write_Transactions
    [Arguments]    ${session}
    [Documentation]    Invoke write-transactions rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:write-transactions
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Produce_Transactions
    [Arguments]    ${session}
    [Documentation]    Invoke produce-transactions rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:produce-transactions
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Become_Prefix_Leader
    [Arguments]    ${session}
    [Documentation]    Invoke become-prefix-leader rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:become-prefix-leader
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Become_Module_Leader
    [Arguments]    ${session}
    [Documentation]    Invoke become-module-leader rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:become-module-leader
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Remove_Shard_Replica
    [Arguments]    ${session}
    [Documentation]    Invoke remove-shard-replica rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:remove-shard-replica
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Add_Shard_Replica
    [Arguments]    ${session}
    [Documentation]    Invoke add-shard-replica rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:add-shard-replica
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Deconfigure_Id_Ints_Shard
    [Arguments]    ${session}
    [Documentation]    Invoke deconfigure-id-ints-shard rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:deconfigure-id-ints-shard
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Is_Client_Aborted
    [Arguments]    ${session}
    [Documentation]    Invoke is-client-aborted rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:is-client-aborted
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Subscribe_Dtcl
    [Arguments]    ${session}
    [Documentation]    Invoke subscribe-dtcl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:subscribe-dtcl
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Unsubscribe_Dtcl
    [Arguments]    ${session}
    [Documentation]    Invoke unsubscribe-dtcl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unsubscribe-dtcl
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Subscribe_Ddtl
    [Arguments]    ${session}
    [Documentation]    Invoke subscribe-ddtl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:subscribe-ddtl
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Unsubscribe_Ddtl
    [Arguments]    ${session}
    [Documentation]    Invoke unsubscribe-ddtl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unsubscribe-ddtl
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Publish_Notifications
    [Arguments]    ${session}
    [Documentation]    Invoke publish-notifications rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:publish-notifications
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Subscribe_Ynl
    [Arguments]    ${session}
    [Documentation]    Invoke subscribe-ynl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:subscribe-ynl
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Unsubscribe_Ynl
    [Arguments]    ${session}
    [Documentation]    Invoke unsubscribe-ynl rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unsubscribe-ynl
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
    BuiltIn.Fail    TODO: to format output data or at least to check the format
    BuiltIn.Return_From_Keyword    ${resp.content}

Rpc_Register_Bound_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke register-bound-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:register-bound-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Unregister_Bound_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke unregister-bound-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unregister-bound-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Register_Default_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke register-default-constant rpc.
    BuiltIn.Fail    TODO: input is missing for the rpc
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:register-default-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200

Rpc_Unregister_Default_Constant
    [Arguments]    ${session}
    [Documentation]    Invoke unregister-default-constant rpc.
    ${resp} =    RequestsLibrary.Post_Request    ${session}    ${URL_PREFIX_C}:unregister-default-constant
    BuiltIn.Should_Be_Equal_As_Integers    ${resp.status_code}    200
