*** Settings ***
Documentation     Resource for L2switch workflows. TODO: Refactor KWs once this test works in public.
Library           SSHLibrary
Library           RequestsLibrary
Library           String
Library           Collections
Library           SwitchClasses/BaseSwitch.py
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Find Max Hosts
    [Arguments]    ${begin}    ${stop}    ${step}    ${sustain_time}=0
    [Documentation]    Will find out max hosts starting from ${begin} till reaching ${stop} and in steps defined by ${step}.
    ...    The network is hold for ${sustain_time} seconds after everything is checked successful.
    ${max-hosts}    Set Variable    ${0}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    : FOR    ${hosts}    IN RANGE    ${begin}    ${stop+1}    ${step}
    \    Log To Console    Starting mininet with one switch and ${hosts} hosts
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet With One Switch And ${hosts} hosts
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${switches} switches
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120s    30s
    \    ...    Check Every Switch    ${1}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Ping all hosts
    \    @{host_list}=    Get Mininet Hosts
    \    ${status}=    Ping All Hosts    @{host_list}
    \    Exit For Loop If    ${status} != ${0}
    \    Log To Console    Verify controller is OK
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Has No Null Pointer Exceptions    ${ODL_SYSTEM_IP}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Check number of hosts in inventory is ${hosts}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120s    30s
    \    ...    Check Number Of Hosts    ${hosts}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Sleep for ${sustain_time} seconds
    \    Sleep    ${sustain_time}
    \    Log To Console    Stopping Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking No Switches
    \    ${status}    ${result}    Run Keyword And Ignore Error    Check No Switches
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking no hosts are present in operational database
    \    ${status}    ${result}    Run Keyword And Ignore Error    Check No Hosts
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-hosts}    Convert To String    ${hosts}
    [Return]    ${max-hosts}

Get Mininet Hosts
    [Documentation]    Get all the hosts from mininet
    ${host_list}=    Create List
    Write    nodes
    ${out}=    Read Until    mininet>
    @{words}=    Split String    ${out}    ${SPACE}
    : FOR    ${item}    IN    @{words}
    \    ${h}=    Get Lines Matching Regexp    ${item.rstrip()}    .*h[0-9]*s.
    \    Run Keyword If    '${h}' != '${EMPTY}'    Append To List    ${host_list}    ${h}
    [Return]    ${host_list}

Ping All Hosts
    [Arguments]    @{host_list}
    [Documentation]    Do one round of ping from one host to all other hosts in mininet
    ${source}=    Get From List    ${host_list}    ${0}
    : FOR    ${h}    IN    @{host_list}
    \    ${status}=    Ping Two Hosts    ${source}    ${h}    1
    \    Exit For Loop If    ${status}!=${0}
    [Return]    ${status}

Start Mininet With One Switch And ${hosts} hosts
    [Documentation]    Start mininet with one switch and ${hosts} hosts
    Log    Starting mininet with one switch and ${hosts} hosts
    ${mininet_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${hosts*3}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,1,${hosts} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>

Check Number Of Hosts
    [Arguments]    ${hosts}
    [Documentation]    Check number of hosts in inventory
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    Check number of hosts in inventory is ${hosts}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.content}    "node-id":"host:
    Should Be Equal As Integers    ${count}    ${hosts}

Ping Two Hosts
    [Arguments]    ${host1}    ${host2}    ${pingcount}=2    ${connection_index}=${EMPTY}    ${connection_alias}=${EMPTY}
    [Documentation]    Ping between mininet hosts. Must be used only after a mininet session is in place.Returns non zero value if there is 100% packet loss.
    Run Keyword If    '${connection_index}'    !=    '${EMPTY}'    Switch Connection    ${connection_index}
    Run Keyword If    '${connection_alias}'    !=    '${EMPTY}'    Switch Connection    ${connection_alias}
    Write    ${host1} ping -c ${pingcount} ${host2}
    ${out}=    Read Until    mininet>
    ${ret}=    Get Lines Matching Regexp    ${out}    .*100% packet loss.*
    ${len}=    Get Length    ${ret}
    [Return]    ${len}

Check No Hosts
    [Documentation]    Check if all hosts are deleted from inventory
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    Checking no hosts are present in operational database
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    "node-id":"host:

Check No Switches
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in inventory
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    "openflow:${switch}"

Stop Mininet Simulation
    [Documentation]    Stop mininet
    Switch Connection    ${mininet_conn_id}
    Read
    Write    exit
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection

Scalability Suite Teardown
    Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    Delete All Sessions
    Clean Mininet System
