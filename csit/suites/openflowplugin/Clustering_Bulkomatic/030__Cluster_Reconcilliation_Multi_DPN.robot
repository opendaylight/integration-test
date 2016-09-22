*** Settings ***
Documentation     Test suite for Cluster with Bulk Flows - Reconcilliation in a multi DPN environment
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
${flow_count_per_switch}    1000
${switch_count}    3
${flow_count_after_add}    3000
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
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_2}
    Set Suite Variable    ${Inventory_Leader}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}

Add Bulk Flow From Follower
    [Documentation]    3000 Flows (1K per DPN) in 3 DPN added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_1}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster
    [Documentation]    Initiate get operation and check flow count across cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Verify Flows In Switch Before Cluster Restart
    [Documentation]    Verify flows are installed in switch before cluster restart.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Follower Node1 and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Start Mininet Reconnect To Follower Node1
    [Documentation]    Start mininet with reconnection to follower node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch Reconnected To Follower Node1
    [Documentation]    Verify 1K flows per DPN installed in switch after it is reconnected to follower node1.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Follower Node1
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Start Mininet Connect To Follower Node2
    [Documentation]    Start mininet with connection to follower node2.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_2}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch Connected To Follower Node2
    [Documentation]    Verify 1K flows per DPN installed in switch after it is connected to follower node2.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Follower Node2
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Start Mininet Connect To Inventory Leader
    [Documentation]    Start mininet with connection to inventroy leader.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Inventory_Leader}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch Connected To Leader
    [Documentation]    Verify 1K flows per DPN installed in switch after it is connected to inventory leader.
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count_after_add}    ${operation_timeout}

Stop Mininet Connected To Inventory Leader
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node1
    [Documentation]    3000 Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

Verify No Flows In Cluster
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}
