*** Settings ***
Documentation     Suite for testing performance of yang-system-test utility.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite measures time (only as a test case duration) needed
...               for yang-system-test to execute on a set of yang model.
...
...               The set of Yang modules is large and fixed (no changes in future).
...               It is the same set of models as in mdsal binding-parent suite.
Suite Setup       Setup_Suite
# TODO: Suite Teardown to close SSH connections and other cleanup?
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     Teardown_Test
Default Tags      1node    yang_system_test    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/YangCollection.robot

*** Variables ***

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL instance consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Prepare_Yang_Files_To_Test
    [Documentation]    Set up collection of Yang files to test with.
    YangCollection.Static_Set_As_Src

Deploy_Yang_System_Test_Utility
    [Documentation]    Download appropriate version of yang-system-test artifact.
    NexusKeywords.Deploy_Test_Tool   component=yangtools    artifact=yang-system-test    suffix=

Run_Utility
    [Documentation]    FIXME: Write.
    BuiltIn.Fail    This test case is not implemented yet.

Collect_Filest_To_Archive
    [Documentation]    Download created files so Releng scripts would archive it. Size of maven log is usually under 7 megabytes.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SSHKeywords.Open_Connection_To_ODL_System    # The original one may have timed out.
    # BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Get_File    ${MAVEN_DEFAULT_OUTPUT_FILENAME}    # only present if multipatch build happened
    # SSHLibrary.Get_File    settings.xml
    # SSHLibrary.Get_File    ${POM_FILENAME}
    # SSHLibrary.Get_File    ${MAVEN_OUTPUT_FILENAME}

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage    tools_system_connect=False
    SSHKeywords.Open_Connection_To_ODL_System

Teardown_Test
    [Documentation]    Make sure CWD is set back to dot, then proceed with SetupUtils stuff.
    SSHKeywords.Set_Cwd    .
    SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
