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
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           Collections
Library           DateTime
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${TEST_DURATION}    1m
${ACCEPTED_PER_SEC_RATE}    100

*** Test Cases ***
Register_Candidates
    [Documentation]    Register a candidate application on each node which starts the test.
    ${index_list} =    ClusterManagement.List_All_Indices
    : FOR    ${index}    IN    @{index_list}
    \    MdsalLowlevel.Register_Flapping_Singleton    ${index}

Do_Nothing
    [Documentation]    Do nothing for the time of the test duration, because there is no api to monitor the statistics
    ...    during the test execution. Statistics are available only at the end, when unregister-flapping-singleton rpc is
    ...    called.
    BuiltIn.Sleep    ${TEST_DURATION}

Unregister_Candidates_And_Validate_Criteria
    [Documentation]    Unregister the testing service and check recevied statistics.
    ${index_list} =    ClusterManagement.List_All_Indices
    ${movements_count} =    BuiltIn.Set_Variable    ${0}
    : FOR    ${index}    IN    @{index_list}
    \    ${count} =    MdsalLowlevel.Unregister_Flapping_Singleton    ${index}
    \    BuiltIn.Run_Keyword_If    ${count} < 0    BuiltIn.Fail    No failure should have occured during the ${TEST_DURATION} timeout.
    \    ${movements_count} =    BuiltIn.Evaluate    ${movements_count}+${count}
    ${seconds} =    DateTime.Convert_Time    ${TEST_DURATION}
    ${rate} =    BuiltIn.Evaluate    ${movements_count}/${seconds}
    BuiltIn.Run_Keyword_If    ${rate} < ${ACCEPTED_PER_SEC_RATE}    BuiltIn.Fail    Acceptance rate ${ACCEPTED_PER_SEC_RATE} not reached, actual rate is ${rate}.
