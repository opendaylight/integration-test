*** Settings ***
Documentation     Test for measuring execution time of MD-SAL DataStore operations in cluster.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test suite requires odl-restconf and odl-clustering-test-app modules.
...               The script cluster_rest_script.py is used for generating requests for
...               operations on people, car and car-people DataStore test models.
...               (see the https://wiki.opendaylight.org/view/MD-SAL_Clustering_Test_Plan)
...
...               Reported bugs:
...               https://bugs.opendaylight.org/show_bug.cgi?id=4220
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/CarPeople.robot

*** Variables ***
${ITEM_COUNT}     ${10000}
${PROCEDURE_TIMEOUT}    5m
${THREADS}        6
${ADDCMD}      python cluster_rest_script.py --port ${RESTCONFPORT} car-with-retries --itemtype car --itemcount ${ITEM_COUNT} --threads ${THREADS}
${DELCMD}    python cluster_rest_script.py --port ${RESTCONFPORT} delete --itemtype car --itemcount ${ITEM_COUNT} --threads ${THREADS}
${CARURL}         /restconf/config/car:cars
${CONTROLLER_LOG_LEVEL}    INFO
${SHARD_NAME}    car
${SHARD_TYPE}    config
${TEST_LOG_LEVEL}    info
@{TEST_LOG_COMPONENTS}    org.opendaylight.controller
@{NO_TAGS}
${TOOL_OPTIONS}    ${EMPTY}

*** Test Cases ***
Get_Car_Shard_Leadership_Details
    Get_Car_Shard_Leader_And_Followers    store=${True}

Start_Adding_Cars_To_Follower
    [Documentation]    Request to add ${ITEM_COUNT} cars (timeout in ${PROCEDURE_TIMEOUT}).
    ${idx}=    Collections.Get_From_List    ${car_followers}    0
    ${follower_ip}=    ClusterManagement.Resolve_IP_Address_For_Member    member_index=${idx}
    Start Tool    ${ADDCMD}    --host ${follower_ip} ${TOOL_OPTIONS}

Isolate_Current_Car_Leader
    [Documentation]    Isolating cluster node which is the owner.
    [Tags]    @{NO_TAGS}
    ClusterManagement.Isolate_Member_From_List_Or_All    ${car_leader}
    BuiltIn.Set Suite variable    ${old_car_leader}    ${car_leader}
    BuiltIn.Set Suite variable    ${old_car_followers}    ${car_followers}

Verify_New_Car_Leader_Elected
    [Documentation]    Verify new owner of the service is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Leader_Elected    ${True}    ${old_car_leader}    member_index_list=${old_car_followers}
    Get_Car_Shard_Leader_And_Followers    store=${True}    member_index_list=${old_car_followers}

Wait_For_Cars_Configured
    [Documentation]    Store logs and verify result
    ${session} =    Resolve_Http_Session_For_Member    member_index=${car_leader}
    Verify_Cars_Count    ${ITEM_COUNT}    ${session}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    [Tags]    @{NO_TAGS}
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_car_leader}

#Delete Cars
#    [Documentation]    Remove cars from the datastore
#    ${rsp}=    RequestsLibrary.Delete Request    ${car_leader_session}    ${carurl}
#    Should Be Equal As Numbers    200    ${rsp.status_code}
#    ${rsp}=    RequestsLibrary.Get Request    ${car_leader_session}    ${carurl}
#    Should Be Equal As Numbers    404    ${rsp.status_code}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}    ${TEST_LOG_COMPONENTS}
    ${mininet_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/scripts/cluster_rest_script.py    .
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True

Stop Suite
    [Documentation]    Suite teardown keyword
    Stop_Tool
    SSHLibrary.Close All Connections

Start_Tool
    [Arguments]    ${command}    ${tool_opt}
    [Documentation]    Start the tool ${command} ${tool_opt}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt}
    BuiltIn.Log    ${output}

Wait_Until_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt

Stop_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}

Verify_Cars_Count
    [Arguments]    ${exp_count}     ${session}
    ${resp}=     RequestsLibrary.Get_Request    ${session}    ${CARURL}
    Log    ${resp.content}

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}

Verify_Leader_Elected
    [Arguments]    ${new_elected}    ${old_leader}    ${member_index_list}=${EMPTY}
    [Documentation]    Verify new leaderr was elected or remained the same.
    ${leader}     ${followers}=    Get_Car_Shard_Leader_And_Followers    member_index_list=${member_index_list}
    BuiltIn.Run_Keyword_If    ${new_elected}    BuiltIn.Should_Not_Be_Equal_As_Numbers    ${old_leader}    ${leader}
    BuiltIn.Run_Keyword_Unless    ${new_elected}    BuiltIn.Should_Be_Equal_As_numbers    ${old_leader}    ${leader}

Get_Car_Shard_Leader_And_Followers
    [Arguments]    ${store}=${False}    ${member_index_list}=${EMPTY}
    [Documentation]    Find a car shard leader and followers and store them if indicated.
    ${car_leader}    ${car_followers} =    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=${SHARD_NAME}    shard_type=${SHARD_TYPE}    member_index_list=${member_index_list}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${car_leader}    ${car_leader}
    BuiltIn.Run_Keyword_If    ${store}    BuiltIn.Set_Suite_Variable    ${car_followers}    ${car_followers}
    BuiltIn.Return_From_Keyword    ${car_leader}    ${car_followers}

