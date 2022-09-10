*** Settings ***
Documentation       Test suite for Split connection bug.

Library             XML
Library             SSHLibrary
Library             RequestsLibrary
Library             Collections
Resource            ../../../libraries/MininetKeywords.robot
Resource            ../../../libraries/FlowLib.robot
Resource            ../../../libraries/OVSDB.robot
Resource            ../../../variables/Variables.robot
Resource            ../../../variables/openflowplugin/Variables.robot

Suite Setup         Initialization Phase
Suite Teardown      Final Phase


*** Variables ***
${ODL_OF_PORT1}     6653
${SH_CNTL_CMD}      ovs-vsctl list Controller
${lprompt}          mininet>


*** Test Cases ***
Create Two Active Switch Connections To Controller And Check OVS Connections
    [Documentation]    Make a second connection from switch s1 to a controller
    ${controller_opt} =    BuiltIn.Set Variable
    ${controller_opt} =    BuiltIn.Catenate
    ...    ${controller_opt}
    ...    ${SPACE}tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}${SPACE}tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT1}
    OVSDB.Set Controller In OVS Bridge    ${TOOLS_SYSTEM_IP}    s1    ${controller_opt}
    BuiltIn.Wait Until Keyword Succeeds    20s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    1
    Check Master Connection    30
    [Teardown]    Report_Failure_Due_To_Bug    8723

Restore original Connection To Controller And Check OVS Connection
    [Documentation]    Restore original Connection To Controller And Check OVS Connection
    ${controller_opt} =    BuiltIn.Set Variable
    ${controller_opt} =    BuiltIn.Catenate    ${controller_opt}    ${SPACE}tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}
    OVSDB.Set Controller In OVS Bridge    ${TOOLS_SYSTEM_IP}    s1    ${controller_opt}
    BuiltIn.Wait Until Keyword Succeeds    20s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    1
    Check Master Connection    20
    FlowLib.Check Number Of Flows    1
    [Teardown]    Report_Failure_Due_To_Bug    8723


*** Keywords ***
Initialization Phase
    [Documentation]    Starts mininet and verify if topology is in operational datastore.
    ${mininet_conn_id} =    MininetKeywords.Start Mininet Single Controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    RequestsLibrary.Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS_XML}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    FlowLib.Check Switches In Topology    1

Final Phase
    [Documentation]    Stops mininet.
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${RFC8040_NODES_API}
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    RequestsLibrary.Delete All Sessions

Check Master Connection
    [Documentation]    Execute OvsVsctl List Controllers Command and check for master connection.
    [Arguments]    ${timeout}=20
    ${output} =    Utils.Run Command On Mininet
    ...    ${TOOLS_SYSTEM_IP}
    ...    sudo timeout --signal=KILL ${timeout} ovsdb-client monitor Controller target,role
    BuiltIn.Set Suite Variable    ${output}
    Should Contain    ${output}    master
    Log    ${output}
    RETURN    ${output}
