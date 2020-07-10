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
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Test Template     DdbCommons.Client_Isolation_Test_Templ
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/DdbCommons.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Test Cases ***
Producer_On_Shard_Leader_Node_ChainedTx
    [Documentation]    Client isolation with producer on shard leader with chained transactions.
    leader    ${CHAINED_TX}

Restart1
    [Documentation]    Restart odl
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ

Producer_On_Shard_Leader_Node_SimpleTx
    [Documentation]    Client isolation with producer on shard leader with simple transactions.
    leader    ${SIMPLE_TX}

Restart2
    [Documentation]    Restart odl
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ

Producer_On_Shard_Non_Leader_Node_ChainedTx
    [Documentation]    Client isolation with producer on shard non-leader with chained transactions.
    non-leader    ${CHAINED_TX}

Restart3
    [Documentation]    Restart odl
    [Template]    ${EMPTY}
    DdbCommons.Restart_Test_Templ

Producer_On_Shard_Non_Leader_Node_SimpleTx
    [Documentation]    Client isolation with producer on shard non-leader with simple transactions.
    non-leader    ${SIMPLE_TX}
