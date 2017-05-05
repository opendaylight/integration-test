*** Settings ***
Documentation     Cluster Singleton testing: Partition And Heal longevity suite
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
Resource          ${CURDIR}/../../../libraries/controller/CsCommon.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/MdsalLowlevel.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${DURATION_24_HOURS_IN_SECONDS}    86400
${STABILITY_TIMEOUT_ISOLATED}    120s
${STABILITY_TIMEOUT_REJOINED}    60s
@{STATUS_ISOLATED}    ${501}

*** Test Cases ***
CS_Pertition_And_Heal
    [Documentation]    24h lasting suite for isolating the cluster singleton leader repeatedly.
    CsCommon.Register_Singleton_Constant_On_Nodes    ${cs_all_indices}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${DURATION_24_HOURS_IN_SECONDS}    3s    Test_Scenario
    CsCommon.Unregister_Singleton_Constant_On_Nodes    ${cs_all_indices}

*** Keywords ***
Setup_Keyword
    [Documentation]    Suite setup.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=30
    CsCommon.Cluster_Singleton_Init

Test_Scenario
    [Documentation]    Isolate the cluster node which is the owner, wait until the new owner is elected, then rejoin isolated node.
    ...    Monitor the stability of the singleton application and fail the the owner is changed during the monitoring. Monitoring
    ...    is done after the node isolation and after the node rejoin.
    ${owner}    ${candidates}=    CsCommon.Get_And_Save_Present_CsOwner_And_CsCandidates    1
    BuiltIn.Wait_Until_Keyword_Succeeds    6s    2s    CsCommon.Verify_Singleton_Constant_On_Nodes    ${cs_all_indices}    ${CS_CONSTANT_PREFIX}${owner}
    CsCommon.Isolate_Owner_And_Verify_Isolated
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_ISOLATED}    3s    CsCommon.Verify_Singleton_Constant_During_Isolation
    CsCommon.Rejoin_Node_And_Verify_Rejoined
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${STABILITY_TIMEOUT_REJOINED}    3s    CsCommon.Verify_Singleton_Constant_On_Nodes    ${cs_all_indices}    ${CS_CONSTANT_PREFIX}${cs_owner}
