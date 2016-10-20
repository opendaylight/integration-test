*** Settings ***
Library           SSHLibrary
Library           DateTime
Library           String
Library           Collections
Library           RequestsLibrary
Library           ScaleClient.py
Library           SwitchClasses/BaseSwitch.py
Resource          Utils.robot
Resource          CompareStream.robot
Resource          MininetKeywords.robot
Variables         ../variables/Variables.py

*** Variables ***
${flow_count}     10000
${swspread}       linear
${tables}         10
${tabspread}      linear
${nrthreads}      1

*** Keywords ***
Find Max Switches
    [Arguments]    ${start}    ${stop}    ${step}    ${sustain_time}=0
    [Documentation]    Will find out max switches starting from ${start} till reaching ${stop} and in steps defined by ${step}.
    ...    The network is hold for ${sustain_time} seconds after everything is checked successful.
    ${error_message}=    Set Variable    No error
    ${controller_list}=    Create List    ${ODL_SYSTEM_IP}
    ${max-switches}=    Set Variable    ${0}
    Set Suite Variable    ${max-switches}
    ${start}=    Convert to Integer    ${start}
    ${stop}=    Convert to Integer    ${stop}
    ${step}=    Convert to Integer    ${step}
    ${flow_count}=    Convert to Integer    ${flow_count}
    : FOR    ${switches}    IN RANGE    ${start}    ${stop+1}    ${step}
    \    ${flows_ovs_25}=    Evaluate    ${flow_count} + ${switches}
    \    ${flows_before}=    CompareStream.Set_Variable_If_At_Least_Boron    ${switches}    ${0}
    \    ${flows_after}=    CompareStream.Set_Variable_If_At_Least_Boron    ${flows_ovs_25}    ${flow_count}
    \    ${flows}    ${notes}    ScaleClient.Generate New Flow Details    flows=${flow_count}    switches=${switches}    swspread=${swspread}
    \    ...    tables=${tables}    tabspread=${tabspread}
    \    Log to console    ${\n}
    \    Log To Console    Starting mininet linear ${switches}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet Linear    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail starting mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${start_time}=    DateTime.Get Current Date    result_format=timestamp
    \    Log To Console    Verify controller is OK
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Controller is dead
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Has No Null Pointer Exceptions    ${ODL_SYSTEM_IP}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Controller has NPE
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${switches} switches
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    10s
    \    ...    Check Every Switch    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking switch
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking Linear Topology
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches}    5s
    \    ...    Check Linear Topology    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking topology
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${end_time}=    DateTime.Get Current Date    result_format=timestamp
    \    ${topology_discover_time}=    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    \    Log To Console    Topology Discovery Time = ${topology_discover_time} seconds
    \    Log To Console    Adding ${flow_count} flows
    \    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Configure Flows    flow_details=${flows}    controllers=${controller_list}
    \    ...    nrthreads=${nrthreads}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail configuring flows
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${flow_count} flows in Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_after}
    \    ...    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking flows in mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${flow_count} flows in Operational DS
    \    ${status}    ${result}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    ${switches*4}    10s
    \    ...    Check Flows Operational Datastore    ${flows_after}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking flows in operational DS
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Sleep for ${sustain_time} seconds
    \    Sleep    ${sustain_time}
    \    Log To Console    Deleting ${flow_count} flows
    \    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Deconfigure Flows    flow_details=${flows}    controllers=${controller_list}
    \    ...    nrthreads=${nrthreads}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail deconfiguring flows
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking no flows in Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_before}
    \    ...    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no flows in mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking no flows in Operational DS
    \    ${status}    ${result}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    ${switches*4}    10s
    \    ...    Check Flows Operational Datastore    ${flows_before}
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no flows in operational DS
    \    Log To Console    Stopping Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail stopping mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking No Switches
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s
    \    ...    Check No Switches    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no switch
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking No Topology
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s
    \    ...    Check No Topology    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no topology
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-switches}=    Convert To String    ${switches}
    Log To Console    ${error_message}
    [Return]    ${max-switches}    ${topology_discover_time}    ${error_message}

