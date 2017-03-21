*** Settings ***
Documentation     DOMDataBroker testing: Common keywords
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           ${CURDIR}/../MdsalLowlevelPy.py
Resource          ${CURDIR}/../MdsalLowlevel.robot

*** Variables ***
${SHARD_NAME}    default
${SHARD_TYPE}    config

*** Keywords ***
Leader_Movement_Test_Templ
    [Argumenrs]    ${leader_from}    ${leader_to}
    ${idx_from}   ${idx_to}    ${idx_trans} =    Get_Node_Indexes_For_The_ELM_Test    ${leader_from}    ${leader_to}
    MdsalLowlevel.Start_Write_Transactions    ${idx_trans}   some params
    ${active}     MdsalLowlevel.Check_Write_Transactions     ${idx_trans}
    MdsalLowlevel.change leade
    WUKS wait leader change
    WUKS Check_Producer_Finihed_Well


Get_Node_Indexes_For_The_ELM_Test
    [Argumenrs]    ${leader_from}    ${leader_to}
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}
    ${idx_from} =     BuiltIn.Set_Variable    ${leader}
    ${idx_to} =    BuiltIn.Set_Variable    @{follower_list}[0]
    ${idx_trans} =    BuiltIn.Set_Variable_If    "${leader_from}" == "remote" and ${leader_to}" == "remote"    @{follower_list}[1]
    ...                                      "${leader_from}" == "local"     ${leader}
    ...                                      "${leader_to}" == "local"       @{follower_list}[0]


Check_Producer_Finihed_Well
