*** Settings ***
Documentation     Suite for testing performance of yang-model-validator utility.
...
...               Copyright (c) 2016,2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite measures time (only as a test case duration) needed
...               for yang-model-validator to execute on a set of yang model.
...
...               The set of Yang modules is large and fixed (no changes in future).
...               It is the same set of models as in mdsal binding-parent suite.
Suite Setup       Setup_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing    # TODO: Suite Teardown to close SSH connections and other cleanup?
Test Teardown     Teardown_Test
Default Tags      1node    yang-model-validator    critical
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/RemoteBash.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/YangCollection.robot

*** Variables ***
${EXPLICIT_YANG_SYSTEM_TEST_URL}    ${EMPTY}
${TEST_TOOL_NAME}    yang-model-validator

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL instance consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Prepare_Yang_Files_To_Test
    [Documentation]    Set up collection of Yang files to test with.
    YangCollection.Static_Set_As_Src
    ${dirs_to_process} =    Get_Recursive_Dirs    root=src/main/yang
    ${p_option_value} =    BuiltIn.Catenate    SEPARATOR=:    @{dirs_to_process}
    ${yang_files_to_validate} =    Get_Yang_Files_From_Dirs    ${dirs_to_process}
    BuiltIn.Set_Suite_Variable    ${yang_files_to_validate}
    BuiltIn.Set_Suite_Variable    \${p_option_value}

Deploy_And_Start_Odl_Yang_Validator_Utility
    [Documentation]    Download appropriate version of yang-model-validator artifact
    ...    and run it for each single yang file in the prepared set.
    ...    The version is either given by ${EXPLICIT_YANG_SYSTEM_TEST_URL},
    ...    or constructed from Jenkins-shaped ${BUNDLE_URL}, or downloaded from Nexus based on ODL version.
    ${status}    ${multipatch_url} =    BuiltIn.Run_Keyword_And_Ignore_Error    Construct_Multipatch_Url
    ${url} =    Builtin.Set_Variable_If    "${status}" == "PASS"    ${multipatch_url}    ${EXPLICIT_YANG_SYSTEM_TEST_URL}
    : FOR    ${yang_file}    IN    @{yang_files_to_validate}
    \    ${logfile} =    NexusKeywords.Install_And_Start_Java_Artifact    component=yangtools    artifact=${TEST_TOOL_NAME}    suffix=jar-with-dependencies    tool_options=-p ${p_option_value} ${yang_file}
    \    ...    explicit_url=${url}
    \    BuiltIn.Set_Suite_Variable    \${logfile}
    \    Wait_Until_Utility_Finishes
    \    Check_Return_Code

Collect_Files_To_Archive
    [Documentation]    Download created files so Releng scripts would archive it.
    [Setup]    Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Get_File    ${logfile}

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${TEST_TOOL_NAME}=    CompareStream.Set_Variable_If_At_Most_Carbon    yang-system-test
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage    tools_system_connect=False
    SSHKeywords.Open_Connection_To_ODL_System

Teardown_Test
    [Documentation]    Make sure CWD is set back to dot, then proceed with SetupUtils stuff.
    SSHKeywords.Set_Cwd    .
    SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed

Get_Recursive_Dirs
    [Arguments]    ${root}=.
    [Documentation]    Return list of sub-directories discovered recursively under ${root} relative to
    ...    the current working directory for a new shell spawned over the active SSH session.
    ...    This implementation returns absolute paths as that is easier.
    ${depth_1} =    SSHLibrary.List_Directories_In_Directory    path=${root}    absolute=True
    ${subtrees} =    BuiltIn.Create_List
    : FOR    ${subdir}    IN    @{depth_1}
    \    ${tree} =    Get_Recursive_Dirs    root=${subdir}
    \    # Relative paths would require prepending ${subdir}${/} to each @{tree} element.
    \    Collections.Append_To_List    ${subtrees}    ${tree}
    ${flat_list} =    Collections.Combine_Lists    ${depth_1}    @{subtrees}
    [Return]    ${flat_list}

Get_Yang_Files_From_Dirs
    [Arguments]    ${dirs_to_process}
    [Documentation]    Return list of yang files from provided directories
    ${collected_yang_files} =    BuiltIn.Create_List
    : FOR    ${dir}    IN    @{dirs_to_process}
    \    ${yang_files_in_dir} =    SSHLibrary.List_Files_In_Directory    path=${dir}    pattern=*.yang    absolute=True
    \    ${collected_yang_files} =    Collections.Combine_Lists    ${collected_yang_files}    ${yang_files_in_dir}
    [Return]    ${collected_yang_files}

Construct_Multipatch_Url
    [Documentation]    If ${EXPLICIT_YANG_SYSTEM_TEST_URL} is non-empty, return it. Otherwise:
    ...    Check whether ${BUNDLE_URL} is from multipatch build (or similar maven style job),
    ...    Check whether yang-model-validator was built there as well,
    ...    and return URL with proper version, or fail.
    BuiltIn.Return_From_Keyword_If    """${EXPLICIT_YANG_SYSTEM_TEST_URL}""" != ""    ${EXPLICIT_YANG_SYSTEM_TEST_URL}
    ${marker} =    BuiltIn.Set_Variable    /org.opendaylight.integration$distribution-karaf
    ${is_multipatch} =    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Should_Contain    ${BUNDLE_URL}    ${marker}
    BuiltIn.Should_Be_True    ${is_multipatch}
    ${yst_base_url} =    String.Fetch_From_Left    ${BUNDLE_URL}    ${marker}
    RequestsLibrary.Create_Session    alias=cmu    url=${yst_base_url}
    ${yst_general_uri} =    BuiltIn.Set_Variable    org.opendaylight.yangtools$yang-model-validator/artifact/org.opendaylight.yangtools/yang-model-validator
    ${yst_html} =    TemplatedRequests.Get_From_Uri    ${yst_general_uri}    session=cmu
    # The following two lines are very specific to a particular Jenkins html layout.
    ${yst_almost_version} =    String.Fetch_From_Right    ${yst_html}    <td><a href="
    ${yst_version} =    String.Fetch_From_Left    ${yst_almost_version}    ">
    ${url} =    BuiltIn.Set_Variable    ${yst_base_url}/${yst_general_uri}/${yst_version}/yang-model-validator-${yst_version}-jar-with-dependencies.jar
    BuiltIn.Return_From_Keyword    ${url}

Wait_Until_Utility_Finishes
    [Documentation]    Repeatedly send endline to keep session alive; pass on prompt, fail on timeout.
    RemoteBash.Wait_Without_Idle    60m

Check_Return_Code
    [Documentation]    Get return code of previous command (the utility), pass if it is zero.
    RemoteBash.Check_Return_Code
