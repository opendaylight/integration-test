*** Settings ***
Documentation     Test suite for OF-18 Spurious Leader Election verification of term change while flows are added/deleted    #
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    400s
${restart_timeout}    450s
####remove after execution ###
${flow_count_per_switch}    1000
${flow_count_per_switch_ten_percent}    100
${switch_count}    1
${flow_count_after_add}    1000
${flow_count_after_del}    0
${flow_count_after_del_ten_percent}    900
#### remove after execution ###
#${flow_count_per_switch}    10000
#${flow_count_per_switch_ten_percent}    1000
#${switch_count}    15
#${flow_count_after_add}    150000
#${flow_count_after_del}    0
#${flow_count_after_del_ten_percent}    135000
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json
${orig_json_config_table_add}    add_table.json
${shard_name}     inventory
${shard_type}     config
${verify_restconf}    False
${Current_Term}    CurrentTerm
${LastIndex}      LastIndex
${LastApplied}    LastApplied

*** Test Cases ***
Check Shard And Get Inventory
    Check Shards Status And Initialize Variables
    Get Inventory Follower

Initial Current Term Verification
    [Documentation]    Verifying current term for Leader Node Before
    ${current_term_value_before}    ${data_object}    Get_Current_Term_Of_Shard_At_Member
    BuiltIn.Log to console    Current Term is ${current_term_value_before}
    BuiltIn.Set Suite Variable    ${current_term_value_before}

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
    [Documentation]    Find a leader and followers in the inventory config shard
    ${current_term_value}    ${data_object}    ClusterManagement.Get_Raft_Property_From_Shard_Member    ${shard_name}    ${shard_type}    ${Inventory_Leader}    ${Current_Term}
    ...    ${verify_restconf}
    [Return]    ${current_term_value}    ${data_object}

Get_Last_Index_Of_Shard_At_Member
    [Documentation]    Find a leader and followers in the inventory config shard
    ${LastIndex}    ${data_object}    ClusterManagement.Get_Raft_Property_From_Shard_Member    ${shard_name}    ${shard_type}    ${Inventory_Leader}    ${Last_Index}
    ...    ${verify_restconf}
    [Return]    ${LastIndex}

Get_Last_Applied_Of_Shard_At_Member
    [Documentation]    Find a leader and followers in the inventory config shard
    ${LastApplied}    ${data_object}    ClusterManagement.Get_Raft_Property_From_Shard_Member    ${shard_name}    ${shard_type}    ${Inventory_Leader}    ${Last_Applied}
    ...    ${verify_restconf}
    [Return]    ${LastApplied}