Find Max Links
    [Arguments]    ${begin}    ${stop}    ${step}    ${sustain_time}=0
    [Documentation]    Will find out max switches in fully mesh topology starting from ${start} till reaching ${stop} and in steps defined by ${step}.
    ...    The network is hold for ${sustain_time} seconds after everything is checked successful.
    ${error_message}=    Set Variable    No error
    ${controller_list}=    Create List    ${ODL_SYSTEM_IP}
    ${max_switches}    Set Variable    ${0}
    ${stop}    Convert to Integer    ${stop}
    ${step}    Convert to Integer    ${step}
    ${flow_count}=    Convert to Integer    ${flow_count}
    : FOR    ${switches}    IN RANGE    ${begin}    ${stop+1}    ${step}
    \    ${mininet_timeout}=    Evaluate    ${switches} * ${switches}
    \    ${flows_ovs_25}=    Evaluate    ${flow_count} + ${switches}
    \    ${flows_before}=    CompareStream.Set_Variable_If_At_Least_Boron    ${switches}    ${0}
    \    ${flows_after}=    CompareStream.Set_Variable_If_At_Least_Boron    ${flows_ovs_25}    ${flow_count}
    \    ${flows}    ${notes}    ScaleClient.Generate New Flow Details    flows=${flow_count}    switches=${switches}    swspread=${swspread}
    \    ...    tables=${tables}    tabspread=${tabspread}
    \    Log to console    ${\n}
    \    Log To Console    Start a custom mininet topology with ${switches} nodes
    \    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet With Custom Topology    ${CREATE_FULLYMESH_TOPOLOGY_FILE}    ${switches}
    \    ...    ${BASE_MAC_1}    ${BASE_IP_1}    ${0}    ${mininet_timeout}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail starting mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${start_time}=    DateTime.Get Current Date    result_format=timestamp
    \    Log To Console    Verify controller is OK
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Controller is dead
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${status}    ${result}    Run Keyword And Ignore Error    Verify Controller Has No Null Pointer Exceptions    ${ODL_SYSTEM_IP}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Controller has NPE
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${switches} switches
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10    2s
    \    ...    Check Every Switch    ${switches}    ${BASE_MAC_1}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking switch
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max-links}=    Evaluate    ${switches} * ${switches-1}
    \    Log To Console    Check number of links in inventory is ${max-links}
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10    2s
    \    ...    Check Number Of Links    ${max-links}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking topology
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${end_time}=    DateTime.Get Current Date    result_format=timestamp
    \    ${topology_discover_time}=    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    \    Log To Console    Topology Discovery Time = ${topology_discover_time} seconds
    \    Log To Console    Adding ${flow_count} flows
    \    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Configure Flows    flow_details=${flows}    controllers=${controller_list}
    \    ...    nrthreads=${nrthreads}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail configuring flows
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${flow_count} flows in Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_after}
    \    ...    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking flows in mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking ${flow_count} flows in Operational DS
    \    ${status}    ${result}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    ${switches*4}    10s
    \    ...    Check Flows Operational Datastore    ${flows_after}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking flows in operational DS
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Sleep for ${sustain_time} seconds
    \    Sleep    ${sustain_time}
    \    Log To Console    Deleting ${flow_count} flows
    \    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Deconfigure Flows    flow_details=${flows}    controllers=${controller_list}
    \    ...    nrthreads=${nrthreads}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail deconfiguring flows
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking no flows in Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_before}
    \    ...    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no flows in mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking no flows in Operational DS
    \    ${status}    ${result}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    ${switches*4}    10s
    \    ...    Check Flows Operational Datastore    ${flows_before}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no flows in operational DS
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Stopping Mininet
    \    ${status}    ${result}    Run Keyword And Ignore Error    Stop Mininet Simulation
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail stopping mininet
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking No Switches
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10    2s
    \    ...    Check No Switches    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no switch
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    Log To Console    Checking No Topology
    \    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10    2s
    \    ...    Check No Topology    ${switches}
    \    ${error_message}=    Set Variable If    '${status}' == 'FAIL'    Fail checking no topology
    \    Exit For Loop If    '${status}' == 'FAIL'
    \    ${max_switches}    Set Variable    ${switches}
    Log To Console    ${error_message}
    ${max-links}=    Evaluate    ${max_switches} * ${max_switches-1}
    [Return]    ${max-links}    ${topology_discover_time}    ${error_message}

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
    \    ${status}    ${result}    Run Keyword And Ignore Error    Check No Switches    ${1}
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

Check Number Of Links
    [Arguments]    ${links}
    [Documentation]    Check number of links in inventory is ${links}
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    Check number of links in inventory is ${links}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.content}    "link-id":"openflow:
    Should Be Equal As Integers    ${count}    ${links}

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

Start Mininet Linear
    [Arguments]    ${switches}
    [Documentation]    Start mininet linear topology with ${switches} nodes
    ${mininet_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${switches*4}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Write    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,${switches} --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>

Start Mininet With Custom Topology
    [Arguments]    ${topology_file}    ${switches}    ${base_mac}=00:00:00:00:00:00    ${base_ip}=1.1.1.1    ${hosts}=0    ${mininet_start_time}=100
    [Documentation]    Start a custom mininet topology.
    ${mininet_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${mininet_start_time}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Log    Copying ${CREATE_FULLYMESH_TOPOLOGY_FILE_PATH} file to Mininet VM
    Put File    ${CURDIR}/${CREATE_FULLYMESH_TOPOLOGY_FILE_PATH}
    Write    python ${topology_file} ${switches} ${hosts} ${base_mac} ${base_ip}
    Read Until    ${DEFAULT_LINUX_PROMPT}
    Write    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom switch.py --topo demotopo --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Write    sh ovs-vsctl show
    ${output}=    Read Until    mininet>
    # Ovsdb connection is sometimes lost after mininet is started. Checking if the connection is alive before proceeding.
    Should Not Contain    ${output}    database connection failed

Check Every Switch
    [Arguments]    ${switches}    ${base_mac}=00:00:00:00:00:00
    [Documentation]    Check all switches and stats in operational inventory
    ${mac}=    Replace String Using Regexp    ${base_mac}    :    ${EMPTY}
    ${mac}=    Convert Hex To Decimal As String    ${mac}
    ${mac}=    Convert To Integer    ${mac}
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    ${dpid_decimal}=    Evaluate    ${mac} + ${switch}
    \    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}/node/openflow:${dpid_decimal}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Should Contain    ${resp.content}    flow-capable-node-connector-statistics
    \    Should Contain    ${resp.content}    flow-table-statistics

Check Linear Topology
    [Arguments]    ${switches}
    [Documentation]    Check Linear topology given ${switches}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
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

Check Flows Operational Datastore
    [Arguments]    ${flow_count}    ${controller_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Check if number of Operational Flows on member of given index is equal to ${flow_count}.
    ${sw}    ${reported_flow}    ${found_flow}=    ScaleClient.Flow Stats Collected    controller=${controller_ip}
    BuiltIn.Should_Be_Equal_As_Numbers    ${flow_count}    ${found_flow}

Check No Switches
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in inventory
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_NODES_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    "openflow:${switch}"

Check No Topology
    [Arguments]    ${switches}
    [Documentation]    Check no switch is in topology
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    Should Not Contain    ${resp.content}    openflow:${switch}

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
