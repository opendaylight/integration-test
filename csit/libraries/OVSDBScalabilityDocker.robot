*** Settings ***
Resource          Utils.robot
Library           SSHLibrary
Library           String
Library           Collections
Library           RequestsLibrary
Library           DockerScale.py  ${TOOLS_SYSTEM_IP}    ${DOCKER_DAEMON_PORT}
Variables         ../variables/Variables.py

*** Variables ***
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
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Docker Linear Topo    ${switches}    192.168.100.${ip_start}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Ovsdb Topology    ${mininet_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Connect All Ovsdb Nodes From Controller
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Ovsdb Topology    ${ovs_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*10}    10s
    \    ...    Check No Ovsdb Topology    ${ovs_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-switches}    Convert To String    ${switches}
    \    ${ip_start} = ${ip_start} + ${step}
    [Return]    ${max-switches}

Find Max Netvirt Switches
    [Arguments]    ${start}    ${stop}    ${step}
    [Documentation]    Will find out max switches starting from ${start} till reaching ${stop} and in steps defined by ${step}
    ${max-switches}    Set Variable    ${0}
    ${start}    Convert to Integer    ${start}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    : FOR    ${switches}    IN RANGE    ${start}    ${stop+1}    ${step}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Docker Linear Topo    ${switches}    192.168.100.${ip_start}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Ovsdb Topology    ${mininet_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Connect All Ovsdb Nodes From Controller
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Ovsdb Topology    ${mininet_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Netvirt Topology    ${ovs_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*10}    10s
    \    ...    Check No Ovsdb Topology    ${ovs_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*10}    10s
    \    ...    Check No Netvirt Topology    ${ovs_ip_list}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-switches}    Convert To String    ${switches}
    \    ${ip_start} = ${ip_start} + ${step}
    [Return]    ${max-switches}

Start Docker Linear Topo
    [Arguments]    ${switches}    ${ipaddress_start}
    [Documentation]    Start docker linear topology with ${switches} nodes
    Log To Console    Starting docker linear topo ${switches}
    Setup Test Switches    ${switches}    ${ipaddress_start}    ${ODL_SYSTEM_IP}

Connect All Ovsdb Nodes From Controller
    [Arguments]    ${ovsdb_port}=6640
    [Documentation]    Initiate connection to OVSDB node from controller for each mininet system
    Log To Console    Connecting all OVSDB nodes to controller
    @{host-list} =    Return Container Names
    @{ovs_ip_list}=    Create List
    : FOR    ${docker-name}    IN    @{host-list}
    \    ${ip-address}    Fetch From Left    ${docker-name}    -
    \   run_command_on_remote   ${ip-address}   sudo ovs-vsctl del-manager
    \   run_command_on_remote   ${ip-address}   sudo ovs-vsctl set-manager ptcp::${ovsdb_port}
    \   Connect To Ovsdb Node    ${ip-address} ${OVSDB_PORT}
    \   Append To List    ${ovs_ip_list}    ${ip-address}
    \   Set Suite Variable  ${ovs_ip_list}

Check Ovsdb Topology
    [Arguments]    ${switch_ip_list}=${ovs_ip_list}  ${ovsdb_port}=6640
    [Documentation]    Check Ovsdb topology given ${switch_ip_list}
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_OVSDB}
    Log To Console    Checking Topology
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch_ip}    IN    ${switch_ip_list}
    \    Should Contain    ${resp.content}    ovsdb://${switch_ip}:${ovsdb_port}

Check Netvirt Topology
    [Arguments]    ${switch_ip_list}=${ovs_ip_list}  ${ovsdb_port}=6640
    [Documentation]    Check netvirt topology given ${switch_ip_list}
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_NETVIRT}
    Log To Console    Checking Topology
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch_ip}    IN    ${switch_ip_list}
    \    Should Contain    ${resp.content}    netvirt://${switch_ip}:${ovsdb_port}

Check No Ovsdb Topology
    [Arguments]    ${switch_ip_list}=${ovs_ip_list}  ${ovsdb_port}=6640
    [Documentation]    Check no switch is in ovsdb topo
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_OVSDB}
    Log To Console    Checking No Switches
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch_ip}    IN    ${switch_ip_list}
    \    Should Not Contain    ${resp.content}    ovsdb://${switch_ip}:${ovsdb_port}

Check No Netvirt Topology
    [Arguments]    ${switch_ip_list}=${ovs_ip_list}  ${ovsdb_port}=6640
    [Documentation]    Check no switch is in netvirt topo
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_NETVIRT}
    Log To Console    Checking No Switches
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch_ip}    IN    ${switch_ip_list}
    \    Should Not Contain    ${resp.content}    netvirt://${switch_ip}:${ovsdb_port}

Scalability Suite Teardown
    Delete All Sessions
    Run Keyword And Ignore Error    Scalability Docker Suite Teardown

Setup Docker Test Suite
    [Documentation]     Create session with controller
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Put File On Remote System
    [Arguments]    ${system}    ${file_path}     ${file_dest}    ${user}=${MININET_USER}    ${password}=${EMPTY}    ${prompt}=${DEFAULT_LINUX_PROMPT}   ${prompt_timeout}=30s
    [Documentation]    Reduces the common work of putting a file on a remote system to a single higher level
    ...    robot keyword, taking care to log in with a public key and. The file given is uploaded
    ...    and the output returned. No test conditions are checked.
    Log    Attempting to put ${file_path} on ${system} at ${file_dest} by ${user} with ${keyfile_pass} and ${prompt}
    ${conn_id}=    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    Flexible SSH Login    ${user}    ${password}
    SSHLibrary.Put File    ${file_path}     destination=${file_dest}
    SSHLibrary.Close Connection


