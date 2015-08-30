*** Settings ***
Documentation     Test for measuring time on md-sal operations
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${items}          ${10000}
${tool_opt}       ${EMPTY}
${addcarcmd}      python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add --itemtype car --itemcount ${items} --ipr ${items}
${addpeoplecmd}    python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add --itemtype people --itemcount ${items} --ipr ${items}
${purchasecmd}    python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add-rpc --itemtype car-people --itemcount ${items} --threads 5
${carurl}         /restconf/config/car:cars
${peopleurl}      /restconf/config/people:people
${carpeopleurl}    /restconf/config/car-people:car-people
${procedure_timeout}    60s

*** Test Cases ***
Add Cars
    [Documentation]    Add ${items} cars and wait ${procedure_timeout}.
    Start Tool    ${addcarcmd}    ${tool_opt}
    Wait Until Tool Finish    ${procedure_timeout}

Finish Cars
    [Documentation]    Stop the tool and store logs.
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_add_cars.log

Verify Cars
    [Documentation]    Cars configuration verifications
    ${rsp}=    RequestsLibrary.Get    session    ${carurl}    headers=${ACCEPT_XML}
    ${count}=    Get Element Count    ${rsp.content}    xpath=car-entry
    Should Be Equal As Numbers    ${count}    ${items}

Add People
    [Documentation]    Add ${items} cars and wait ${procedure_timeout}.
    Start Tool    ${addpeoplecmd}    ${tool_opt}
    Wait Until Tool Finish    ${procedure_timeout}

Finish People
    [Documentation]    Stop the tool and store logs.
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_add_people.log

Verify People
    [Documentation]    People configuration verifications
    ${rsp}=    RequestsLibrary.Get    session    ${peopleurl}    headers=${ACCEPT_XML}
    ${count}=    Get Element Count    ${rsp.content}    xpath=person
    Should Be Equal As Numbers    ${count}    ${items}

Purchase Cars
    [Documentation]    Add ${items} cars and wait ${procedure_timeout}.
    Start Tool    ${purchasecmd}    ${tool_opt}
    Wait Until Tool Finish    ${procedure_timeout}

Finish Purchase Cars
    [Documentation]    Stop the tool and store logs.
    Stop Tool
    Store File To Workspace    cluster_rest_script.log    cluster_rest_script_purchase_cars.log

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${carurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get    session    ${carurl}
    Should Be Equal As Numbers    404    ${rsp.status_code}


Delete People
    [Documentation]    Remove people from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${peopleurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get    session    ${peopleurl}
    Should Be Equal As Numbers    404    ${rsp.status_code}


Delete CarPeople
    [Documentation]    Remove car-people entries from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${carpeopleurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}
    ${rsp}=    RequestsLibrary.Get    session    ${carpeopleurl}
    Should Be Equal As Numbers    404    ${rsp.status_code}


*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Set Suite Variable    ${mininet_conn_id}
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
    BuiltIn.Log    ${command}
    ${output}=    SSHLibrary.Write    ${command} ${tool_opt}
    BuiltIn.Log    ${output}

Wait_Until_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    Read Until Prompt
    ${return_code}=    SSHLibrary.Execute_Command    echo \$?
    Log    ${return_code}
    Should Be Equal As Numbers    0    ${return_code}

Stop_Tool
    [Documentation]    Stop the tool. Fail if still running.
    Utils.Write_Bare_Ctrl_C
    SSHLibrary.Read Until Prompt

Store_File_To_Workspace
    [Arguments]    ${source_file_name}    ${target_file_name}
    [Documentation]    Store the ${source_file_name} to the workspace as ${target_file_name}.
    ${output_log}=    SSHLibrary.Execute_Command    cat ${source_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${target_file_name}    ${output_log}
