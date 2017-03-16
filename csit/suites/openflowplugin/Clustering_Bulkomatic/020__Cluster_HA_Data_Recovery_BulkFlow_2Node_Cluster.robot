*** Settings ***
Documentation     Test suite for 2Node Cluster HA with Bulk Flows - Cluster node convergance and Data consistency after leader and follower restart with one switch connected
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    200s
${restart_timeout}    350s
${flow_count_per_switch}    10000
${switch_count}    1
${flow_count_after_add}    10000
${flow_count_after_del}    0
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json

*** Test Cases ***
Check Shards Status and Initialize Variables
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    Set Suite Variable    ${temp_json_config_add}
    Set Suite Variable    ${temp_json_config_get}
    Set Suite Variable    ${temp_json_config_del}

Get Inventory Follower and Leader Before Cluster Restart
    [Documentation]    Find a follower in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    ${Inventory_Leader_List}=    Create List    ${inventory_leader}
    ${Inventory_Follower_Node1_List}=    Create List    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_2}
    Set Suite Variable    ${Inventory_Leader}
    Set Suite Variable    ${Inventory_Leader_List}
    Set Suite Variable    ${Inventory_Follower_Node1_List}
    Set Suite Variable    ${Inventory_Followers}

Check Shards Status After Leader Shutdown
    [Documentation]    Wait for node convergence and check status for all shards in OpenFlow application.
    Wait Until Keyword Succeeds    ${operation_timeout}    2s    ClusterOpenFlow.Check OpenFlow Shards Status    ${Inventory_Followers}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower
    [Documentation]    ${flow_count_per_switch} Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_1}    ${operation_timeout}

Get Bulk Flows and Verify In Leader Node
    [Documentation]    Initiate get operation and check flow count across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Inventory_Leader_List}

Shutdown Leader From Cluster Node
    [Documentation]    Shutdown Leader Node and Start it Up.
    ClusterManagement.Kill Single Member    ${Inventory_Leader}

Verify Flows In Switch Before Cluster Restart
    [Documentation]    Verify flows are installed in switch before cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Restart Leader From Cluster Node
    [Documentation]    Restart Leader Node.
    ClusterManagement.Start Single Member    ${Inventory_Leader}

Verify Data Recovery After Leader Restart
    [Documentation]    ${flow_count_per_switch} Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Inventory_Leader_List}

Verify Flows In Switch After Leader Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Follower Node1
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node1
    [Documentation]    ${flow_count_per_switch} Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

Verify No Flows In Leader Node
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${Inventory_Leader_List}

Get Inventory Follower Before Follower Restart
    [Documentation]    Find Leader and followers in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Active_Nodes}=    Create List
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    Append To List    ${Active_Nodes}    ${inventory_leader}    ${Follower_Node_1}
    Set Suite Variable    ${Active_Nodes}
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_2}

Shutdown Follower From Cluster Node
    [Documentation]    Shutdown Follower Node2 and Start it Up.
    ClusterManagement.Kill Single Member    ${Follower_Node_2}

Check Shards Status After Follower Shutdown
    [Documentation]    Wait for node convergence and check status for all shards in OpenFlow application.
    Wait Until Keyword Succeeds    ${operation_timeout}    2s    ClusterOpenFlow.Check OpenFlow Shards Status    ${Active_Nodes}

Start Mininet Connect To Follower Node
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower Node1
    [Documentation]    ${flow_count_per_switch} Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_1}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster Before Follower Restart
    [Documentation]    Initiate get operation and check flow count only across active cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Active_Nodes}

Verify Flows In Switch Before Follower Restart
    [Documentation]    Verify flows are installed in switch before follower restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Restart Follower From Cluster Node
    [Documentation]    Restart Follower Node2.
    ClusterManagement.Start Single Member    ${Follower_Node_2}

Verify Data Recovery After Follower Restart
    [Documentation]    ${flow_count_per_switch} Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Inventory_Leader_List}

Verify Flows In Switch After Follower Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Follower Node
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node
    [Documentation]    ${flow_count_per_switch} Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

Verify No Flows In Cluster After Follower Restart
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${Inventory_Leader_List}
