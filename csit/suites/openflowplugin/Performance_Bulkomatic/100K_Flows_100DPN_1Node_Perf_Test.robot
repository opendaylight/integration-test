*** Settings ***
Documentation       Test suite for 3Node Cluster - 100K flows and 10 DPNs in Cluster Scale Up scenario

Library             DateTime
Library             OperatingSystem
Resource            ../../../libraries/BulkomaticKeywords.robot
Resource            ../../../libraries/MininetKeywords.robot
Resource            ../../../libraries/ClusterManagement.robot
Resource            ../../../libraries/ClusterOpenFlow.robot
Variables           ../../../variables/Variables.py

Suite Setup         ClusterManagement Setup
Suite Teardown      Delete All Sessions


*** Variables ***
${enable_openflow_tls}      True
${operation_timeout}        250s
${oper_ds_timeout}          400s
${mininet_timeout}          120s
${flow_count_per_switch}    1000
${switch_count}             100
${karaf_log_level}          log:set WARN
${orig_json_config_add}     sal_add_bulk_flow_config.json
${orig_json_config_get}     sal_get_bulk_flow_config.json
${orig_json_config_del}     sal_del_bulk_flow_config.json
${rate_results_file}        rate.csv
${time_results_file}        time.csv


*** Test Cases ***
Initialize Variables
    [Documentation]    Initialize Variables and set the log.
    Wait Until Keyword Succeeds    3x    3s    ClusterManagement.Run_Karaf_Command_On_List_Or_All    ${karaf_log_level}
    ${flow_count_after_add}=    BuiltIn.Evaluate    ${flow_count_per_switch} * ${switch_count}
    BuiltIn.Set Suite Variable    ${flow_count_after_add}
    ${temp_json_config_add}=    BulkomaticKeywords.Set DPN And Flow Count In Json Add
    ...    ${orig_json_config_add}
    ...    ${switch_count}
    ...    ${flow_count_per_switch}
    ${temp_json_config_get}=    BulkomaticKeywords.Set DPN And Flow Count In Json Get
    ...    ${orig_json_config_get}
    ...    ${switch_count}
    ...    ${flow_count_after_add}
    ${temp_json_config_del}=    BulkomaticKeywords.Set DPN And Flow Count In Json Del
    ...    ${orig_json_config_del}
    ...    ${switch_count}
    ...    ${flow_count_per_switch}
    BuiltIn.Set Suite Variable    ${temp_json_config_add}
    BuiltIn.Set Suite Variable    ${temp_json_config_get}
    BuiltIn.Set Suite Variable    ${temp_json_config_del}

Start Mininet And verify Switches
    [Documentation]    Start mininet, controller OF port 6653 should be enabled for TLS while port 6633 should be for TCP.
    ${ofport}=    Set Variable If    '${enable_openflow_tls}' == 'True'    6653    6633
    ${protocol}=    Set Variable If    '${enable_openflow_tls}' == 'True'    ssl    tcp
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers
    ...    options=--topo linear,${switch_count}
    ...    ofport=${ofport}
    ...    protocol=${protocol}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds
    ...    ${mininet_timeout}
    ...    2s
    ...    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member
    ...    ${switch_count}
    ...    1
    Comment    Fail the entire suite if switches cannot connect
    [Teardown]    Run Keyword If Test Failed    Fatal Error

