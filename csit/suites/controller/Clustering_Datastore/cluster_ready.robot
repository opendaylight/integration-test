*** Settings ***
Documentation     This test waits until cluster appears to be ready.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Intended use is at a start of testplan, so that suites can assume cluster works.
...
...               This suite expects car, people and car-people modules to have separate Shards.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      clustering    carpeople    critical
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    180s
@{SHARD_NAME_LIST}    car    people    car-people

*** Test Cases ***
Wait_For_Sync_And_Shards
    [Documentation]    Repeatedly check for cluster sync status and Shard Leaders, fail when timeout is exceeded.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_BOOTUP_SYNC_TIMEOUT}    10s    Check_Sync_And_Shards

*** Keywords ***
Check_Sync_And_Shards
    ClusterManagement.Check_Cluster_Is_In_Sync
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_NAME_LIST}    shard_type=config
