*** Settings ***
Documentation     Suite for testing performance of Java binding v1 using binding-parent.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite tests performance of binding-parent from Mdsal project.
...               It measures time (only as a test case duration) needed to create Java bindings (v1).
...               It uses large set of Yang modules, collected from YangModels and openconfig
...               github projects.
...               Some modules are removed prior to testing, as they either do not conform to RFC6020,
...               or they trigger known Bugs in ODL.
...               Known Bugs: 6125, 6135, 6141, 2323, 6150, 2360, 138, 6172, 6180, 6183, 5772, 6189.
...
...               The suite performs installation of Maven, optionally with building patched artifacts.
...
...               FIXME: This suite does not work when run with URL from Autorelease.
...               The thing is, mdsal-parent is not part of .zip distribution.
...               The fix would need to override the usual maven settings,
...               as Autorelease artifacts have non-snapshot versions, but they are not released yet.
Suite Setup       Setup_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     Teardown_Test
Default Tags      1node    binding_v1    critical
Library           SSHLibrary
Library           String
Library           ${CURDIR}/../../../libraries/MdsalUtils.py
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/YangCollection.robot

*** Variables ***
${BRANCH}         ${EMPTY}
${MAVEN_OUTPUT_FILENAME}    maven.log
${PATCHES_TO_BUILD}    ${EMPTY}
${POM_FILENAME}    binding-parent-test.xml

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL instance consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Detect_Config_Version
    [Documentation]    Examine ODL installation to figure out which version of binding-parent should be used.
    ...    Parent poms are not present in Karaf installation, so NexusKeywords search for a component
    ...    associated with bindingv1 nickname.
    ${version}    ${location} =    NexusKeywords.NexusKeywords__Detect_Version_To_Pull    component=bindingv1
    BuiltIn.Set_Suite_Variable    \${binding_parent_version}    ${version}

Install_Maven
    [Documentation]    Install Maven, optionally perform multipatch build.
    NexusKeywords.Install_Maven    branch=${BRANCH}    patches=${PATCHES_TO_BUILD}

Prepare_Yang_Files_To_Test
    [Documentation]    Set up collection of Yang files to test with.
    YangCollection.Static_Set_As_Src

Run_Maven
    [Documentation]    Create pom file with correct version and run maven with some performance switches.
    ${final_pom} =    TemplatedRequests.Resolve_Text_From_Template_File    folder=${CURDIR}/../../../variables/mdsal/binding_v1    file_name=binding_template.xml    mapping={"BINDING_PARENT_VERSION":"${binding_parent_version}"}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    echo '${final_pom}' > '${POM_FILENAME}'
    ${autorelease_dir} =    String.Get_Regexp_Matches    ${url1}    (autorelease-[0-9]+)
    BuiltIn.Run_Keyword_If    ${autorelease_dir} != []    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    sed -i 's/repositories\/public/repositories\/@{autorelease_dir}[0]/g' settings.xml
    NexusKeywords.Run_Maven    pom_file=${POM_FILENAME}    log_file=${MAVEN_OUTPUT_FILENAME}
    # TODO: Figure out patters to identify various known Bug symptoms.

Collect_Filest_To_Archive
    [Documentation]    Download created files so Releng scripts would archive it. Size of maven log is usually under 7 megabytes.
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    SSHKeywords.Open_Connection_To_ODL_System    # The original one may have timed out.
    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Get_File    ${MAVEN_DEFAULT_OUTPUT_FILENAME}    # only present if multipatch build happened
    SSHLibrary.Get_File    settings.xml
    SSHLibrary.Get_File    ${POM_FILENAME}
    SSHLibrary.Get_File    ${MAVEN_OUTPUT_FILENAME}

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
