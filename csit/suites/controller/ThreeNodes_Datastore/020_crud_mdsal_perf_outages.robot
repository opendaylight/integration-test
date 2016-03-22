*** Settings ***
Documentation     Test for measuring execution time of MD-SAL DataStore operations in cluster.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This test suite requires odl-restconf and odl-clustering-test-app modules.
...               The script cluster_rest_script.py is used for generating requests for
...               operations on people, car and car-people DataStore test models.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Library           Collections
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ClusterKeywords.robot

*** Variables ***
${ITEMS5K}        5000
${ITEMS10K}       10000
${IPR100}         100
${PROCEDURE_TIMEOUT}    5m
${threads}        6    # threads are assigned to cluster nodes in round robin way
${CAR_URL}        /restconf/config/car:cars
${PEOPLE_URL}     /restconf/config/people:people
${CARPEOPLE_URL}    /restconf/config/car-people:car-people
${CONTROLLER_LOG_LEVEL}    INFO
${TOOL_OPTIONS}    ${EMPTY}
${SHARD_CAR_NAME}    shard-car-config
${SHARD_PEOPLE_NAME}    shard-people-config
${SHARD_CAR_PERSON_NAME}    shard-car-people-config
${START_TIMEOUT}    90s
${leader}         ${None}
${stopped_node}    ${None}
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}

