*** Settings ***
Documentation     Test suite with independent flow tests
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           RequestsLibrary
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${XmlsDir}        ${CURDIR}/../../../variables/xmls
${flowfile}       f21.xml
${switch_idx}     1
${switch_name}    s${switch_idx}
${iteration}      5

*** Test Cases ***
Bug 6917
    [Documentation]    Iterate on add and delete flow until alien ID is found in Operational Datastore..
    : FOR    ${i}    IN RANGE    ${iteration}
    \    Add And Delete Flow
    [Teardown]    Report_Failure_Due_To_Bug    6917

*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational datastore.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Final Phase
    [Documentation]    Stops mininet.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    RequestsLibrary.Delete All Sessions

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    BuiltIn.Should Be Equal As Numbers    ${count}    1

Add And Delete Flow
    [Documentation]    Add a Delete a Flow and verify presence in Datastore. The 5 sec sleep is required to reproduce the bug.
    Sleep    5
    FlowLib.Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    FlowLib.Check Datastore Presence    ${flowfile}    ${True}    ${True}    ${False}    ${True}
    FlowLib.Delete Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Operational Flow    ${False}    ${data}
    FlowLib.Check Datastore Presence    ${flowfile}    ${False}    ${False}    ${True}
    [Teardown]    BuiltIn.Run Keyword And Ignore Error    FlowLib.Delete Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}
