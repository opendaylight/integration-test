*** Settings ***
Documentation     Test suite for Cluster HA - Device Owner failover
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status

Start Mininet Multiple Connections
    [Documentation]    Start mininet tree,2 with connection to all cluster instances.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${ClusterManagement__member_index_list}    --topo tree,2 --switch ovsk,protocols=OpenFlow13
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    9

Check Entity Owner Status And Find Owner and Successor Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${original_owner}    ${original_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1
    ${original_successor}=    Collections.Get From List    ${original_successor_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_successor_list}
    BuiltIn.Set Suite Variable    ${original_successor}

Reconnect Extra Switches To Successors And Check OVS Connections
    [Documentation]    Connect switches s2 and s3 to successor instances.
    ${controller_opt} =    BuiltIn.Set Variable
    : FOR    ${index}    IN    @{original_successor_list}
    \    ${controller_opt} =    BuiltIn.Catenate    ${controller_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ODL_OF_PORT}
    \    Log    ${controller_opt}
    OVSDB.Set Controller In OVS Bridge    ${TOOLS_SYSTEM_IP}    s2    ${controller_opt}
    OVSDB.Set Controller In OVS Bridge    ${TOOLS_SYSTEM_IP}    s3    ${controller_opt}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    7

Check Network Operational Information Before Fail
    [Documentation]    Check devices in operational inventory and topology in all cluster instances.
    ClusterOpenFlow.Check OpenFlow Network Operational Information For Sample Topology

Add Configuration In Owner and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow and Verify    ${original_owner}

Modify Configuration In Owner and Verify Before Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${original_owner}

Delete Configuration In Owner and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${original_owner}

Add Configuration In Successor and Verify Before Fail
    [Documentation]    Add Flow in Successor and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow and Verify    ${original_successor}

Modify Configuration In Successor and Verify Before Fail
    [Documentation]    Modify Flow in successor and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${original_successor}

Delete Configuration In Successor and Verify Before Fail
    [Documentation]    Delete Flow in Successor and verify it gets removed from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${original_successor}

Send RPC Add to Owner and Verify Before Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${original_owner}

Send RPC Delete to Owner and Verify Before Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${original_owner}

Send RPC Add to Successor and Verify Before Fail
    [Documentation]    Add Flow in Successor and verify it gets applied from all instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${original_successor}

Send RPC Delete to Successor and Verify Before Fail
    [Documentation]    Delete Flow in Successor and verify it gets removed from all instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${original_successor}

Modify Network And Verify Before Fail
    [Documentation]    Take a link down and verify port status in all instances.
    ClusterOpenFlow.Take OpenFlow Device Link Down and Verify

Restore Network And Verify Before Fail
    [Documentation]    Take the link up and verify port status in all instances.
    ClusterOpenFlow.Take OpenFlow Device Link Up and Verify

Stop Owner Instance
    [Documentation]    Stop Owner Instance and verify it is dead
    ClusterManagement.Stop Single Member    ${original_owner}
    BuiltIn.Set Suite Variable    ${new_cluster_list}    ${original_successor_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Successor After Fail
    [Documentation]    Check Entity Owner Status and identify owner and successor.
    ${new_owner}    ${new_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    ${original_successor}    ${new_cluster_list}    after_stop=True
    ${new_successor}=    Collections.Get From List    ${new_successor_list}    0
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_successor}

Check Network Operational Information After Fail
    [Documentation]    Check devices in operational inventory and topology in all cluster instances.
    ClusterOpenFlow.Check OpenFlow Network Operational Information For Sample Topology    ${new_cluster_list}

Add Configuration In Owner and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow and Verify    ${new_owner}    ${new_cluster_list}

Modify Configuration In Owner and Verify After Fail
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${new_owner}    ${new_cluster_list}

Delete Configuration In Owner and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${new_owner}    ${new_cluster_list}

Add Configuration In Successor and Verify After Fail
    [Documentation]    Add Flow in Successor and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow and Verify    ${new_successor}    ${new_cluster_list}

Modify Configuration In Successor and Verify After Fail
    [Documentation]    Modify Flow in Successor and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${new_successor}    ${new_cluster_list}

Delete Configuration In Successor and Verify After Fail
    [Documentation]    Delete Flow in Successor and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${new_successor}    ${new_cluster_list}

Send RPC Add to Owner and Verify After Fail
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${new_owner}    ${new_cluster_list}

Send RPC Delete to Owner and Verify After Fail
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${new_owner}    ${new_cluster_list}

Send RPC Add to Successor and Verify After Fail
    [Documentation]    Add Flow in Successor and verify it gets applied from all instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${new_successor}    ${new_cluster_list}

Send RPC Delete to Successor and Verify After Fail
    [Documentation]    Delete Flow in Successor and verify it gets removed from all instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${new_successor}    ${new_cluster_list}

Modify Network and Verify After Fail
    [Documentation]    Take a link down and verify port status in all instances.
    ClusterOpenFlow.Take OpenFlow Device Link Down and Verify    ${new_cluster_list}

Restore Network and Verify After Fail
    [Documentation]    Take the link up and verify port status in all instances.
    ClusterOpenFlow.Take OpenFlow Device Link Up and Verify    ${new_cluster_list}

Start Old Owner Instance
    [Documentation]    Start old Owner Instance and verify it is up
    ClusterManagement.Start Single Member    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and successor.
    ${new_owner}    ${new_successors_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1
    BuiltIn.Set Suite Variable    ${new_owner}

Check Network Operational Information After Recover
    [Documentation]    Check devices in operational inventory and topology in all cluster instances.
    ClusterOpenFlow.Check OpenFlow Network Operational Information For Sample Topology

Add Configuration In Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow and Verify    ${new_owner}

Modify Configuration In Owner and Verify After Recover
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${new_owner}

Delete Configuration In Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${new_owner}

Add Configuration In Old Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow and Verify    ${original_owner}

Modify Configuration In Old Owner and Verify After Recover
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${original_owner}

Delete Configuration In Old Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${original_owner}

Send RPC Add to Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${new_owner}

Send RPC Delete to Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${new_owner}

Send RPC Add to Old Owner and Verify After Recover
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${original_owner}

Send RPC Delete to Old Owner and Verify After Recover
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${original_owner}

Modify Network and Verify After Recover
    [Documentation]    Take a link down and verify port status in all instances.
    ClusterOpenFlow.Take OpenFlow Device Link Down and Verify

Restore Network and Verify After Recover
    [Documentation]    Take the link up and verify port status in all instances.
    ClusterOpenFlow.Take OpenFlow Device Link Up and Verify

Stop Mininet and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Check No Network Operational Information
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances.
    ClusterOpenFlow.Check No OpenFlow Network Operational Information
