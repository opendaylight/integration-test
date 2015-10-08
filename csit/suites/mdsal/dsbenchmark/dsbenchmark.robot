*** Settings ***
Documentation     MD-SAL Data Store benchmarking.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
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
${MININET_PROMPT}    ${DEFAULT_LINUX_PROMPT}
${ODL_LOG_LEVEL}    DEFAULT
${TX_TYPE}    {TX-CHAINING,SIMPLE-TX}
${OP_TYPE}    {PUT,MERGE,DELETE}
${COUNT}    100000
${ELEMENTS}    {1,10,100,1000,10000,100000}
${OP_COUNT}    {1,10,100,1000,10000,100000}
${WARMUP}    1
${RUN}    1
${TEST_TIMEOUT}    1h
${FILTER}    all
${tool}    dsbenchmark.py
${tool_args}     ${EMPTY}
${tool_log}    dsbenchmark.log
${tool_output}    test.csv
${tool_results1}    perf_per_struct.csv
${tool_results2}    perf_per_ops.csv

*** Test Cases ***
Set Karaf Log Levels
    [Documentation]    Set Karaf log level
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}

Start Measurement
    [Documentation]    Start the benchmark tool
    Start_Benchmark_Tool

Wait For Results
    [Documentation]    Wait until results are available
    Wait_Until_File_Is_Created    ${tool_results1}    ${TEST_TIMEOUT}
    Wait_Until_File_Is_Created    ${tool_results2}    5s

Store Results
    [Documentation]    Store data to result files
    Store_File    ${tool_results1}
    Store_File    ${tool_results2}

Stop Measurement
    [Documentation]    Stop the benchmark tool (if running)
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    Stop_Benchmark_Tool

Collect Logs
    [Documentation]    Collect logs and detailed results for debugging
    [Setup]    FailFast.Run_Even_When_Failing_Fast
    ${files}=    SSHLibrary.List Files In Directory    .
    Log_File    ${tool_log}
    Log_File    ${tool_output}
    Log_File    ${tool_results1}
    Log_File    ${tool_results2}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine,
    ...    create HTTP session, put Python tool to mininet machine.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    FailFast.Do_Not_Fail_Fast_From_Now_On
    SSHLibrary.Set_Default_Configuration    prompt=${MININET_PROMPT}
    SSHLibrary.Open_Connection    ${MININET}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/mdsal_benchmark/${tool}
    KarafKeywords.Open_Controller_Karaf_Console_On_Background

Teardown_Everything
    [Documentation]    Cleaning-up
    SSHLibrary.Close_All_Connections

Start_Benchmark_Tool
    [Documentation]    Start the benchmark tool.
    ${command}=    BuiltIn.Set_Variable    python ${tool} --host ${CONTROLLER} --port ${RESTCONFPORT} --warmup ${WARMUP} --runs ${RUN} --total ${COUNT} --inner ${ELEMENTS} --txtype ${TX_TYPE} --ops ${OP_COUNT} --optype ${OP_TYPE} --plot ${FILTER} ${tool_args} &> ${tool_log}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}
    Sleep    1s
    SSHLibrary.Write Until Expected Output    ps -o cmd\n    expected=${tool}    timeout=5s    retry_interval=1s

Log_File
    [Arguments]    ${file_name}
    [Documentation]    Dump the provided file content.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}

Store_File
    [Arguments]    ${file_name}
    [Documentation]    Store the provided MININET file content to the same file on ROBOT machine.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${file_name}    ${output_log}

Wait_Until_File_Is_Created
    [Arguments]    ${file_name}    ${timeout}
    [Documentation]    Wait until the file is created
    SSHLibrary.Write Until Expected Output    ls\n    expected=${file_name}    timeout=${timeout}    retry_interval=1s

Stop_Benchmark_Tool
    [Documentation]    Stop the benchmark tool.
    Utils.Write_Bare_Ctrl_C
    ${status}    ${message}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'
    BuiltIn.Log    ${message}
    BuiltIn.Fail    The prompt was not seen within timeout period.
