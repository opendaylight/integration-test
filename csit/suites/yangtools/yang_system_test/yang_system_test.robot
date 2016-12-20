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
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/YangCollection.robot

*** Variables ***
${EXPLICIT_YANG_SYSTEM_TEST_URL}    ${EMPTY}

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL instance consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Prepare_Yang_Files_To_Test
    [Documentation]    Set up collection of Yang files to test with.
    YangCollection.Static_Set_As_Src

Deploy_And_Start_Yang_System_Test_Utility
    [Documentation]    Download appropriate version of yang-system-test artifact and start it against the prepared set.
    ...    The version is either given by ${EXPLICIT_YANG_SYSTEM_TEST_URL},
    ...    or constructed from Jenkins-shaped ${BUNDLE_URL}, or downloaded from Nexus based on ODL version.
    ${multipatch_url}    ${status} =    Construct_Multipatch_Url
    ${url} =    Builtin.Set_Variable_If    "${status}" == "PASS"    ${multipatch_url}    ${EXPLICIT_YANG_SYSTEM_TEST_URL}
    ${logfile} =    NexusKeywords.Install_And_Start_Java_Artifact    component=yangtools    artifact=yang-system-test    suffix=jar-with-dependencies    tool_options=-p src/main/yang/standard/ietf/RFC    explicit_url=${url}
    BuiltIn.Set_Suite_Variable    \${logfile}

Wait_Until_Utility_Finishes
    [Documentation]    Repeatedly send endline to keep session alive; pass on prompt, fail on timeout.
    # TODO: Move to SSHKeywords?
    BuiltIn.Wait_Until_Keyword_Succeeds    60m    1s    Wait_Iteration

Check_Return_Code
    [Documentation]    Get return code of previous command (the utility), pass if it is zero.
    SSHLibrary.Read    # Consume eccess prompts
    SSHLibrary.Write    echo \$?
    ${rc} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Should_Be_Equal    0    ${rc}

Collect_Files_To_Archive
    [Documentation]    Download created files so Releng scripts would archive it.
    [Setup]    Setup_Test_With_Logging_And_Without_Fast_Failing
    # SSHKeywords.Open_Connection_To_ODL_System    # The original one may have timed out.
    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Get_File    ${logfile}

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

Wait_Iteration
    [Documentation]    Write endline and wait for prompt.
    SSHLibrary.Write    ${EMPTY}
    # TODO: Configure timeout for Read_Until_Prompt.
    SSHLibrary.Read_Until_Prompt

Construct_Multipatch_Url
    [Documentation]    If ${EXPLICIT_YANG_SYSTEM_TEST_URL} is non-empty, return it. Otherwise:
    ...    Check whether ${BUNDLE_URL} is from multipatch build (or similar maven style job),
    ...    Check whether yang-system-test was built there as well,
    ...    and return URL with proper version, or fail.
    BuiltIn.Return_From_Keyword_If    """${EXPLICIT_YANG_SYSTEM_TEST_URL}""" != ""    ${EXPLICIT_YANG_SYSTEM_TEST_URL}
    ${marker} =    BuiltIn.Set_Variable    org.opendaylight.integration$distribution-karaf
    ${is_multipatch} =    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Should_Contain    ${BUNDLE_URL}    ${marker}
    BuiltIn.Should_Be_True    ${is_multipatch}
    ${url_base} =    String.Fetch_From_Left    ${BUNDLE_URL}    ${marker}
    ${yst_base} =    BuiltIn.Catenate    ${url_base}    org.opendaylight.yangtools$yang-system-test/artifact/org.opendaylight.yangtools/yang-system-test
    ${yst_response} =    RequestsLibrary.Get_Request    url=${yst_base}
    BuiltIn.Should_Be_Equal    ${200}    ${yst_reponse.http_code}
    ${yst_html} =    BuiltIn.Set_Variable    ${yst_response.text}
    BuiltIn.Log    ${yst_html}
    # The following two lines are very specific to a particular Jenkins html layout.
    ${yst_almost_version} =    String.Fetch_From_Left    ${yst_html}    <td><a href="
    ${yst_version} =    String.Fetch_From_Left   ${yst_almost_version}    ">
    ${url} =    BuiltIn.Set_Variable    ${yst_base}/${yst_version}/yang-system-test-${yst_version}-jar-with-dependencies.jar
    BuiltIn.Return_From_Keyword    ${url}
