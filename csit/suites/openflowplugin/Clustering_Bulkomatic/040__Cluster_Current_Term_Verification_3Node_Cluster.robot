*** Settings ***
Documentation     Test suite for OF-18 Spurious Leader Election verification of term change while flows are added/deleted    #
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    Delete All Sessions
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    400s
${restart_timeout}    450s
${flow_count_per_switch}    10000
${flow_count_per_switch_ten_percent}    1000
${switch_count}    1
${flow_count_after_add}    10000
${flow_count_after_del}    0
${flow_count_after_del_ten_percent}    9000
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json
${orig_json_config_table_add}    add_table.json
${shard_name}     inventory
${shard_type}     config
${verify_restconf}    False

*** Test Cases ***
Check Shard And Get Inventory
    [Documentation]    Check Status for all shards and Finding a leader and followers in the inventory config shard
    Check Shards Status And Initialize Variables
    Get Inventory Follower

Initial Current Term Verification
    [Documentation]    Verifying current term for Leader Node Before
    ${current_term_value_before}    Get_Current_Term_Of_Shard_At_Member
    BuiltIn.Log to console    Current Term is ${current_term_value_before}
    BuiltIn.Set Suite Variable    ${current_term_value_before}

Add Bulk Flow From Follower
    [Documentation]    ${flow_count_after_add} Flows added via Follower Node1 and verify it gets applied in all instances.
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    ${Follower_Node_1}    ${operation_timeout}

Get Bulk Flows And Verify In Cluster
    [Documentation]    Initiate get operation and check flow count across cluster nodes
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Inventory_Leader_List}

Current Term Verification After Adding Bulk Flow
    [Documentation]    Verifying current term for Leader Node after pushing the flows
    ${current_term_value_after}    Get_Current_Term_Of_Shard_At_Member
    BuiltIn.Set Suite Variable    ${current_term_value_after}

Current Term Comparison Before And After Addition Of Flow
    [Documentation]    Comparison of Current Term Before and After Addition of Flows
    BuiltIn.Log to console    Current Term after pushing the flows is ${current_term_value_after}
    Run Keyword If    ${current_term_value_before} == ${current_term_value_after}    Log    SUCCESS
    ...    ELSE    Log    FAILURE
    Should Be Equal    ${current_term_value_before}    ${current_term_value_after}

Delete and Add ten percent of the flows for 5 iterations
    [Documentation]    Performeing 5 iterations for Delete and Add ten Percentage of the flows
    : FOR    ${index}    IN RANGE    1    6
    \    Log    ${index}
    \    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del_ten_percent}    ${Follower_Node_1}    ${operation_timeout}
    \    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del_ten_percent}    ${Inventory_Leader_List}
    \    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add_ten_percent}    ${Follower_Node_1}    ${operation_timeout}
    \    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_add}    ${Inventory_Leader_List}

Current Term Verification After Continuous Deletion and Addition Of Flows for 5 iterations
    [Documentation]    Verifying current term for Leader Node after continuous deletion and addition of ten percent of the flows
    ${current_term_value_after}    Get_Current_Term_Of_Shard_At_Member
    BuiltIn.Set Suite Variable    ${current_term_value_after}

Current Term Comparison Before and After Continuous Deletion and Addition Of Flows for 5 iterations
    [Documentation]    Comparison Current Term Before and After Continuous Deletion and Addition Of Flows for 5 iterations
    BuiltIn.Log to console    Current Term after pushing the flows is ${current_term_value_after}
    Run Keyword If    ${current_term_value_before} == ${current_term_value_after}    Log    SUCCESS
    ...    ELSE    Log    FAILURE
    Should Be Equal    ${current_term_value_before}    ${current_term_value_after}

Delete All Flows From Follower Node
    [Documentation]    ${flow_count_after_add} Flows deleted via Leader Node and verify it gets applied in all instances.
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    ${Follower_Node_1}    ${operation_timeout}

Verify No Flows In Cluster After Flow Deletion
    [Documentation]    Verifying No FLows in Cluster after Flows Deletion
    BulkomaticKeywords.Get Bulk Flow And Verify Count In Cluster    ${temp_json_config_get}    ${operation_timeout}    ${flow_count_after_del}    ${Inventory_Leader_List}

PreLeader Verification
    [Documentation]    Verifying LastIndex and LastApplied and compare both are equal
    ${LastIndex}    Get_Last_Index_Of_Shard_At_Member
    ${LastApplied}    Get_Last_Applied_Of_Shard_At_Member
    Should Be Equal    ${LastIndex}    ${LastApplied}
    BulkomaticKeywords.Add Table In Node    ${temp_json_config_table}    ${Follower_Node_1}    ${operation_timeout}
    ${LastIndex}    Get_Last_Index_Of_Shard_At_Member
    ${LastApplied}    Get_Last_Applied_Of_Shard_At_Member
    Should Be Equal    ${LastIndex}    ${LastApplied}

*** Keywords ***
Check Shards Status And Initialize Variables
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_del_ten_percent}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch_ten_percent}
    ${temp_json_config_add_ten_percent}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch_ten_percent}
    ${temp_json_config_table}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_table_add}    ${switch_count}    ${flow_count_per_switch}
    Set Suite Variable    ${temp_json_config_add}
    Set Suite Variable    ${temp_json_config_get}
    Set Suite Variable    ${temp_json_config_del}
    Set Suite Variable    ${temp_json_config_del_ten_percent}
    Set Suite Variable    ${temp_json_config_add_ten_percent}
    Set Suite Variable    ${temp_json_config_table}

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

Get_Current_Term_Of_Shard_At_Member
    [Documentation]    Find a Raft Property Values From Shard Member
    ${current_term_value} =    ClusterManagement.Get_Raft_Property_From_Shard_Member    CurrentTerm    ${shard_name}    ${shard_type}    ${Inventory_Leader}    ${verify_restconf}
    [Return]    ${current_term_value}

Get_Last_Index_Of_Shard_At_Member
    [Documentation]    Find a leader and followers in the inventory config shard
    ${LastIndex} =    ClusterManagement.Get_Raft_Property_From_Shard_Member    LastIndex    ${shard_name}    ${shard_type}    ${Inventory_Leader}    ${verify_restconf}
    [Return]    ${LastIndex}

Get_Last_Applied_Of_Shard_At_Member
    [Documentation]    Find a leader and followers in the inventory config shard
    ${LastApplied} =    ClusterManagement.Get_Raft_Property_From_Shard_Member    LastApplied    ${shard_name}    ${shard_type}    ${Inventory_Leader}    ${verify_restconf}
    [Return]    ${LastApplied}
