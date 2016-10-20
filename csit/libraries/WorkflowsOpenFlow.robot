*** Settings ***
Documentation     Resource for OpenFlow workflows. This library can be used for scalability and longevity tests.
Library           SSHLibrary
Library           DateTime
Library           RequestsLibrary
Library           ScaleClient.py
Library           SwitchClasses/BaseSwitch.py
Resource          Utils.robot
Resource          CompareStream.robot
Resource          MininetKeywords.robot
Resource          KarafKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
${topology_file}    create_fullymesh.py
${topology_file_path}    MininetTopo/${topology_file}
${flow_count}     10000
${swspread}       linear
${tables}         10
${tabspread}      linear
${nrthreads}      1

*** Keywords ***
Workflow Linear Topology
    [Arguments]    ${switches}    ${sustain_time}=0
    [Documentation]    Workflow to bring a Linear topology of ${switches} switches, push flows, hold for ${sustain_time} seconds, delete flows and stop topology.
    ...    This KW returns workflow state (PASS/FAIL), error message and topology discover time.
    # Define required variables
    ${error_message}=    Set Variable    Test has completed
    ${topology_discover_time}=    Set Variable    ${0}
    ${controller_list}=    Create List    ${ODL_SYSTEM_IP}
    ${flow_count}=    Convert to Integer    ${flow_count}
    ${flows_ovs_25}=    Evaluate    ${flow_count} + ${switches}
    ${flows_before}=    CompareStream.Set_Variable_If_At_Least_Boron    ${switches}    ${0}
    ${flows_after}=    CompareStream.Set_Variable_If_At_Least_Boron    ${flows_ovs_25}    ${flow_count}
    ${flows}    ${notes}    ScaleClient.Generate New Flow Details    flows=${flow_count}    switches=${switches}    swspread=${swspread}    tables=${tables}
    ...    tabspread=${tabspread}
    # Workflow starts
    Log to console    ${\n}
    Log To Console    Starting mininet linear ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet Linear    ${switches}    ${mininet_timeout}=${switches*4}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail starting mininet    ${topology_discover_time}
    ${start_time}=    DateTime.Get Current Date    result_format=timestamp
    Log To Console    Verify controller is OK
    ${status}    ${result}    Run Keyword And Ignore Error    Utils.Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Controller is dead    ${topology_discover_time}
    ${status}    ${result}    Run Keyword And Ignore Error    Utils.Verify Controller Has No Null Pointer Exceptions    ${ODL_SYSTEM_IP}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Controller has NPE    ${topology_discover_time}
    Log To Console    Checking ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*2}    2s    Check Every Switch
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking switch    ${topology_discover_time}
    Log To Console    Checking Linear Topology
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches}    2s    Check Linear Topology
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking topology    ${topology_discover_time}
    ${end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${topology_discover_time}=    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    Log To Console    Topology Discovery Time = ${topology_discover_time} seconds
    Log To Console    Adding ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Configure Flows    flow_details=${flows}    controllers=${controller_list}    nrthreads=${nrthreads}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail configuring flows    ${topology_discover_time}
    Log To Console    Checking ${flow_count} flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_after}    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking flows in mininet    ${topology_discover_time}
    Log To Console    Checking ${flow_count} flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*4}    2s    Check Flows Operational Datastore
    ...    ${flows_after}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking flows in operational DS    ${topology_discover_time}
    Log To Console    Sleep for ${sustain_time} seconds
    Sleep    ${sustain_time}
    Log To Console    Deleting ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Deconfigure Flows    flow_details=${flows}    controllers=${controller_list}    nrthreads=${nrthreads}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail deconfiguring flows    ${topology_discover_time}
    Log To Console    Checking no flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_before}    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no flows in mininet    ${topology_discover_time}
    Log To Console    Checking no flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*4}    2s    Check Flows Operational Datastore
    ...    ${flows_before}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no flows in operational DS    ${topology_discover_time}
    Log To Console    Stopping Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Stop Mininet And Exit
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail stopping mininet    ${topology_discover_time}
    Log To Console    Checking No Switches
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s    Check No Switches
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no switch    ${topology_discover_time}
    Log To Console    Checking No Topology
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s    Check No Topology
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no topology    ${topology_discover_time}
    [Return]    PASS    ${error_message}    ${topology_discover_time}

