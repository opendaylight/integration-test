*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The purpose is to check the cluster environment before starting.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Do_Not_Start_Failing_If_This_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ClusterKeywords.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${SHARD_DEFAULT_CONFIG}    shard-default-config
${SHARD_DEFAULT_OPERATIONAL}    shard-default-operational
${SHARD_TOPOLOGY_CONFIG}    shard-topology-config
${SHARD_TOPOLOGY_OPERATIONAL}    shard-topology-operational
${CLUSTER_SYNC_TIMEOUT}    60s
${ODL_USER}    admin
${ODL_PASSWORD}    admin

*** Test Cases ***

Check_Cluster_Config
    Show_Cluster_Config    ${controller_list}

Check_Cluster_Sync
    ClusterKeywords.Wait_For_Cluster_Sync    ${CLUSTER_SYNC_TIMEOUT}    ${controller_list}

Check_Default_Shards
    BuiltIn.Log    ${SHARD_DEFAULT_CONFIG}
    ${leader_node_ip}=    ClusterKeywords.Get_Leader_And_Verify    ${SHARD_DEFAULT_CONFIG}
    BuiltIn.Log    ${leader_node_ip}
    ${follower_nodes_ip}=    ClusterKeywords.Get_All_Followers    ${SHARD_DEFAULT_CONFIG}
    BuiltIn.Log    ${follower_nodes_ip}

Check_Topology_Shards
    BuiltIn.Log    ${SHARD_TOPOLOGY_CONFIG}
    ${leader_node_ip}=    ClusterKeywords.Get_Leader_And_Verify    ${SHARD_TOPOLOGY_CONFIG}
    BuiltIn.Log    ${leader_node_ip}
    ${follower_nodes_ip}=    ClusterKeywords.Get_All_Followers    ${SHARD_TOPOLOGY_CONFIG}
    BuiltIn.Log    ${follower_nodes_ip}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    ClusterKeywords.Create_Controller_Sessions
    ${controller_list}=    ClusterKeywords.Get_Controller_List
    Builtin.Set_Suite_Variable    ${controller_list}
    BuiltIn.Log    ${controller_list}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    SSHLibrary.Close_All_Connections

Show_Cluster_Config
    [Arguments]    @{controllers}
    [Documentation]    Prints out the cluster configuration files for one or more controllers.
    Log    controllers: @{controllers}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/akka.conf
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}    ${ODL_USER}    ${ODL_PASSWORD}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/modules.conf
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}    ${ODL_USER}    ${ODL_PASSWORD}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/module-shards.conf
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}    ${ODL_USER}    ${ODL_PASSWORD}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/configuration/initial/jolokia.xml
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}    ${ODL_USER}    ${ODL_PASSWORD}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/etc/initial/org.apache.karaf.management.cfg
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}    ${ODL_USER}    ${ODL_PASSWORD}
    ${cmd} =    Set Variable    cat ${KARAF_HOME}/etc/org.apache.karaf.features.cfg
    : FOR    ${ip}    IN    @{controllers}
    \    Run Command On Remote System    ${ip}    ${cmd}    ${ODL_USER}    ${ODL_PASSWORD}


