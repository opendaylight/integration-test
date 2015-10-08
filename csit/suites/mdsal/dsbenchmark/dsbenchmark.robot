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
${COUNT}    100
${TX_TYPE}    TX-CHAINING
${OP_TYPES}    {PUT,MERGE,DELETE}
${WARMUPS}    1
${RUNS}    1
${MAX_TEST_PERIOD}    10
${tool}    dsbenchmark.py
${tool_args}     ${EMPTY}
${tool_log}    dsbenchmark.log
${tool_results}    test.csv

*** Test Cases ***
Set Karaf Log Levels
    [Documentation]    Set Karaf log level
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}

Perform Measurement
    Start_Benchmark_Tool
    Sleep    ${MAX_TEST_PERIOD}
    Stop_Benchmark_Tool
    Log_File    ${tool_log}
    Log_File    ${tool_results}

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
    ${command}=    BuiltIn.Set_Variable    python ${tool} --host ${CONTROLLER} --port ${RESTCONFPORT} --total ${COUNT} --warmup ${WARMUPS} --runs ${RUNS} --txtype ${TX_TYPE} --optype ${OP_TYPES} ${tool_args} &> ${tool_log}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command}

Log_File
    [Arguments]    ${file_name}
    [Documentation]    Dump the provided file content.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}

Stop_Benchmark_Tool
    [Documentation]    Stop the benchmark tool.
    Utils.Write_Bare_Ctrl_C
    ${status}    ${message}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read_Until_Prompt
    BuiltIn.Return_From_Keyword_If    '${status}' == 'PASS'
    BuiltIn.Log    ${message}
    BuiltIn.Fail    The prompt was not seen within timeout period.
