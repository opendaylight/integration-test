*** Settings ***
Documentation     DOMDataBroker testing: Explicit Leader Movement
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The goal is to ensure that applications do not observe disruption when a shard
...               leader is moved as the result of explicit application request. This is performed
...               by having a steady-stream producer execute operations against the shard and then
...               initiate shard leader shutdown, then the producer is shut down cleanly.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=30
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${DURATION_24_HOURS_IN_SECONDS}    86400
@{MOVEMENT_DIRECTION_LIST}    remote    local    remote

*** Test Cases ***
Explicit_Leader_Movement_Test
    [Documentation]    Leader move for 24 hours from one node to another
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${DURATION_24_HOURS_IN_SECONDS}    5s    Test_Scenario

*** Keywords ***
Test_Scenario
    [Documentation]    One leader movement scenario based on randomly chosen direction.
    ${node_from}    ${node_to}    BuiltIn.Evaluate    random.sample(${MOVEMENT_DIRECTION_LIST}, 2)    modules=random
    DdbCommons.Explicit_Leader_Movement_Test_Templ    ${node_from}    ${node_to}
