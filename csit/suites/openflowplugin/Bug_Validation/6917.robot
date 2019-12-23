*** Settings ***
Documentation     Test suite for bug 6917 validation.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           RequestsLibrary
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${XmlsDir}        ${CURDIR}/../../../variables/xmls
${switch_idx}     1
${switch_name}    s${switch_idx}
${iteration}      4

*** Test Cases ***
Add Delete Same Flow
    [Documentation]    Iterate on add and delete flow until alien ID is found in Operational Datastore.
    FOR    ${i}    IN RANGE    ${iteration}
        Run Keyword And Continue On Failure    Add And Delete Flow    f21.xml
    END
    [Teardown]    Report_Failure_Due_To_Bug    6917

Add Multiple Flows
    [Documentation]    Iterate on add and delete flow until alien ID is found in Operational Datastore.
    Run Keyword And Continue On Failure    Add Flow    f20.xml
    Run Keyword And Continue On Failure    Add Flow    f21.xml
    Run Keyword And Continue On Failure    Add Flow    f22.xml
    Run Keyword And Continue On Failure    Add Flow    f23.xml
    [Teardown]    Report_Failure_Due_To_Bug    6917

*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational datastore.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Switches In Topology    1

Final Phase
    [Documentation]    Stops mininet.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    RequestsLibrary.Delete All Sessions

Add And Delete Flow
    [Arguments]    ${flowfile}
    [Documentation]    Add a Delete a Flow and verify presence in Datastore. The 5 sec sleep is required to reproduce the bug.
    FlowLib.Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Datastore Presence    ${flowfile}    ${True}    ${True}
    ...    ${False}    ${True}
    FlowLib.Delete Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Operational Flow    ${False}    ${data}
    FlowLib.Check Datastore Presence    ${flowfile}    ${False}    ${False}    ${True}
    Sleep    5
    [Teardown]    BuiltIn.Run Keyword And Ignore Error    FlowLib.Delete Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}

Add Flow
    [Arguments]    ${flowfile}
    [Documentation]    Add a Delete a Flow and verify presence in Datastore. The 5 sec sleep is required to reproduce the bug.
    FlowLib.Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    FlowLib.Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Operational Flow    ${True}    ${data}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Datastore Presence    ${flowfile}    ${True}    ${True}
    ...    ${False}    ${True}
    Sleep    8
    [Teardown]    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
