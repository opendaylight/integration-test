*** Settings ***
Library           SSHLibrary
Resource          Utils.robot
Library           String
Library           Collections
Variables         ../variables/Variables.py
Library           RequestsLibrary
Library           DockerScale.py  ${MININET}    ${PORT}

*** Variables ***
${linux_prompt}    >
${ip_start}       2
${OVSDB_PORT}     6640

*** Keywords ***
Find Max Ovsdb Switches
    [Arguments]    ${start}    ${stop}    ${step}
    [Documentation]    Will find out max switches starting from ${start} till reaching ${stop} and in steps defined by ${step}
    ${max-switches}    Set Variable    ${0}
    ${start}    Convert to Integer    ${start}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    : FOR    ${switches}    IN RANGE    ${start}    ${stop+1}    ${step}
    \    Start Docker Linear Topo    ${switches}    172.0.100.${ip_start}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${CONTROLLER}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*5}    10s
    \    ...    Add Ovsdb Switches To Controller    ${switches}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Ovsdb Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Scalability Docker Suite Teardown
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*10}    10s
    \    ...    Check No Ovs Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check No Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-switches}    Convert To String    ${switches}
    \    ${ip_start} = ${ip_start} + ${step}
    [Return]    ${max-switches}
do
Start Docker Linear Topo
    [Arguments]    ${switches}    ${ipaddress_start}
    [Documentation]    Start docker linear topology with ${switches} nodes
    Log To Console    Starting docker linear topo ${switches}
    Setup Test Switches    ${switches}    ${ipaddress_start}    ${CONTROLLER}

Add Ovsdb Switches To Controller
    [Arguments]    ${switches}
    [Documentation]    Start docker linear topology with ${switches} nodes
    ${host-list} =    Return Container Names
    : FOR    ${docker-name}    IN    @{host-list}
    \    ${ip-address}    Fetch From Left    ${docker-name}    '-'
    \    Connect To Ovsdb Node    ${ip-address} ${OVSDB_PORT}

Check Ovsdb Topology
    [Arguments]    ${switches}
    [Documentation]    Check Ovsdb topology given ${switches}
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_OVSDB}
    Log To Console    Checking Topology
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Contain    ${resp.content}    "node-id":"ovsdb://${switch}:6640"

Check No Ovs Topology
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in ovsdb topo
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_OVSDB}
    Log To Console    Checking No Switches
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    ovsdb://${switch}:6640

Check No Topology
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in topology
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}
    Log To Console    Checking No Topology
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    ovsdb://${switch}:6640

Scalability Suite Teardown
    Delete All Sessions
    Scalability Docker Suite Teardown
