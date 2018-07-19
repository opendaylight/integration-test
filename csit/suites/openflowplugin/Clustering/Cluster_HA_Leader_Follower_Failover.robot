*** Settings ***
Documentation     Test suite for Cluster HA - Device Leader Follower failover
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Check Shards Status Before Leader Restart
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status

Get inventory Leader Before Leader Restart
    [Documentation]    Find leader in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Leader
    [Documentation]    Start mininet with connection to cluster Leader.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${inventory_leader}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Flows In Leader and Verify Before Leader Restart
    [Documentation]    Add Flow via Leader and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow And Verify    ${inventory_leader}

Modify Flows In Leader and Verify Before Leader Restart
    [Documentation]    Modify Flow in Leader and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${inventory_leader}

Delete Flows In Leader and Verify Before Leader Restart
    [Documentation]    Delete Flow in Leader and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${inventory_leader}

Send RPC Add to Leader and Verify Before Leader Restart
    [Documentation]    Add Flow in Leader and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${inventory_leader}

Send RPC Delete to Leader and Verify Before Leader Restart
    [Documentation]    Delete Flow in Owner and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${inventory_leader}

Send RPC Add to Follower Node1 and Verify Before Leader Restart
    [Documentation]    Add Flow in Follower and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${follower_node_1}

Send RPC Delete to Follower Node2 and Verify Before Leader Restart
    [Documentation]    Delete Flow in Follower and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${follower_node_2}

Stop Mininet Connected To Leader and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Leader From Cluster Node
    [Documentation]    Kill Leader Node and Start it Up, Verify it is sync with other controller node.
    ClusterManagement.Kill Single Member    ${inventory_leader}
    ClusterManagement.Start Single Member    ${inventory_leader}

Get inventory Follower After Leader Restart
    [Documentation]    Find new Followers and Leader in the inventory config shard After Leader Restart
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to cluster Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_1}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Flows In Follower Node2 and Verify Before Follower Restart
    [Documentation]    Add Flow via cluster Follower Node2 and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow And Verify    ${follower_node_2}

Modify Flows In Follower Node2 and Verify Before Follower Restart
    [Documentation]    Modify Flow in Follower Node2 and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${follower_node_2}

Delete Flows In Follower Node2 and Verify Follower Restart
    [Documentation]    Delete Flow in Follower Node2 and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${follower_node_2}

Send RPC Add to Leader and Verify Before Follower Restart
    [Documentation]    Add Flow in Leader and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${inventory_leader}

Send RPC Delete to Leader and Verify Before Follower Restart
    [Documentation]    Delete Flow in Owner and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${inventory_leader}

Send RPC Add to First Follower Node1 and Verify Before Follower Restart
    [Documentation]    Add Flow in Follower and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${follower_node_1}

Send RPC Delete to Follower Node2 and Verify Before Follower Restart
    [Documentation]    Delete Flow in Follower Node2 and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${follower_node_2}

Stop Mininet Connected To Follower and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Follower Node2
    [Documentation]    Kill Follower Node2 and Start it Up, Verify it is sync with other controller node.
    ClusterManagement.Kill Single Member    ${follower_node_2}
    ClusterManagement.Start Single Member    ${follower_node_2}

Get inventory Follower After Follower Restart
    [Documentation]    Find Followers and Leader in the inventory config shard After Follower Restart
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node2
    [Documentation]    Start mininet with connection to cluster Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_2}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Flows In Follower Node1 and Verify Before Cluster Restart
    [Documentation]    Add Flow via cluster Follower Node1 and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow And Verify    ${follower_node_1}

Modify Flows In Follower Node1 and Verify Before Cluster Restart
    [Documentation]    Modify Flow in Follower Node1 and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${follower_node_1}

Delete Flows In Follower Node1 and Verify Before Cluster Restart
    [Documentation]    Delete Flow in Follower Node1 and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${follower_node_1}

Send RPC Add to Leader and Verify Before Cluster Restart
    [Documentation]    Add Flow in Leader and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${inventory_leader}

Send RPC Delete to Leader and Verify Before Cluster Restart
    [Documentation]    Delete Flow in Owner and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${inventory_leader}

Send RPC Add to Follower Node2 and Verify Before Cluster Restart
    [Documentation]    Add Flow in Follower and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${follower_node_2}

Send RPC Delete to Follower Node1 and Verify Before Cluster Restart
    [Documentation]    Delete Flow in Follower and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${follower_node_1}

Stop Mininet Connected To Other Follower and Exit
    [Documentation]    Stop mininet Connected To Other Follower and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Full Cluster
    [Documentation]    Kill all Cluster Nodes and Start it Up All.
    ClusterManagement.Kill Members From List Or All
    ClusterManagement.Start Members From List Or All

Get inventory Status After Cluster Restart
    [Documentation]    Find New Followers and Leader in the inventory config shard After Cluster Restart
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node2 After Cluster Restart
    [Documentation]    Start mininet with connection to cluster Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_2}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Flows In Follower Node1 and Verify After Cluster Restart
    [Documentation]    Add Flow via cluster Follower Node1 and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow And Verify    ${follower_node_1}

Modify Flows In Follower Node1 and Verify After Cluster Restart
    [Documentation]    Modify Flow in Follower Node1 and verify it gets applied from all instances.
    ClusterOpenFlow.Modify Sample Flow and Verify    ${follower_node_1}

Delete Flows In Follower Node1 and Verify After Cluster Restart
    [Documentation]    Delete Flow in Follower Node1 and verify it gets applied from all instances.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${follower_node_1}

Send RPC Add to Leader and Verify After Cluster Restart
    [Documentation]    Add Flow in Leader and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${inventory_leader}

Send RPC Delete to Leader and Verify After Cluster Restart
    [Documentation]    Delete Flow in Owner and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${inventory_leader}

Send RPC Add to Follower Node2 and Verify After Cluster Restart
    [Documentation]    Add Flow in Follower and verify it gets applied from all Controller instances.
    ClusterOpenFlow.Send RPC Add Sample Flow and Verify    ${follower_node_2}

Send RPC Delete to Follower Node2 and Verify After Cluster Restart
    [Documentation]    Delete Flow in Follower and verify it gets removed from all Controller instances.
    ClusterOpenFlow.Send RPC Delete Sample Flow and Verify    ${follower_node_1}

Stop Mininet Connected To Follower Node2 and Exit After Cluster Restart
    [Documentation]    Stop mininet Connected To Other Follower and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System
