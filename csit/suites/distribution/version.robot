*** Settings ***
Documentation     Suite for testing ODL distribution ability to report ist version via Restconf.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Features needed to be installed:
...               odl-distribution-version (the main feature, defines the version string holder as a config module)
...               odl-netconf-connector (controller-config device is used to access the config subsystem)
...               odl-restconf (or odl-restconf-noauth, to get restconf access to the data mounted by controller-config)
...
...               Variables needed to be rovided on pybot invocation:
...               ${BUNDLEFOLDER} (directory name of ODL installation, as it is suffxed by the distribution version)
...
...               This suite require both Restconf and Netconf-connector to be ready,
...               so it is recommended to run netconfready.robot before running this suite.
Suite Setup       Suite_Setup
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical
Resource          ${CURDIR}/../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../libraries/SetupUtils.robot

*** Variables ***
${VERSION_VARDIR}    ${CURDIR}/../../variables/distribution/version

*** Test Cases ***
Distribution_Version
    [Documentation]    Get version string as a part of ${BUNDLEFOLDER} and match with what RESTCONF says.
    # ${BUNDLEFOLDER} typically looks like this: distribution-karaf-0.5.0-SNAPSHOT
    ${version} =    BuiltIn.Evaluate    '''${BUNDLEFOLDER}'''[len("distribution-karaf-"):]
    TemplatedRequests.Get_As_Json_Templated    folder=${VERSION_VARDIR}    mapping={"VERSION":"${version}"}    verify=True

*** Keywords ***
Suite_Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
