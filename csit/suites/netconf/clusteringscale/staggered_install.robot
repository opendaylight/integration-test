*** Settings ***
Documentation     Suite for controlled installation of odl-netconf-clustered-toology
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This suite requires odl-netconf-ssh feature to be already installed,
...               otherwise SSH bundle refresh will cause connection to drop and karaf command "fails".
...
...               Operation of clustered netconf topology relies on two key services.
...               The netconf topology manager application, which runs on the member
...               which owns "topology-manager" entity (of "netconf-topoogy" type);
...               And config datastore shard for network-topology module,
...               which is controlled by the Leader of the config topology shard.
...               The Leader is providing the desired state (concerning Netconf connectors),
...               the Owner consumes the state, performs necessary actions and updated operational view.
...               In this suite, the common name for the Owner and the Leader is Manager.
...
...               In a typical cluster High Availability testing scenario,
...               one cluster member is selected, killed (or isolated), and later re-started (re-joined).
...               For Netconf cluster topology testing, there will be scenarios tragetting
...               the Owner, and other scenarios targeting the Leader.
...
...               But both Owner and Leader selection is overned by the same RAFT algorithm,
...               which relies on message ordering, so there are two typical cases.
...               Either one member becomes both Owner and Leader,
...               or the two Managers are located at random.
...
...               As the targeted scenarios require the two Managers to reside on different members,
...               neither of the two case is beneficial for testing.
...
...               There are APIs in place which should allow relocation of Leader,
...               but there are no system tests for them yet.
...               TODO: Study those APIs and create the missing system tests.
...
...               This suite helps with the Manager placement situation
...               by performing feature installation in runtime, aplying the following strategy:
...
...               A N-node cluster is started (without odl-netconf-clustered-toology installed),
...               and it is verified one node has become the Leader of topology config shard.
...               As odl-netconf-clustered-toology is installed on the (N-1) follower members
...               (but not on the Leader yet), it is expected one of the members
...               becomes Owner of topology-manager entity.
...               After verifying that, odl-netconf-clustered-toology is installed on the Leader.
...               If neither Owner nor Leader has moved, the desired placement has been created.
...
...               More specifically, this suite assumes the cluster has been started,
...               it has been stabilized, and odl-netconf-clustered-toology is not installed anywhere.
...               After successful run of this suite, the feature is installed on each member,
...               and the Owner is verified to be placed on different member than the Leader.
...
...               Note that stress tests may cause Akka delays, which may move the Managers around.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Default Tags      clustering    netconf    critical
Resource          ${CURDIR}/../../../libraries/CarPeople.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${OWNER_ELECTION_TIMEOUT}    20s

*** Test Cases ***
Locate_Leader
    [Documentation]    Set suite variables based on where the Leader is.
    BuiltIn.Comment    FIXME: Migrate Set_Variables_For_Shard to ClusterManagement.robot
    CarPeople.Set_Variables_For_Shard    shard_name=topology    shard_type=config

Install_Feature_On_Followers
    [Documentation]   Perform feature installation on follower members, one by one.
    ##...    As first connection attempt may fail, WUKS is used.
    # Make sure this works, alternative is to perform the installation in parallel.
    ClusterManagement.Install_Feature_On_List_Or_All    feature_name=odl-netconf-clustered-topology    timeout=60s    member_index_list=${topology_follower_indices}

Locate_Owner
    [Documentation]    Wait for Owner to appear, store its index to suite variable.
    ${netconf_manager_owner_index}    ${candidates} =    BuiltIn.Wait_Until_Keyword_Succeeds    ${OWNER_ELECTION_TIMEOUT}    1s    ClusterManagement.Get_Owner_And_Candidates_For_Type_And_Id    type=topology-netconf    id=/general-entity:entity[general-entity:name='topology-manager']    member_index=${topology_first_follower_index}
    BuiltIn.Set_Suite_Variable    \${netconf_manager_owner_index}

Install_Feature_On_Leader
    [Documentation]    Perform feature installation on the Leader member.
    ...   This seem to be failing, so use TRACE log.
    ClusterManager.Run_Command_On_Member    command=log:set TRACE    member_index=${topology_leader_index}
    ClusterManagement.Install_Feature_On_Member    feature_name=odl-netconf-clustered-toology    member_index=${topology_leader_index}
    # FIXME: Do not skip the old teardown.
    [Teardown]    ClusterManager.Run_Command_On_Member    command=log:set TRACE    member_index=${topology_leader_index}

Verify_Managers_Are_Stationary
    [Documentation]    Keep checking that Managers do not move for a while.
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${OWNER_ELECTION_TIMEOUT}    1s    Check_Manager_Positions

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize libraries and set suite variables.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup

Teardown_Everything
    [Documentation]    Teardown the test infrastructure, perform cleanup and release all resources.
    RequestsLibrary.Delete_All_Sessions

Check_Manager_Positions
    [Documentation]    For each Manager, locate its current position and check it is the one stored in suite variable.
    ${new_leader}    ${followers} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=topology    shard_type=config
    BuiltIn.Should_Be_Equal    ${topology_leader_index}    ${new_leader}
    ${new_owner}    ${candidates} =    ClusterManagement.Get_Owner_And_Candidates_For_Type_And_Id    type=topology-netconf    id=/general-entity:entity[general-entity:name='topology-manager']    member_index=${topology_first_follower_index}
    BuiltIn.Should_Be_Equal    ${netconf_manager_owner_index}    ${new_owner}
