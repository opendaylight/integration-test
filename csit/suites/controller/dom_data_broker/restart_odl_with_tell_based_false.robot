*** Settings ***
Documentation     Unset tell-based protocol usage
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Suite stops all odl nodes, outcomment usage of tell-based protocol in
...               config file (means make it false by default) and starts all nodes again.
Suite Setup       BuiltIn.Run_Keywords    ClusterManagement.ClusterManagement_Setup    http_timeout=10
...               AND    SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    SSHLibrary.Close_All_Connections
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/ShardStability.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot

*** Variables ***
${DATASTORE_CFG}    /${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg

*** Test Cases ***
Kill_All_Members
    [Documentation]    Kill every odl node.
    ClusterManagement.Kill_Members_From_List_Or_All

Unset_Tell_Based_Protocol_Usage
    [Documentation]    Comment out the flag usage in config file. Also clean most data except data/log/.
    ClusterManagement.Check_Bash_Command_On_List_Or_All    sed -ie "s/use-tell-based-protocol=/#use-tell-based-protocol=/g" ${DATASTORE_CFG}
    ClusterManagement.Check_Bash_Command_On_List_Or_All    cat ${DATASTORE_CFG}
    ClusterManagement.Clean_Directories_On_List_Or_All    tmp_dir=/tmp

Start_All_And_Sync
    [Documentation]    Start each member and wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds    300s    10s    ShardStability.Shards_Stability_Get_Details    ${DEFAULT_SHARD_LIST}
    ClusterManagement.Run_Bash_Command_On_List_Or_All    ps -ef | grep java
