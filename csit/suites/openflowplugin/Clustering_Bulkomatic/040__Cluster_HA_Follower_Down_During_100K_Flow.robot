*** Settings ***
Documentation     Test suite for Cluster HA with Bulk Flows - Follower going down when 100K Flow installation in Config DS
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot    #Resource    ../../../libraries/BulkomaticKeywords_flow_count_fix.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    300s
${restart_timeout}    150s
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

Get Inventory Config Shard Follower And Leader
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

Add Bulk Flow From Follower
    [Documentation]    100K Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow    ${temp_json_config_add}    ${Follower_Node_1}
    Log To Console    Started adding flows


Get Bulk Flows And Verify In Leader
    [Documentation]    Initiate get operation and check flow count across cluster nodes.
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Inventory_Leader_List}

#Kill Follower Node2
#    [Documentation]    Kill Follower Node2.
#    ClusterManagement.Kill Single Member    ${Follower_Node_2}
#
#Wait For Write To Finish
#    [Documentation]    Wait for write to finish in the node.
#    BulkomaticKeywords.Wait Until Write Finishes    ${Follower_Node_1}    ${restart_timeout}
#
#Verify Success Failure Flow Count
#    [Documentation]    Compare initial flow count with Success and failure flow count combined.
#    BulkomaticKeywords.Verify Success Failure Count    ${flow_count_after_add}    ${Follower_Node_1}
#
#Restart Follower Node2
#    [Documentation]    Start Follower Node2 Up.
#    ClusterManagement.Start Single Member    ${Follower_Node_2}
#
#Delete All Flows From Follower Node2
#    [Documentation]    100K Flows deleted via Follower Node2 and verify it gets applied in all instances.
#    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_2}    ${operation_timeout}
#
#Verify No Flows In Cluster
#    [Documentation]    Verify flow count is 0 across cluster nodes.
#    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${Inventory_Leader_List}
