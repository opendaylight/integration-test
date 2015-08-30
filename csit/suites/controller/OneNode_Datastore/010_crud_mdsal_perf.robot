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
${addcarcmd}      python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add --itemtype car --itemcount ${items} --ipr ${items}
${addpeoplecmd}    python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add --itemtype people --itemcount ${items} --ipr ${items}
${purchasecmd}    python cluster_rest_script.py --host ${CONTROLLER} --port ${RESTCONFPORT} add-rpc --itemtype car-people --itemcount ${items} --threads 5
${carurl}         /restconf/config/car:cars
${peopleurl}      /restconf/config/people:people
${carpeopleurl}    /restconf/config/car-people:car-people

*** Test Cases ***
Add Cars
    [Documentation]    Test to configure ${items} cars into datastore. Time of this testcase is the thing we are interesting in.
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${addcarcmd}    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stderr}
    Should Be Equal As Numbers    0    ${rc}

Verify Cars
    [Documentation]    Cars configuration verifications
    ${rsp}=    RequestsLibrary.Get    session    ${carurl}    headers=${ACCEPT_XML}
    ${count}=    Get Element Count    ${rsp.content}    xpath=car-entry
    Should Be Equal As Numbers    ${count}    ${items}

Add People
    [Documentation]    Test to configure ${items} cars into datastore. Time of this testcase is the thing we are interesting in.
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${addpeoplecmd}    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stderr}
    Should Be Equal As Numbers    0    ${rc}

Verify People
    [Documentation]    People configuration verifications
    ${rsp}=    RequestsLibrary.Get    session    ${peopleurl}    headers=${ACCEPT_XML}
    ${count}=    Get Element Count    ${rsp.content}    xpath=person
    Should Be Equal As Numbers    ${count}    ${items}

Purchase Cars
    [Documentation]    Performs ${items} of rpc calls to purchase cars. Time of this testcase is the thing we are interesting in.
    ${stdout}    ${stderr}    ${rc}=    Execute Command    ${purchasecmd}    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stderr}
    Should Be Equal As Numbers    0    ${rc}

Delete Cars
    [Documentation]    Remove cars from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${carurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}

Delete People
    [Documentation]    Remove people from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${peopleurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}

Delete CarPeople
    [Documentation]    Remove car-people entries from the datastore
    ${rsp}=    RequestsLibrary.Delete    session    ${carpeopleurl}
    Should Be Equal As Numbers    200    ${rsp.status_code}

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
