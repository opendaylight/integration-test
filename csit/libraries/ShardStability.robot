*** Settings ***
Documentation     Robot library to monitor shard stability.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This is a "stateful" library to monitor shard leaders and candidates. During the initial phase
...               all leaders and followeres are stored and then checked with new value on verify.
...               TODO: investigate whether pure stateless library would be easier or harder to use.
...
...               Requirements: ClusterManagement.ClusterManagement_Setup must be called before Shard_Stability_Init
...
...               It is possible to use it for stateless comparison.
Library           Collections
Library           String
Resource          ${CURDIR}/ClusterManagement.robot

*** Variables ***
&{stored_details}

*** Keywords ***
Shards_Stability_Init_Details
    [Arguments]    ${shard_list}    ${member_index_list}=${EMPTY}
    [Documentation]    Initialize data for given shards.
    ...    ${shard_list} should be initialized as @{list} shard_name1:shard_type1 shard_name2:shard..
    ${shards_details} =    Shards_Stability_Get_Details    ${shard_list}    member_index_list=${member_index_list}
    BuiltIn.Set_Suite_Variable    ${stored_details}    ${shards_details}

Shards_Stability_Get_Details
    [Arguments]    ${shard_list}    ${member_index_list}=${EMPTY}
    [Documentation]    Return shard details stored in dictionary.
    ...    ${shard_list} should be initialized as @{list} shard_name1:shard_type1 shard_name2:shard..
    &{shards_details}    BuiltIn.Create_Dictionary
    : FOR    ${shard_details}    IN    @{shard_list}
    \    ${shard_name}    ${shard_type}    String.Split_String    ${shard_details}    separator=:
    \    ${leader}    ${followers}    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${shard_name}    shard_type=${shard_type}    member_index_list=${member_index_list}
    \    Collections.Sort_List    ${followers}
    \    Collections.Set_To_Dictionary    ${shards_details}    ${shard_name}_${shard_type}_leader=${leader}
    \    Collections.Set_To_Dictionary    ${shards_details}    ${shard_name}_${shard_type}_followers=${followers}
    BuiltIn.Return_From_Keyword    ${shards_details}

Shards_Stability_Verify
    [Arguments]    ${shard_list}    ${member_index_list}=${EMPTY}
    [Documentation]    Verify that present details as the same as the stored one from Shards_Stability_Init_Details
    ${present_details} =    Shards_Stability_Get_Details    ${shard_list}    member_index_list=${member_index_list}
    Shards_Stability_Compare_Same    ${present_details}

Shards_Stability_Compare_Same
    [Arguments]    ${details}    ${stateless_details}=${EMPTY}
    [Documentation]    Compare two distionaries created by Shards_Stability_Get_Details
    ${exp_details} =    BuiltIn.Set_Variable_If    "${stateless_details}" == "${EMPTY}"    ${stored_details}    ${stateless_details}
    Collections.Log_Dictionary    ${exp_details}
    Collections.Log_Dictionary    ${details}
    Collections.Dictionaries_Should_Be_Equal    ${exp_details}    ${details}
