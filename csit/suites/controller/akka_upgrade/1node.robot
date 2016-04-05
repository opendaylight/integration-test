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
Suite Setup       ClusterManagement.ClusterManagement_Setup
Default Tags      1node    carpeople    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${CLUSTER_BOOTUP_SYNC_TIMEOUT}    180s
${PREVIOUS_ODL_RELEASE_ZIP_URL}    https://nexus.opendaylight.org/content/repositories/public/org/opendaylight/integration/distribution-karaf/0.4.1-Beryllium-SR1/distribution-karaf-0.4.1-Beryllium-SR1.zip
${ALTERNATIVE_BUNDLEFOLDER_PARENT}    /tmp/old

*** Test Cases ***
Kill_Original_Odl
    [Documentation]    The ODL prepared by releng/builder is the newer one, kill it.
    ...    Also, remove journal and snapshots.
    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Clean_Journals_And_Snapshots_On_List_Or_All

Install_Older_Odl
    [Documentation]    Download .zip, unpack, delete .zip, copy featuresBoot line.
    # Download.
    SSHLibrary.Execute_Command    cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && wget -N "${PREVIOUS_RELEASE_ZIP_URL}"
    # Unzip.
    SSHLibrary.Execute_Command    cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}" && unzip "${PREVIOUS_RELEASE_ZIP_URL}" && rm "${PREVIOUS_RELEASE_ZIP_URL}"
    # Remove featuresBoot lines.
    ${cfg} =    BuiltIn.Set_Variable    org.apache.karaf.features.cfg
    SSHLibrary.Execute_Command    cd "${ALTERNATIVE_BUNDLEFOLDER_PARENT}/etc" && grep -v featuresBoot "${cfg}" > "${cfg}_"

Wait_For_Sync_And_Shards
    [Documentation]    Repeatedly check for cluster sync status, fail when timeout is exceeded.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${CLUSTER_BOOTUP_SYNC_TIMEOUT}    10s    Check_Sync

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection.
    ClusterManagement.ClusterManagement_Setup
    TemplatedRequests.Create_Default_Session
    SSHKeywords.Open_Connection_To_ODL_System

Check_Sync
    [Documentation]    Call ClusterManagement keyword.
    ...    FIXME: Eliminate if there is no additional logic in final suite.
    ClusterManagement.Check_Cluster_Is_In_Sync