Workflow Full Mesh Topology
    [Arguments]    ${switches}    ${sustain_time}=0
    [Documentation]    Workflow to bring a Full mesh topology of ${switches} switches, push some flows, delete flows and stop topology.
    ...    This KW returns workflow state (PASS/FAIL), error message and topology discover time.
    # Define required variables
    ${error_message}=    Set Variable    Test has completed
    ${topology_discover_time}=    Set Variable    ${0}
    ${mininet_timeout}=    Evaluate    ${switches} * ${switches}
    ${links}=    Evaluate    ${switches} * ${switches-1}
    ${controller_list}=    Create List    ${ODL_SYSTEM_IP}
    ${flow_count}=    Convert to Integer    ${flow_count}
    ${flows_ovs_25}=    Evaluate    ${flow_count} + ${switches}
    ${flows_before}=    CompareStream.Set_Variable_If_At_Least_Boron    ${switches}    ${0}
    ${flows_after}=    CompareStream.Set_Variable_If_At_Least_Boron    ${flows_ovs_25}    ${flow_count}
    ${flows}    ${notes}    ScaleClient.Generate New Flow Details    flows=${flow_count}    switches=${switches}    swspread=${swspread}    tables=${tables}
    ...    tabspread=${tabspread}
    # Workflow starts
    Log to console    ${\n}
    Log To Console    Start a mininet full mesh ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error    Start Mininet Full Mesh    ${switches}    mininet_timeout=${mininet_timeout}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail starting mininet    ${topology_discover_time}
    ${start_time}=    DateTime.Get Current Date    result_format=timestamp
    Log To Console    Verify controller is OK
    ${status}    ${result}    Run Keyword And Ignore Error    Utils.Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Controller is dead    ${topology_discover_time}
    ${status}    ${result}    Run Keyword And Ignore Error    Utils.Verify Controller Has No Null Pointer Exceptions    ${ODL_SYSTEM_IP}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Controller has NPE    ${topology_discover_time}
    Log To Console    Checking ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s    Check Every Switch
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking switch    ${topology_discover_time}
    Log To Console    Check number of links in inventory is ${links}
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s    Check Number Of Links
    ...    ${links}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking topology    ${topology_discover_time}
    ${end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${topology_discover_time}=    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    Log To Console    Topology Discovery Time = ${topology_discover_time} seconds
    Log To Console    Adding ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Configure Flows    flow_details=${flows}    controllers=${controller_list}    nrthreads=${nrthreads}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail configuring flows    ${topology_discover_time}
    Log To Console    Checking ${flow_count} flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_after}    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking flows in mininet    ${topology_discover_time}
    Log To Console    Checking ${flow_count} flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*4}    2s    Check Flows Operational Datastore
    ...    ${flows_after}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking flows in operational DS    ${topology_discover_time}
    Log To Console    Sleep for ${sustain_time} seconds
    Sleep    ${sustain_time}
    Log To Console    Deleting ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error    ScaleClient.Deconfigure Flows    flow_details=${flows}    controllers=${controller_list}    nrthreads=${nrthreads}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail deconfiguring flows    ${topology_discover_time}
    Log To Console    Checking no flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Verify Aggregate Flow From Mininet Session    ${mininet_conn_id}    ${flows_before}    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no flows in mininet    ${topology_discover_time}
    Log To Console    Checking no flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${switches*4}    2s    Check Flows Operational Datastore
    ...    ${flows_before}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no flows in operational DS    ${topology_discover_time}
    Log To Console    Stopping Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Stop Mininet And Exit
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail stopping mininet    ${topology_discover_time}
    Log To Console    Checking No Switches
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s    Check No Switches
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no switch    ${topology_discover_time}
    Log To Console    Checking No Topology
    ${status}    ${result}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    10s    2s    Check No Topology
    ...    ${switches}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no topology    ${topology_discover_time}
    [Return]    PASS    ${error_message}    ${topology_discover_time}

Start Mininet Linear
    [Arguments]    ${switches}    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start mininet linear topology with ${switches} nodes
    Log    Start Mininet Linear
    MininetKeywords.StartMininet Single Controller    options=--topo linear,${switches} --switch ovsk,protocols=OpenFlow13    timeout=${mininet_timeout}

Start Mininet Full Mesh
    [Arguments]    ${switches}    ${base_mac}=00:00:00:00:00:00    ${base_ip}=10.0.0.0    ${hosts}=0    ${mininet_timeout}=${DEFAULT_TIMEOUT}
    [Documentation]    Start a custom mininet topology.
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=${mininet_timeout}
    Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible_Mininet_Login
    Log    Copying ${topology_file_path} file to Mininet VM and Creating Full Mesh topology
    SSHLibrary.Put File    ${CURDIR}/${topology_file_path}
    SSHLibrary.Write    python ${topology_file} ${switches} ${hosts} ${base_mac} ${base_ip}
    SSHLibrary.Read Until    ${DEFAULT_LINUX_PROMPT}
    Log    Start Mininet Full Mesh
    SSHLibrary.Write    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom switch.py --topo demotopo --switch ovsk,protocols=OpenFlow13
    Read Until    mininet>
    Log    Check OVS configuratiom
    Write    sh ovs-vsctl show
    ${output}=    Read Until    mininet>
    # Ovsdb connection is sometimes lost after mininet is started. Checking if the connection is alive before proceeding.
    Should Not Contain    ${output}    database connection failed

Check Every Switch
    [Arguments]    ${switches}    ${base_mac}=00:00:00:00:00:00
    [Documentation]    Check all switches and stats in operational inventory
    ${mac}=    String.Replace String Using Regexp    ${base_mac}    :    ${EMPTY}
    ${mac}=    BaseSwitch.Convert Hex To Decimal As String    ${mac}
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

Check Number Of Links
    [Arguments]    ${links}
    [Documentation]    Check number of links in inventory is ${links}
    ${resp}=    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    Check number of links in inventory is ${links}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}=    Get Count    ${resp.content}    "link-id":"openflow:
    Should Be Equal As Integers    ${count}    ${links}

Check Flows Operational Datastore
    [Arguments]    ${flow_count}    ${controller_ip}=${ODL_SYSTEM_IP}
    [Documentation]    Check if number of Operational Flows on member of given index is equal to ${flow_count}.
    ${sw}    ${reported_flow}    ${found_flow}=    ScaleClient.Flow Stats Collected    controller=${controller_ip}
    Should_Be_Equal_As_Numbers    ${flow_count}    ${found_flow}

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

Workflow Setup
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    3x    1s    KarafKeywords.Issue Command On Karaf Console    log:set ERROR

Workflow Teardown
    [Documentation]    Cleanup when workflow is interrupt
    Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    Clean Mininet System
    RequestsLibrary.Delete All Sessions
