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
...               "odl-integration-compatible-with-all".
Suite Setup       Setup_karaf_hang
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/Setup.Utils.robot    #Suite Teardown    Teardown_Everything    #Library    RequestsLibrary
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/cluster_reset.robot
Resource          ${CURDIR}/../../../libraries/version.robot
Variables         ${CURDIR}/../../../variables/Variables.py
Test Template     Install With Time Limit
*** Variables ***
${KARAF_CHECK_TIMEOUT}    3m

*** Testcases ***
Try_To_Install_Compatible_With_All
    [Arguments]    ${feature_name_list}
    [Documentation]    Try to install current list of compatible features and check whether Karaf hangs on it or not (bug 4462).
    #Use XML Library [0] to parse the local feature file, by default located at
    #${WORKSPACE}/${BUNDLEFOLDER}/system/org/opendaylight/integration/features-integration-test/*/features-integration-test-*-features.xml
    #where * stands for the version string, for example BUNDLEFOLDER value is distribution-karaf-*.
    ${Actual_version}=          BuiltIn.Evaluate    '''${BUNDLEFOLDER}'''[len("distribution-karaf-"):]
    @{feature_name_list}=         Get Elements Texts    ${WORKSPACE}/${BUNDLEFOLDER}/system/org/opendaylight/integration/features-integration-test/${Actual_version}/features-integration-test-${Actual_version}-features.xml    features/feature
    : FOR    ${feature_name}    IN    @{feature_name_list}
    \    Install With Time Limit    ${feature_name}

*** Keywords ***
Setup_karaf_hang
    [Documentation]    Stop Karaf launched by releng/builder scripts, start it by running "bin/karaf clean".
    cluster_reset.Kill_All_And_Get_Logs
    cluster_reset.Clean_Start_All_And_Sync
    SetupUtils.Setup_Utils_For_Setup_And_Teardown

Install With Time Limit
    [Arguments]    ${feature_name}
    [Documentation]    Template for ODL feature:install with the given timeout.
    KarafKeywords.Issue_Command_On_Karaf_Console    feature:install ${feature_name}    ${controller}=${ODL_SYSTEM_IP}    ${karaf_port}=${KARAF_SHELL_PORT}    timeout=${KARAF_CHECK_TIMEOUT}    ${loglevel}=INFO
