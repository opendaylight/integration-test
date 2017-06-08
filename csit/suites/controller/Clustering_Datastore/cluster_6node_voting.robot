*** Settings ***
Documentation     This test waits until cluster appears to be ready.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Intended use is at a start of testplan, so that suites can assume cluster works.
...
...               This suite expects car, people and car-people modules to have separate Shards.
Suite Setup
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Default Tags      clustering    voting    critical
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/ClusterAdmin.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    180s
@{SHARD_NAME_LIST}    car    people    car-people

*** Test Cases ***
Setup_First_Half_Of_Nodes_Voting
    [Documentation]    Sets the first half of nodes voting and the remaining half non-voting.
    Log To Console    Setting first three nodes to Voting
    ${rpc_response}    ClusterAdmin.Change_Member_Voting_States_For_All_Shards_Normal    1
    Log    ${rpc_response}