*** Test Cases ***
Add Cars On Leader
    [Documentation]    Request to add ${ITEMS5K} cars on master in 1 post request (timeout in ${PROCEDURE_TIMEOUT}).
    ${car_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_CAR_NAME}
    BuiltIn.Set Suite Variable    ${leader}    ${car_leader}
    ${cmd}=    Command Creator    ${car_leader}    add    car    ${ITEMS5K}    items_per_req=${ITEMS5K}
    Log    ${cmd}
    Start Tool    ${cmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    [Teardown]    Stop Tool

Add Cars On Followers
    [Documentation]    Request to add ${ITEMS5K} cars on followers in more post requests (timeout in ${PROCEDURE_TIMEOUT}). Just to try that
    @{followers}=    ClusterKeywords.Get All Followers    ${SHARD_CAR_NAME}
    ${followers_str}=    Controller List To String    @{followers}
    ${cmd}=    Command Creator    ${followers_str}    add    car    ${ITEMS5K}    threads_count=6
    ...    items_per_req=${IPR100}    initid=${ITEMS5K}
    Log    ${cmd}
    Start Tool    ${cmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    [Teardown]    Stop Tool

Verify Cars
    [Documentation]    Verify number of car items
    Verify Cars    ${leader}    ${ITEMS10K}

Add People Part1
    [Documentation]    Request to add ${ITEMS5K} people using rpc on all nodes (timeout in ${PROCEDURE_TIMEOUT}).
    @{controllers}=    ClusterKeywords.Get Controller List
    ${controllers_str}=    Controller List To String    @{controllers}
    ${cmd}=    Command Creator    ${controllers_str}    add-rpc    people    ${ITEMS5K}    threads_count=6
    Start Tool    ${cmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    [Teardown]    Stop Tool

Kill People Leader And Wait For New One
    [Documentation]    Stops people shard leader and verify new leader exists
    ${people_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_PEOPLE_NAME}
    @{leader_list}=    BuiltIn.Create List    ${people_leader}
    ClusterKeywords.Kill One Or More Controllers    @{leader_list}
    ClusterKeywords.Controller Down Check    ${people_leader}
    BuiltIn.Set Suite Variable    ${stopped_node}    ${people_leader}
    ${people_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_PEOPLE_NAME}
    BuiltIn.Set Suite Variable    ${leader}    ${people_leader}

Add People Part2
    [Documentation]    Request to add ${ITEMS5K} people using 1 post request (timeout in ${PROCEDURE_TIMEOUT}).
    ${people_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_PEOPLE_NAME}
    @{controllers}=    ClusterKeywords.Get All Followers    ${SHARD_PEOPLE_NAME}
    Collections.Append To List    ${controllers}    ${people_leader}
    ${controllers_str}=    Controller List To String    @{controllers}
    ${cmd}=    Command Creator    ${controllers_str}    add    people    ${ITEMS5K}    threads_count=6
    ...    initid=${ITEMS5K}    items_per_req=${ITEMS5K}
    Start Tool    ${cmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    BuiltIn.Set Suite Variable    ${leader}    ${people_leader}
    [Teardown]    Stop Tool

Verify People
    [Documentation]    Verify number of people items
    Verify People    ${leader}    ${ITEMS10K}

Start Killed Node 1
    [Documentation]    Starts killed node
    @{controllers}=    BuiltIn.CreateList    ${stopped_node}
    ClusterKeywords.Start One Or More Controllers    @{controllers}
    ClusterKeywords.Wait For Controller Sync    ${START_TIMEOUT}    @{controllers}

Add Purchases Part1
    [Documentation]    Request to add ${ITEMS5K} purchases using rpc on all nodes (timeout in ${PROCEDURE_TIMEOUT}).
    ${purch_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_CAR_PERSON_NAME}
    BuiltIn.Set Suite Variable    ${leader}    ${purch_leader}
    @{controllers}=    ClusterKeywords.Get All Followers    ${SHARD_CAR_PERSON_NAME}
    Collections.Append To List    ${controllers}    ${purch_leader}
    ${controllers_str}=    Controller List To String    @{controllers}
    ${cmd}=    Command Creator    ${controllers_str}    add-rpc    car-people    ${ITEMS5K}    threads_count=6
    Start Tool    ${cmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    [Teardown]    Stop Tool

Kill Purchase Leader And Wait For New One
    [Documentation]    Stops car people shard leader and verify new leader exists
    ${purch_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_CAR_PERSON_NAME}
    @{leader_list}=    BuiltIn.Create List    ${purch_leader}
    ClusterKeywords.Kill One Or More Controllers    @{leader_list}
    ClusterKeywords.Controller Down Check    ${purch_leader}
    BuiltIn.Set Suite Variable    ${stopped_node}    ${purch_leader}
    ${purch_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_CAR_PERSON_NAME}
    BuiltIn.Set Suite Variable    ${leader}    ${purch_leader}

Add Purchases Part2
    [Documentation]    Request to add ${ITEMS5K} purchases using rpc on all available nodes (timeout in ${PROCEDURE_TIMEOUT}).
    ${purch_leader}=    ClusterKeywords.Get Leader And Verify    ${SHARD_CAR_PERSON_NAME}
    @{controllers}=    ClusterKeywords.Get All Followers    ${SHARD_CAR_PERSON_NAME}
    Collections.Append To List    ${controllers}    ${purch_leader}
    ${controllers_str}=    Controller List To String    @{controllers}
    ${cmd}=    Command Creator    ${controllers_str}    add-rpc    car-people    ${ITEMS5K}    threads_count=6
    ...    initid=${ITEMS5K}
    Start Tool    ${cmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    BuiltIn.Set Suite Variable    ${leader}    ${purch_leader}
    [Teardown]    Stop Tool

Verify Purchases
    [Documentation]    Verify purchases
    Verify Purchases    ${leader}    ${ITEMS10K}

Start Killed Node 2
    [Documentation]    Starts killed node
    @{controllers}=    BuiltIn.CreateList    ${stopped_node}
    ClusterKeywords.Start One Or More Controllers    @{controllers}
    ClusterKeywords.Wait For Controller Sync    ${START_TIMEOUT}    @{controllers}

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${rsp}=    RequestsLibrary.Delete    ${leader}    ${CAR_URL}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    ${leader}    ${CAR_URL}
    Should Be Equal As Numbers    404    ${rsp.status_code}

Delete People
    [Documentation]    Remove people from the datastore
    ${rsp}=    RequestsLibrary.Delete    ${leader}    ${PEOPLE_URL}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    ${leader}    ${PEOPLE_URL}
    Should Be Equal As Numbers    404    ${rsp.status_code}

Delete CarPeople
    [Documentation]    Remove car-people entries from the datastore
    ${rsp}=    RequestsLibrary.Delete    ${leader}    ${CARPEOPLE_URL}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    ${leader}    ${CARPEOPLE_URL}
    Should Be Equal As Numbers    404    ${rsp.status_code}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/scripts/cluster_rest_script.py    .
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    @{controllers}=    ClusterKeywords.Get Controller List
    : FOR    ${controller}    IN    @{controllers}
    \    RequestsLibrary.Create Session    ${controller}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Start_Tool
    [Arguments]    ${command}    ${tool_opt}
    [Documentation]    Start the tool ${command} ${tool_opt}
    SSHLibrary.Switch Connection    ${mininet_conn_id}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt}
    BuiltIn.Log    ${output}

Wait_Until_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt

Stop_Tool
    [Documentation]    Stop the tool if still running.
    SSHLibrary.Switch Connection    ${mininet_conn_id}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read Until Prompt    timeout=60
    BuiltIn.Log    ${output}

Controller List To String
    [Arguments]    @{controllers}
    ${controllers_str}=    Set Variable    ${Empty}
    : FOR    ${controller}    IN    @{controllers}
    \    ${controllers_str}=    Set Variable If    '${controllers_str}'=='${Empty}'    ${controller}    ${controllers_str},${controller}
    [Return]    ${controllers_str}

Command Creator
    [Arguments]    ${hosts}    ${operation}    ${itemtype}    ${itemcount}    ${threads_count}=${None}    ${items_per_req}=${None}
    ...    ${initid}=${None}
    [Documentation]    Returns created command with parameters
    ${ipr}=    Set Variable If    ${items_per_req}!=${None}    --ipr ${items_per_req}    ${Empty}
    ${threads}=    Set Variable If    ${threads_count}!=${None}    --threads ${threads_count}    ${Empty}
    ${init_id}=    Set Variable If    ${initid}!=${None}    --init-id ${initid}    ${Empty}
    ${cmd}=    Set Variable    python cluster_rest_script.py --host ${hosts} --port ${RESTCONFPORT} ${operation} --itemtype ${itemtype} --itemcount ${itemcount} ${ipr} ${threads} ${init_id}
    Log    Created command: ${cmd}
    [Return]    ${cmd}

Verify Cars
    [Arguments]    ${session}    ${exp_count}
    Verify Config Items    ${session}    ${CAR_URL}    car-entry    ${exp_count}

Verify People
    [Arguments]    ${session}    ${exp_count}
    Verify Config Items    ${session}    ${PEOPLE_URL}    person    ${exp_count}

Verify Purchases
    [Arguments]    ${session}    ${exp_count}
    Verify Config Items    ${session}    ${CARPEOPLE_URL}    car-person    ${exp_count}

Verify Config Items
    [Arguments]    ${session}    ${url}    ${xpath}    ${exp_count}
    [Documentation]    Verifies number of items
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${url}    headers=${ACCEPT_XML}
    ${count}=    XML.Get Element Count    ${rsp.content}    xpath=${xpath}
    Should Be Equal As Numbers    ${count}    ${ITEMS10K}
