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
${INNER}    100000
${OP_COUNT}    100000
${WARMUP}    1
${RUN}    1
${TEST_TIMEOUT}    5 min
${FILTER}    EXEC
${tool}    dsbenchmark.py
${tool_args}     ${EMPTY}
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
    Sleep    10s
    ${tool_log}=    Get_Log_File    ${tool_log_name}
    Should Contain    ${tool_log}    Start time:

Wait For Results
    [Documentation]    Wait until results are available. Fail if timeout occures.
    [Tags]    critical
    Wait_Until_Benchmark_Tool_Finish    ${TEST_TIMEOUT}
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
    Should Contain    ${tool_log}    Total execution time:
    Should Not Contain    ${tool_log}    status: NOK

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
    ${command}=    BuiltIn.Set_Variable    python ${tool} --host ${CONTROLLER} --port ${RESTCONFPORT} --warmup ${WARMUP} --runs ${RUN} --total ${COUNT} --inner ${INNER} --txtype ${TX_TYPE} --ops ${OP_COUNT} --optype ${OP_TYPE} --plot ${FILTER} ${tool_args} &> ${tool_log_name}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Wait_Until_Benchmark_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait for the benchmark tool is finished
    Wait Until Keyword Succeeds    ${timeout}    15s    Read Until Prompt

Stop_Benchmark_Tool
    [Documentation]    Stop the benchmark tool.
    Utils.Write_Bare_Ctrl_C
    Read Until Prompt

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
