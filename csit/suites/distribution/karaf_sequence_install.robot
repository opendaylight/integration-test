*** Settings ***
Documentation     Bug 4462 test suite.
...
...               Copyright (c) 2016-2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Try to detect whether Karaf hangs when trying to install
...               list of features one by one. Default list is odl-integration-compatible-with-all.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Default Tags      critical    distribution    features
Resource          ${CURDIR}/../../libraries/distribution/StreamDistro.robot
Resource          ${CURDIR}/../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../variables/Variables.robot
Library           XML
Library           SSHLibrary

*** Variables ***
${FEATURES_LIST_NAME}    odl-integration-compatible-with-all
${FEATURE_INSTALL_TIMEOUT}    10m

*** Test Cases ***
Install_Features_One_By_One
    [Documentation]    Try to install current list of features and check whether Karaf hangs on it or not (bug 4462).
    SSHKeywords.Open_Connection_To_ODL_System
    ${filename_prefix} =    StreamDistro.Compose_Zip_Filename_Prefix
    ${actual_version} =    BuiltIn.Evaluate    '''${BUNDLEFOLDER}'''[len("${filename_prefix}-"):]
    ${features_test} =    StreamDistro.Compose_Test_Feature_Repo_Name
    SSHLibrary.Get_File    ${WORKSPACE}/${BUNDLEFOLDER}/system/org/opendaylight/integration/${features_test}/${actual_version}/${features_test}-${actual_version}-features.xml    features.xml
    @{features} =    XML.Get_Elements_Texts    features.xml    .feature[@name="${FEATURES_LIST_NAME}"]/feature
    Collections.Log_List    ${features}
    KarafKeywords.Open_Controller_Karaf_Console_With_Timeout    ${1}    ${FEATURE_INSTALL_TIMEOUT}
    FOR    ${feature}    IN    @{features}
        KarafKeywords.Log_Message_To_Controller_Karaf    Installing feature: ${feature}
        KarafKeywords.Install_a_Feature_Using_Active_Connection    ${feature}
    END
