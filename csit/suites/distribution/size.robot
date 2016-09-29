*** Settings ***
Documentation     Suite for testing ODL distribution zip file size.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Variables needed to be rovided on pybot invocation:
...               ${BUNDLEFOLDER} (directory name of ODL installation, as it is suffxed by the distribution version).
...               This suite assumes the .zip file is stll present on ${ODL_SYSTEM_IP} in ${WORKSPACE} directory.
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      critical    distribution    size
Resource          ${CURDIR}/../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../libraries/SSHKeywords.robot

*** Variables ***
${DISTRIBUTION_SIZE_LIMIT}    469762048    # == 7 * 64 MiB, Nexus limit is 8 * 64 MiB.

*** Test Cases ***
Distribution_Size
    [Documentation]    Run "ls" on ODL_SYSTEM, parze file size and compare to ${DISTRIBUTION_SIZE_LIMIT}.
    SSHKeywords.Open_Connection_To_ODL_System
    # FIXME: Remove the following debug.
    SSHKeywords.Execute_Command_Should_Pass    command=ls -lAn ${WORKSPACE}/
    # Typical filename is: distribution-karaf-0.6.0-20160929.072954-898.zip
    ${ls_output} =    SSHKeywords.Execute_Command_Should_Pass    command=ls -lAn ${WORKSPACE}/${BUNDLEFOLDER}*.zip
    ${size} =    SSHKeywords.Execute_Command_Should_Pass    command=echo '${ls_output}' | cut -d ' ' -f 5
    # The following probably fails of there were multiple *.zip files listed.
    BuiltIn.Should_Be_True    ${size} < ${DISTRIBUTION_SIZE_LIMIT}    Distribution size ${size} is not smaller than limit ${DISTRIBUTION_SIZE_LIMIT}.
