*** Settings ***
Documentation     Test suite for 3Node Cluster - 100K flows and 10 DPNs in Cluster Scale Up scenario
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           DateTime
Library           OperatingSystem
Resource          ../../../libraries/BulkomaticKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${enable_openflow_tls}    False
${operation_timeout}    120s
${oper_ds_timeout}    120s
${mininet_timeout}    120s
${flow_count_per_switch}    1000
${delay}          2s
${switch_count}    1
${karaf_log_level}    log:set INFO
${orig_json_config_add}    sal_add_bulk_flow_config.json
${orig_json_config_get}    sal_get_bulk_flow_config.json
${orig_json_config_del}    sal_del_bulk_flow_config.json
${rate_results_file}    rate.csv
${time_results_file}    time.csv

*** Test Cases ***
Initialize Variables
    [Documentation]    Initialize Variables and set the log.
    Wait Until Keyword Succeeds    3x    3s    ClusterManagement.Run_Karaf_Command_On_List_Or_All    ${karaf_log_level}
    ${flow_count_after_add}=    BuiltIn.Evaluate    ${flow_count_per_switch} * ${switch_count}
    BuiltIn.Set Suite Variable    ${flow_count_after_add}
    ${temp_json_config_add}    BulkomaticKeywords.Set DPN And Flow Count In Json Add    ${orig_json_config_add}    ${switch_count}    ${flow_count_per_switch}
    ${temp_json_config_get}    BulkomaticKeywords.Set DPN And Flow Count In Json Get    ${orig_json_config_get}    ${switch_count}    ${flow_count_after_add}
    ${temp_json_config_del}    BulkomaticKeywords.Set DPN And Flow Count In Json Del    ${orig_json_config_del}    ${switch_count}    ${flow_count_per_switch}
    BuiltIn.Set Suite Variable    ${temp_json_config_add}
    BuiltIn.Set Suite Variable    ${temp_json_config_get}
    BuiltIn.Set Suite Variable    ${temp_json_config_del}

Start Mininet And verify Switches
    [Documentation]    Start mininet, controller OF port 6653 should be enabled for TLS while port 6633 should be for TCP.
    ${ofport}    Set Variable If    '${enable_openflow_tls}' == 'True'    6653    6633
    ${protocol}    Set Variable If    '${enable_openflow_tls}' == 'True'    ssl    tcp
    #MininetKeywords.Disconnect Controller Mininet    break
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers    options=--topo linear,${switch_count}    ofport=${ofport}    protocol=${protocol}
    #MininetKeywords.Disconnect Controller Mininet    restore
    ${topology_start_time}=    DateTime.Get Current Date    result_format=timestamp
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    ${switch_count}    1
    ${topology_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${topology_time}=    DateTime.Subtract Date From Date    ${topology_end_time}    ${topology_start_time}
    ${topology_rate}=    BuiltIn.Evaluate    ${switch_count} / ${topology_time}
    BuiltIn.Set Suite Variable    ${topology_time}
    BuiltIn.Set Suite Variable    ${topology_rate}
    Comment    Fail the entire suite if switches cannot connect
    [Teardown]    Run Keyword If Test Failed    Fatal Error

Stop Mininet And Verify
    [Documentation]    Stop mininet and exit connection.
    Sleep    10
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    0    1

Log Results And Determine Status
    [Documentation]    Log results for plotting.
    OperatingSystem.Append To File    ${rate_results_file}    Config DS,OVS Switch,Operational DS\n
    OperatingSystem.Append To File    ${rate_results_file}    ${topology_rate}\n
    OperatingSystem.Append To File    ${time_results_file}    Config DS,OVS Switch,Operational DS\n
    OperatingSystem.Append To File    ${time_results_file}    ${topology_time}\n
