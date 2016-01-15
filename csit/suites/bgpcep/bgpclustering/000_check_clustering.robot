*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
...
...               Copyright (c) 2015-2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               The purpose is to check the cluster environment before starting.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ClusterKeywords.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${KARAF_LOG_LEVEL}    INFO

*** Test Cases ***

Check_Clustering
    ${controller_index_list}=    ClusterKeywords.Create_Controller_Index_List
    BuiltIn.Log    ${controller_index_list}
    ClusterKeywords.Create_Controller_Sessions
    ${controller_list)=    ClusterKeywords.Get_Controller_List
    BuiltIn.Log    ${controller_list)
    ClusterKeywords.Show_Cluster_Configuation_Files

Check_Default_Shard
    ${shard_name}=    default
    BuiltIn.Log    ${shard_name}
    ${leader_node_ip}=    ClusterKeywords.Get_Leader_And_Verify    shard_name
    BuiltIn.Log    ${leader_node_ip}
    ${follower_nodes_ip}=    ClusterKeywords.Get_All_Followers    shard_name
    BuiltIn.Log    ${follower_nodes_ip}

Check_Topology_Shard
    ${shard_name}=    topology
    BuiltIn.Log    ${shard_name}
    ${leader_node_ip}=    ClusterKeywords.Get_Leader_And_Verify    shard_name
    BuiltIn.Log    ${leader_node_ip}
    ${follower_nodes_ip}=    ClusterKeywords.Get_All_Followers    shard_name
    BuiltIn.Log    ${follower_nodes_ip}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ConfigViaRestconf.Setup_Config_Via_Restconf
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${KARAF_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    # Environment issue may have dropped the SSH connection, but we do not want Teardown to fail.
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections
