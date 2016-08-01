*** Settings ***
Documentation     Test suite for 3Node Cluster - 100K flows and 10 DPNs in Cluster Scale Up scenario
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
${oper_ds_timeout}    400s
${mininet_timeout}    120s
${flow_count_per_switch}    10000
${switch_count}    10
${switch_state_pre_connection}    TIME_WAIT
${switch_state_post_connection}    ESTABLISHED
${flow_count_after_add}    100000
${flow_count_after_del}    0
${karaf_log_level}    log:set ERROR
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json

*** Test Cases ***
Check Shards Status And Initialize Variables
    [Documentation]    Check Status for all shards in OpenFlow application and set the logs across cluster nodes.
    ClusterOpenFlow.Check OpenFlow Shards Status
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    ${karaf_log_level}
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    Set Suite Variable    ${temp_json_config_add}
    Set Suite Variable    ${temp_json_config_get}
    Set Suite Variable    ${temp_json_config_del}

Get Inventory Config Shard Follower And Leader
    [Documentation]    Find a leader and followers in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    ${inventory_leader_list}=    Create List    ${inventory_leader}
    Log to console    ${\n}
    Log to console    The follower Node1 is ${Follower_Node_1}
    Log to console    The follower Node2 is ${Follower_Node_2}
    Log to console    The leader Node is ${Inventory_Leader}
    Set Suite Variable    ${Follower_Node_1}
    Set Suite Variable    ${Follower_Node_2}
    Set Suite Variable    ${Inventory_Leader}
    Set Suite Variable    ${inventory_leader_list}

Check Switch State Prior To Connection
    [Documentation]    Ensure no switches connected to cluster node are in TIME_WAIT or ESTABLISHED state.
    ${status}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    0
    ...    ${switch_state_pre_connection}    ${Follower_Node_1}
    Run Keyword If    '${status}' == 'False'    Utils.Clean_And_Stabilize_Mininet_System    ${switch_state_pre_connection}
    ${status}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    0
    ...    ${switch_state_post_connection}    ${Follower_Node_1}
    Run Keyword If    '${status}' == 'False'    Utils.Clean_And_Stabilize_Mininet_System    ${switch_state_pre_connection}

Start Mininet Connect To Follower Node
    [Documentation]    Start mininet with connection to follower Node.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${Follower_Node_1}_IP}    --topo linear,${switch_count} --switch ovsk,protocols=OpenFlow13
    Wait Until Keyword Succeeds    ${mininet_timeout}    1s    Utils.Stabilize_Mininet_System    ${switch_state_pre_connection}
    Set Suite Variable    ${mininet_conn_id}

Verify Stable Switch State Post Connection
    [Documentation]    Ensure switches connected to cluster node are in ESTABLISHED state and none in TIME_WAIT state.
    Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    0    ${switch_state_pre_connection}    ${Follower_Node_1}
    Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    ${switch_count}    ${switch_state_post_connection}    ${Follower_Node_1}

Add Bulk Flow From Follower Node2
    [Documentation]    100K Flows (10K Flows per DPN) in 10 DPN added via Follower Node2 and verify it gets applied in all instances.
    ${config_datastore_write_start_time}=    Get Current Date    result_format=timestamp
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_2}    ${operation_timeout}
    ${config_datastore_write_end_time}=    Get Current Date    result_format=timestamp
    ${config_datastore_write_time}=    Subtract Date From Date    ${config_datastore_write_end_time}    ${config_datastore_write_start_time}
    ${config_datastore_write_rate}=    Evaluate    ${flow_count_after_add} / ${config_datastore_write_time}
    Set Suite Variable    ${config_datastore_write_start_time}
    Log to console    ${\n}
    Log to console    The config_datastore_write_time is ${config_datastore_write_time}
    Log to console    The config_datastore_write_rate is ${config_datastore_write_rate}

Verify Flows In Switch
    [Documentation]    Verify 100K flows are installed in 10 switches.
    ${Mininet_write_start_time}=    Get Current Date    result_format=timestamp
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${switch_count}    ${flow_count_per_switch}    ${operation_timeout}
    ${Mininet_write_end_time}=    Get Current Date    result_format=timestamp
    ${Mininet_write_time}=    Subtract Date From Date    ${Mininet_write_end_time}    ${config_datastore_write_start_time}
    ${Mininet_write_rate}=    Evaluate    ${flow_count_after_add} / ${Mininet_write_time}
    Log to console    ${\n}
    Log to console    The Mininet_write_time is ${Mininet_write_time}
    Log to console    The Mininet_write_rate is ${Mininet_write_rate}

Verify Flows In Oper DS
    [Documentation]    Check Flows in Operational Datastore
    Wait Until Keyword Succeeds    ${oper_ds_timeout}    2s    ClusterOpenFlow.Check_Flows_Inventory_Oper_DS    ${switch_count}    ${flow_count_after_add}    ${Inventory_Leader}
    ${Oper_ds_write_end_time}=    Get Current Date    result_format=timestamp
    ${Oper_ds_write_time}=    Subtract Date From Date    ${Oper_ds_write_end_time}    ${config_datastore_write_start_time}
    ${Oper_ds_write_rate}=    Evaluate    ${flow_count_after_add} / ${Oper_ds_write_time}
    Log to console    ${\n}
    Log to console    The Oper_ds_write_time_write_time is ${Oper_ds_write_time}
    Log to console    The Oper_ds_write_rate is ${Oper_ds_write_rate}

Stop Mininet Connected To Follower Node1 After Reconcilliation
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Delete All Flows From Follower Node2
    [Documentation]    100K Flows deleted via Follower Node2 and verify it gets applied in all instances.
    ${config_datastore_delete_start_time}=    Get Current Date    result_format=timestamp
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_2}    ${operation_timeout}
    Set Suite Variable    ${config_datastore_delete_start_time}

Verify No Flows In Cluster
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${inventory_leader_list}
    ${config_datastore_delete_end_time}=    Get Current Date    result_format=timestamp
    ${config_datastore_delete_time}=    Subtract Date From Date    ${config_datastore_delete_end_time}    ${config_datastore_delete_start_time}
    ${config_datastore_delete_rate}=    Evaluate    ${flow_count_after_add} / ${config_datastore_delete_time}
    Log to console    ${\n}
    Log to console    The config_datastore_delete_time is ${config_datastore_delete_time}
    Log to console    The config_datastore_delete_rate is ${config_datastore_delete_rate}
