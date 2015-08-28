*** Settings ***
Library           SSHLibrary
Resource          Utils.robot
Library           String
Library           Collections
Variables           ../variables/Variables.py
Library           RequestsLibrary
Library           SwitchClasses/BaseSwitch.py

*** Keywords ***
Find Max Switches
    [Arguments]    ${start}    ${stop}    ${step}
    [Documentation]    Will find out max switches starting from ${start} till reaching ${stop} and in steps defined by ${step}
    ${max-switches}    Set Variable    ${0}
    Set Suite Variable    ${max-switches}
    ${start}    Convert to Integer    ${start}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    : FOR    ${switches}    IN RANGE    ${start}    ${stop+1}    ${step}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet Linear    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${CONTROLLER}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Every Switch    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Linear Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check No Switches    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check No Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-switches}    Convert To String    ${switches}
    [Return]    ${max-switches}

Find Max Links
    [Arguments]    ${begin}    ${stop}    ${step}
    [Documentation]    Will find out max switches in fully mesh topology starting from ${start} till reaching ${stop} and in steps defined by ${step}
    ${max_switches}    Set Variable    ${0}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    : FOR    ${switches}    IN RANGE    ${begin}    ${stop+1}    ${step}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet With Custom Topology     ${CREATE_FULLYMESH_TOPOLOGY_FILE}   ${switches}  ${BASE_MAC_1}  ${BASE_IP_1}    ${0}   ${switches*20}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${CONTROLLER}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Has No Null Pointer Exceptions    ${CONTROLLER}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120    10s
    \    ...    Check Every Switch    ${switches}    ${BASE_MAC_1}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-links}=      Evaluate  ${switches}*${switches-1}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120    10s
    \    ...    Check Number Of Links  ${max-links}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120    10s
    \    ...    Check No Switches    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120    10s
    \    ...    Check No Topology    ${switches}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max_switches}    Set Variable    ${switches}
    ${max-links}=      Evaluate  ${max_switches}*${max_switches-1}
    [Return]    ${max-links}

Find Max Hosts
    [Arguments]    ${begin}    ${stop}    ${step}
    [Documentation]    Will find out max hosts starting from ${begin} till reaching ${stop} and in steps defined by ${step}
    ${max-hosts}    Set Variable    ${0}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    : FOR    ${hosts}    IN RANGE    ${begin}    ${stop+1}    ${step}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet With One Switch And ${hosts} hosts
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error   Wait Until Keyword Succeeds    120s    30s
    \    ...    Check Every Switch  ${1}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    @{host_list}=      Get Mininet Hosts
    \    ${status}=     Ping All Hosts     @{host_list}
    \    Exit For Loop If    ${status} != ${0}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${CONTROLLER}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    120s    30s
    \    ...    Check Number Of Hosts    ${hosts}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Check No Switches    ${1}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Check No Hosts
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-hosts}    Convert To String    ${hosts}
    [Return]    ${max-hosts}

Get Mininet Hosts
    [Documentation]  Get all the hosts from mininet
    ${host_list}=       Create List
    Write       nodes
    ${out}=     Read Until      mininet>
    @{words}=       Split String    ${out}  ${SPACE}
    :FOR  ${item}   IN  @{words}
    \   ${h}=   Get Lines Matching Regexp       ${item.rstrip()}     .*h[0-9]*s.
    \   Run Keyword If  '${h}' != '${EMPTY}'    Append To List     ${host_list}   ${h}
    [Return]  ${host_list}

Ping All Hosts
    [Arguments]     @{host_list}
    [Documentation]  Do one round of ping from one host to all other hosts in mininet
    ${source}=      Get From List   ${host_list}  ${0}
    : FOR    ${h}   IN  @{host_list}
    \   ${status}=   Ping Two Hosts      ${source}   ${h}    1
    \   Exit For Loop If    ${status}!=${0}
    [Return]    ${status}

Start Mininet With One Switch And ${hosts} hosts
    [Documentation]    Start mininet with one switch and ${hosts} hosts
    Log     Starting mininet with one switch and ${hosts} hosts
    Log To Console   Starting mininet with one switch and ${hosts} hosts
    ${mininet_conn_id}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${hosts*3}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo mn --controller=remote,ip=${CONTROLLER} --topo linear,1,${hosts} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>

Check Number Of Hosts
    [Arguments]    ${hosts}
    [Documentation]    Check number of hosts in inventory
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}
    Log     Check number of hosts in inventory
    Log To Console  Check number of hosts in inventory
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count       ${resp.content}    "node-id":"host:
    Should Be Equal As Integers  ${count}   ${hosts}

Check Number Of Links
    [Arguments]    ${links}
    [Documentation]    Check number of links in inventory is ${links}
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}
    Log     Check number of links in inventory is ${links}
    Log To Console  Check number of links in inventory is ${links}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count       ${resp.content}   "link-id":"openflow:
    Should Be Equal As Integers  ${count}   ${links}

Ping Two Hosts
    [Arguments]     ${host1}    ${host2}    ${pingcount}=2   ${connection_index}=${EMPTY}   ${connection_alias}=${EMPTY}
    [Documentation]  Ping between mininet hosts. Must be used only after a mininet session is in place.Returns non zero value if there is 100% packet loss.
    Run Keyword If       '${connection_index}'  !=   '${EMPTY}'        Switch Connection   ${connection_index}
    Run Keyword If       '${connection_alias}'  !=   '${EMPTY}'        Switch Connection   ${connection_alias}
    Write     ${host1} ping -c ${pingcount} ${host2}
    ${out}=     Read Until  mininet>
    ${ret}=     Get Lines Matching Regexp   ${out}  .*100% packet loss.*
    ${len}=     Get Length      ${ret}
    [Return]    ${len}

Check No Hosts
    [Documentation]    Check if all hosts are deleted from inventory
    ${resp}=    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}
    Log To Console    Checking no hosts are present in operational database
    Log    Checking no hosts are present in operational database
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    "node-id":"host:

Start Mininet Linear
    [Arguments]    ${switches}
    [Documentation]    Start mininet linear topology with ${switches} nodes
    Log To Console    Starting mininet linear ${switches}
    ${mininet_conn_id}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${switches*3}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo mn --controller=remote,ip=${CONTROLLER} --topo linear,${switches} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Sleep    6

Start Mininet With Custom Topology
    [Arguments]  ${topology_file}  ${switches}   ${base_mac}=00:00:00:00:00:00  ${base_ip}=1.1.1.1  ${hosts}=0  ${mininet_start_time}=100
    [Documentation]  Start a custom mininet topology.
    Log To Console    Start a custom mininet topology with ${switches} nodes
    ${mininet_conn_id}=    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${mininet_start_time}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    python ${topology_file} ${switches} ${hosts} ${base_mac} ${base_ip}
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Write    sudo mn --controller=remote,ip=${CONTROLLER} --custom switch.py --topo demotopo --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Write   sh ovs-vsctl show
    ${output}=  Read Until    mininet>
    # Ovsdb connection is sometimes lost after mininet is started. Checking if the connection is alive before proceeding.
    Should Not Contain  ${output}   database connection failed
    Log To Console  Mininet Started with ${switches} nodes

Check Every Switch
    [Arguments]    ${switches}  ${base_mac}=00:00:00:00:00:00
    [Documentation]    Check all switches and stats in operational inventory
    ${mac}=     Replace String Using Regexp     ${base_mac}      :     ${EMPTY}
    ${mac}=     Convert Hex To Decimal As String    ${mac}
    ${mac}=     Convert To Integer  ${mac}
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    ${dpid_decimal}=   Evaluate  ${mac}+${switch}
    \    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}/node/openflow:${dpid_decimal}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Log To Console    Checking Switch ${switch}
    \    Should Contain    ${resp.content}    flow-capable-node-connector-statistics
    \    Should Contain    ${resp.content}    flow-table-statistics

Check Linear Topology
    [Arguments]    ${switches}
    [Documentation]    Check Linear topology given ${switches}
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}
    Log To Console    Checking Topology
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Contain    ${resp.content}    "node-id":"openflow:${switch}"
    \    Should Contain    ${resp.content}    "tp-id":"openflow:${switch}:1"
    \    Should Contain    ${resp.content}    "tp-id":"openflow:${switch}:2"
    \    Should Contain    ${resp.content}    "source-tp":"openflow:${switch}:2"
    \    Should Contain    ${resp.content}    "dest-tp":"openflow:${switch}:2"
    \    ${edge}    Evaluate    ${switch}==1 or ${switch}==${switches}
    \    Run Keyword Unless    ${edge}    Should Contain    ${resp.content}    "tp-id":"openflow:${switch}:3"
    \    Run Keyword Unless    ${edge}    Should Contain    ${resp.content}    "source-tp":"openflow:${switch}:3"
    \    Run Keyword Unless    ${edge}    Should Contain    ${resp.content}    "dest-tp":"openflow:${switch}:3"

Check No Switches
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in inventory
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Log To Console    Checking No Switches
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    openflow:${switch}

Check No Topology
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in topology
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_TOPO_API}
    Log To Console    Checking No Topology
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    openflow:${switch}

Stop Mininet Simulation
    [Documentation]    Stop mininet
    Log To Console    Stopping Mininet
    Switch Connection    ${mininet_conn_id}
    Read
    Write    exit
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Close Connection

Scalability Suite Teardown
    Delete All Sessions
    Clean Mininet System
