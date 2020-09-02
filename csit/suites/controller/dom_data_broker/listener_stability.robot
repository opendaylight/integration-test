*** Settings ***
Documentation     DOMDataBroker testing: Listener Stability for module-based shards
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
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DdbCommons.Listener_Stability_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Move_Leader_From_Listener_Local_To_Remote
    [Documentation]    Listener runs on leader node when leader is moved to remote node.
    local    remote

Restart_1
    [Documentation]    Restart odl.
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ

Move_Leader_From_Listener_Remote_To_Other_Remote
    [Documentation]    Listener runs on follower node when leader is moved to the third node.
    remote    remote

Restart_2
    [Documentation]    Restart odl.
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ

Move_Leader_From_Listener_Remote_To_Local
    [Documentation]    Listener runs on follower node when leader is moved to local node.
    remote    local
