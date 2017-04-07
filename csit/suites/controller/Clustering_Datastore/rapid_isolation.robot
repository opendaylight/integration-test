*** Settings ***
Documentation     Suite for performing member isolation and rejoin in relatively quick succession.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               The failure state is Jolokia 404, unable to confirm cluster is in sync.
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Default Tags      clustering    carpeople    critical
Library           Collections
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Round_1_Member_1
    [Documentation]    Isolate and rejoin member-1.
    Scenario    1

Round_1_Member_2
    [Documentation]    Isolate and rejoin member-2.
    Scenario    2

Round_1_Member_3
    [Documentation]    Isolate and rejoin member-3.
    Scenario    3

Round_2_Member_1
    [Documentation]    Isolate and rejoin member-1.
    Scenario    1

Round_2_Member_2
    [Documentation]    Isolate and rejoin member-2.
    Scenario    2

Round_2_Member_3
    [Documentation]    Isolate and rejoin member-3.
    Scenario    3

*** Keywords ***
Setup
    [Documentation]    Initialize resources, memorize car shard leader and followers.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Teardown
    [Documentation]    Clear IPTables in all nodes.
    ClusterManagement.Flush_Iptables_From_List_Or_All

Scenario
    [Arguments]    ${isolated_member_index}
    [Documentation]    Isolate member, wait for the rest of the cluster become in sync, rejoin, wait for whole cluster become in sync.
    ${isol} =    BuiltIn.Convert_To_Integer    ${isolated_member_index}
    ${alive} =    ClusterManagement.List_All_Indices
    ClusterManagement.Isolate_Member_From_List_Or_All    ${isol}
    Collections.Remove_Values_From_List    ${alive}    ${isol}
    ClusterManagement.Wait_For_Cluster_In_Sync    delay=1s    member_index_list=${alive}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${isol}
    ClusterManagement.Wait_For_Cluster_In_Sync    delay=1s
