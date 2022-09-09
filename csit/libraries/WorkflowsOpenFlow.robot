*** Settings ***
Documentation       Resource for OpenFlow workflows. This library can be used for scalability and longevity tests.

Library             SSHLibrary
Library             DateTime
Library             RequestsLibrary
Library             ScaleClient.py
Library             SwitchClasses/BaseSwitch.py
Resource            Utils.robot
Resource            FlowLib.robot
Resource            CompareStream.robot
Resource            MininetKeywords.robot
Resource            KarafKeywords.robot
Resource            ../variables/Variables.robot
Resource            ../variables/openflowplugin/Variables.robot


*** Variables ***
${log_level}        ERROR
${flow_count}       10000
${swspread}         linear
${tables}           10
${tabspread}        linear
${nrthreads}        1


*** Keywords ***
Workflow Linear Topology
    [Documentation]    Workflow to bring a Linear topology of ${switches} switches, push flows, hold for ${sustain_time} seconds, delete flows and stop topology.
    ...    This KW returns workflow state (PASS/FAIL), error message and topology discover time.
    [Arguments]    ${switches}    ${sustain_time}=0
    # Define required variables
    ${error_message}    Set Variable    Test has completed
    ${topology_discover_time}    Set Variable    ${0}
    ${controller_list}    Create List    ${ODL_SYSTEM_IP}
    ${flow_count}    Convert to Integer    ${flow_count}
    ${flows_ovs_25}    Evaluate    ${flow_count} + ${switches}
    ${flows_before}    Set Variable    ${switches}
    ${flows_after}    Set Variable    ${flows_ovs_25}
    ${flows}    ${notes}    ScaleClient.Generate New Flow Details
    ...    flows=${flow_count}
    ...    switches=${switches}
    ...    swspread=${swspread}
    ...    tables=${tables}
    ...    tabspread=${tabspread}
    # Workflow starts
    Log to console    ${\n}
    Log To Console    Starting mininet linear ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    MininetKeywords.Start Mininet Linear
    ...    ${switches}
    ...    mininet_timeout=${switches*4}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail starting mininet    ${topology_discover_time}
    END
    ${start_time}    DateTime.Get Current Date    result_format=timestamp
    Log To Console    Verify controller is OK
    ${status}    ${result}    Run Keyword And Ignore Error    Utils.Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Controller is dead    ${topology_discover_time}
    END
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Utils.Verify Controller Has No Null Pointer Exceptions
    ...    ${ODL_SYSTEM_IP}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Controller has NPE    ${topology_discover_time}
    END
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Utils.Verify Controller Has No Runtime Exceptions
    ...    ${ODL_SYSTEM_IP}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Controller has RuntimeException
        ...    ${topology_discover_time}
    END
    Log To Console    Checking ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches*2}
    ...    2s
    ...    FlowLib.Check Switches In Inventory
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail checking switch    ${topology_discover_time}
    END
    Log To Console    Add table miss flows
    ${status}    ${result}    Run Keyword And Ignore Error    FlowLib.Add Table Miss Flows    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail adding table Miss flows
        ...    ${topology_discover_time}
    END
    Log To Console    Checking Table Miss Flows
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches}
    ...    2s
    ...    FlowLib.Check Table Miss Flows
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking table miss flows
        ...    ${topology_discover_time}
    END
    Log To Console    Checking Linear Topology
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches}
    ...    2s
    ...    FlowLib.Check Linear Topology
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail checking topology    ${topology_discover_time}
    END
    ${end_time}    DateTime.Get Current Date    result_format=timestamp
    ${topology_discover_time}    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    Log To Console    Topology Discovery Time = ${topology_discover_time} seconds
    Log To Console    Adding ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    ScaleClient.Configure Flows
    ...    flow_details=${flows}
    ...    controllers=${controller_list}
    ...    nrthreads=${nrthreads}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail configuring flows    ${topology_discover_time}
    END
    Log To Console    Checking ${flow_count} flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    MininetKeywords.Verify Aggregate Flow From Mininet Session
    ...    ${mininet_conn_id}
    ...    ${flows_after}
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking flows in mininet
        ...    ${topology_discover_time}
    END
    Log To Console    Checking ${flow_count} flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches*4}
    ...    2s
    ...    FlowLib.Check Flows Operational Datastore
    ...    ${flows_after}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking flows in operational DS
        ...    ${topology_discover_time}
    END
    Log To Console    Sleep for ${sustain_time} seconds
    Sleep    ${sustain_time}
    Log To Console    Deleting ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    ScaleClient.Deconfigure Flows
    ...    flow_details=${flows}
    ...    controllers=${controller_list}
    ...    nrthreads=${nrthreads}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail deconfiguring flows
        ...    ${topology_discover_time}
    END
    Log To Console    Checking no flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    MininetKeywords.Verify Aggregate Flow From Mininet Session
    ...    ${mininet_conn_id}
    ...    ${flows_before}
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no flows in mininet
        ...    ${topology_discover_time}
    END
    Log To Console    Checking no flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches*4}
    ...    2s
    ...    FlowLib.Check Flows Operational Datastore
    ...    ${flows_before}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no flows in operational DS
        ...    ${topology_discover_time}
    END
    Log To Console    Stopping Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Stop Mininet And Exit
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail stopping mininet    ${topology_discover_time}
    END
    Log To Console    Checking No Switches
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    FlowLib.Check No Switches In Inventory
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no switch
        ...    ${topology_discover_time}
    END
    Log To Console    Checking No Topology
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    FlowLib.Check No Switches In Topology
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no topology
        ...    ${topology_discover_time}
    END
    RETURN    PASS    ${error_message}    ${topology_discover_time}

