*** Settings ***
Documentation     DOMDataBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/../MdsalLowlevelPy.py
Resource          ${CURDIR}/../ClusterAdmin.robot
Resource          ${CURDIR}/../ClusterManagement.robot
Resource          ${CURDIR}/../MdsalLowlevel.robot

*** Variables ***
${SHARD_NAME}    default
${SHARD_TYPE}    config
${TRANSACTION_RATE}     ${1000}
${TEST_DURATION}      ${30}
${ID_PREFIX}      prefix-

*** Keywords ***
Leader_Movement_Test_Templ
    [Arguments]    ${leader_from}    ${leader_to}
    ${idx_from}   ${idx_to}    ${idx_trans} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}
    MdsalLowlevelPy.Initiate_Write_Transactions_On_Nodes    ${ODL_SYSTEM_${idx_trans}_IP}    ${ID_PREFIX}    ${TEST_DURATION}   ${TRANSACTION_RATE}    chained_flag=${False}
    ClusterAdmin.Make_Leader_Local     ${idx_to}
    ${new_leader}    ${new_followers} =     BuiltIn.Wait_Until_Keyword_Succeeds    10s    1s    ClusterManagement.Verify_Shard_Leader_Elected    ${SHARD_NAME}    ${SHARD_TYPE}    ${True}    ${idx_from}
    BuiltIn.Should_Be_Equal    ${leader_to}    ${new_leader}
    ${resp_list} =    MdsalLowlevelPy.Wait_For_Write_Transactions
    TemplatedRequests.Check_Status_Code    @{resp_list}[0]


Get_Node_Indexes_For_The_ELM_Test
    [Arguments]    ${leader_from}    ${leader_to}
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}
    ${idx_from} =     BuiltIn.Set_Variable    ${leader}
    ${idx_to} =    BuiltIn.Set_Variable    @{follower_list}[0]
    ${idx_trans} =    BuiltIn.Set_Variable_If    "${leader_from}" == "remote" and "${leader_to}" == "remote"    @{follower_list}[1]
    ...                                      "${leader_from}" == "local"     ${leader}
    ...                                      "${leader_to}" == "local"       @{follower_list}[0]


