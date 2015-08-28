*** Settings ***
Documentation     Test suite for Stats Manager flows collection
Suite Setup       Initialization Phase
Suite Teardown    Teardown Phase
Library           OperatingSystem
Library           Collections
Library           XML
Library           ../../../libraries/XmlComparator.py
Variables         ../../../variables/Variables.py
Library           RequestsLibrary
Library           ../../../libraries/Common.py

*** Variables ***
${XmlsDir}        ${CURDIR}/../../../variables/xmls
${switch_idx}     1
${switch_name}    s${switch_idx}
@{xml_files}      f1.xml    f2.xml    f3.xml    f5.xml    f7.xml    f8.xml    f9.xml
...               f10.xml    f11.xml    f12.xml    f13.xml    f14.xml    f17.xml    f19.xml
...               f24.xml

*** Test Cases ***
Test Add Flows
    [Documentation]    Add all flows and waits for SM to collect data
    : FOR    ${flowfile}    IN    @{xml_files}
    \    Log    ${flowfile}
    \    Init Flow Variables    ${flowfile}
    \    Run Keyword And Continue On Failure    Add Flow

Test Is Flow 1 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f1.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 2 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f2.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 3 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f3.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 5 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f5.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 7 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f7.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 8 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f8.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 9 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f9.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 10 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f10.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 11 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f11.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 12 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f12.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 13 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f13.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 14 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f14.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 17 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f17.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 19 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f19.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Is Flow 24 Added
    [Documentation]    Checks if flow is configured and operational
    Init Flow Variables    f24.xml
    Check Config Flow    ${True}
    Check Operational Table    ${True}

Test Delete Flows
    [Documentation]    Delete all flows and waits for SM to collect data
    : FOR    ${flowfile}    IN    @{xml_files}
    \    Log    ${flowfile}
    \    Init Flow Variables    ${flowfile}
    \    Run Keyword And Continue On Failure    Delete Flow

Test Is Flow 1 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f1.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 2 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f2.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 3 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f3.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 5 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f5.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 7 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f7.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 8 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f8.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 9 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f9.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 10 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f10.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 11 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f11.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 12 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f12.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 13 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f13.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 14 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f14.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 17 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f17.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 19 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f19.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

Test Is Flow 24 Deleted
    [Documentation]    Checks if flow is not configured and operational
    Init Flow Variables    f24.xml
    Check Config Flow    ${False}
    Check Operational Table    ${False}

*** Keywords ***
Init Flow Variables
    [Arguments]    ${file}
    ${data}=    Get File    ${XmlsDir}/${file}
    ${xmlroot}=    Parse Xml    ${XmlsDir}/${file}
    ${table_id}=    Get Element Text    ${xmlroot}    table_id
    ${flow_id}=    Get Element Text    ${xmlroot}    id
    ${flow_priority}=    Get Element Text    ${xmlroot}    priority
    Set Suite Variable    ${table_id}
    Set Suite Variable    ${flow_id}
    Set Suite Variable    ${flow_priority}
    Set Suite Variable    ${data}
    Set Suite Variable    ${xmlroot}

Check Config Flow
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    40s    2s    Check Config Flow Presence    ${expected}

Check Config Flow Presence
    [Arguments]    ${expected}
    ${presence_flow}    ${msg}=    Flow Presence Config Flow
    ${msgf}=    Get Presence Failure Message    config    ${expected}    ${presence_flow}    ${msg}
    Should Be Equal    ${expected}    ${presence_flow}    msg=${msgf}

Flow Presence Config Flow
    ${headers}=    Create Dictionary    Accept    application/xml
    ${resp}=    RequestsLibrary.Get    session    /restconf/config/opendaylight-inventory:nodes/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}    headers=${headers}
    Log    ${resp}
    Log    ${resp.content}
    Return From Keyword If    ${resp.status_code}!=200    ${False}    ${EMPTY}
    ${pres}    ${msg}=    Is Flow Configured    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Return From Keyword    ${pres}    ${msg}

Check Operational Table
    [Arguments]    ${expected}
    Wait Until Keyword Succeeds    120s    2s    Check Operational Table Presence    ${expected}

Check Operational Table Presence
    [Arguments]    ${expected}
    ${presence_table}    ${msg}=    Flow Presence Operational Table
    ${msgf}=    Get Presence Failure Message    config    ${expected}    ${presence_table}    ${msg}
    Should Be Equal    ${expected}    ${presence_table}    msg=${msgf}

Flow Presence Operational Table
    ${headers}=    Create Dictionary    Accept    application/xml
    ${resp}=    RequestsLibrary.Get    session    /restconf/operational/opendaylight-inventory:nodes/node/openflow:${switch_idx}/table/${table_id}    headers=${headers}
    Log    ${resp}
    Log    ${resp.content}
    Return From Keyword If    ${resp.status_code}!=200    ${False}    ${EMPTY}
    ${pres}    ${msg}=    Is Flow Operational2    ${data}    ${resp.content}
    Run Keyword If    '''${msg}'''!='${EMPTY}'    Log    ${msg}
    Return From Keyword    ${pres}    ${msg}

Add Flow
    Log    ${data}
    ${resp}=    RequestsLibrary.Put    session    /restconf/config/opendaylight-inventory:nodes/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}    headers=${HEADERS_XML}    data=${data}
    ${msg}=    Set Variable    Adding flow for /restconf/config/opendaylight-inventory:nodes/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Delete Flow
    ${resp}=    RequestsLibrary.Delete    session    /restconf/config/opendaylight-inventory:nodes/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id}
    ${msg}=    Set Variable    Delete flow for /restconf/config/opendaylight-inventory:nodes/node/openflow:${switch_idx}/table/${table_id}/flow/${flow_id} failed, http response ${resp.status_code} received.
    Should Be Equal As Strings    ${resp.status_code}    200    msg=${msg}

Delete All Flows
    [Documentation]    Deletes all flows
    : FOR    ${flowfile}    IN    @{xml_files}
    \    Log    ${flowfile}
    \    Init Flow Variables    ${flowfile}
    \    Delete Flow

Initialization Phase
    [Documentation]    Initiate tcp connection with controller
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

Teardown Phase
    [Documentation]    Closes tcp connection with controller and removes flows
    Delete All Sessions

Get Presence Failure Message
    [Arguments]    ${ds}    ${expected}    ${presence}    ${diffmsg}
    Return From Keyword If    '''${diffmsg}'''!='${EMPTY}'    Flow found in ${ds} data store but: ${diffmsg}
    ${msgf}=    Set Variable If    ${expected}==${True}    The flow is expected in operational data store, but    The flow is not expected in operational data store, but
    ${msgp}=    Set Variable If    ${presence}==${True}    it is present.    it is not present.
    Return From Keyword    ${msgf} ${msgp}
