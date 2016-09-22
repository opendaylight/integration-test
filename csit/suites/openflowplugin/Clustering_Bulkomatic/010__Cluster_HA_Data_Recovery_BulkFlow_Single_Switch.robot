*** Settings ***
Documentation     Test suite for Cluster HA with Bulk Flows - Data consistency after cluster restart, leader restart and follower restart with one switch connected
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
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
Check Shards Status And Initialize Variables
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    Set Suite Variable    ${temp_json_config_add}
    Set Suite Variable    ${temp_json_config_get}
    Set Suite Variable    ${temp_json_config_del}

Get Inventory Follower Before Cluster Restart
    [Documentation]    Find a follower in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    Set Suite Variable    ${Follower_Node_1}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower
    [Documentation]    1000 Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_1}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster
    [Documentation]    Initiate get operation and check flow count across cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Verify Flows In Switch Before Cluster Restart
    [Documentation]    Verify flows are installed in switch before cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Kill All Cluster Nodes
    [Documentation]    Kill All Nodes.
    ClusterManagement.Kill Members From List Or All

Stop Mininet Connected To Follower Node1 and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart All Cluster Nodes
    [Documentation]    Restart all cluster nodes.
    ClusterManagement.Start Members From List Or All

Verify Data Recovery After Cluster Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Start Mininet Again Connect To Follower Node1
    [Documentation]    Start mininet with connection to follower node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Cluster Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Follower Node1
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node1
    [Documentation]    1000 Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

Verify No Flows In Cluster
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}

Get Inventory Leader Before Leader Restart
    [Documentation]    Find leader in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    Set Suite Variable    ${Inventory_Leader}

Start Mininet Connect To Leader
    [Documentation]    Start mininet with connection to Leader Node.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Inventory_Leader}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Leader
    [Documentation]    1000 Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Inventory_Leader}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster Before Leader Restart
    [Documentation]    Initiate get operation and check flow count across cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Verify Flows In Switch Before Leader Restart
    [Documentation]    Verify flows are installed in switch before leader restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Kill Leader From Cluster Node
    [Documentation]    Kill Leader Node.
    ClusterManagement.Kill Single Member    ${Inventory_Leader}

Stop Mininet Connected To Leader Node
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Leader from Cluster Node
    [Documentation]    Start Leader Node Up.
    ClusterManagement.Start Single Member    ${Inventory_Leader}

Verify Data Recovery After Leader Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Check No Network Operational Information After Leader Restart
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances.
    ClusterOpenFlow.Check No OpenFlow Network Operational Information
    [Teardown]    Report_Failure_Due_To_Bug    6459

Start Mininet Again Connect To Leader
    [Documentation]    Start mininet with connection to Leader Node.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Inventory_Leader}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Leader Restart
    [Documentation]    Verify flows are installed in switch after leader restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}
    [Teardown]    Report_Failure_Due_To_Bug    6459

Stop Mininet Connected To Leader Node After Leader Restart
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Leader Node
    [Documentation]    1000 Flows deleted via Leader Node and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Inventory_Leader}    ${operation_timeout}

Verify No Flows In Cluster After Leader Restart
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}

Get Inventory Follower Before follower Restart
    [Documentation]    Find follower in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    Set Suite Variable    ${Follower_Node_2}

Start Mininet Connect To Follower Node2
    [Documentation]    Start mininet with connection to Follower Node2.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_2}_IP}
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower Node2
    [Documentation]    1000 Flows added via Follower Node2 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_2}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster Before Follower Restart
    [Documentation]    Initiate get operation and check flow count across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Verify Flows In Switch Before Follower Restart
    [Documentation]    Verify flows are installed in switch before follower restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Kill Follower Node2
    [Documentation]    Kill Follower Node2.
    ClusterManagement.Kill Single Member    ${Follower_Node_2}

Stop Mininet Connected To Follower Node2 and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Follower Node2
    [Documentation]    Start Follower Node2 Up.
    ClusterManagement.Start Single Member    ${Follower_Node_2}

Verify Data Recovery After Follower Node2 Restart
    [Documentation]    1000 Flows preserved in all controller instances.
    Wait Until Keyword Succeeds    ${restart_timeout}    2s    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Check No Network Operational Information After Follower Node2 Restart
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances.
    ClusterOpenFlow.Check No OpenFlow Network Operational Information
    [Teardown]    Report_Failure_Due_To_Bug    6459

Start Mininet Again Connect To Follower Node2
    [Documentation]    Start mininet with connection to follower node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_2}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Follower Node2 Restart
    [Documentation]    Verify flows are installed in switch after follower restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}
    [Teardown]    Report_Failure_Due_To_Bug    6459

Stop Mininet Connected To Follower Node2
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node 2
    [Documentation]    1000 Flows deleted via Leader Node and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_2}    ${operation_timeout}

Verify No Flows In Cluster After Follower Node2 Restart
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}