Workflow Full Mesh Topology
    [Documentation]    Workflow to bring a Full mesh topology of ${switches} switches, push some flows, delete flows and stop topology.
    ...    This KW returns workflow state (PASS/FAIL), error message and topology discover time.
    [Arguments]    ${switches}    ${sustain_time}=0
    # Define required variables
    ${error_message}    Set Variable    Test has completed
    ${topology_discover_time}    Set Variable    ${0}
    ${mininet_timeout}    Evaluate    ${switches} * ${switches}
    ${links}    Evaluate    ${switches} * ${switches-1}
    ${controller_list}    Create List    ${ODL_SYSTEM_IP}
    ${flow_count}    Convert to Integer    ${flow_count}
    ${flows_ovs_25}    Evaluate    ${flow_count} + ${switches}
    ${flows_before}    Set Variable    ${switches}
    ${flows_after}    Set Variable    ${flows_ovs_25}
    ${flows}    ${notes}    ScaleClient.Generate New Flow Details
    ...    flows=${flow_count}
    ...    switches=${switches}
    ...    swspread=${swspread}
    ...    tables=${tables}
    ...    tabspread=${tabspread}
    # Workflow starts
    Log to console    ${\n}
    Log To Console    Start a mininet full mesh ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    MininetKeywords.Start Mininet Full Mesh
    ...    ${switches}
    ...    mininet_timeout=${mininet_timeout}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail starting mininet    ${topology_discover_time}
    END
    ${start_time}    DateTime.Get Current Date    result_format=timestamp
    Log To Console    Verify controller is OK
    ${status}    ${result}    Run Keyword And Ignore Error    Utils.Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Controller is dead    ${topology_discover_time}
    END
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Utils.Verify Controller Has No Null Pointer Exceptions
    ...    ${ODL_SYSTEM_IP}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Controller has NPE    ${topology_discover_time}
    END
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Utils.Verify Controller Has No Runtime Exceptions
    ...    ${ODL_SYSTEM_IP}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Controller has RuntimeException
        ...    ${topology_discover_time}
    END
    Log To Console    Checking ${switches} switches
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    FlowLib.Check Switches In Inventory
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail checking switch    ${topology_discover_time}
    END
    Log To Console    Check number of links in inventory is ${links}
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    FlowLib.Check Number Of Links
    ...    ${links}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail checking topology    ${topology_discover_time}
    END
    ${end_time}    DateTime.Get Current Date    result_format=timestamp
    ${topology_discover_time}    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    Log To Console    Topology Discovery Time = ${topology_discover_time} seconds
    Log To Console    Adding ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    ScaleClient.Configure Flows
    ...    flow_details=${flows}
    ...    controllers=${controller_list}
    ...    nrthreads=${nrthreads}
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail configuring flows    ${topology_discover_time}
    END
    Log To Console    Checking ${flow_count} flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    MininetKeywords.Verify Aggregate Flow From Mininet Session
    ...    ${mininet_conn_id}
    ...    ${flows_after}
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking flows in mininet
        ...    ${topology_discover_time}
    END
    Log To Console    Checking ${flow_count} flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches*4}
    ...    2s
    ...    FlowLib.Check Flows Operational Datastore
    ...    ${flows_after}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking flows in operational DS
        ...    ${topology_discover_time}
    END
    Log To Console    Sleep for ${sustain_time} seconds
    Sleep    ${sustain_time}
    Log To Console    Deleting ${flow_count} flows
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    ScaleClient.Deconfigure Flows
    ...    flow_details=${flows}
    ...    controllers=${controller_list}
    ...    nrthreads=${nrthreads}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail deconfiguring flows
        ...    ${topology_discover_time}
    END
    Log To Console    Checking no flows in Mininet
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    MininetKeywords.Verify Aggregate Flow From Mininet Session
    ...    ${mininet_conn_id}
    ...    ${flows_before}
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no flows in mininet
        ...    ${topology_discover_time}
    END
    Log To Console    Checking no flows in Operational DS
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    ${switches*4}
    ...    2s
    ...    FlowLib.Check Flows Operational Datastore
    ...    ${flows_before}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no flows in operational DS
        ...    ${topology_discover_time}
    END
    Log To Console    Stopping Mininet
    ${status}    ${result}    Run Keyword And Ignore Error    MininetKeywords.Stop Mininet And Exit
    IF    '${status}' == 'FAIL'
        RETURN    ${status}    Fail stopping mininet    ${topology_discover_time}
    END
    Log To Console    Checking No Switches
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    FlowLib.Check No Switches In Inventory
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no switch
        ...    ${topology_discover_time}
    END
    Log To Console    Checking No Topology
    ${status}    ${result}    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    FlowLib.Check No Switches In Topology
    ...    ${switches}
    IF    '${status}' == 'FAIL'
        RETURN...    '${status}' == 'FAIL'
        ...    ${status}
        ...    Fail checking no topology
        ...    ${topology_discover_time}
    END
    RETURN    PASS    ${error_message}    ${topology_discover_time}

Workflow Setup
    RequestsLibrary.Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS_XML}
    Wait Until Keyword Succeeds    3x    1s    KarafKeywords.Issue Command On Karaf Console    log:set ${log_level}

Workflow Teardown
    [Documentation]    Cleanup when workflow is interrupt
    Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${RFC8040_NODES_API}
    Utils.Clean Mininet System
    RequestsLibrary.Delete All Sessions
