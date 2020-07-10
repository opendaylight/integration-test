*** Settings ***
Documentation     Suite for testing ODL distribution zip file size.
...           
...               Copyright (c) 2016-2017 Cisco Systems, Inc. and others. All rights reserved.
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
Resource          ${CURDIR}/../../libraries/distribution/StreamDistro.robot
Resource          ${CURDIR}/../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../libraries/SSHKeywords.robot

*** Variables ***
${BUNDLE_SUFFIX}    .zip
${DISTRIBUTION_SIZE_LIMIT}    469762048    # == 7 * 64 MiB, Nexus limit is 8 * 64 MiB.

*** Test Cases ***
Distribution_Size
    [Documentation]    Run "ls" on ODL_SYSTEM, parse file size and compare to ${DISTRIBUTION_SIZE_LIMIT}.
    SSHKeywords.Open_Connection_To_ODL_System
    ${bundle_prefix} =    StreamDistro.Compose_Zip_Filename_Prefix
    # TODO: 'du -b' is shorter, but gives less info. Is that better than ls?
    ${ls_output} =    SSHKeywords.Execute_Command_Should_Pass    command=bash -c 'ls -lAn ${WORKSPACE}/${bundle_prefix}*${BUNDLE_SUFFIX}'
    ${size} =    SSHKeywords.Execute_Command_Should_Pass    command=echo '${ls_output}' | cut -d ' ' -f 5
    # The following probably fails of there were multiple *.zip files listed.
    BuiltIn.Should_Be_True    ${size} < ${DISTRIBUTION_SIZE_LIMIT}    Distribution size ${size} is not smaller than limit ${DISTRIBUTION_SIZE_LIMIT}.
