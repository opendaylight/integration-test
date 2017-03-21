*** Settings ***
Documentation     DOMDataBroker testing: Client Isolation
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The purpose of this test is to ascertain that the failure modes of
...               cds-access-client work as expected. This is performed by having a steady
...               stream of transactions flowing from the frontend and isolating the node hosting
...               the frontend from the rest of the cluster.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Library           ${CURDIR}/../../../libraries/MdsalLowlevelPy.py
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${ID_PREFIX}    blabla
${DURATION}    ${30}
${TRANS_PER_SEC}    ${1000}
${CHAINED_TX}    ${True}
${SIMPLE_TX}    ${False}

*** Test Cases ***
Producer_On_Shard_Leader_Node_ChainedTx
    leader    ${CHAINED_TX}

Producer_On_Shard_Leader_Node_SimpleTx
    leader    ${SIMPLE_TX}

Producer_On_Shard_Non_Leader_Node_ChainedTx
    non-leader    ${CHAINED_TX}

Producer_On_Shard_Non_Leader_Node_SimpleTx
    non-leader    ${SIMPLE_TX}

*** Keywords ***
Test_Scenario
    [Arguments]    ${listener_node_role}    ${trans_chain_flag}
    ${all_indices} =     ClusterManagement.List_All_Indices
    ${leader}    ${follower_list} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=default    shard_type=config    member_index_list=${all_indices}
    ${follower1} =     Collections.Get_From_List    ${follower_list}    ${0}
    ${client_node_dst} =    BuiltIn.Set_Variable_If    "${listener_node_role}" == "leader"    ${leader}    ${follower1}
    ${client_node_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    ${client_node_dst}
    ${client_node_ip_as_list}    BuiltIn.Create_List    ${client_node_ip}
    MdsalLowlevelPy.Initiate_Write_Transactions_On_Nodes    ${client_node_ip_as_list}   ${ID_PREFIX}   ${DURATION}    ${TRANS_PER_SEC}    chained_flag=${trans_chain_flag}
    ${time1}    Set Variable    ${1}
    ${a} =    MdsalLowlevelPy.Wait_For_Write_Transactions
    ClusterManagement.Isolate_Member_From_List_Or_All    ${client_node_dst}
    BuiltIn.Log    $
    #: FOR   ${i}   IN RANGE    6
    #\    Log    ${b.content}
    ${b}      Set Variable     ${a}[3]
    Log    ${b.content}
    MdsalLowlevel.Unsubscribe_Dtcl    ${listener_node_dst}

