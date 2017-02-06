*** Settings ***
Documentation     Test when a car shard leader is isolated while configuring cars.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test suite requires odl-restconf and odl-clustering-test-app modules.
...               The script cluster_rest_script.py is used for generating requests for
...               PUTing car items while the car shard leader is isolated.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/CarPeople.robot

*** Variables ***
${ITEM_COUNT}     ${10000}
${THREADS}        10
${ADDCMD}         python ${TOOL_NAME} --port ${RESTCONFPORT} add-with-retries --itemtype car --itemcount ${ITEM_COUNT} --threads ${THREADS}
${CARURL}         /restconf/config/car:cars
${SHARD_NAME}     car
${SHARD_TYPE}     config
${TEST_LOG_LEVEL}    info
@{TEST_LOG_COMPONENTS}    org.opendaylight.controller
${TOOL_OPTIONS}    ${EMPTY}
${TOOL_NAME}      cluster_rest_script.py

*** Test Cases ***
Get_Car_Shard_Leadership_Details
    [Documentation]    Get car shard leader and followers.
    Get_Car_Shard_Leader_And_Followers    store=${True}

Start_Adding_Cars_To_Follower
    [Documentation]    Start the script to configure ${ITEM_COUNT} cars in the background.
    ${idx} =    Collections.Get_From_List    ${car_followers}    0
    ${follower_ip} =    ClusterManagement.Resolve_IP_Address_For_Member    member_index=${idx}
    Start Tool    ${ADDCMD}    --host ${follower_ip} ${TOOL_OPTIONS}
    ${session} =    Resolve_Http_Session_For_Member    member_index=${car_leader}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Ensure_Cars_Being_Configured    ${session}

Isolate_Current_Car_Leader
    [Documentation]    Isolating cluster node which is the car shard leader.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${car_leader}
    BuiltIn.Set Suite variable    ${old_car_leader}    ${car_leader}
    BuiltIn.Set Suite variable    ${old_car_followers}    ${car_followers}

Verify_New_Car_Leader_Elected
    [Documentation]    Verify new owner of the car shard is elected.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Leader_Elected    ${True}    ${old_car_leader}    member_index_list=${old_car_followers}
    Get_Car_Shard_Leader_And_Followers    store=${True}    member_index_list=${old_car_followers}

Verify_Cars_Configured
    [Documentation]    Verify that all cars are configured.
    [Tags]    critical
    BuiltIn.Wait_Until_Keyword_Succeeds    120x    2s    SSHLibrary.Read_Until_Prompt
    ${session} =    Resolve_Http_Session_For_Member    member_index=${car_leader}
    Verify_Cars_Count    ${ITEM_COUNT}    ${session}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    [Tags]    @{NO_TAGS}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_car_leader}

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${session} =    Resolve_Http_Session_For_Member    member_index=${car_leader}
    ${rsp}=    RequestsLibrary.Delete Request    ${session}    ${CARURL}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${CARURL}
    Should Be Equal As Numbers    404    ${rsp.status_code}

*** Keywords ***
Start Suite
    [Documentation]    Upload the script file and create a virtual env
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}    ${TEST_LOG_COMPONENTS}
    ${mininet_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/scripts/${TOOL_NAME}    .
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${out_file} =    Utils.Get_Log_File_Name    ${TOOL_NAME}
    BuiltIn.Set_Suite_Variable    ${out_file}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    requests

Stop Suite
    [Documentation]    Stop the tool, remove virtual env and close ssh connection towards tools vm.
    Stop_Tool
    SSHKeywords.Virtual_Env_Delete
    Store_File_To_Workspace    ${out_file}    ${out_file}
    SSHLibrary.Close All Connections

Start_Tool
    [Arguments]    ${command}    ${tool_opt}
    [Documentation]    Start the tool
    # TODO: https://trello.com/c/rXsMu7iz/444-create-keywords-for-the-tool-start-and-stop-in-remotebash-robot
    BuiltIn.Log    ${command}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt} | tee ${out_file}
    BuiltIn.Log    ${output}

Stop_Tool
    [Documentation]    Stop the tool if still running.
    # TODO: https://trello.com/c/rXsMu7iz/444-create-keywords-for-the-tool-start-and-stop-in-remotebash-robot
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Verify_Cars_Count
    [Arguments]    ${exp_count}    ${session}
    [Documentation]    Count car items in config ds and compare with expected number.
    ${count} =    Get_Cars_Count    ${session}
    BuiltIn.Should_Be_Equal_As_Numbers    ${count}    ${exp_count}

Get_Cars_Count
    [Arguments]    ${session}
    [Documentation]    Count car items in config ds.
    ${resp}=    RequestsLibrary.Get_Request    ${session}    ${CARURL}
    ${count} =    BuiltIn.Evaluate    len(${resp.json()}["cars"]["car-entry"])
    BuiltIn.Return_From_Keyword    ${count}

Ensure_Cars_Being_Configured
    [Arguments]    ${session}
    ${count1} =    Get_Cars_Count    ${session}
    ${count2} =    Get_Cars_Count    ${session}
    BuiltIn.Should_Not_Be_Equal_As_Integers    ${count1}    ${count2}

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    SSHLibrary.Get_File    ${source_file_name}    ${target_file_name}

Verify_Leader_Elected
    [Arguments]    ${new_elected}    ${old_leader}    ${member_index_list}=${EMPTY}
    [Documentation]    Verify new leader was elected or remained the same.
    ${leader}    ${followers}=    Get_Car_Shard_Leader_And_Followers    member_index_list=${member_index_list}
    BuiltIn.Run_Keyword_If    ${new_elected}    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_leader}    ${leader}
    BuiltIn.Run_Keyword_Unless    ${new_elected}    BuiltIn.Should_Be_Equal_As_numbers    ${old_leader}    ${leader}

Get_Car_Shard_Leader_And_Followers
    [Arguments]    ${store}=${False}    ${member_index_list}=${EMPTY}
    [Documentation]    Find a car shard leader and followers and store them if indicated.
    ${car_leader}    ${car_followers} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}    member_index_list=${member_index_list}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${car_leader}    ${car_leader}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${car_followers}    ${car_followers}
    BuiltIn.Return_From_Keyword    ${car_leader}    ${car_followers}
