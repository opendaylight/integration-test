*** Settings ***
Documentation     Simple Sharding Benchmark Test.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test suite uses the odl-shardingsimple feature controlled
...               via shardbenchmark.py tool for testing the datastore sharding performance.
...               (see the '')
...
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
${TEST_TYPE}      ROUND-ROBIN
${DATA_STORE}      CONFIG
${SHARDS}          1 4 16
${SHARD_TYPE}      CDS
${DATAITEMS}       100000
${OPERATIONS}      1
${PUTSPERTX}       1
${LISTENERS}       0 2 8
${WARMUPS}         1
${RUNS}            3
${TOOL}           shardbenchmark.py
${DATA_LOG_FILE}    shardbenchmark_data.log
${CSV_OUT_FILE}    shardbenchmark.csv
${STDOUT_LOG}      stdout.log

*** Test Cases ***
Benchmark_Sharding
    ${ip_list}=    BuiltIn.Set_Variable    ${Empty}
    #: FOR    ${idx}    IN    @{ClusterManagement__member_index_list}
    #\    ${ip_list}=    BuiltIn.Set_Variable_If    "${ip_list}"=="${Empty}"      ${ODL_SYSTEM_${idx}_IP}    ${ip_list},${ODL_SYSTEM_${idx}_IP}
    ${ip_list}=    BuiltIn.Set_Variable    ${ODL_SYSTEM_1_IP}
    ${cmd}=    BuiltIn.Set_Variable    python shardbenchmark.py --hosts ${ip_list} --port ${RESTCONFPORT} --warmups ${WARMUPS} --runs ${RUNS} --test-type ${TEST_TYPE} --datastore ${DATA_STORE} --shard-type ${SHARD_TYPE} --totaldataitems ${DATAITEMS} --shards ${SHARDS} --operations ${OPERATIONS} --putspertx ${PUTSPERTX} --listeners ${LISTENERS} --csv ${CSV_OUT_FILE} --fulldata ${DATA_LOG_FILE} &> ${STDOUT_LOG}
    SSHKeywords.Virtual_Env_Run_Cmd_At_Cwd    ${cmd}

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to mininet machine, put python tool to mininet machine.
    #BuiltIn.Log_To_Console     ${TEST_TYPE} ${DATA_STORE} ${SHARDS} ${SHARD_TYPE} ${DATAITEMS} ${OPERATIONS} ${PUTSPERTX} ${LISTENERS} ${WARMUPS} ${RUNS}
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/mdsal_benchmark/${TOOL}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    requests
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set ${ODL_LOG_LEVEL}
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set DEBUG org.opendaylight.controller.cluster.sharding.DistributedShardedDOMDataTree
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set DEBUG org.opendaylight.controller.cluster.sharding.ShardedDataTreeActor
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set DEBUG org.opendaylight.controller.cluster.datastore
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:set DEBUG org.opendaylight.controller.cluster.access.client
    ClusterManagement.Run_Karaf_Command_On_List_Or_All    log:list
    #BuiltIn.Log_To_Console     ${TEST_TYPE} ${DATA_STORE} ${SHARDS} ${SHARD_TYPE} ${DATAITEMS} ${OPERATIONS} ${PUTSPERTX} ${LISTENERS} ${WARMUPS} ${RUNS}

Teardown_Everything
    [Documentation]    Cleaning-up
    Collect Logs
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections

Get_Log_File
    [Arguments]    ${file_name}
    [Documentation]    Return and log content of the provided file.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${file_name}
    BuiltIn.Log    ${output_log}
    [Return]    ${output_log}

Collect_Logs
    [Documentation]    Collect logs and detailed results for debugging
    ${files}=    SSHLibrary.List Files In Directory    .
    ${cnt}=    Get_Log_File    ${STDOUT_LOG}
    OperatingSystem.Create_File    ${STDOUT_LOG}    ${cnt}
    ${cnt}=    Get_Log_File    ${CSV_OUT_FILE}
    OperatingSystem.Create_File    ${CSV_OUT_FILE}    ${cnt}
    ${cnt}=    Get_Log_File    ${DATA_LOG_FILE}
    OperatingSystem.Create_File    ${DATA_LOG_FILE}    ${cnt}

