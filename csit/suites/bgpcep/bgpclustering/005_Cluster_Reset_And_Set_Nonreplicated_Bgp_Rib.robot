*** Settings ***
Documentation     Kill nodes, delete all data created since boot, change cluster configs,
...               start nodes, wait for sync.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
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
Kill_All_Members
    [Documentation]    Kill every node, download karaf logs.
    ClusterManagement.Kill_Members_From_List_Or_All

Store_Karaf_Log_And_Clean_All
    [Documentation]    Remove various data folders, including ${KARAF_HOME}/data/ on every node.
    ...    Start each memberand wait for sync.
    ClusterManagement.Store_Karaf_Log_On_List_Or_All
    ClusterManagement.Clean_Directories_On_List_Or_All
    ClusterManagement.Run_Bash_Command_On_List_Or_All    mkdir -p ${KARAF_HOME}/data/log
    ClusterManagement.Restore_Karaf_Log_On_List_Or_All

Upload_Initial_Config_Files
    [Documentation]    Upload config files for non-replicated bgp_rib
    : FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
    \    ${idxl}=    BuiltIn.Create_List    ${idx}
    \    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    member_index_list=${idxl}    keyword_name=Set_Config_Files_With_Nonreplicated_Rib    index_list=${idxl}

Start_All_And_Sync
    [Documentation]    Start each memberand wait for sync.
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Comment    Basic synch performed, but waits for specific functionality may still be needed.
    BuiltIn.Wait_Until_Keyword_Succeeds    2m    5s    Topology_Available
    ClusterManagement.Run_Bash_Command_On_List_Or_All    ps -ef | grep java

*** Keywords ***
Download_Karaf_Log
    ${timestamp} =    DateTime.Get_Current_Date    time_zone=UTC    result_format=%Y%m%d%H%M%S%f
    SSHLibrary.Get_File    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}data${/}log${/}karaf.log    karaf_${timestamp}.log

Topology_Available
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    1
    TemplatedRequests.Get_As_Json_From_Uri    /restconf/operational/network-topology:network-topology/topology/example-ipv4-topology    session=${session}

Set_Config_Files_With_Nonreplicated_Rib
    [Arguments]    ${index_list}
    ${modules_file}=    SSHLibrary.Execute_Command    ls ${WORKSPACE}${/}${BUNDLEFOLDER}${/}system${/}org${/}opendaylight${/}controller${/}sal-clustering-config${/}*${/}*-moduleconf.xml
    ${module_shards_file}=    SSHLibrary.Execute_Command    ls ${WORKSPACE}${/}${BUNDLEFOLDER}${/}system${/}org${/}opendaylight${/}controller${/}sal-clustering-config${/}*${/}*-moduleshardconf.xml
    SSHLibrary.Get File    ${modules_file}    ${CURDIR}${/}${MODULES_FILE}.tmpl
    SSHLibrary.Get File    ${module_shards_file}    ${CURDIR}${/}${MODULE_SHARDS_FILE}.tmpl
    ${modules_content}=    ConfGen.Generate_Modules    ${CURDIR}${/}${MODULES_FILE}.tmpl    name=${RIB_SHARD_NAME}    namespace=${RIB_SHARD_NAMESPACE}
    ${ms_content}=    ConfGen.Generate_Module_Shards    ${CURDIR}${/}${MODULE_SHARDS_FILE}.tmpl    nodes=${NUM_ODL_SYSTEM}    shard_name=${RIB_SHARD_NAME}    replicas=${index_list}
    OperatingSystem.Create File    ${CURDIR}${/}${MODULES_FILE}    ${modules_content}
    OperatingSystem.Create File    ${CURDIR}${/}${MODULE_SHARDS_FILE}    ${ms_content}
    SSHLibrary.Put File    ${CURDIR}${/}${MODULES_FILE}    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}configuration${/}initial${/}${MODULES_FILE}
    SSHLibrary.Put File    ${CURDIR}${/}${MODULE_SHARDS_FILE}    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}configuration${/}initial${/}${MODULE_SHARDS_FILE}
    ${stdout}    ${stderr}=    SSHLibrary.Execute_Command    cat ${WORKSPACE}${/}${BUNDLEFOLDER}${/}configuration${/}initial${/}${MODULES_FILE}    return_stderr=True
    BuiltIn.Log    ${stdout}
    BuiltIn.Should_Be_Empty    ${stderr}
    ${stdout}    ${stderr}=    SSHLibrary.Execute_Command    cat ${WORKSPACE}${/}${BUNDLEFOLDER}${/}configuration${/}initial${/}${MODULE_SHARDS_FILE}    return_stderr=True
    BuiltIn.Log    ${stdout}
    BuiltIn.Should_Be_Empty    ${stderr}
