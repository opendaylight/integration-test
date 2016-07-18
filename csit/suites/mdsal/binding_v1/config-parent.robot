*** Settings ***
Documentation     Suite for testing performance of Java binding v1 using config-parent.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Config-parent comes from controller project, but the majority of time is spent
...               on generating Java binding v1, so this is performance test for Mdsal project functionality.
...
# ...               FIXME: Rewrite the rest of Documentation.
# ...
# ...               This suite kills the running (newer) ODL at its default location.
# ...               It then installs (configurable) older ODL to an alternative location,
# ...               pushes large amount of car data, verifies and kills the older ODL.
# ...               The journal and snapshot files are transferred to the default location
# ...               and the newer ODL is started.
# ...               Then it verifies the config data is still present and matches what was seen before.
# ...
# ...               In principle, the suite should also work if "newer" ODL is in fact older.
# ...               The limiting factor is featuresBoot, the value should be applicable to both ODL versions.
# ...
# ...               Note that in order to create traffic large enough for snapshots to be created,
# ...               this suite also actis as a stress test for Restconf.
# ...               But as that is not a primary focus of this suite,
# ...               data seen on newer ODL is only compared to what was seen on the older ODL
# ...               (stored in ${data_before} suite variable).
# ...
# ...               As using Robotframework would be both too slow and too memory consuming,
# ...               this suite uses a specialized Python utility for pushing the data locally on ODL_SYSTEM.
# ...               The utility filename is configurable, as there may be changes in PATCH behavior in future.
# ...
# ...               This suite uses relatively new support for PATCH http method.
# ...               It repetitively replaces a segment of cars with moving IDs,
# ...               so that there is a lot of data in journal (both write and delete),
# ...               but the overall size of data stored remains limited.
# ...
# ...               This is 1-node suite, but it still uses ClusterManagement.Check_Cluster_Is_In_Sync
# ...               in order to detect the same sync condition as 3-node suite would do.
# ...               Jolokia feature is required for that.
# ...
# ...               Minimal set of features to be installed: odl-restconf, odl-jolokia, odl-clustering-test-app.
Suite Setup       Setup_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      1node    binding_v1    critical
Library           SSHLibrary
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot

*** Test Cases ***
Kill_Odl
    [Documentation]    The ODL consumes resources, kill it.
    ClusterManagement.Kill_Members_From_List_Or_All

Detect_Config_Version
    [Documentation]    Examine ODL installation to figure out which version of config-parent should be used.
    ...    Parent poms are not present in Karaf installation, and NexusKeywords assumes we want artifact ending with -impl,
    ...    so config-persister is given as a component version of which we are interested in.
    ${version}    ${location}    NexusKeywords.NexusKeywords__Detect_Version_To_Pull    component=config-persister
    BuiltIn.Log    ${version}
    BuiltIn.Log    ${location}

__Work_In_Progress__
    BuiltIn.Fail

*** Keywords ***
Setup_Suite
    [Documentation]    Activate dependency Resources, create SSH connection, copy Python utility.
    ClusterManagement.ClusterManagement_Setup
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage    tools_system_connect=False
    ${connection} =    SSHKeywords.Open_Connection_To_ODL_System

#Check_Restored_Data
#    [Documentation]    Get car data from config datastore and check it is equal to the stored data.
#    ...    This has to be a separate keyword, as it is run under WUKS.
#    ${data_after} =    TemplatedRequests.Get_As_Json_Templated    folder=${CAR_VAR_DIR}    verify=False
#    BuiltIn.Should_Be_Equal    ${data_before}    ${data_after}
