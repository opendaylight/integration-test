*** Settings ***
Documentation       Test for measuring execution time of MD-SAL DataStore operations.
...
...                 Copyright (c) 2015-2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 This test suite requires odl-restconf and odl-clustering-test-app modules.
...                 The script cluster_rest_script.py is used for generating requests for
...                 operations on people, car and car-people DataStore test models.
...                 (see the https://wiki.opendaylight.org/view/MD-SAL_Clustering_Test_Plan)
...
...                 TODO: Decide whether keyword names should contain spaces or underscores.

Library             RequestsLibrary
Library             SSHLibrary
Library             XML
Resource            ../../../libraries/RemoteBash.robot
Resource            ../../../libraries/SetupUtils.robot
Resource            ../../../libraries/SSHKeywords.robot
Resource            ../../../libraries/TemplatedRequests.robot
Resource            ../../../libraries/Utils.robot
Variables           ../../../variables/Variables.py

Suite Setup         Start Suite
Suite Teardown      Stop Suite
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown       SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed


*** Variables ***
${ITEM_COUNT}               ${10000}
${ITEM_BATCH}               ${10000}
${PROCEDURE_TIMEOUT}        11m
${addcarcmd}
...                         python cluster_rest_script.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} add --itemtype car --itemcount ${ITEM_COUNT} --ipr ${ITEM_BATCH}
${addpeoplecmd}
...                         python cluster_rest_script.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} add-rpc --itemtype people --itemcount ${ITEM_COUNT} --threads 5
${purchasecmd}
...                         python cluster_rest_script.py --host ${ODL_SYSTEM_IP} --port ${RESTCONFPORT} add-rpc --itemtype car-people --itemcount ${ITEM_COUNT} --threads 5
${carurl}                   /rests/data/car:cars
${carurl_config}            /rests/data/car:cars?content=config
${peopleurl}                /rests/data/people:people
${peopleurl_config}         /rests/data/people:people?content=config
${carpeopleurl}             /rests/data/car-people:car-people
${carpeopleurl_config}      /rests/data/car-people:car-people?content=config
${CONTROLLER_LOG_LEVEL}     INFO
${TOOL_OPTIONS}             ${EMPTY}


*** Test Cases ***
Add Cars
    [Documentation]    Request to add ${ITEM_COUNT} cars (timeout in ${PROCEDURE_TIMEOUT}).
    Start Tool    ${addcarcmd}    ${TOOL_OPTIONS}
    ${output}=    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}
    BuiltIn.Log    ${output}
    BuiltIn.Should Not Contain    ${output}    ERROR

Verify Cars
    [Documentation]    Store logs and verify result
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_add_cars.log
    ${rsp}=    RequestsLibrary.GET On Session    session    url=${carurl_config}    headers=${ACCEPT_XML}
    ${count}=    XML.Get Element Count    ${rsp.content}    xpath=car-entry
    Should Be Equal As Numbers    ${count}    ${ITEM_COUNT}

Add People
    [Documentation]    Request to add ${ITEM_COUNT} people (timeout in ${PROCEDURE_TIMEOUT}).
    Start Tool    ${addpeoplecmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}

Verify People
    [Documentation]    Store logs and verify result
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_add_people.log
    ${rsp}=    RequestsLibrary.GET On Session    session    url=${peopleurl_config}    headers=${ACCEPT_XML}
    ${count}=    XML.Get Element Count    ${rsp.content}    xpath=person
    Should Be Equal As Numbers    ${count}    ${ITEM_COUNT}

Purchase Cars
    [Documentation]    Request to purchase ${ITEM_COUNT} cars (timeout in ${PROCEDURE_TIMEOUT}).
    Start Tool    ${purchasecmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}

Verify Purchases
    [Documentation]    Store logs and verify result
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_purchase_cars.log
    Wait Until Keyword Succeeds    ${PROCEDURE_TIMEOUT}    1    Purchase Is Completed    ${ITEM_COUNT}

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${rsp}=    RequestsLibrary.DELETE On Session    session    url=${carurl}    expected_status=204
    ${rsp}=    RequestsLibrary.GET On Session    session    url=${carurl_config}    expected_status=anything
    Should Contain    ${DELETED_STATUS_CODES}    ${rsp.status_code}

Delete People
    [Documentation]    Remove people from the datastore
    ${rsp}=    RequestsLibrary.DELETE On Session    session    url=${peopleurl}    expected_status=204
    ${rsp}=    RequestsLibrary.GET On Session    session    url=${peopleurl_config}    expected_status=anything
    Should Contain    ${DELETED_STATUS_CODES}    ${rsp.status_code}

Delete CarPeople
    [Documentation]    Remove car-people entries from the datastore
    ${rsp}=    RequestsLibrary.DELETE On Session    session    url=${carpeopleurl}    expected_status=204
    ${rsp}=    RequestsLibrary.GET On Session    session    url=${carpeopleurl_config}    expected_status=anything
    Should Contain    ${DELETED_STATUS_CODES}    ${rsp.status_code}


*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    ${mininet_conn_id}=    SSHLibrary.Open Connection
    ...    ${TOOLS_SYSTEM_IP}
    ...    prompt=${TOOLS_SYSTEM_PROMPT}
    ...    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/scripts/cluster_rest_script.py    .
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Start_Tool
    [Documentation]    Start the tool ${command} ${tool_opt}
    [Arguments]    ${command}    ${tool_opt}
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt}
    BuiltIn.Log    ${output}

Wait_Until_Tool_Finish
    [Documentation]    Wait ${timeout} for the tool exit, return the printed output.
    [Arguments]    ${timeout}
    BuiltIn.Run Keyword And Return
    ...    BuiltIn.Wait Until Keyword Succeeds
    ...    ${timeout}
    ...    1s
    ...    SSHLibrary.Read Until Prompt

Purchase Is Completed
    [Documentation]    Check purchase of ${item_count} is completed.
    [Arguments]    ${item_count}
    ${rsp}=    RequestsLibrary.GET On Session    session    url=${carpeopleurl_config}    headers=${ACCEPT_XML}
    ${count}=    XML.Get Element Count    ${rsp.content}    xpath=car-person
    Should Be Equal As Numbers    ${count}    ${item_count}

Stop_Tool
    [Documentation]    Stop the tool if still running.
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}

Store_File_To_Workspace
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    [Arguments]    ${source_file_name}    ${target_file_name}
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}
