*** Settings ***
Documentation     Cluster Singleton testing: Chasing the Leader
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test aims to establish the service operates correctly when faced with
...               rapid application transitions without having a stabilized application.
Suite Setup       Setup_Keyword
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/controller/CsCommon.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
#${TEST_DURATION}    1m
${TEST_DURATION}    30s
${ACCEPTED_PER_SEC_RATE}    5
# Changed ACCEPTED_PER_SEC_RATE from 50 to 5
# TODO: Use a better wait to start testing when ODL does not use CPU for initializing features. Then inrease rate to 100.

*** Test Cases ***
Register_Candidates
    [Documentation]    Register a candidate application on each node which starts the test.
    CsCommon.Register_Flapping_Singleton_On_Nodes    ${cs_all_indices}

Do_Nothing
    [Documentation]    Do nothing for the time of the test duration, because there is no api to monitor the statistics
    ...    during the test execution. Statistics are available only at the end, when unregister-flapping-singleton rpc is
    ...    called.
    BuiltIn.Sleep    ${TEST_DURATION}

Unregister_Candidates_And_Validate_Criteria
    [Documentation]    Unregister the testing service and check recevied statistics.
    CsCommon.Unregister_Flapping_Singleton_On_Nodes_And_Validate_Results    ${cs_all_indices}    ${ACCEPTED_PER_SEC_RATE}    ${TEST_DURATION}

*** Keywords ***
Setup_Keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
    CsCommon.Cluster_Singleton_Init
