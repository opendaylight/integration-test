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
...               list of compatible features one by one.
Suite Setup       Setup_karaf_hang
Test Template     Install With Time Limit
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../libraries/Utils.robot
Resource          ${CURDIR}/../../variables/Variables.robot
Library           XML

*** Variables ***
${KARAF_CHECK_TIMEOUT}    3m

*** Testcases ***
Try_To_Install_Features_Compatible_With_All
    [Documentation]    Try to install current list of compatible features and check whether Karaf hangs on it or not (bug 4462).
    ${Actual_version}=    BuiltIn.Evaluate    '''${BUNDLEFOLDER}'''[len("distribution-karaf-"):]
    @{feature_name_list}=    XML.Get_Elements_Texts    ${WORKSPACE}/${BUNDLEFOLDER}/system/org/opendaylight/integration/features-integration-test/${Actual_version}/features-integration-test-${Actual_version}-features.xml    features/feature
    : FOR    ${feature_name}    IN    @{feature_name_list}
    \    Install_With_Time_Limit    ${feature_name}

*** Keywords ***
Setup_karaf_hang
    [Documentation]    Stop Karaf launched by releng/builder scripts, start it by running "bin/karaf clean".
    Kill_All_And_Get_Logs
    Clean_Start_All_And_Sync
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Install With Time Limit
    [Arguments]    ${feature_name}
    [Documentation]    Template for ODL feature:install with the given timeout.
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    timeout=${KARAF_CHECK_TIMEOUT}    ${loglevel}=INFO

Kill_All_And_Get_Logs
    [Documentation]    Kill every node, download karaf logs.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Safe_With_Ssh_To_List_Or_All_Run_Keyword    member_index_list=${EMPTY}    keyword_name=Download_Karaf_Log
