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
...               pushes large amount of car data, verifies and kills ODL.
...               The journal and snapshot files are transferred to default location
...               and the original ODL is started.
...               Then it is verified the config data is still present.
...
...               This is 1-node suite, but it still uses ClusterManagement.Check_Cluster_Is_In_Sync
...               in order to detect the same sync condition as 3-node suite would do.
...               Jolokia feature is required for that.
...               TODO: Write minimal feature list?
...
...               FIXME: Unify usage of alternative, incumbent, older, old, newer, new, original, vanilla, previous (and similar).
Suite Setup       Setup_Suite
Default Tags      1node    carpeople    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    1200s    # Rebooting after kill may take longer time.
${PREVIOUS_ODL_RELEASE_ZIP_URL}    https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/0.4.2-Beryllium-SR2/distribution-karaf-0.4.2-Beryllium-SR2.zip
${ALTERNATIVE_BUNDLEFOLDER_PARENT}    /tmp/old    # Not a typo, an older version of ODL would come there.
${SEGMENT_SIZE}    10000
${ITERATIONS}     1000
${MOVE_PER_ITER}    1000
${CAR_VAR_DIR}    ${CURDIR}/../../../variables/carpeople/libtest/cars

*** Test Cases ***
Kill_Original_Odl
    [Documentation]    The ODL prepared by releng/builder is the newer one, kill it.
    ...    Also, remove journal and snapshots.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All

Install_Older_Odl
    [Documentation]    Download .zip, unpack, delete .zip, copy featuresBoot line.
    # SSHLibrary.Switch_Connection    ${odl_system_ssh_index}
    # Download.
    SSHKeywords.Execute_Command_Should_Pass    mkdir -p "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && rm -rf * && wget -N "${PREVIOUS_ODL_RELEASE_ZIP_URL}"    stderr_must_be_empty=False
    # Unzip and detect bundle folder name.
    ${bundle_dir} =    SSHKeywords.Execute_Command_Should_Pass    cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && unzip -q *.zip && rm *.zip && ls -1
    BuiltIn.Set_Suite_Variable    \${alternative_bundlefolder}    ${ALTERNATIVE_BUNDLEFOLDER_PARENT}/${bundle_dir}
    # TODO: Add more strict checks. Folder should have single line, without .zip extension.
    # Extract featuresBoot lines.
    ${cfg} =    BuiltIn.Set_Variable    org.apache.karaf.features.cfg
    ${cfg_orig} =    BuiltIn.Set_Variable    ${WORKSPACE}/${BUNDLEFOLDER}/etc/${cfg}
    ${cfg_vanilla} =    BuiltIn.Set_Variable    ${alternative_bundlefolder}/etc/${cfg}
    ${vanilla_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_vanilla}" | grep -v 'featuresBootAsynchronous'
    ${orig_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_orig}" | grep -v 'featuresBootAsynchronous'
    # Replace the newly installed line.
    SSHKeywords.Execute_Command_Should_Pass    sed -i 's/${vanilla_line}/${orig_line}/g' "${cfg_vanilla}"
    ${updated_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_vanilla}" | grep -v 'featuresBootAsynchronous'
    BuiltIn.Should_Not_Be_Equal    ${vanilla_line}    ${updated_line}
    BuiltIn.Should_Be_Equal    ${orig_line}    ${updated_line}

Start_Older_Odl
    [Documentation]    Start older ODL on background.
    [Tags]    1node    carpeople    # Not critical, to save space in default log.html presentation
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True    timeout=${CLUSTER_BOOTUP_SYNC_TIMEOUT}    karaf_home=${alternative_bundlefolder}

Add_Data
    [Documentation]    Put car data to config datastore.
    # SSHLibrary.Switch_Connection    ${odl_system_ssh_index}
    ${command} =    BuiltIn.Set_Variable    python patch_cars_sr2.py --segment-size=${SEGMENT_SIZE} --iterations=${ITERATIONS} --move-per-iter=${MOVE_PER_ITER}
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    Check_Script_Results    ${stdout}    ${stderr}    ${rc}
    ${first_id} =    BuiltIn.Evaluate    (${ITERATIONS} - 1) * ${MOVE_PER_ITER} + 1
    # # TODO: Do we need to verify the data is really there?
    ${data} =    TemplatedRequests.Get_As_Json_Templated    folder=${CAR_VAR_DIR}    verify=True    iterations=${SEGMENT_SIZE}    iter_start=${first_id}
    BuiltIn.Set_Suite_Variable    \${data_before}    ${data}

Kill_Older_Odl
    [Documentation]    Kill the ODL immediatelly.
    # TODO: Perhaps we need to wait few seconds?
    ClusterManagement.Kill_Members_From_List_Or_All

Transfer_Persisted_Data
    [Documentation]    Move snapshots and journal into the original ODL installation.
    # SSHLibrary.Switch_Connection    ${odl_system_ssh_index}
    ${stdout} =    SSHKeywords.Execute_Command_Should_Pass    cp -rv "${alternative_bundlefolder}/snapshots" "${WORKSPACE}/${BUNDLEFOLDER}/" && cp -rv "${alternative_bundlefolder}/journal" "${WORKSPACE}/${BUNDLEFOLDER}/"
    BuiltIn.Log    ${stdout}
    # TODO: Should we check whether there was a snapshot created?

Start_Newer_Odl
    [Documentation]    Start newer ODL on background.
    [Tags]    1node    carpeople    # Not critical, to save space in default log.html presentation
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True    timeout=${CLUSTER_BOOTUP_SYNC_TIMEOUT}

Verify_Data_Is_Restored
    [Documentation]    Get car data from config datastore and verify it matches what was put there.
    ${data_after} =    TemplatedRequests.Get_As_Json_Templated    folder=${CAR_VAR_DIR}    verify=False    iterations=${SEGMENT_SIZE}    iter_start=${first_id}
    BuiltIn.Should_Be_Equal    ${data_before}    ${data_after}

Archive_Older_Karaf_Log
    [Documentation]    Only original location benefits from automatic karaf.log archivation.
    SSHLibrary.Execute_Command    xz -9evv ${alternative_bundlefolder}/data/log/karaf.log
    SSHLibrary.Get_File    ${alternative_bundlefolder}/data/log/karaf.log.xz    older.karaf.log.xz
    # TODO: Uncompress first or last megabyte for better readability?

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection, copy Python utility.
    ClusterManagement.ClusterManagement_Setup
    TemplatedRequests.Create_Default_Session
    ${connection} =    SSHKeywords.Open_Connection_To_ODL_System
    # BuiltIn.Set_Suite_Variable    \${odl_system_ssh_index}    ${connection}
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/patch_cars_sr2.py

Check_Script_Results
    [Arguments]    ${stdout}    ${stderr}    ${rc}
    [Documentation]    Log stderr, if ${rc} is nonzero also Log stdout and Fail.
    BuiltIn.Log    ${stderr}
    BuiltIn.Return_From_Keyword_If    0 == ${rc}
    BuiltIn.Log    ${stdout}
    BuiltIn.Fail    Script failed, see logs.
