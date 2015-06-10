*** Settings ***
Resource          Utils.robot
Library           SSHLibrary
Library           String
Library           Collections
Library           RequestsLibrary
Library           DockerScale.py  ${MININET}    ${PORT}
Variables         ../variables/Variables.py

*** Variables ***
${ip_start}       2
${OVSDB_PORT}     6640
${CHMOD_PIPEWORK_CMD}    'chmod +x /usr/local/bin/pipework'
${SETUP_DOCKER}     'export DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://${MININET}:5555"; systemctl restart docker'


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

Setup Docker Test Suite
    [Documentation]     Setup environment to run tests - start docker daemon to listen on port 5555 and copy pipework to docker system
    Put File On Remote System   ${MININET}    'include-raw-pipework.sh'     '/usr/local/pipework'   prompt='$'
    Run Command On Mininet    ${CHMOD_PIPEWORK_CMD}     prompt='$'
    Run Command On Mininet    ${SETUP_DOCKER}       prompt='$'
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}

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


