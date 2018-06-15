*** Settings ***
Documentation     Test suite for RPC performance
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
${enable_openflow_tls}    True
${operation_timeout}    250s
${oper_ds_timeout}    400s
${mininet_timeout}    120s
${switch_count}    32
${flow_count_per_switch}    15000
${karaf_log_level}    log:set INFO
${orig_json_rpc_add}    sal_add_bulk_flow_rpc.json
${rate_results_file}    rate.csv
${time_results_file}    time.csv

*** Test Cases ***
Initialize Variables
    [Documentation]    Initialize Variables and set the log.
    Wait Until Keyword Succeeds    3x    3s    ClusterManagement.Run_Karaf_Command_On_List_Or_All    ${karaf_log_level}
    ${flow_count}=    BuiltIn.Evaluate    ${flow_count_per_switch} * ${switch_count}
    BuiltIn.Set Suite Variable    ${flow_count}
    ${temp_json_rpc_add}    BulkomaticKeywords.Set Flow Count In Json Add RPC    ${orig_json_rpc_add}    ${flow_count_per_switch}
    BuiltIn.Set Suite Variable    ${temp_json_rpc_add}

Start Mininet And verify Switches
    [Documentation]    Start mininet, controller OF port 6653 should be enabled for TLS while port 6633 should be for TCP.
    ${ofport}    Set Variable If    '${enable_openflow_tls}' == 'True'    6653    6633
    ${protocol}    Set Variable If    '${enable_openflow_tls}' == 'True'    ssl    tcp
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers    options=--topo linear,${switch_count}    ofport=${ofport}    protocol=${protocol}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    ${switch_count}    1
    Comment    Fail the entire suite if switches cannot connect
    [Teardown]    Run Keyword If Test Failed    Fatal Error

Add Bulk Flow
    [Documentation]    100K Flows (1K Flows per DPN) in 100 DPN added and verify it gets applied.
    ${rpc_write_start_time}=    DateTime.Get Current Date    result_format=timestamp
    BulkomaticKeywords.Add Bulk Flow RPC    ${temp_json_rpc_add}    1
    ${rpc_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${rpc_write_time}=    DateTime.Subtract Date From Date    ${rpc_write_end_time}    ${rpc_write_start_time}
    ${rpc_write_rate}=    BuiltIn.Evaluate    ${flow_count} / ${rpc_write_time}
    BuiltIn.Set Suite Variable    ${rpc_write_start_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The rpc_write_time is ${rpc_write_time}
    BuiltIn.Log to console    The rpc_write_rate is ${rpc_write_rate}
    BuiltIn.Set Suite Variable    ${rpc_write_time}
    BuiltIn.Set Suite Variable    ${rpc_write_rate}

Verify Flows In Switch
    [Documentation]    Verify 100K flows are installed in 100 switches.
    ${Mininet_write_start_time}=    DateTime.Get Current Date    result_format=timestamp
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count}    ${operation_timeout}
    ${Mininet_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${Mininet_write_time}=    DateTime.Subtract Date From Date    ${Mininet_write_end_time}    ${rpc_write_start_time}
    ${Mininet_write_rate}=    BuiltIn.Evaluate    ${flow_count} / ${Mininet_write_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The Mininet_write_time is ${Mininet_write_time}
    BuiltIn.Log to console    The Mininet_write_rate is ${Mininet_write_rate}
    BuiltIn.Set Suite Variable    ${Mininet_write_time}
    BuiltIn.Set Suite Variable    ${Mininet_write_rate}

Stop Mininet And Verify
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    0    1

Log Results And Determine Status
    [Documentation]    Log results for plotting.
    OperatingSystem.Append To File    ${rate_results_file}    Config DS,OVS Switch\n
    OperatingSystem.Append To File    ${rate_results_file}    ${rpc_write_rate},${Mininet_write_rate}\n
    OperatingSystem.Append To File    ${time_results_file}    Config DS,OVS Switch\n
    OperatingSystem.Append To File    ${time_results_file}    ${rpc_write_time},${Mininet_write_time}\n
