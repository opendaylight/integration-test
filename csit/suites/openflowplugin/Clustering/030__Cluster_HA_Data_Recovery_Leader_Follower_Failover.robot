*** Settings ***
Documentation     Test suite for Cluster HA - Data Recovery at Leader Follower failover and cluster restart
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${INVENTORY_SHARD}    shard-inventory-config
${START_TIMEOUT}    300s
${flow_count_per_switch}    1
${switch_count_per_node}    1
${operation_timeout}    15s

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${original_cluster_list}

Check Shards Status Before Leader Restart
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status    ${original_cluster_list}

Get inventory Leader Before Leader Restart
    [Documentation]    Find leader in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${inventory_leader_old}    ${inventory_leader}
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_1}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Flows In Follower Node2 and Verify Before Leader Restart
    [Documentation]    Add Flow via Follower Node2 and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow And Verify    ${original_cluster_list}    ${follower_node_2}

Stop Mininet Connected To Follower Node1 and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Leader From Cluster Node
    [Documentation]    Kill Leader Node and Start it Up, Verify it is sync with other controller node.
    ClusterKeywords.Kill Multiple Controllers    ${inventory_leader}
    ClusterKeywords.Start Multiple Controllers    ${START_TIMEOUT}    ${inventory_leader}

Get inventory Follower After Leader Restart
    [Documentation]    Find new Followers and Leader in the inventory config shard After Leader Restart.
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Old Leader
    [Documentation]    Start mininet with connection to cluster old leader.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${inventory_leader_old}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Leader Restart
    [Documentation]    Verify flows are installed in switch after leader restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count_per_node}    ${flow_count_per_switch}    ${operation_timeout}

Stop Mininet Connected To Old Leader and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Follower Node2
    [Documentation]    Kill Follower Node2 and Start it Up, Verify it is sync with other controller node.
    ClusterKeywords.Kill Multiple Controllers    ${follower_node_2}
    ClusterKeywords.Start Multiple Controllers    ${START_TIMEOUT}    ${follower_node_2}

Get inventory Follower After Follower Restart
    [Documentation]    Find Followers and Leader in the inventory config shard After Follower Restart.
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Leader
    [Documentation]    Start mininet with connection to Leader.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${inventory_leader}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Follower Restart
    [Documentation]    Verify flows are installed in switch after follower restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count_per_node}    ${flow_count_per_switch}    ${operation_timeout}

Stop Mininet Connected To Leader and Exit
    [Documentation]    Stop mininet Connected To Other Follower and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Full Cluster
    [Documentation]    Kill all Cluster Nodes and Start it Up All.
    ClusterKeywords.Kill Multiple Controllers    @{original_cluster_list}
    ClusterKeywords.Start Multiple Controllers    ${START_TIMEOUT}    @{original_cluster_list}

Get inventory Status After Cluster Restart
    [Documentation]    Find New Followers and Leader in the inventory config shard After Cluster Restart.
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node2 After Cluster Restart
    [Documentation]    Start mininet with connection to cluster Follower Node2.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_2}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Cluster Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count_per_node}    ${flow_count_per_switch}    ${operation_timeout}

Delete Flows In Follower Node1 and Verify After Leader Restart
    [Documentation]    Delete Flow in Follower Node1.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${original_cluster_list}    ${follower_node_1}

Stop Mininet Connected To Follower Node2 and Exit After Cluster Restart
    [Documentation]    Stop mininet Connected To Other Follower and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System
