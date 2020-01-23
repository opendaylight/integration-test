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
@{index_list}     1    2    3

*** Test Cases ***
TC01 Create All Controller Sessions
    [Documentation]    Create sessions for all three controllers.
    ClusterManagement.ClusterManagement Setup

TC02 Take Down ODL1
    [Documentation]    Stop the karaf in First Controller
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ${new_cluster_list} =    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    BuiltIn.Set Suite Variable    ${new_cluster_list}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC03 Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterManagement.Start Single Member    1    msg=up: ODL2, ODL3, down: ODL1
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC04 Take Down ODL2
    [Documentation]    Stop the karaf in Second Controller
    ClusterManagement.Stop Single Member    2    msg=up: ODL1, ODL2, ODL3, down=none
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC05 Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    ClusterManagement.Start Single Member    2    msg=up: ODL1, ODL3, down: ODL2
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC06 Take Down ODL3
    [Documentation]    Stop the karaf in Third Controller
    ClusterManagement.Stop Single Member    3    msg=up: ODL1, ODL2, ODL3, down=none
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC07 Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    3    msg=up: ODL1, ODL2, down: ODL3
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC08 Take Down ODL1 and ODL2
    [Documentation]    Stop the karaf in First and Second Controller
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC09 Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again. Do not check for cluster sync until all nodes are
    ...    up. akka will not let nodes join until they are all back up if two were down.
    ClusterManagement.Start Single Member    1    msg=up: ODL3, down: ODL1, ODL2    wait_for_sync=False
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Start Single Member    2    msg=up: ODL1, ODL3, down: ODL2
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC10 Take Down Leader Of Default Shard
    [Documentation]    Stop the karaf on ODL cluster leader
    ${cluster_leader}    ${followers} =    ClusterManagement.Get Leader And Followers For Shard    shard_type=config
    BuiltIn.Set Suite Variable    ${cluster_leader}
    ${new_cluster_list} =    ClusterManagement.Stop Single Member    ${cluster_leader}    msg=up: ODL1, ODL2, ODL3, down=none
    BuiltIn.Set Suite Variable    ${new_cluster_list}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC11 Bring Up Leader Of Default Shard
    [Documentation]    Bring up on cluster leader
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Start Single Member    ${cluster_leader}    msg=up: ${new_cluster_list}, down: ${cluster_leader}
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC22 Take Down All Instances
    [Documentation]    Stop karaf on all controllers
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Stop Single Member    3    msg=up: ODL3, down=ODL1, ODL2
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False

TC23 Bring Up All Instances
    [Documentation]    Bring up all controllers. Do not check for cluster sync until all nodes are
    ...    up. akka will not let nodes join until they are all back up if two were down.
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Start Single Member    1    msg=up: none, down: ODL1, ODL2, ODL3    wait_for_sync=False
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Start Single Member    2    msg=up: ~ODL1, down: ODL2, ODL3    wait_for_sync=False
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    ClusterManagement.Start Single Member    3    msg=up: ~ODL1, ~ODL2, down: ODL3
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    [Teardown]    OpenStackOperations.Get Test Teardown Debugs    fail=False
