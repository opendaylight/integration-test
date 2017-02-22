*** Settings ***
Documentation     Test suite for OF-18 Spurious Leader Election verifying term change while flows are added/deleted
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Library 	  DebugLibrary
*** Variables ***
${operation_timeout}    400s
${restart_timeout}    450s
${flow_count_per_switch}    100
${switch_count}    15
${flow_count_after_add}    1500
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

Get Inventory Follower 
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

Initial Current Term Verification 
    [Documentation]    Verifying current term for Leader Node Before
    ${current_term_value_before}   ClusterManagement.Get_Current Term Of Shard At Member   inventory    config    ${Inventory_Leader}    False
    BuiltIn.Log to console    Current Term is ${current_term_value_before}    
    BuiltIn.Set Suite Variable    ${current_term_value_before}

Add Bulk Flow From Follower
    [Documentation]    1000 Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_1}    ${operation_timeout}

Get Bulk Flows and Verify In Cluster
    [Documentation]    Initiate get operation and check flow count across cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}

Current Term verification after adding bulk flow
    [Documentation]    Verifying current term for Leader Node after pushing the flows
    ${current_term_value_after}    ClusterManagement.Get_Current Term Of Shard At Member   inventory    config    ${Inventory_Leader}    False
    BuiltIn.Set Suite Variable    ${current_term_value_after}

Current term Comparison before and after addition of flow
    BuiltIn.Log to console    Current Term after pushing the flows is ${current_term_value_after}
    Run Keyword If    ${current_term_value_before} == ${current_term_value_after}    Log    SUCCESS    ELSE    Log    FAILURE
    Should Be Equal    ${current_term_value_before}    ${current_term_value_after}


Delete All Flows From Follower Node 2
    [Documentation]    1000 Flows deleted via Leader Node and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

Verify No Flows In Cluster After Follower Node2 Restart
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${Inventory_Leader_List}
