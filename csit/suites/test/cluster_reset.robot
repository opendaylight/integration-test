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
...           
...               FIXME: Import improvements from suites manipulating tell-based protocol setting.
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      clustering    critical
Library           DateTime
Library           SSHLibrary
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot

*** Test Cases ***
Kill_All_And_Get_Logs
    [Documentation]    Kill every node, download karaf logs.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    member_index_list=${EMPTY}    keyword_name=Download_Karaf_Log

Clean_Start_All_And_Sync
    [Documentation]    Remove various data folders, including ${KARAF_HOME}/data/ on every node.
    ...    Start each memberand wait for sync.
    ClusterManagement.Clean_Directories_On_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Comment    Basic synch performed, but waits for specific functionality may still be needed.

*** Keywords ***
Download_Karaf_Log
    ${timestamp} =    DateTime.Get_Current_Date    time_zone=UTC    result_format=%Y%m%d%H%M%S%f
    SSHLibrary.Get_File    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}data${/}log${/}karaf.log    karaf_${timestamp}.log
