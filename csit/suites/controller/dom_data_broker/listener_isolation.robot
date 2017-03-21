*** Settings ***
Documentation     DOMDataBroker testing: Listener Isolation
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The goal is to ensure listeners do no observe disruption when the leader moves.
...               This is performed by having a steady stream of transactions being observed by
...               the listeners and having the leader move.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     Test_Scenario
Library           Collections
Library           SSHLibrary
Library           ${CURDIR}/../../../libraries/MdsalLowlevelPy.py
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${GRID}    blabla
${DURATION}    ${10}
${TRANS_PER_SEC}    ${1000}
${CHAINED_TX}    ${True}
${SIMPLE_TX}    ${False}

*** Test Cases ***
Listener_On_Shard_Leader_Node
    leader

Listener_On_Shard_Non_Leader_Node
    non-leader

*** Keywords ***
Test_Scenario
    [Arguments]    ${listener_node_role}
    ${all_indices} =     ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=default    shard_type=config    member_index_list=${all_indices}
    ${follower1} =     Collections.Get_From_List    ${follower_list}    ${0}
    ${follower1} =     Collections.Get_From_List    ${follower_list}    ${0}
    ${listener_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    #DdbCommons.Subscribe_Dtcl    ${listener_node_dst}
    ${all_ip_list} =    ClusterManagement.Resolve_IP_Address_For_Members    ${all_indices}
    MdsalLowlevelPy.Initiate_Write_Transactions_On_Nodes    ${all_ip_list}   ${GRID}   ${DURATION}    ${TRANS_PER_SEC}    chained_flag=${SIMPLE_TX}
    #MdsalLowlevel.Become_Module_Leader    ${follower1}
    ${a} =    MdsalLowlevelPy.Wait_For_Write_Transactions
    BuiltIn.Log    ${a}
    #DdbCommons.Unsubscribe_Dtcl    ${listener_node_dst}

