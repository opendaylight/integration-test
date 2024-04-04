*** Settings ***
Documentation       Test suite to test various rcp calls

Library             XML
Library             RequestsLibrary
Library             SSHLibrary
Resource            ../../../libraries/Utils.robot
Resource            ../../../libraries/FlowLib.robot
Variables           ../../../variables/ofplugin/RpcVariables.py

Suite Setup         Initialization Phase
Suite Teardown      Final Phase


*** Variables ***
${send_update_table_url}    /rests/operations/sal-table:update-table
${start}                    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch user


*** Test Cases ***
Sending Update Table
    [Documentation]    Test to send table update request
    ${resp}=    RequestsLibrary.POST On Session
    ...    session
    ...    url=${send_update_table_url}
    ...    data=${RPC_SEND_UPDATE_TABLE_DATA}
    ...    headers=${HEADERS_XML}
    ...    expected_status=200
    Log    ${resp.content}


*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational ds
    Start Mininet
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    90s    1s    FlowLib.Check Switches In Topology    1

Final Phase
    [Documentation]    Stops mininet
    Stop Mininet
    Delete All Sessions
