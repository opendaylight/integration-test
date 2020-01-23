*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    cl2_sg
@{NETWORKS}       cl2_net_1    cl2_net_2
@{SUBNETS}        cl2_sub_1    cl2_sub_2
@{NET_1_VMS}      cl2_net_1_vm_1    cl2_net_1_vm_2    cl2_net_1_vm_3
@{NET_2_VMS}      cl2_net_2_vm_1    cl2_net_2_vm_2    cl2_net_2_vm_3
@{SUBNET_CIDRS}    26.0.0.0/24    27.0.0.0/24
@{CLUSTER_DOWN_LIST}    ${1}    ${2}

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three controllers.
    ClusterManagement.ClusterManagement Setup

Take Down ODL1
    [Documentation]    Stop the karaf in First Controller    
    Get Leader And Followers
    ${new_cluster_list} =    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    BuiltIn.Set Suite Variable    ${new_cluster_list}
    Get Leader And Followers

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    Get Leader And Followers
    ClusterManagement.Start Single Member    1    msg=up: ODL2, ODL3, down: ODL1
    Get Leader And Followers

Take Down ODL2
    [Documentation]    Stop the karaf in Second Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    2    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    Get Leader And Followers
    ClusterManagement.Start Single Member    2    msg=up: ODL1, ODL3, down: ODL2
    Get Leader And Followers


Take Down ODL3
    [Documentation]    Stop the karaf in Third Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    3    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    Get Leader And Followers
    ClusterManagement.Start Single Member    3    msg=up: ODL1, ODL2, down: ODL3
    Get Leader And Followers

Take Down ODL1 and ODL2
    [Documentation]    Stop the karaf in First and Second Controller
    Get Leader And Followers
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    Get Leader And Followers

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again. Do not check for cluster sync until all nodes are
    ...    up. akka will not let nodes join until they are all back up if two were down.
    Get Leader And Followers
    ClusterManagement.Start Single Member    1    msg=up: ODL3, down: ODL1, ODL2    wait_for_sync=False
    Get Leader And Followers
    ClusterManagement.Start Single Member    2    msg=up: ODL1, ODL3, down: ODL2
    Get Leader And Followers

Take Down Leader Of Default Shard
    [Documentation]    Stop the karaf on ODL cluster leader
    ${cluster_leader}    ${followers} =    Get Leader And Followers
    BuiltIn.Set Suite Variable    ${cluster_leader}
    ${new_cluster_list} =    ClusterManagement.Stop Single Member    ${cluster_leader}    msg=up: ODL1, ODL2, ODL3, down=none
    BuiltIn.Set Suite Variable    ${new_cluster_list}
    Get Leader And Followers

Bring Up Leader Of Default Shard
    [Documentation]    Bring up on cluster leader
    ClusterManagement.Start Single Member    ${cluster_leader}    msg=up: ${new_cluster_list}, down: ${cluster_leader}

Take Down ODL1
    [Documentation]    Stop the karaf in First Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    Get Leader And Followers
    ClusterManagement.Start Single Member    1    msg=up: ODL2, ODL3, down: ODL1
    Get Leader And Followers

Take Down ODL2
    [Documentation]    Stop the karaf in Second Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    2    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    Get Leader And Followers
    ClusterManagement.Start Single Member    2    msg=up: ODL1, ODL3, down: ODL2
    Get Leader And Followers

Take Down ODL3
    [Documentation]    Stop the karaf in Third Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    3    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    Get Leader And Followers
    ClusterManagement.Start Single Member    3    msg=up: ODL1, ODL2, down: ODL3
    Get Leader And Followers

Take Down ODL1 and ODL2
    [Documentation]    Stop the karaf in First and Second Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    Get Leader And Followers
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again. Do not check for cluster sync until all nodes are
    ...    up. akka will not let nodes join until they are all back up if two were down.
    Get Leader And Followers
    ClusterManagement.Start Single Member    1    msg=up: ODL3, down: ODL1, ODL2    wait_for_sync=False
    Get Leader And Followers
    ClusterManagement.Start Single Member    2    msg=up: ODL1, ODL3, down: ODL2
    Get Leader And Followers
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

Take Down ODL2 and ODL3
    [Documentation]    Stop the karaf in First and Second Controller
    Get Leader And Followers
    ClusterManagement.Stop Single Member    2    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers
    ClusterManagement.Stop Single Member    3    msg=up: ODL1, ODL3, down=ODL2
    Get Leader And Followers
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

Bring Up ODL2 and ODL3
    [Documentation]    Bring up ODL2 and ODL3 again. Do not check for cluster sync until all nodes are
    ...    up. akka will not let nodes join until they are all back up if two were down.
    Get Leader And Followers
    ClusterManagement.Start Single Member    2    msg=up: ODL1, down: ODL2, ODL3    wait_for_sync=False
    Get Leader And Followers
    ClusterManagement.Start Single Member    3    msg=up: ODL1, ODL2, down: ODL3
    Get Leader And Followers
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

Take Down All Instances
    [Documentation]    Stop karaf on all controllers
    Get Leader And Followers
    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    Get Leader And Followers
    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    Get Leader And Followers
    ClusterManagement.Stop Single Member    3    msg=up: ODL3, down=ODL1, ODL2
    Get Leader And Followers
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

Bring Up All Instances
    [Documentation]    Bring up all controllers. Do not check for cluster sync until all nodes are
    ...    up. akka will not let nodes join until they are all back up if two were down.    
    Get Leader And Followers
    ClusterManagement.Start Single Member    1    msg=up: none, down: ODL1, ODL2, ODL3    wait_for_sync=False
    Get Leader And Followers
    ClusterManagement.Start Single Member    2    msg=up: ~ODL1, down: ODL2, ODL3    wait_for_sync=False
    Get Leader And Followers
    ClusterManagement.Start Single Member    3    msg=up: ~ODL1, ~ODL2, down: ODL3
    Get Leader And Followers
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

*** Keywords ***
Get Leader And Followers
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_type=config
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_type=operational
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_name=entity-ownership    shard_type=operational
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_name=inventory    shard_type=config
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_name=inventory    shard_type=operational
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_name=topology    shard_type=config
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Leader And Followers For Shard    shard_name=topology    shard_type=operational
    