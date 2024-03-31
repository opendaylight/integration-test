*** Settings ***
Documentation       Test suite with independent flow tests

Library             String
Library             Collections
Library             XML
Library             RequestsLibrary
Library             SSHLibrary
Resource            ../../../libraries/Utils.robot
Resource            ../../../libraries/FlowLib.robot
Resource            ../../../variables/openflowplugin/Variables.robot
Variables           ../../../variables/Variables.py
Library             ../../../libraries/XmlComparator.py

Suite Setup         Initialization Phase
Suite Teardown      Final Phase


*** Variables ***
${XmlsDir}          ${CURDIR}/../../../../csit/variables/xmls
${flowfile}         f2.xml
${switch_idx}       1
${switch_name}      s${switch_idx}


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
    Start Mininet
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Switches In Topology    1

Final Phase
    [Documentation]    Stops mininet
    Stop Mininet
    Delete All Sessions

Delete Flow
    [Documentation]    Removes used flow
    ${resp}=    RequestsLibrary.DELETE On Session
    ...    session
    ...    url=${RFC8040_NODES_API}/node=openflow%3A${switch_idx}/flow-node-inventory:table=${table_id}/flow=${flow_id}
    ...    expected_status=200
    Log    ${resp.content}
