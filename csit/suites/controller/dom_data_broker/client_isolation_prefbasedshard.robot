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
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        BuiltIn.Run_Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
...               AND    DdbCommons.Create_Prefix_Based_Shard_And_Verify
Test Teardown     BuiltIn.Run_Keywords    DdbCommons.Remove_Prefix_Based_Shard_And_Verify
...               AND    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DdbCommons.Client_Isolation_PrefBasedShard_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Producer_On_Shard_Leader_Node_Isolated_Transactions
    [Documentation]    Client isolation with producer on shard leader with isolated transactions flag set.
    leader    ${ISOLATED_TRANS_TRUE}

Restart1
    [Documentation]    Restart odl.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Producer_On_Shard_Leader_Node_Nonisolated_Transactions
    [Documentation]    Client isolation with producer on shard leader with isolated transactions flag unset.
    leader    ${ISOLATED_TRANS_FALSE}

Restart2
    [Documentation]    Restart odl.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Producer_On_Shard_Non_Leader_Node_Isolated_Transactions
    [Documentation]    Client isolation with producer on shard non-leader with isolated transactions flag set.
    non-leader    ${ISOLATED_TRANS_TRUE}

Restart3
    [Documentation]    Restart odl
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Producer_On_Shard_Non_Leader_Node_Nonisolated_Transactions
    [Documentation]    Client isolation with producer on shard non-leader with isolated transactions flag unset.
    non-leader    ${ISOLATED_TRANS_FALSE}
