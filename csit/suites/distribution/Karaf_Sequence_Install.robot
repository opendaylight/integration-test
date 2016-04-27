*** Settings ***
Documentation     Bug 4462 test suite.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Try to detect whether Karaf hangs when trying to install
...               list of features one by one. Default list is odl-integration-compatible-with-all.
Suite Setup       Setup_Clean_Karaf
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../variables/Variables.robot
Library           XML
Library           SSHLibrary
Default Tags      critical    distribution    features

*** Variables ***
${FEATURES_LIST_NAME}    odl-integration-compatible-with-all
${FEATURE_INSTALL_TIMEOUT}    10m

*** Testcases ***
Install_Features_One_By_One
    [Documentation]    Try to install current list of compatible features and check whether Karaf hangs on it or not (bug 4462).
    SSHKeywords.Open_Connection_To_ODL_System
    ${actual_version}=    BuiltIn.Evaluate    '''${BUNDLEFOLDER}'''[len("distribution-karaf-"):]
    SSHLibrary.Get_File    ${WORKSPACE}/${BUNDLEFOLDER}/system/org/opendaylight/integration/features-integration-test/${actual_version}/features-integration-test-${actual_version}-features.xml    features.xml
    @{features}=    XML.Get_Elements Texts    features.xml    .feature[@name="${FEATURES_LIST_NAME}"]/feature
    Collections.Log_List    ${features}
    KarafKeywords.Configure_Timeout_For_Karaf_Console    ${FEATURE_INSTALL_TIMEOUT}
    :FOR    ${feature}    IN    @{features}
    \    KarafKeywords.Log_Message_To_Controller_Karaf    Installing feature: ${feature}
    \    KarafKeywords.Execute_Controller_Karaf_Command_With_Retry_On_Background    feature:install ${feature}

*** Keywords ***
Setup_Clean_Karaf
    [Documentation]    Stop Karaf launched by releng/builder scripts, start it by running "bin/karaf clean".
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Kill_All_And_Get_Logs
    Clean_Start_All_And_Sync

Kill_All_And_Get_Logs
    [Documentation]    Kill every node, download karaf logs.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    member_index_list=${EMPTY}    keyword_name=Download_Karaf_Log

Download_Karaf_Log
    ${timestamp} =    DateTime.Get_Current_Date    time_zone=UTC    result_format=%Y%m%d%H%M%S%f
    SSHLibrary.Get_File    ${WORKSPACE}${/}${BUNDLEFOLDER}${/}data${/}log${/}karaf.log    karaf_${timestamp}.log

Clean_Start_All_And_Sync
    [Documentation]    Remove various data folders, including ${KARAF_HOME}/data/ on every node.
    ...    Start each memberand wait for sync.
    ClusterManagement.Clean_Directories_On_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    BuiltIn.Comment    Basic synch performed, but waits for specific functionality may still be needed.
