*** Settings ***
Documentation       Set tell-based protocol usage
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 Suite stops all odl nodes, un-comment usage of tell-based protocol in
...                 config file (means make it true) and starts all nodes again.

Library             SSHLibrary
Resource            ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource            ${CURDIR}/../../../libraries/ShardStability.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/controller/DdbCommons.robot

Suite Setup         SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
Suite Teardown      SSHLibrary.Close_All_Connections

Default Tags        critical


*** Variables ***
${DATASTORE_CFG}    /${WORKSPACE}/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg


*** Test Cases ***
Stop_All_Members
    [Documentation]    Stop every odl node.
    BuiltIn.Sleep    60s
    Run_Keyword_And_Ignore_Error    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Check_Bash_Command_On_List_Or_All    cat /${WORKSPACE}/${BUNDLEFOLDER}/data/log/karaf.log

Set_Tell_Based_Protocol_Usage
    [Documentation]    Un-comment the flag usage in config file. Also clean most data except data/log/.
    DdbCommons.Change_Use_Tell_Based_Protocol    True    ${DATASTORE_CFG}
    ClusterManagement.Check_Bash_Command_On_List_Or_All    cat ${DATASTORE_CFG}
    ClusterManagement.Clean_Directories_On_List_Or_All    tmp_dir=/tmp

Start_All_And_Sync
    [Documentation]    Start each member and wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    300s
    ...    10s
    ...    ShardStability.Shards_Stability_Get_Details
    ...    ${DEFAULT_SHARD_LIST}
    ...    verify_restconf=True
    ClusterManagement.Run_Bash_Command_On_List_Or_All    ps -ef | grep java
