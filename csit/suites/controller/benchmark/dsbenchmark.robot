*** Settings ***
Documentation     MD-SAL Data Store benchmarking.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test suite uses the odl-dsbenchmark-impl feature controlled
...               via dsbenchmark.py tool for testing the MD-SAL Data Store performance.
...               (see the 'https://wiki.opendaylight.org/view/Controller_Core_Functionality_Tutorials:Tutorials:Data_Store_Benchmarking_and_Data_Access_Patterns')
...
...               Based on values in test suite variables it triggers required numbers of
...               warm-up and measured test runs: odl-dsbenchmark-impl module generates
...               (towards MD-SAL Data Store) specified structure, type and number of operations.
...               The test suite performs checks for start-up and test execution timeouts
...               (Start Measurement, Wait For Results) and basic checks for test runs results
...               (Check Results). Finally it provides total numbers per operation structure and type
...               (by default in the perf_per_struct.csv, perf_per_ops.csv files)
...               suitable for plotting in system test environment. See also the
...               'https://wiki.opendaylight.org/view/CrossProject:Integration_Group:System_Test:Step_by_Step_Guide#Optional_-_Plot_a_graph_from_your_job'
...               Included totals can be filtered using the FILTER parameter (RegExp).
...               Because of the way how graphs are drawn, it is recomended to keep
...               all test suite variables unchanged as defined for the 1st build.
...               Parameters WARMUPS, RUNS and accordingly the TIMEOUT value can be changed
...               for each build if needed. Parameter UNITS defines time units returned
...               by odl-dsbenchmark-impl module. The dsbenchmark.py tool always returns
...               values in miliseconds.
...
...               When running this robot suite always use --exclude tag for distinguish
...               the run for 3node setup: need a benchmark for leader and follow (--exclude singlenode_setup)
...               the run for 1node setup: no followr present (--exclude clustered_setup)
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${ODL_LOG_LEVEL}    info
${TX_TYPE}        {TX-CHAINING,SIMPLE-TX}
${OP_TYPE}        {PUT,READ,MERGE,DELETE}
${TOTAL_OPS}      100000
${OPS_PER_TX}     100000
${INNER_OPS}      100000
${WARMUPS}        4
${RUNS}           8
${TIMEOUT}        3h
${FILTER}         EXEC
${UNITS}          microseconds
${tool}           dsbenchmark.py
${tool_args}      ${EMPTY}
${tool_startup_timeout}    10s
${tool_log_name}    dsbenchmark.log
${tool_output_name}    test.csv
${tool_results1_name}    perf_per_struct.csv
${tool_results2_name}    perf_per_ops.csv

*** Test Cases ***
Measure_Both_Datastores_For_One_Node_Odl_Setup
    [Tags]    critical    singlenode_setup
    [Template]    Measuring_Template
    leader    {CONFIG,OPERATIONAL}    both_lead_

Measure_Config_Leader
    [Tags]    critical    clustered_setup
    [Template]    Measuring_Template
    leader    CONFIG    conf_lead_

Measure_Operational_Leader
    [Tags]    critical    clustered_setup
    [Template]    Measuring_Template
    leader    OPERATIONAL    op_lead_

Measure_Config_Follwer
    [Tags]    critical    clustered_setup
    [Template]    Measuring_Template
    follower    CONFIG    conf_fol_

Measure_Operational_Follower
    [Tags]    critical    clustered_setup
    [Template]    Measuring_Template
    follower    OPERATIONAL    op_fol_

Merge_Csvs_Together
    [Documentation]    Merge created csvs into given file necause plot plugin cannot have more
    ...    source files for one graph.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Merge_Csv    perf_per_ops.csv
    Merge_Csv    perf_per_struct.csv

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/mdsal_benchmark/${tool}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    requests
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set ${ODL_LOG_LEVEL}

Teardown_Everything
    [Documentation]    Cleaning-up
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections

Start_Benchmark_Tool
    [Arguments]    ${tested_datastore}    ${tested_node_ip}
    [Documentation]    Start the benchmark tool. Check that it has been running at least for ${tool_startup_timeout} period.
    ${command}=    BuiltIn.Set_Variable    python ${tool} --host ${tested_node_ip} --port ${RESTCONFPORT} --warmup ${WARMUPS} --runs ${RUNS} --total ${TOTAL_OPS} --inner ${INNER_OPS} --txtype ${TX_TYPE} --ops ${OPS_PER_TX} --optype ${OP_TYPE} --plot ${FILTER} --units ${UNITS} --datastore ${tested_datastore} ${tool_args} &> ${tool_log_name}
    BuiltIn.Log    ${command}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session
    ${output}=    SSHLibrary.Write    ${command}
    ${status}    ${message}=    BuiltIn.Run Keyword And Ignore Error    Write Until Expected Output    ${EMPTY}    ${TOOLS_SYSTEM_PROMPT}    ${tool_startup_timeout}
    ...    1s
    BuiltIn.Log    ${status}
    BuiltIn.Log    ${message}
    BuiltIn.Run Keyword If    '${status}' == 'PASS'    BuiltIn.Fail    Benchmark tool is not running

Wait_Until_Benchmark_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait until the benchmark tool is finished. Fail in case of test timeout (${timeout}).
    ...    In order to prevent SSH session from closing due to inactivity, newline is sent every check.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    30s    BuiltIn.Run Keywords    SSHLibrary.Write    ${EMPTY}
    ...    AND    SSHLibrary.Read Until Prompt

