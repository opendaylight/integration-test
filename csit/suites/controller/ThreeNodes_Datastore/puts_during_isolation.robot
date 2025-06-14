*** Settings ***
Documentation       Test when a car shard leader is isolated while configuring cars.
...
...                 Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 This test suite requires odl-restconf and odl-clustering-test-app modules.
...                 The script cluster_rest_script.py is used for generating requests for
...                 PUTing car items while the car shard leader is isolated.

Library             RequestsLibrary
Library             SSHLibrary
Resource            ${CURDIR}/../../../libraries/CarPeople.robot
Resource            ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource            ${CURDIR}/../../../libraries/RemoteBash.robot
Resource            ${CURDIR}/../../../libraries/SetupUtils.robot
Resource            ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource            ${CURDIR}/../../../libraries/Utils.robot
Resource            ${CURDIR}/../../../variables/Variables.robot

Suite Setup         Start_Suite
Suite Teardown      Stop_Suite
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing

Default Tags        critical


*** Variables ***
${ITEM_COUNT}               ${10000}
${THREADS}                  10
${ADDCMD}
...                         python ${TOOL_NAME} --port ${RESTCONFPORT} add-with-retries --itemtype car --itemcount ${ITEM_COUNT} --threads ${THREADS}
${CARURL}                   /rests/data/car:cars
${CARURL_CONFIG}            /rests/data/car:cars?content=config
${SHARD_NAME}               car
${SHARD_TYPE}               config
${TEST_LOG_LEVEL}           info
@{TEST_LOG_COMPONENTS}      org.opendaylight.controller
${TOOL_OPTIONS}             ${EMPTY}
${TOOL_NAME}                cluster_rest_script.py


*** Test Cases ***
Start_Adding_Cars_To_Follower
    [Documentation]    Start the script to configure ${ITEM_COUNT} cars in the background.
    ${idx} =    Collections.Get_From_List    ${car_follower_indices}    0
    ${follower_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    member_index=${idx}
    Start Tool    ${ADDCMD}    --host ${follower_ip} ${TOOL_OPTIONS}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${car_leader_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Ensure_Cars_Being_Configured    ${session}

Isolate_Current_Car_Leader
    [Documentation]    Isolating cluster node which is the car shard leader.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${car_leader_index}
    BuiltIn.Set Suite variable    ${old_car_leader}    ${car_leader_index}
    BuiltIn.Set Suite variable    ${old_car_followers}    ${car_follower_indices}

Verify_New_Car_Leader_Elected
    [Documentation]    Verify new owner of the car shard is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    10x
    ...    2s
    ...    ClusterManagement.Verify_Shard_Leader_Elected
    ...    ${SHARD_NAME}
    ...    ${SHARD_TYPE}
    ...    ${True}
    ...    ${old_car_leader}
    ...    member_index_list=${old_car_followers}
    CarPeople.Set_Tmp_Variables_For_Shard_For_Nodes
    ...    ${old_car_followers}
    ...    shard_name=${SHARD_NAME}
    ...    shard_type=${SHARD_TYPE}

Verify_Cars_Configured
    [Documentation]    Verify that all cars are configured.
    BuiltIn.Wait_Until_Keyword_Succeeds    120x    2s    SSHLibrary.Read_Until_Prompt
    ${session} =    Resolve_Http_Session_For_Member    member_index=${new_leader_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Cars_Count    ${ITEM_COUNT}    ${session}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_car_leader}

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${session} =    Resolve_Http_Session_For_Member    member_index=${new_leader_index}
    ${rsp} =    RequestsLibrary.DELETE On Session    ${session}    url=${CARURL}    expected_status=204
    ${rsp} =    RequestsLibrary.GET On Session    ${session}    url=${CARURL_CONFIG}    expected_status=anything
    Should Contain    ${DELETED_STATUS_CODES}    ${rsp.status_code}


*** Keywords ***
Start Suite
    [Documentation]    Upload the script file and create a virtual env
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}    ${TEST_LOG_COMPONENTS}
    ${mininet_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System    prompt=~]>
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/scripts/${TOOL_NAME}    .
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${out_file} =    Utils.Get_Log_File_Name    ${TOOL_NAME}
    BuiltIn.Set_Suite_Variable    ${out_file}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    requests
    CarPeople.Set_Variables_For_Shard    ${SHARD_NAME}    shard_type=${SHARD_TYPE}

Stop Suite
    [Documentation]    Stop the tool, remove virtual env and close ssh connection towards tools vm.
    Stop_Tool
    ${session} =    Resolve_Http_Session_For_Member    member_index=${new_leader_index}
    # best effort to make sure cars are deleted in case more suites will run after this and the delete test case had trouble
    ${rsp} =    RequestsLibrary.DELETE On Session    ${session}    url=${CARURL}    expected_status=anything
    BuiltIn.Log    ${rsp.status_code} : ${rsp.text}
    SSHKeywords.Virtual_Env_Delete
    Store_File_To_Workspace    ${out_file}    ${out_file}
    SSHLibrary.Close All Connections

Start_Tool
    [Documentation]    Start the tool
    [Arguments]    ${command}    ${tool_opt}
    # TODO: https://trello.com/c/rXsMu7iz/444-create-keywords-for-the-tool-start-and-stop-in-remotebash-robot
    BuiltIn.Log    ${command}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output} =    SSHLibrary.Write    ${command} ${tool_opt} 2>&1 | tee ${out_file}
    BuiltIn.Log    ${output}

Stop_Tool
    [Documentation]    Stop the tool if still running.
    # TODO: https://trello.com/c/rXsMu7iz/444-create-keywords-for-the-tool-start-and-stop-in-remotebash-robot
    ${output} =    SSHLibrary.Read
    BuiltIn.Log    ${output}
    RemoteBash.Write_Bare_Ctrl_C
    ${output} =    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Verify_Cars_Count
    [Documentation]    Count car items in config ds and compare with expected number.
    [Arguments]    ${exp_count}    ${session}
    ${count} =    Get_Cars_Count    ${session}
    BuiltIn.Should_Be_Equal_As_Numbers    ${count}    ${exp_count}

Get_Cars_Count
    [Documentation]    Count car items in config ds.
    [Arguments]    ${session}
    ${resp} =    RequestsLibrary.GET On Session    ${session}    url=${CARURL_CONFIG}
    ${count} =    BuiltIn.Evaluate    len(${resp.json()}[car:cars][car-entry])
    RETURN    ${count}

Ensure_Cars_Being_Configured
    [Documentation]    FIXME: Add a documentation.
    [Arguments]    ${session}
    ${count1} =    Get_Cars_Count    ${session}
    ${count2} =    Get_Cars_Count    ${session}
    BuiltIn.Should_Not_Be_Equal_As_Integers    ${count1}    ${count2}

Store_File_To_Workspace
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    [Arguments]    ${source_file_name}    ${target_file_name}
    SSHLibrary.Get_File    ${source_file_name}    ${target_file_name}