Add Bulk Flow
    [Documentation]    100K Flows (1K Flows per DPN) in 100 DPN added and verify it gets applied.
    ${config_datastore_write_start_time}=    DateTime.Get Current Date    result_format=timestamp
    BulkomaticKeywords.Add Bulk Flow In Node    ${temp_json_config_add}    1    ${operation_timeout}
    ${config_datastore_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${config_datastore_write_time}=    DateTime.Subtract Date From Date
    ...    ${config_datastore_write_end_time}
    ...    ${config_datastore_write_start_time}
    ${config_datastore_write_rate}=    BuiltIn.Evaluate    ${flow_count_after_add} / ${config_datastore_write_time}
    BuiltIn.Set Suite Variable    ${config_datastore_write_start_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The config_datastore_write_time is ${config_datastore_write_time}
    BuiltIn.Log to console    The config_datastore_write_rate is ${config_datastore_write_rate}
    BuiltIn.Set Suite Variable    ${config_datastore_write_time}
    BuiltIn.Set Suite Variable    ${config_datastore_write_rate}

Verify Flows In Switch
    [Documentation]    Verify 100K flows are installed in 100 switches.
    ${Mininet_write_start_time}=    DateTime.Get Current Date    result_format=timestamp
    MininetKeywords.Verify Aggregate Flow From Mininet Session
    ...    ${mininet_conn_id}
    ...    ${flow_count_after_add}
    ...    ${operation_timeout}
    ${Mininet_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${Mininet_write_time}=    DateTime.Subtract Date From Date
    ...    ${Mininet_write_end_time}
    ...    ${config_datastore_write_start_time}
    ${Mininet_write_rate}=    BuiltIn.Evaluate    ${flow_count_after_add} / ${Mininet_write_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The Mininet_write_time is ${Mininet_write_time}
    BuiltIn.Log to console    The Mininet_write_rate is ${Mininet_write_rate}
    BuiltIn.Set Suite Variable    ${Mininet_write_time}
    BuiltIn.Set Suite Variable    ${Mininet_write_rate}

Verify Flows In Oper DS
    [Documentation]    Check Flows in Operational Datastore
    BuiltIn.Wait Until Keyword Succeeds
    ...    ${oper_ds_timeout}
    ...    2s
    ...    ClusterOpenFlow.Check_Flows_Operational_Datastore_On_Member
    ...    ${flow_count_after_add}
    ...    1
    ${oper_datastore_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${oper_datastore_write_time}=    DateTime.Subtract Date From Date
    ...    ${oper_datastore_write_end_time}
    ...    ${config_datastore_write_start_time}
    ${oper_datastore_write_rate}=    BuiltIn.Evaluate    ${flow_count_after_add} / ${oper_datastore_write_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The operational_datastore_write_time is ${oper_datastore_write_time}
    BuiltIn.Log to console    The operational_datastore_write_rate is ${oper_datastore_write_rate}
    BuiltIn.Set Suite Variable    ${oper_datastore_write_time}
    BuiltIn.Set Suite Variable    ${oper_datastore_write_rate}

Stop Mininet And Verify
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds
    ...    ${mininet_timeout}
    ...    2s
    ...    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member
    ...    0
    ...    1

Delete All Flows
    [Documentation]    100K Flows deleted and verify.
    ${config_datastore_delete_start_time}=    DateTime.Get Current Date    result_format=timestamp
    BulkomaticKeywords.Delete Bulk Flow In Node    ${temp_json_config_del}    1    ${operation_timeout}
    ${config_datastore_delete_end_time}=    Get Current Date    result_format=timestamp
    ${config_datastore_delete_time}=    Subtract Date From Date
    ...    ${config_datastore_delete_end_time}
    ...    ${config_datastore_delete_start_time}
    ${config_datastore_delete_rate}=    Evaluate    ${flow_count_after_add} / ${config_datastore_delete_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The config_datastore_delete_time is ${config_datastore_delete_time}
    BuiltIn.Log to console    The config_datastore_delete_rate is ${config_datastore_delete_rate}
    BuiltIn.Set Suite Variable    ${config_datastore_delete_time}
    BuiltIn.Set Suite Variable    ${config_datastore_delete_rate}

Log Results And Determine Status
    [Documentation]    Log results for plotting.
    OperatingSystem.Append To File    ${rate_results_file}    Config DS,OVS Switch,Operational DS\n
    OperatingSystem.Append To File
    ...    ${rate_results_file}
    ...    ${config_datastore_write_rate},${Mininet_write_rate},${oper_datastore_write_rate}\n
    OperatingSystem.Append To File    ${time_results_file}    Config DS,OVS Switch,Operational DS\n
    OperatingSystem.Append To File
    ...    ${time_results_file}
    ...    ${config_datastore_write_time},${Mininet_write_time},${oper_datastore_write_time}\n
