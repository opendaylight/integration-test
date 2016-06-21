*** Settings ***
Documentation     Test suite for 2Node Cluster HA with Bulk Flows - Cluster node convergance and Data consistency after leader and follower restart with one switch connected
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    100s
${restart_timeout}    350s
${flow_count_per_switch}    1000
${switch_count}    1
${flow_count_after_add}    1000
${flow_count_after_del}    0
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${original_cluster_list}

Check Shards Status Before Leader Restart
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status    ${original_cluster_list}

Get Inventory Follower Before Cluster Restart
    [Documentation]    Find a follower in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${Inventory_Leader_List}=    Create List    ${Inventory_Leader}
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    Set Suite Variable    ${Inventory_Followers}
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Inventory_Leader}
    Set Suite Variable    ${Inventory_Leader_List}

Shutdown Leader From Cluster Node
    [Documentation]    Shutdown Leader Node and Start it Up.
    ClusterKeywords.Kill Multiple Controllers    ${Inventory_Leader}

Check Shards Status After Leader Shutdown
    [Documentation]    Wait for node convergence and check status for all shards in OpenFlow application.
    Wait Until Keyword Succeeds    ${operation_timeout}    2s    ClusterOpenFlow.Check OpenFlow Shards Status    ${Inventory_Followers}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower
    [Documentation]    1000 Flows added via Follower Node1 and verify it gets applied in all instances.
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    Set Suite Variable    ${temp_json_config_add}
    BulkomaticKeywords.Add Bulk Flow In Node    ${Follower_Node_1}    ${temp_json_config_add}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster
    [Documentation]    Initiate get operation and check flow count across cluster nodes.
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    Set Suite Variable    ${temp_json_config_get}
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${Inventory_Followers}    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Verify Flows In Switch Before Cluster Restart
    [Documentation]    Verify flows are installed in switch before cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count}    ${flow_count_per_switch}    ${operation_timeout}

Restart Leader From Cluster Node
    [Documentation]    Restart Leader Node.
    ClusterKeywords.Start Multiple Controllers    ${operation_timeout}    ${Inventory_Leader}

Verify Data Recovery After Leader Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${original_cluster_list}    ${temp_json_config_get}    ${operation_timeout}
    ...    ${flow_count_after_add}

Verify Flows In Switch After Leader Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count}    ${flow_count_per_switch}    ${operation_timeout}

Stop Mininet Connected To Follower Node1
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node1
    [Documentation]    1000 Flows deleted via Follower Node1 and verify it gets applied in all instances.
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    Set Suite Variable    ${temp_json_config_del}
    BulkomaticKeywords.Delete Bulk Flow In Node    ${Follower_Node_1}    ${temp_json_config_del}    ${operation_timeout}

Verify No Flows In Cluster
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${original_cluster_list}    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}

Get Inventory Follower Before Follower Restart
    [Documentation]    Find Leader and followers in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${Active_Nodes}=    Create List
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    Append To List    ${Active_Nodes}    ${inventory_leader}    ${Follower_Node_1}
    Set Suite Variable    ${Active_Nodes}
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_2}

Shutdown Follower From Cluster Node
    [Documentation]    Shutdown Follower Node2 and Start it Up.
    ClusterKeywords.Kill Multiple Controllers    ${Follower_Node_2}

Check Shards Status After Follower Shutdown
    [Documentation]    Wait for node convergence and check status for all shards in OpenFlow application.
    Wait Until Keyword Succeeds    ${operation_timeout}    2s    ClusterOpenFlow.Check OpenFlow Shards Status    ${Active_Nodes}

Start Mininet Connect To Follower Node
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower Node1
    [Documentation]    1000 Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${Follower_Node_1}    ${temp_json_config_add}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster Before Follower Restart
    [Documentation]    Initiate get operation and check flow count only across active cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${Active_Nodes}    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Verify Flows In Switch Before Follower Restart
    [Documentation]    Verify flows are installed in switch before follower restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count}    ${flow_count_per_switch}    ${operation_timeout}

Restart Follower From Cluster Node
    [Documentation]    Restart Follower Node2.
    ClusterKeywords.Start Multiple Controllers    ${operation_timeout}    ${Follower_Node_2}

Verify Data Recovery After Follower Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${original_cluster_list}    ${temp_json_config_get}    ${operation_timeout}
    ...    ${flow_count_after_add}

Verify Flows In Switch After Follower Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count}    ${flow_count_per_switch}    ${operation_timeout}

Stop Mininet Connected To Follower Node
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node
    [Documentation]    1000 Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${Follower_Node_1}    ${temp_json_config_del}    ${operation_timeout}

Verify No Flows In Cluster After Follower Restart
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${original_cluster_list}    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}
