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
...               This suite kills the running (newer) ODL at its default location.
...               It then installs (configurable) older ODL to an alternative location,
...               pushes large amount of car data, verifies and kills the older ODL.
...               The journal and snapshot files are transferred to the default location
...               and the newer ODL is started.
...               Then it verifies the config data is still present and matches what was seen before.
...
...               In principle, the suite should also work if "newer" ODL is in fact older.
...               The limiting factor is featuresBoot, the value should be applicable to both ODL versions.
...
...               Note that in order to create traffic large enough for snapshots to be created,
...               this suite also actis as a stress test for Restconf.
...               But as that is not a primary focus of this suite,
...               data seen on newer ODL is only compared to what was seen on the older ODL
...               (stored in ${data_before} suite variable).
...
...               As using Robotframework would be both too slow and too memory consuming,
...               this suite uses a specialized Python utility for pushing the data locally on ODL_SYSTEM.
...               The utility filename is configurable, as there may be changes in PATCH behavior in future.
...
...               This suite uses relatively new support for PATCH http method.
...               It repetitively replaces a segment of cars with moving IDs,
...               so that there is a lot of data in journal (both write and delete),
...               but the overall size of data stored remains limited.
...
...               This is 1-node suite, but it still uses ClusterManagement.Check_Cluster_Is_In_Sync
...               in order to detect the same sync condition as 3-node suite would do.
...               Jolokia feature is required for that.
...
...               Minimal set of features to be installed: odl-restconf, odl-jolokia, odl-clustering-test-app.
Suite Setup       Setup_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      1node    carpeople    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot

*** Variables ***
${ALTERNATIVE_BUNDLEFOLDER_PARENT}    /tmp/older
${CAR_VAR_DIR}    ${CURDIR}/../../../variables/carpeople/libtest/cars
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    1200s    # Rebooting after kill may take longer time, especially for -all- install.
${ITERATIONS}     1000
${MOVE_PER_ITER}    1000
${PREVIOUS_ODL_RELEASE_ZIP_URL}    https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/0.4.2-Beryllium-SR2/distribution-karaf-0.4.2-Beryllium-SR2.zip
${PYTHON_UTILITY_FILENAME}    patch_cars_be_sr2.py
${SEGMENT_SIZE}    10000

*** Test Cases ***
Select_Latest_Release_If_Not_Specified
    [Documentation]    If previous ODL release is not specified, then latest release for previous to current stream is used.
    ...    Note: If current stream is not found on nexus, then it is taken as new one (not released yet).
    ...    So in this case, latest release version is return.
    ${previous_release} =    NexusKeywords.Get_Latest_ODL_Previous_Stream_Release_URL    ${ODL_STREAM}
    ${PREVIOUS_ODL_RELEASE_ZIP_URL} =    BuiltIn.Set_Variable_If    '${PREVIOUS_ODL_RELEASE_ZIP_URL}'==''    ${previous_release}    ${PREVIOUS_ODL_RELEASE_ZIP_URL}
    BuiltIn.Set_Suite_Variable    ${PREVIOUS_ODL_RELEASE_ZIP_URL}
 
Kill_Original_Odl
    [Documentation]    The ODL prepared by releng/builder is the newer one, kill it.
    ...    Also, remove journal and snapshots.
    ClusterManagement.Kill_Members_From_List_Or_All
    # This is deliberately analoguous to killing the whole cluster.
    # (As opposed to killing just one member, but for 1 node it is the same.)
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All

Install_Older_Odl
    [Documentation]    Download .zip of older ODL, unpack, delete .zip, copy featuresBoot line.
    # Download.
    SSHKeywords.Execute_Command_Should_Pass    mkdir -p "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && rm -rf * && wget -N "${PREVIOUS_ODL_RELEASE_ZIP_URL}"
    # Unzip and detect bundle folder name.
    ${bundle_dir} =    SSHKeywords.Execute_Command_Should_Pass    cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && unzip -q *.zip && rm *.zip && ls -1
    BuiltIn.Set_Suite_Variable    \${alternative_bundlefolder}    ${ALTERNATIVE_BUNDLEFOLDER_PARENT}/${bundle_dir}
    # TODO: Add more strict checks. Folder should have single line, without .zip extension.
    # Extract featuresBoot lines.
    ${cfg_filename} =    BuiltIn.Set_Variable    org.apache.karaf.features.cfg
    ${cfg_older} =    BuiltIn.Set_Variable    ${alternative_bundlefolder}/etc/${cfg_filename}
    ${cfg_newer} =    BuiltIn.Set_Variable    ${WORKSPACE}/${BUNDLEFOLDER}/etc/${cfg_filename}
    ${vanilla_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_older}" | grep -v 'featuresBootAsynchronous'
    ${csit_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_newer}" | grep -v 'featuresBootAsynchronous'
    # Replace the vanilla line.
    SSHKeywords.Execute_Command_Should_Pass    sed -i 's/${vanilla_line}/${csit_line}/g' "${cfg_older}"
    # Verify the replaced line.
    ${updated_line} =    SSHKeywords.Execute_Command_Should_Pass    grep 'featuresBoot' "${cfg_older}" | grep -v 'featuresBootAsynchronous'
    BuiltIn.Should_Not_Be_Equal    ${vanilla_line}    ${updated_line}
    BuiltIn.Should_Be_Equal    ${csit_line}    ${updated_line}

