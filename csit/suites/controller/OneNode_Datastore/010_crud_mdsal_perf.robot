*** Settings ***
Documentation     Test for measuring time on md-sal operations
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/SetupUtils.robot

*** Variables ***
${ITEM_COUNT}     ${10000}
${ITEM_BATCH}     ${10000}
${PROCEDURE_TIMEOUT}    5m
${addcarcmd}      python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add --itemtype car --itemcount ${ITEM_COUNT} --ipr ${ITEM_BATCH}
${addpeoplecmd}    python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add --itemtype people --itemcount ${ITEM_COUNT} --ipr ${ITEM_BATCH}
${purchasecmd}    python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add-rpc --itemtype car-people --itemcount ${ITEM_COUNT} --threads 5
${carurl}         /restconf/config/car:cars
${peopleurl}      /restconf/config/people:people
${carpeopleurl}    /restconf/config/car-people:car-people
${CONTROLLER_LOG_LEVEL}    INFO
${TOOL_OPTIONS}    ${EMPTY}

*** Test Cases ***
Add Cars
    [Documentation]    Add ${ITEM_COUNT} cars (timeout in ${PROCEDURE_TIMEOUT}).
    Start Tool    ${addcarcmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}

Finalize Cars
    [Documentation]    Store logs and stop the tool.
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_add_cars.log

Verify Cars
    [Documentation]    Cars configuration verifications
    ${rsp}=    RequestsLibrary.Get Request    session    ${carurl}    headers=${ACCEPT_XML}
    ${count}=    XML.Get Element Count    ${rsp.content}    xpath=car-entry
    Should Be Equal As Numbers    ${count}    ${ITEM_COUNT}

Add People
    [Documentation]    Add ${ITEM_COUNT} people (timeout in ${PROCEDURE_TIMEOUT}).
    Start Tool    ${addpeoplecmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}

Finalize People
    [Documentation]    Store logs and stop the tool.
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_add_people.log

Verify People
    [Documentation]    People configuration verifications
    ${rsp}=    RequestsLibrary.Get Request    session    ${peopleurl}    headers=${ACCEPT_XML}
    ${count}=    XML.Get Element Count    ${rsp.content}    xpath=person
    Should Be Equal As Numbers    ${count}    ${ITEM_COUNT}

Purchase Cars
    [Documentation]    Purchase ${ITEM_COUNT} cars (timeout in ${PROCEDURE_TIMEOUT}).
    Start Tool    ${purchasecmd}    ${TOOL_OPTIONS}
    Wait Until Tool Finish    ${PROCEDURE_TIMEOUT}

Finalize Purchase Cars
    [Documentation]    Store logs and stop the tool.
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_purchase_cars.log

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${carurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    session    ${carurl}
    Should Be Equal As Numbers    404    ${rsp.status_code}

Delete People
    [Documentation]    Remove people from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${peopleurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    session    ${peopleurl}
    Should Be Equal As Numbers    404    ${rsp.status_code}

Delete CarPeople
    [Documentation]    Remove car-people entries from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${carpeopleurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get Request    session    ${carpeopleurl}
    Should Be Equal As Numbers    404    ${rsp.status_code}

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${CONTROLLER_LOG_LEVEL}
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${MININET_USER}
    SSHLibrary.Put File    ${CURDIR}/../../../../tools/odl-mdsal-clustering-tests/scripts/cluster_rest_script.py    .
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    RequestsLibrary.Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Start_Tool
    [Arguments]    ${command}    ${tool_opt}
    [Documentation]    Start the tool ${command} ${tool_opt}
    BuiltIn.Run Keyword And Ignore Error    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt}

Wait_Until_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt
    ${return_code}=    SSHLibrary.Execute_Command    echo \$?
    Log    ${return_code}
    Should Be Equal As Numbers    0    ${return_code}

Stop_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}
