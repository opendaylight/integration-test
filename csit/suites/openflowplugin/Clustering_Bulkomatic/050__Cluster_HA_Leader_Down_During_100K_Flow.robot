*** Settings ***
Documentation     Test suite for Cluster HA with Bulk Flows - Leader going down when 100K Flow installation in Config DS
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
${flow_count_per_switch}    10000
${switch_count}    10
${flow_count_after_del}    0
${karaf_log_level}    log:set ERROR
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json

*** Test Cases ***
TCT_Check Shards Status And Initialize Variables
    [Documentation]    Check Status for all shards in OpenFlow application and set the logs across cluster nodes.
    ClusterOpenFlow.Check OpenFlow Shards Status
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    ${karaf_log_level}
    ${flow_count_after_add}=    BuiltIn.Evaluate    ${flow_count_per_switch} * ${switch_count}
    BuiltIn.Set Suite Variable    ${flow_count_after_add}
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    BuiltIn.Set Suite Variable    ${temp_json_config_add}
    BuiltIn.Set Suite Variable    ${temp_json_config_get}
    BuiltIn.Set Suite Variable    ${temp_json_config_del}

TCT_Get Inventory Config Shard Follower And Leader
    [Documentation]    Find a leader and followers in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${Follower_Node_1}=    Get From List    ${Inventory_Followers}    0
    ${Follower_Node_2}=    Get From List    ${Inventory_Followers}    1
    ${Inventory_Leader_List}=    Create List    ${inventory_leader}
    ${Inventory_Follower_Node1_List}=    Create List    ${Follower_Node_1}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The follower Node1 is ${Follower_Node_1}
    BuiltIn.Log to console    The follower Node2 is ${Follower_Node_2}
    BuiltIn.Log to console    The leader Node is ${Inventory_Leader}
    BuiltIn.Set Suite Variable    ${Follower_Node_1}
    BuiltIn.Set Suite Variable    ${Follower_Node_2}
    BuiltIn.Set Suite Variable    ${Inventory_Leader}
    BuiltIn.Set Suite Variable    ${Inventory_Leader_List}
    BuiltIn.Set Suite Variable    ${Inventory_Follower_Node1_List}

TCT_Add Bulk Flow From Follower
    [Documentation]    100K Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow    ${temp_json_config_add}    ${Follower_Node_1}
    Sleep    60

TCT_Kill Leader Node
    [Documentation]    Kill Leader Node.
    ClusterManagement.Kill Single Member    ${Inventory_Leader}


TCT_Wait For Write To Finish
     [Documentation]   Wait for write to finish in the node.
     ${status}=    Run Keyword And Return Status    BulkomaticKeywords.Wait Until Write Finishes    ${Follower_Node_1}    ${restart_timeout}
     Run Keyword If    '${status}' == 'False'    BuiltIn.Log to console    The Write was expected to fail

TCT_Restart Leader Node
    [Documentation]    Start Leader Node Up.
    ClusterManagement.Start Single Member    ${Inventory_Leader}

TCT_Verify Success Failure Flow Count 
    [Documentation]    Compare initial flow count with Success and failure flow count combined.
    BulkomaticKeywords.Verify Success Failure Count    ${flow_count_after_add}    ${Follower_Node_1}

TCT_Delete All Flows From Follower Node1
    [Documentation]    100K Flows deleted via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

TCT_Verify No Flows In Cluster
    [Documentation]    Verify flow count is 0 across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${Inventory_Leader_List}