Start_Older_Odl
    [Documentation]    Start older ODL on background.
    [Tags]    1node    carpeople    # Not critical, to save space in default log.html presentation
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True    timeout=${CLUSTER_BOOTUP_SYNC_TIMEOUT}    karaf_home=${alternative_bundlefolder}

Add_Data
    [Documentation]    Put car data to config datastore of older ODL.
    ${command} =    BuiltIn.Set_Variable    python ${PYTHON_UTILITY_FILENAME} --segment-size=${SEGMENT_SIZE} --iterations=${ITERATIONS} --move-per-iter=${MOVE_PER_ITER}
    SSHKeywords.Execute_Command_Should_Pass    ${command}    stderr_must_be_empty=True
    # TODO: I have seen 401 here once. Implement workaround or report a Bug.

Remember_Data
    [Documentation]    Get and save the stored data for later comparison.
    ${data} =    TemplatedRequests.Get_As_Json_Templated    folder=${CAR_VAR_DIR}    verify=False
    BuiltIn.Set_Suite_Variable    \${data_before}    ${data}

Validate_Data
    [Documentation]    Compare the saved data against what the data should look like.
    ${first_id} =    BuiltIn.Evaluate    (${ITERATIONS} - 1) * ${MOVE_PER_ITER} + 1
    SetupUtils.Set_Known_Bug_Id    5909
    # The following line is the second part of TemplatedRequests.Get_As_Json_Templated for verify=True.
    TemplatedRequests.Verify_Response_As_Json_Templated    response=${data_before}    folder=${CAR_VAR_DIR}    base_name=data    iterations=${SEGMENT_SIZE}    iter_start=${first_id}

Kill_Older_Odl
    [Documentation]    Kill the older ODL immediatelly.
    ClusterManagement.Kill_Members_From_List_Or_All

Transfer_Persisted_Data
    [Documentation]    Move snapshots and journal into the original ODL installation.
    # SSHLibrary.Switch_Connection    ${odl_system_ssh_index}
    ${stdout} =    SSHKeywords.Execute_Command_Should_Pass    cp -rv "${alternative_bundlefolder}/snapshots" "${WORKSPACE}/${BUNDLEFOLDER}/" && cp -rv "${alternative_bundlefolder}/journal" "${WORKSPACE}/${BUNDLEFOLDER}/"
    Set_Suite_Variable    ${stdout}

Check_Snapshot_With_Transferred_Persisted_Data
    [Documentation]    Fail if no snapshot file was created.
    BuiltIn.Should_Contain    ${stdout}    /snapshots/    msg='Snapshot file was not created.'

Start_Newer_Odl
    [Documentation]    Start the newer ODL on background.
    [Tags]    1node    carpeople    # Not critical, to save space in default log.html presentation
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=True    timeout=${CLUSTER_BOOTUP_SYNC_TIMEOUT}

Verify_Data_Is_Restored
    [Documentation]    Wait until data check succeeds (there may be temporary 503).
    BuiltIn.Wait_Until_Keyword_Succeeds    180s    5s    Check_Restored_Data

Archive_Older_Karaf_Log
    [Documentation]    Only original location benefits from automatic karaf.log archivation.
    SSHKeywords.Execute_Command_Should_Pass    xz -9evv ${alternative_bundlefolder}/data/log/karaf.log
    SSHLibrary.Get_File    ${alternative_bundlefolder}/data/log/karaf.log.xz    older.karaf.log.xz
    # TODO: Uncompress first (or last) megabyte for better readability?

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection, copy Python utility.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    TemplatedRequests.Create_Default_Session
    ${connection} =    SSHKeywords.Open_Connection_To_ODL_System
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/${PYTHON_UTILITY_FILENAME}

Check_Restored_Data
    [Documentation]    Get car data from config datastore and check it is equal to the stored data.
    ...    This has to be a separate keyword, as it is run under WUKS.
    ${data_after} =    TemplatedRequests.Get_As_Json_Templated    folder=${CAR_VAR_DIR}    verify=False
    BuiltIn.Should_Be_Equal    ${data_before}    ${data_after}
