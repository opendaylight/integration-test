*** Settings ***
Documentation     Cluster Singleton testing: Partition And Heal
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Cluster Singleton service is designed to ensure that only one instance of
...               an application is registered globally in the cluster.
...               The goal is to establish the service operates correctly in face of node
...               failures.
Suite Setup       Setup_Keyword
Suite Teardown    SSHLibrary.Close_All_Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Resource          ${CURDIR}/CsCommon.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${TEST_DURATION}    5m
${STABILITY_TIMEOUT_ISOLATED}    30s
${STABILITY_TIMEOUT_REJOINED}    15s
@{STATUS_ISOLATED}    ${501}

*** Test Cases ***
Rpc_Provider_Precedence_Longevity
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${TEST_DURATION}    1s    Test_Scenario


*** Keywords ***
Setup_Keyword
    [Documentation]    Suite setup.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    CsCommon.Cluster_Singleton_Init

Test_Scenario
    CsCommon.Register_Singleton_Constant_On_Nodes    ${all_indices}    ${CONSTANT_PREFIX}
    ${owner}    ${candidates}=     CsCommon.Get_And_Save_Present_CsOwner_And_CsCandidates    1
    CsCommon.Verify_Singleton_Constant_On_Nodes    ${all_indices}    ${CONSTANT_PREFIX}${owner}
    CsCommon.Isolate_Owner_And_Verify_Isolated
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_ISOLATED}    3s    CsCommon.Verify_Stability_During_Isolation
    CsCommon.Rejoin_Isolated_Node_And_Verify
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_REJOINED}    3s    CsCommon.Verify_Singleton_Constant_On_Nodes    ${all_indices}    ${CONSTANT_PREFIX}${cs_owner}
    CsCommon.Unregister_Singleton_Constant_On_Nodes    ${all_indices}
