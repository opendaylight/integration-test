*** Settings ***
Documentation     Suite for testing upgrading persisted data from earlier release.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite kills the running ODL at default location.
...               It then installs (configurable) older ODL to alternative location,
...               pushes large amount of car/people data, verifies and kills ODL.
...               The jornal and snapshot files are transferred to default locaton
...               and the original ODL is started.
...               Then it is verified the config data is still present.
...
...               This is 1-node suite, but it still uses ClusterManagement.Check_Cluster_Is_In_Sync
...               in order to detect the same sync condition as 3-node suite would do.
...               Jolokia feature is required for that.
...               TODO: Write minimal feature list?
...
...               TODO: Make ClusterManagement preserve active SSH connection.
...
...               FIXME: Unify usage of alternative, incumbent, older, old, newer, new, original, vanilla, previous (and similar).
Suite Setup       Setup_Suite
Default Tags      1node    carpeople    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    180s
${PREVIOUS_ODL_RELEASE_ZIP_URL}    https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/0.4.1-Beryllium-SR1/distribution-karaf-0.4.1-Beryllium-SR1.zip
${ALTERNATIVE_BUNDLEFOLDER_PARENT}    /tmp/old    # Not a typo, an older version of ODL would come there.
${AMOUNT}         1000
${CAR_VAR_DIR}    ${CURDIR}/../../../variables/carpeople/libtest/cars

*** Test Cases ***
Kill_Original_Odl
    [Documentation]    The ODL prepared by releng/builder is the newer one, kill it.
    ...    Also, remove journal and snapshots.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All

Install_Older_Odl
    [Documentation]    Download .zip, unpack, delete .zip, copy featuresBoot line.
    SSHLibrary.Switch_Connection    ${odl_system_ssh_index}
    # Download.
    SSHKeywords.Execute_Command_Should_Pass    mkdir -p "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && rm -rf * && wget -N "${PREVIOUS_ODL_RELEASE_ZIP_URL}"    stderr_must_be_empty=False
    # Unzip and detect bundle folder name.
    ${alternative_bundlefolder} =    SSHKeywords.Execute_Command_Should_Pass    cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && unzip *.zip && rm *.zip && ls -1
    BuiltIn.Set_Suite_Variable    \${alternative_bundlefolder}    ${alternative_bundlefolder}
    # TODO: Add stricter checks. Folder should have single line, without .zip extension.
    # Extract featuresBoot lines.
    ${cfg} =    BuiltIn.Set_Variable    org.apache.karaf.features.cfg
    ${cfg_orig} =    BuiltIn.Set_Variable    ${WORKSPACE}/${BUNDLEFOLDER}/etc/${cfg}
    ${cfg_vanilla} =    BuiltIn.Set_Variable    ${alternative_bundlefolder}/etc/${cfg}
    ${vanilla_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_vanilla}" | grep -v 'featuresBootAsynchronous'
    ${orig_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_orig}" | grep -v 'featuresBootAsynchronous'
    # Replace the newly installed line.
    SSHKeywords.Execute_Command_Should_Pass    sed -i 's/${vanilla_line}/${orig_line}/g' "${cfg_vanilla}"
    ${updated_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_vanilla}" | grep -v 'featuresBootAsynchronous'
    BuiltIn.Should_Not_Be_Equal    ${vanilla_line}    ${new_line}

Start_Older_Odl
    [Documentation]    Start older ODL on background.
    ClusterManagement.Start_Members_From_List_Or_All    karaf_home=${alternative_bundlefolder}

Wait_For_Older_Sync
    [Documentation]    Repeatedly check for cluster sync status, fail when timeout is exceeded.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_BOOTUP_SYNC_TIMEOUT}    10s    Check_Sync

Add_Data
    [Documentation]    Put car data to config datastore.
    TemplatedRequests.Put_As_Json_Templated    folder=${CAR_VAR_DIR}   iterations=${AMOUNT}
    # TODO: Do we need to verify the data is really there?

Kill_Older_Odl
    [Documentation]    Kill the ODL immediatelly.
    # TODO: Perhaps we need to wait few seconds?
    ClusterManagement.Kill_Members_From_List_Or_All

Transfer_Persisted_Data
    [Documentation]    Move snapshots and journal into the original ODL installation.
    SSHLibrary.Switch_Connection    ${odl_system_ssh_index}
    SSHKeywords.Execute_Command_Should_Pass    mv "${alternative_bundlefolder}/snapshots" "${WORKSPACE}/${BUNDLEFOLDER}/" && mv "${alternative_bundlefolder}/journal" "${WORKSPACE}/${BUNDLEFOLDER}/"

Start_Newer_Odl
    [Documentation]    Start newer ODL on background.
    ClusterManagement.Start_Members_From_List_Or_All

Wait_For_Newer_Sync
    [Documentation]    Repeatedly check for cluster sync status, fail when timeout is exceeded.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_BOOTUP_SYNC_TIMEOUT}    10s    Check_Sync

Verify_Data_Is_Restored
    [Documentation]    Get car data from config datastore and verify it matches what was put there.
    TemplatedRequests.Get_As_Json_Templated    folder=${CAR_VAR_DIR}   iterations=${AMOUNT}    verify=True

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection.
    ClusterManagement.ClusterManagement_Setup
    TemplatedRequests.Create_Default_Session
    ${connection} =    SSHKeywords.Open_Connection_To_ODL_System
    BuiltIn.Set_Suite_Variable    \${odl_system_ssh_index}    ${connection}

Check_Sync
    [Documentation]    Call ClusterManagement keyword.
    ...    FIXME: Eliminate if there is no additional logic in final suite.
    ClusterManagement.Check_Cluster_Is_In_Sync
