*** Settings ***
Documentation     Test suite for 3Node Cluster - 100K flows and 10 DPNs in Cluster Scale Up scenario
Suite Setup       ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           DateTime
Library           OperatingSystem
Library           ../../../libraries/ScaleClient.py
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../variables/openflowplugin/Variables.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${operation_timeout}    250s
${oper_ds_timeout}    400s
${mininet_timeout}    120s
${flow_count}     100000
${switch_count}    100
${swspread}       linear
${tabspread}      first
${fpr}            200
${nrthreads}      5
${karaf_log_level}    log:set WARN
${rate_results_file}    rate.csv
${time_results_file}    time.csv

*** Test Cases ***
Initialize Variables
    [Documentation]    Initialize variables and set the log.
    Wait Until Keyword Succeeds    3x    3s    ClusterManagement.Run_Karaf_Command_On_List_Or_All    ${karaf_log_level}
    ${controller_list}=    Create List    ${ODL_SYSTEM_IP}
    Set Suite Variable    ${controller_list}
    ${flows}    ${notes}    ScaleClient.Generate New Flow Details    flows=${flow_count}    switches=${switch_count}    swspread=${swspread}    tabspread=${tabspread}
    Set Suite Variable    ${flows}

Start Mininet And verify Switches
    [Documentation]    Start mininet.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_IP}    --topo linear,${switch_count}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    ${switch_count}    1

Add Bulk Flow Via REST
    [Documentation]    100K Flows (1K Flows per DPN) in 100 DPN added and verify it gets applied.
    ${config_datastore_write_start_time}=    DateTime.Get Current Date    result_format=timestamp
    ScaleClient.Configure Flows Bulk    flow_details=${flows}    controllers=${controller_list}    nrthreads=${nrthreads}    fpr=${fpr}
    ${config_datastore_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${config_datastore_write_time}=    DateTime.Subtract Date From Date    ${config_datastore_write_end_time}    ${config_datastore_write_start_time}
    ${config_datastore_write_rate}=    BuiltIn.Evaluate    ${flow_count} / ${config_datastore_write_time}
    BuiltIn.Set Suite Variable    ${config_datastore_write_start_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The config_datastore_write_time is ${config_datastore_write_time}
    BuiltIn.Log to console    The config_datastore_write_rate is ${config_datastore_write_rate}
    BuiltIn.Set Suite Variable    ${config_datastore_write_time}
    BuiltIn.Set Suite Variable    ${config_datastore_write_rate}

Verify Flows In Switch
    [Documentation]    Verify 100K flows are installed in 100 switches.
    ${Mininet_write_start_time}=    DateTime.Get Current Date    result_format=timestamp
    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flow_count}    ${operation_timeout}
    ${Mininet_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${Mininet_write_time}=    DateTime.Subtract Date From Date    ${Mininet_write_end_time}    ${config_datastore_write_start_time}
    ${Mininet_write_rate}=    BuiltIn.Evaluate    ${flow_count} / ${Mininet_write_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The Mininet_write_time is ${Mininet_write_time}
    BuiltIn.Log to console    The Mininet_write_rate is ${Mininet_write_rate}
    BuiltIn.Set Suite Variable    ${Mininet_write_time}
    BuiltIn.Set Suite Variable    ${Mininet_write_rate}

Verify Flows In Oper DS
    [Documentation]    Check Flows in Operational Datastore
    BuiltIn.Wait Until Keyword Succeeds    ${oper_ds_timeout}    2s    ClusterOpenFlow.Check_Flows_Operational_Datastore_On_Member    ${flow_count}    1
    ${oper_datastore_write_end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${oper_datastore_write_time}=    DateTime.Subtract Date From Date    ${oper_datastore_write_end_time}    ${config_datastore_write_start_time}
    ${oper_datastore_write_rate}=    BuiltIn.Evaluate    ${flow_count} / ${oper_datastore_write_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The operational_datastore_write_time is ${oper_datastore_write_time}
    BuiltIn.Log to console    The operational_datastore_write_rate is ${oper_datastore_write_rate}
    BuiltIn.Set Suite Variable    ${oper_datastore_write_time}
    BuiltIn.Set Suite Variable    ${oper_datastore_write_rate}

Stop Mininet And Verify
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    ${mininet_timeout}    2s    ClusterOpenFlow.Verify_Switch_Connections_Running_On_Member    0    1

Delete All Flows
    [Documentation]    100K Flows deleted and verify.
    ${config_datastore_delete_start_time}=    DateTime.Get Current Date    result_format=timestamp
    ClusterManagement.Delete From Member    ${RFC8040_NODES_API}    1
    ${config_datastore_delete_end_time}=    Get Current Date    result_format=timestamp
    ${config_datastore_delete_time}=    Subtract Date From Date    ${config_datastore_delete_end_time}    ${config_datastore_delete_start_time}
    ${config_datastore_delete_rate}=    Evaluate    ${flow_count} / ${config_datastore_delete_time}
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log to console    The config_datastore_delete_time is ${config_datastore_delete_time}
    BuiltIn.Log to console    The config_datastore_delete_rate is ${config_datastore_delete_rate}
    BuiltIn.Set Suite Variable    ${config_datastore_delete_time}
    BuiltIn.Set Suite Variable    ${config_datastore_delete_rate}

Log Results And Determine Status
    [Documentation]    Log results for plotting.
    OperatingSystem.Append To File    ${rate_results_file}    Config DS,OVS Switch,Operational DS\n
    OperatingSystem.Append To File    ${rate_results_file}    ${config_datastore_write_rate},${Mininet_write_rate},${oper_datastore_write_rate}\n
    OperatingSystem.Append To File    ${time_results_file}    Config DS,OVS Switch,Operational DS\n
    OperatingSystem.Append To File    ${time_results_file}    ${config_datastore_write_time},${Mininet_write_time},${oper_datastore_write_time}\n
