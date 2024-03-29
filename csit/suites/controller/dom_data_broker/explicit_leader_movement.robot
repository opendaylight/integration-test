*** Settings ***
Documentation       DOMDataBroker testing: Explicit Leader Movement
...
...                 Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 The goal is to ensure that applications do not observe disruption when a shard
...                 leader is moved as the result of explicit application request. This is performed
...                 by having a steady-stream producer execute operations against the shard and then
...                 initiate shard leader shutdown, then the producer is shut down cleanly.

Library             SSHLibrary
Resource            ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot

Suite Setup         SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown      SSHLibrary.Close_All_Connections
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown       SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Test Template       DdbCommons.Explicit_Leader_Movement_Test_Templ

Default Tags        critical


*** Test Cases ***
Local_To_Remote_Movement
    [Documentation]    Leader moves from local to remote node during transaction producing.
    local    remote
Restart1
    [Documentation]    Restart odl
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ
Remote_To_Remote_Movement
    [Documentation]    Leader moves from one remote to other remote node during transaction producing.
    remote    remote
Restart2
    [Documentation]    Restart odl
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ
Remote_To_Local_Movement
    [Documentation]    Leader moves from remote to local node during transaction producing.
    remote    local
