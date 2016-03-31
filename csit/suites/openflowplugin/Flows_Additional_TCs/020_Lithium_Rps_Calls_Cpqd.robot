*** Settings ***
Documentation     Test suite to test various rcp calls
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/ofplugin/RpcVariables.py

*** Variables ***
${send_update_table_url}    /restconf/operations/sal-table:update-table
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch user

*** Test Cases ***
Sending Update Table
    [Documentation]    Test to send table update request
    ${resp}=    RequestsLibrary.Post Request    session    ${send_update_table_url}    data=${RPC_SEND_UPDATE_TABLE_DATA}    headers=${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational ds
    Start Suite
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    60s    1s    Are Switches Connected Topo

Final Phase
    [Documentation]    Stops mininet
    Stop Suite
    Delete All Sessions

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    Log    ${resp.content}
    ${count}=    Get Element Count    ${resp.content}    xpath=node
    Should Be Equal As Numbers    ${count}    1
