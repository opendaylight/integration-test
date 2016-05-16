*** Settings ***
Documentation     Test suite for Cluster HA with Bulk Flows - Data consistency after cluster restart, leader restart and follower restart
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/BulkomaticKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${INVENTORY_SHARD}    shard-inventory-config
${operation_timeout}    350s
${add_small_config}    sal_add_bulk_flow_small_config.json
${get_small_config}    sal_get_bulk_flow_small_config.json
${del_small_config}    sal_del_bulk_flow_small_config.json
${flow_count_after_add}    1000
${final_count_after_del}    0
${jolokia_write_op_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/WriteOpStatus
${jolokia_read_op_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/ReadOpStatus
${jolokia_flow_count_status}    /jolokia/read/org.opendaylight.openflowplugin.applications.bulk.o.matic:type=FlowCounter/FlowCount

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${original_cluster_list}

Check Shards Status Before Leader Restart
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status    ${original_cluster_list}

Get inventory Follower Before Cluster Restart
    [Documentation]    Find a follower in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${Inventory_Follower_Node_1}=    Create List
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    Append To List    ${Inventory_Follower_Node_1}    ${Follower_Node_1}
    Set Suite Variable    ${Inventory_Follower_Node_1}
    Set Suite Variable    ${Follower_Node_1}

Add Bulk Flow From Follower
    [Documentation]    1000 Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow    ${Follower_Node_1}    ${add_small_config}
    BulkomaticKeywords.Get Write Op Status    ${Inventory_Follower_Node_1}    ${jolokia_write_op_status}    ${operation_timeout}
    BulkomaticKeywords.Verify Bulk Flow    ${original_cluster_list}    ${get_small_config}    ${operation_timeout}
    BulkomaticKeywords.Get Read Op Status    ${original_cluster_list}    ${jolokia_read_op_status}    ${operation_timeout}
    BulkomaticKeywords.Get Flow Count Status    ${original_cluster_list}    ${jolokia_flow_count_status}    ${flow_count_after_add}

Restart All Cluster Nodes
    [Documentation]    Kill All Nodes and Start it Up.
    ClusterKeywords.Kill Multiple Controllers    @{original_cluster_list}
    ClusterKeywords.Start Multiple Controllers    ${operation_timeout}    @{original_cluster_list}

Verify Data Recovery After Cluster Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    BulkomaticKeywords.Verify Bulk Flow    ${original_cluster_list}    ${get_small_config}    ${operation_timeout}
    BulkomaticKeywords.Get Read Op Status    ${original_cluster_list}    ${jolokia_read_op_status}    ${operation_timeout}
    BulkomaticKeywords.Get Flow Count Status    ${original_cluster_list}    ${jolokia_flow_count_status}    ${flow_count_after_add}

Get inventory Leader Before Leader Restart
    [Documentation]    Find leader in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${Inventory_Leader_List}=    Create List    ${Inventory_Leader}
    Set Suite Variable    ${Inventory_Leader}
    Set Suite Variable    ${Inventory_Leader_List}

Restart Leader From Cluster Node
    [Documentation]    Kill Leader Node and Start it Up.
    ClusterKeywords.Kill Multiple Controllers    ${inventory_leader}
    ClusterKeywords.Start Multiple Controllers    ${operation_timeout}    ${inventory_leader}

Verify Data Recovery After Leader Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    BulkomaticKeywords.Verify Bulk Flow    ${original_cluster_list}    ${get_small_config}    ${operation_timeout}
    BulkomaticKeywords.Get Read Op Status    ${original_cluster_list}    ${jolokia_read_op_status}    ${operation_timeout}
    BulkomaticKeywords.Get Flow Count Status    ${original_cluster_list}    ${jolokia_flow_count_status}    ${flow_count_after_add}

Get inventory Follower Before follower Restart
    [Documentation]    Find followers in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status    ${original_cluster_list}
    ${Inventory_Follower_Node_1}=    Create List
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    Append To List    ${Inventory_Follower_Node_1}    ${Follower_Node_1}
    Set Suite Variable    ${Inventory_Follower_Node_1}
    Set Suite Variable    ${Follower_Node_1}

Restart Follower Node1
    [Documentation]    Kill Follower Node1 and Start it Up.
    ClusterKeywords.Kill Multiple Controllers    ${Follower_Node_1}
    ClusterKeywords.Start Multiple Controllers    ${operation_timeout}    ${Follower_Node_1}

Verify Data Recovery After Follower Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    BulkomaticKeywords.Verify Bulk Flow    ${original_cluster_list}    ${get_small_config}    ${operation_timeout}
    BulkomaticKeywords.Get Read Op Status    ${original_cluster_list}    ${jolokia_read_op_status}    ${operation_timeout}
    BulkomaticKeywords.Get Flow Count Status    ${original_cluster_list}    ${jolokia_flow_count_status}    ${flow_count_after_add}

Delete All Flows From Follower
    [Documentation]    Rest 1000 Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow    ${Follower_Node_1}    ${del_small_config}
    BulkomaticKeywords.Get Write Op Status    ${Inventory_Follower_Node_1}    ${jolokia_write_op_status}    ${operation_timeout}
    BulkomaticKeywords.Verify Bulk Flow    ${original_cluster_list}    ${get_small_config}    ${operation_timeout}
    BulkomaticKeywords.Get Read Op Status    ${original_cluster_list}    ${jolokia_read_op_status}    ${operation_timeout}
    BulkomaticKeywords.Get Flow Count Status    ${original_cluster_list}    ${jolokia_flow_count_status}    ${final_count_after_del}
