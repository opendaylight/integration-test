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
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot

*** Variables ***
${ODL_LOG_LEVEL}    DEFAULT
${TX_TYPE}        {TX-CHAINING,SIMPLE-TX}
${OP_TYPE}        {PUT,MERGE,DELETE}
${TOTAL_OPS}      100000
${OPS_PER_TX}     100000
${INNER_OPS}      100000
${WARMUPS}        10
${RUNS}           10
${TIMEOUT}        30 min
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
Set Karaf Log Levels
    [Documentation]    Set Karaf log level
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}

Start Measurement
    [Documentation]    Start the benchmark tool. Fail if test not started.
    [Tags]    critical
    Start_Benchmark_Tool

Wait For Results
    [Documentation]    Wait until results are available. Fail if timeout occures.
    [Tags]    critical
    Wait_Until_Benchmark_Tool_Finish    ${TIMEOUT}
    SSHLibrary.File Should Exist    ${tool_results1_name}
    SSHLibrary.File Should Exist    ${tool_results2_name}
    Store_File_To_Robot    ${tool_results1_name}
    Store_File_To_Robot    ${tool_results2_name}

Stop Measurement
    [Documentation]    Stop the benchmark tool (if still running)
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Stop_Benchmark_Tool

Collect Logs
    [Documentation]    Collect logs and detailed results for debugging
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    ${files}=    SSHLibrary.List Files In Directory    .
    ${tool_log}=    Get_Log_File    ${tool_log_name}
    ${tool_output}=    Get_Log_File    ${tool_output_name}
    ${tool_results1}=    Get_Log_File    ${tool_results1_name}
    ${tool_results2}=    Get_Log_File    ${tool_results2_name}

Check Results
    [Documentation]    Check outputs for expected content. Fail in case of unexpected content.
    [Tags]    critical
    ${tool_log}=    Get_Log_File    ${tool_log_name}
    BuiltIn.Should Contain    ${tool_log}    Total execution time:
    BuiltIn.Should Not Contain    ${tool_log}    status: NOK

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/mdsal_benchmark/${tool}

Teardown_Everything
    [Documentation]    Cleaning-up
    SSHLibrary.Close_All_Connections

Start_Benchmark_Tool
    [Documentation]    Start the benchmark tool. Check that it has been running at least for ${tool_startup_timeout} period.
    ${command}=    BuiltIn.Set_Variable    python ${tool} --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} --warmup ${WARMUPS} --runs ${RUNS} --total ${TOTAL_OPS} --inner ${INNER_OPS} --txtype ${TX_TYPE} --ops ${OPS_PER_TX} --optype ${OP_TYPE} --plot ${FILTER} --units ${UNITS} ${tool_args} &> ${tool_log_name}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}
    ${status}    ${message}=    BuiltIn.Run Keyword And Ignore Error    Write Until Expected Output    ${EMPTY}    ${TOOLS_SYSTEM_PROMPT}    ${tool_startup_timeout}
    ...    1s
    BuiltIn.Log    ${status}
    BuiltIn.Log    ${message}
    BuiltIn.Run Keyword If    '${status}' == 'PASS'    BuiltIn.Fail    Benchmark tool is not running

Wait_Until_Benchmark_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait until the benchmark tool is finished. Fail in case of test timeout (${timeout}).
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    15s    Read Until Prompt

Stop_Benchmark_Tool
    [Documentation]    Stop the benchmark tool. Fail if still running.
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read Until Prompt

Get_Log_File
    [Arguments]    ${file_name}
    [Documentation]    Return and log content of the provided file.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    [Return]    ${output_log}

Store_File_To_Robot
    [Arguments]    ${file_name}
    [Documentation]    Store the provided file from the MININET to the ROBOT machine.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${file_name}    ${output_log}
