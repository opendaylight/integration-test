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

TC01 Take Down ODL1 and ODL2
    [Documentation]    Stop the karaf in First and Second Controller
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC02 Bring Up ODL1 and ODL2
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

TC03 Take Down ODL1 and ODL2
    [Documentation]    Stop the karaf in First and Second Controller
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    1    msg=up: ODL1, ODL2, ODL3, down=none
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop Single Member    2    msg=up: ODL2, ODL3, down=ODL1
    FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
        BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Get Raft State Of Shard At Member    shard_name=default    shard_type=config    member_index=${index}
    END

TC04 Bring Up ODL1 and ODL2
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
