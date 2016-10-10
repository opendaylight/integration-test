*** Settings ***
Documentation     Kill nodes, delete all data created since boot, start nodes, wait for sync.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite is useful for undoing feature installation, Leader movement
...               and for recovering from bably broken state.
...               The intent is to provide speed compared to isolated job runs.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      clustering    critical
Library           DateTime
Library           OperatingSystem
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Library           ${CURDIR}/../../../libraries/ConfGen.py
Library           Collections

*** Variables ***
${MODULES_FILE}    modules.conf
${MODULE_SHARDS_FILE}    module-shards.conf
${RIB_SHARD_NAME}    bgp_rib
${RIB_SHARD_NAMESPACE}    urn:opendaylight:params:xml:ns:yang:bgp-rib

*** Test Cases ***
Kill_All_And_Get_Logs
    [Documentation]    Kill every node, download karaf logs.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    member_index_list=${EMPTY}    keyword_name=Download_Karaf_Log

Clean_All
    [Documentation]    Remove various data folders, including ${KARAF_HOME}/data/ on every node.
    ...    Start each memberand wait for sync.
    ClusterManagement.Clean_Directories_On_List_Or_All

Upload_Initial_Config_Files
    [Documentation]    Upload config files for non-replicated bgp_rib
    ${idx}=    Collections.Get_From_List    ${ClusterManagement__member_index_list}    0
    ${idxl}=    BuiltIn.Create_List    ${idx}
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${idxl}    SSHLibrary.Execute_Command    cp `ls ${WORKSPACE}${/}${BUNDLEFOLDER}${/}system${/}org${/}opendaylight${/}controller${/}sal-clustering-config${/}*${/}*-moduleconf.xml` ${WORKSPACE}/${MODULES_FILE}
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${idxl}    SSHLibrary.Execute_Command    cp `ls ${WORKSPACE}${/}${BUNDLEFOLDER}${/}system${/}org${/}opendaylight${/}controller${/}sal-clustering-config${/}*${/}*-moduleshardconf.xml` ${WORKSPACE}/${MODULE_SHARDS_FILE}
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${idxl}    SSHLibrary.Get File    ${WORKSPACE}${/}${MODULES_FILE}    ${CURDIR}${/}${MODULES_FILE}.tmpl
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${idxl}    SSHLibrary.Get File    ${WORKSPACE}${/}${MODULE_SHARDS_FILE}    ${CURDIR}${/}${MODULE_SHARDS_FILE}.tmpl
    ${modules_content}=    ConfGen.Generate_Modules    ${CURDIR}${/}${MODULES_FILE}.tmpl    name=${RIB_SHARD_NAME}    namespace=${RIB_SHARD_NAMESPACE}
    OperatingSystem.Create File    ${CURDIR}${/}${MODULES_FILE}    ${modules_content}
    : FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
    \    ${idxl}=    BuiltIn.Create_List    ${idx}
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${EMPTY}    SSHLibrary.Put File    ${CURDIR}${/}${MODULES_FILE}    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}configuration${/}initial${/}${MODULES_FILE}
    : FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
    \    ${idxl}=    BuiltIn.Create_List    ${idx}
    \    ${ms_content}=    ConfGen.Generate_Module_Shards    ${CURDIR}${/}${MODULE_SHARDS_FILE}.tmpl    nodes=${NUM_ODL_SYSTEM}    shard_name=${RIB_SHARD_NAME}    replicas=${idxl}
    \    OperatingSystem.Create File    ${CURDIR}${/}${MODULE_SHARDS_FILE}    ${ms_content}
    \    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    ${idxl}    SSHLibrary.Put File    ${CURDIR}${/}${MODULE_SHARDS_FILE}    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}configuration${/}initial${/}${MODULE_SHARDS_FILE}

Start_All_And_Sync
    [Documentation]    Start each memberand wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Comment    Basic synch performed, but waits for specific functionality may still be needed.

*** Keywords ***
Download_Karaf_Log
    ${timestamp} =    DateTime.Get_Current_Date    time_zone=UTC    result_format=%Y%m%d%H%M%S%f
    SSHLibrary.Get_File    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}data${/}log${/}karaf.log    karaf_${timestamp}.log
