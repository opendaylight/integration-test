*** Settings ***
Documentation       Suite for testing performance of yang-model-validator utility.
...
...                 Copyright (c) 2016,2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This suite executes the yang-model-validator tool and will turn up any major
...                 breakages in that tool. Since yangtools is now a release integrated project
...                 and the version of the tool is static and unchanging per release, this suite
...                 does not need to run very often.
...
...                 Two main things to check for this suite and the yang-model-validator tool:
...
...                 1) Does it work against the updated yang model repos (see YangCollection.robot)
...                 and report valid issues in those models. When the models are updated, does
...                 the tool still work as expected.
...
...                 2) What does the runtime of the tool look like as new versions of the tool are
...                 released? Does validation take significanltly shorter (an improvement) or
...                 longer (a regression)?
...
...                 The set of Yang modules is large and fixed to specific commits from their relevant
...                 repos. That fixed point can be updated periodically in the YangCollection.robot
...                 library. Just be sure there is an apples to apples comparision (same exact repo
...                 state) between yangtools releases, so #2 above is known.
...

Library             RequestsLibrary
Library             SSHLibrary
Library             String
Resource            ${CURDIR}/../../../libraries/CompareStream.robot
Resource            ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource            ${CURDIR}/../../../libraries/RemoteBash.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../../libraries/YangCollection.robot

Suite Setup         Setup_Suite
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown       Teardown_Test

Default Tags        1node    yang-model-validator    critical


*** Variables ***
${TEST_TOOL_NAME}                   yang-model-validator
${EXPLICIT_YANG_SYSTEM_TEST_URL}    ${EMPTY}


*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL instance consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Prepare_Yang_Files_To_Test
    [Documentation]    Set up collection of Yang files to test with, manually deleting any files/paths
    ...    that have known breakages that are issues with the models (not the validator tool).
    YangCollection.Static_Set_As_Src
    YangCollection.Delete_Static_Paths

Deploy_And_Start_Odl_Yang_Validator_Utility
    [Documentation]    Download appropriate version of ${TEST_TOOL_NAME} artifact
    ...    and run it for each single yang file in the prepared set.
    ...    The version is either given by ${EXPLICIT_YANG_SYSTEM_TEST_URL},
    ...    or constructed from Jenkins-shaped ${BUNDLE_URL}, or downloaded from Nexus based on ODL version.
    ${dirs_to_process} =    Get_Recursive_Dirs    root=src/main/yang
    ${yang_files_to_validate} =    Get_Yang_Files_From_Dirs    ${dirs_to_process}
    ${yang_path_option} =    Get_Yang_Model_Validator_Path_Option    ${YANG_MODEL_PATHS}
    FOR    ${yang_file}    IN    @{yang_files_to_validate}
        Log To Console    working on: ${yang_file}
        ${logfile} =    NexusKeywords.Install_And_Start_Java_Artifact
        ...    component=yangtools
        ...    artifact=${TEST_TOOL_NAME}
        ...    suffix=jar-with-dependencies
        ...    tool_options=${yang_path_option} -- ${yang_file}
        ...    explicit_url=${EXPLICIT_YANG_SYSTEM_TEST_URL}
        Wait_Until_Utility_Finishes
        Check_Return_Code
    END
    [Teardown]    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Get_File    ${logfile}


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

Get_Recursive_Dirs
    [Documentation]    Return list of sub-directories discovered recursively under ${root} relative to
    ...    the current working directory for a new shell spawned over the active SSH session.
    ...    This implementation returns absolute paths as that is easier.
    [Arguments]    ${root}=.
    ${depth_1} =    SSHLibrary.List_Directories_In_Directory    path=${root}    absolute=True
    ${subtrees} =    BuiltIn.Create_List
    FOR    ${subdir}    IN    @{depth_1}
        ${tree} =    Get_Recursive_Dirs    root=${subdir}
        # Relative paths would require prepending ${subdir}${/} to each @{tree} element.
        Collections.Append_To_List    ${subtrees}    ${tree}
    END
    ${flat_list} =    Collections.Combine_Lists    ${depth_1}    @{subtrees}
    RETURN    ${flat_list}

Get_Yang_Files_From_Dirs
    [Documentation]    Return list of yang files from provided directories
    [Arguments]    ${dirs_to_process}
    ${collected_yang_files} =    BuiltIn.Create_List
    FOR    ${dir}    IN    @{dirs_to_process}
        ${yang_files_in_dir} =    SSHLibrary.List_Files_In_Directory    path=${dir}    pattern=*.yang    absolute=True
        ${collected_yang_files} =    Collections.Combine_Lists    ${collected_yang_files}    ${yang_files_in_dir}
    END
    RETURN    ${collected_yang_files}

Get_Yang_Model_Validator_Path_Option
    [Documentation]    Return the path option for yang-model-validator from the provided list of YANG paths.
    [Arguments]    ${yang_paths}
    ${separator} =    CompareStream.Set_Variable_If_At_Most_Sulfur    :    ${SPACE}
    ${path_option} =    Evaluate    "${separator}".join(${yang_paths})
    ${path_option} =    Catenate    SEPARATOR=${SPACE}    --path    ${path_option}
    RETURN    ${path_option}

Wait_Until_Utility_Finishes
    [Documentation]    Repeatedly send endline to keep session alive; pass on prompt, fail on timeout.
    RemoteBash.Wait_Without_Idle    60m

Check_Return_Code
    [Documentation]    Get return code of previous command (the utility), pass if it is zero.
    RemoteBash.Check_Return_Code
