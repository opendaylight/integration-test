*** Settings ***
Documentation     Test suite with independent flow tests
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           String
Library           Collections
Library           XML
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/FlowLib.robot
Library           ../../../libraries/XmlComparator.py

*** Variables ***
${XmlsDir}        ${CURDIR}/../../../../csit/variables/xmls
${flowfile}       f2.xml
${switch_idx}     1
${switch_name}    s${switch_idx}

*** Test Cases ***
Update With Delete And Add
    [Documentation]    Updates a flow by changing priority which causes delete and add flow reaction
    Create Flow Variables For Suite From XML File    ${XmlsDir}/${flowfile}
    Add Flow Via Restconf    ${switch_idx}    ${table_id}    ${data}
    Check Config Flow    ${True}    ${data}
    Log Switch Flows
    Wait Until Keyword Succeeds    30s    1s    Check Operational Flow    ${True}    ${data}
    ${upddata}=    Replace String    ${data}    <priority>2</priority>    <priority>3</priority>
    Update Flow Via Restconf    ${switch_idx}    ${table_id}    ${flow_id}    ${upddata}
    Check Config Flow    ${True}    ${upddata}
    Log Switch Flows
    Wait Until Keyword Succeeds    30s    1s    Check Operational Flow    ${True}    ${upddata}
    [Teardown]    Delete Flow

*** Keywords ***
Log Switch Flows
    [Documentation]    Logs the switch content
    Write    dpctl dump-flows -O OpenFlow13
    ${switchouput}=    Read Until    mininet>
    Log    ${switchouput}

Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational ds
    Start Suite
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

Final Phase
    [Documentation]    Stops mininet
    Stop Suite
    Delete All Sessions

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    1

Delete Flow
    [Documentation]    Removes used flow
    ${resp}=    RequestsLibrary.Delete    session    ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}
    Log    ${resp.content}
    ${msg}=    Set Variable    Delete flow for ${CONFIG_NODES_API}/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}