Stop_Benchmark_Tool
    [Documentation]    Stop the benchmark tool. Fail if still running.
    SSHLibrary.Read
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read Until Prompt
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session

Get_Log_File
    [Arguments]    ${file_name}
    [Documentation]    Return and log content of the provided file.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    [Return]    ${output_log}

Store_File_To_Robot
    [Arguments]    ${file_name}    ${file_prefix}
    [Documentation]    Store the provided file from the MININET to the ROBOT machine.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    OperatingSystem.Create_File    ${file_prefix}${file_name}    ${output_log}

Collect Logs
    [Documentation]    Collect logs and detailed results for debugging
    ${files}=    SSHLibrary.List Files In Directory    .
    ${tool_log}=    Get_Log_File    ${tool_log_name}
    ${tool_output}=    Get_Log_File    ${tool_output_name}
    ${tool_results1}=    Get_Log_File    ${tool_results1_name}
    ${tool_results2}=    Get_Log_File    ${tool_results2_name}

Check Results
    [Documentation]    Check outputs for expected content. Fail in case of unexpected content.
    ${tool_log}=    Get_Log_File    ${tool_log_name}
    BuiltIn.Should Contain    ${tool_log}    Total execution time:
    BuiltIn.Should Not Contain    ${tool_log}    status: NOK

Set_Node_Ip_For_Benchmark
    [Arguments]    ${state}    ${tested_ds}    ${file_prefix}
    [Documentation]    Returns the node ip which should be tested
    BuiltIn.Return From Keyword If    ${NUM_ODL_SYSTEM}==1    ${ODL_SYSTEM_1_IP}
    ${shard_type}=    BuiltIn.Set_Variable_If    "${tested_ds}"=="CONFIG"    config    operational
    ${leader}    ${followers}=    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_type=${shard_type}
    BuiltIn.Return From Keyword If    "${state}"=="leader"    ${ODL_SYSTEM_${leader}_IP}
    BuiltIn.Return From Keyword    ${ODL_SYSTEM_@{followers}[0]_IP}

Measuring_Template
    [Arguments]    ${state}    ${tested_ds}    ${file_prefix}
    [Documentation]    Keywork which will cover a whole banchmark.
    ...    If ${file_prefix} is ${Empty} we have 1 node odl.
    ${odl_node_ip}=    Set_Node_Ip_For_Benchmark    ${state}    ${tested_ds}    ${file_prefix}
    Start_Benchmark_Tool    ${tested_ds}    ${odl_node_ip}
    Wait_Until_Benchmark_Tool_Finish    ${TIMEOUT}
    SSHLibrary.File Should Exist    ${tool_results1_name}
    SSHLibrary.File Should Exist    ${tool_results2_name}
    Check Results
    Store_File_To_Robot    ${tool_results1_name}    ${file_prefix}
    Store_File_To_Robot    ${tool_results2_name}    ${file_prefix}
    [Teardown]    Stop_Measurement_And_Save_Logs

Stop_Measurement_And_Save_Logs
    Stop_Benchmark_Tool
    Collect Logs

Merge_Csv
    [Arguments]    ${final_file}
    [Documentation]    Creates ${final_file} csv file from existing files in the current directory
    ${final_columns}=    BuiltIn.Set_Variable    ${Empty}
    ${final_values}=    BuiltIn.Set_variable    ${Empty}
    @{csv_files}=    OperatingSystem.List_Files_In_Directory    .    *${final_file}
    Collections.Sort_List    ${csv_files}
    : FOR    ${file}    IN    @{csv_files}
    \    BuiltIn.Log_To_Console    ${file}
    \    ${csv_content}=    OperatingSystem.GetFile    ${file}
    \    ${column_names}=    Get_Column_Names    ${file}    ${csv_content}
    \    ${column_values}=    String.Get_Line    ${csv_content}    1
    \    ${final_columns}=    BuiltIn.Set_Variable_If    "${final_columns}"=="${Empty}"    ${column_names}    ${final_columns},${column_names}
    \    ${final_values}=    BuiltIn.Set_Variable_If    "${final_values}"=="${Empty}"    ${column_values}    ${final_values},${column_values}
    ${content}=    BuiltIn.Catenate    SEPARATOR=${\n}    ${final_columns}    ${final_values}
    OperatingSystem.Create_File    ${final_file}    ${content}

Get_Column_Names
    [Arguments]    ${file_name}    ${file_content}
    [Documentation]    Returns the first line of the given csv file. It is modified if the file name
    ...    indicates that it is the file from the shard follower.
    ${column_names}=    String.Get_Line    ${file_content}    0
    BuiltIn.Return_From_Keyword_If    "_fol_" not in "${file_name}"    ${column_names}
    # now we have followers and FOL_ will be prepended to the column names
    @{columns}    String.Split_String    ${column_names}    ,
    ${final_columns}    BuiltIn.Set_Variable    ${Empty}
    : FOR    ${column}    IN    @{columns}
    \    ${final_columns}    BuiltIn.Set_Variable_If    "${final_columns}"=="${Empty}"    FOL_${column}    ${final_columns},FOL_${column}
    BuiltIn.Return_From_Keyword    ${final_columns}
