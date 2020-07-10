*** Settings ***
Documentation     DOMDataBroker testing: Clean Leader Shutdown
...           
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...               The goal is to ensure that applications do not observe disruption when a shard
...               leader is shut down cleanly. This is performed by having a steady-stream
...               producer execute operations against the shard and then initiate leader shard
...               shutdown, then the producer is shut down cleanly.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DdbCommons.Clean_Leader_Shutdown_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Local_Leader_Shutdown
    [Documentation]    Shutdown the leader on the same node as transaction producer.
    local

Restart
    [Documentation]    Restart odl
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ

Remote_Leader_Shutdown
    [Documentation]    Shutdown the leader on different node as transaction producer.
    remote
