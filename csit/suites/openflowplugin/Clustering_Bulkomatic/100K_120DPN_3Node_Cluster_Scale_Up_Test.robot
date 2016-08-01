*** Settings ***
Documentation     Test suite for 3Node Cluster - 100K flows in 120 DPNs
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    250s
${flow_count_per_switch}    834
${switch_count}    120
${flow_count_after_add}    100080
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

Get Inventory Follower And Leader
    [Documentation]    Find a leader and followers in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_2}
    Set Suite Variable    ${Inventory_Leader}

Start Mininet Connect To Leader Node
    [Documentation]    Start mininet with connection to Leader Node.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Inventory_Leader}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Set Suite Variable    ${mininet_conn_id}
    Sleep    60s

Add Bulk Flow From Leader
    [Documentation]    100080 Flows (834 Flows per DPN) in 120 DPN added via Leader Node and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Inventory_Leader}    ${operation_timeout}
    ${config_datastore_write_time}=    Convert To Number    ${config_datastore_write_time}
    ${total_flows}=     Convert To Integer    ${flow_count_after_add}
    ${config_datastore_write_rate}=    Evaluate    ${flow_count_after_add} / ${config_datastore_write_time}

Verify Flows In Switch
    [Documentation]    Verify flows are installed in switch.
    ${Mininet_write_start_time}=    Get Current Date    result_format=timestamp
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count}    ${flow_count_per_switch}    ${operation_timeout}
    ${Mininet_write_end_time}=    Get Current Date    result_format=timestamp
    ${Mininet_write_time}=    Subtract Date From Date    ${Mininet_write_end_time}     ${datastore_write_start_time}

Stop Mininet Connected To Leader Node and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Leader Node
    [Documentation]    100080 Flows deleted via Leader Node and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Inventory_Leader}    ${operation_timeout}

Verify No Flows In Cluster
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}
