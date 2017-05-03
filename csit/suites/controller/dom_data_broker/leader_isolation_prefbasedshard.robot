*** Settings ***
Documentation     DOMDataBroker testing: Leader Isolation
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The goal is to ensure the datastore succeeds in basic isolation/rejoin scenario,
...               simulating either a network partition, or a prolonged GC pause.
Suite Setup       BuiltIn.Run_Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DdbCommons.Create_Prefix_Based_Shard_And_Verify
Suite Teardown    BuiltIn.Run_Keywords    DdbCommons.Remove_Prefix_Based_Shard_And_Verify
...               AND    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DdbCommons.Leader_Isolation_PrefBasedShard_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Healing_Within_Transaction_Timeout
    [Documentation]    The isolated node (leader) is rejoined as soon as new leader is elected and
    ...    and within transaction timeout.
    ${0}

Healing_After_2x_Transaction_Timeout
    [Documentation]    The isolated node (leader) is rejoined after 2x transaction timeout.
    ${${TRANSACTION_TIMEOUT_2X}+1}
