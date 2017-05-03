*** Settings ***
Documentation     DOMDataBroker testing: Remote Listener
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
Suite Setup       BuiltIn.Run_Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DdbCommons.Create_Prefix_Based_Shard_And_Verify
Suite Teardown    BuiltIn.Run_Keywords    DdbCommons.Remove_Prefix_Based_Shard_And_Verify
...               AND    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DdbCommons.Remote_Listener_PrefBasedShard_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Listener_On_Shard_Leader_Node
    [Documentation]    Listener runs on leader node when leader changed.
    leader

Listener_On_Shard_Non_Leader_Node
    [Documentation]    Listener runs on non-leader node when leader changed.
    non-leader
