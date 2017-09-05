*** Settings ***
Documentation     Resource for L2switch workflows. TODO: Refactor KWs once this test works in public.
Library           RequestsLibrary
Resource          Utils.robot
Resource          FlowLib.robot
Resource          MininetKeywords.robot
Resource          ../variables/Variables.robot

*** Variables ***
${log_level}      ERROR

*** Keywords ***
Workflow Single Switch Multiple Hosts
    [Arguments]    ${hosts}    ${sustain_time}=0
    [Documentation]    Workflow to bring a Linear topology of ${switches} switches, push flows, hold for ${sustain_time} seconds, delete flows and stop topology.
    ...    This KW returns workflow state (PASS/FAIL), error message and topology discover time.
    # Define required variables
    ${error_message}=    BuiltIn.Set Variable    Test has completed
    ${host_discover_time}=    BuiltIn.Set Variable    ${0}
    # Workflow starts
    BuiltIn.Log to console    ${\n}
    BuiltIn.Log To Console    Starting mininet with one switch and ${hosts} hosts
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    MininetKeywords.Start Mininet Multiple Hosts    ${hosts}    mininet_timeout=${hosts}
    BuiltIn.Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail starting mininet    ${host_discover_time}
    BuiltIn.Log To Console    Check 1 switch
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${hosts}    2s    FlowLib.Check Switches In Inventory
    ...    ${1}
    BuiltIn.Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking switch    ${host_discover_time}
    BuiltIn.Log To Console    Ping all hosts
    @{host_list}=    MininetKeywords.Get Mininet Hosts
    ${start_time}=    DateTime.Get Current Date    result_format=timestamp
    ${status}=    MininetKeywords.Ping All Hosts    @{host_list}
    BuiltIn.Return From Keyword If    ${status} != ${0}    ${status}    Ping test fails    ${host_discover_time}
    BuiltIn.Log To Console    Verify controller is OK
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    Utils.Verify Controller Is Not Dead    ${ODL_SYSTEM_IP}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Controller is dead    ${host_discover_time}
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    Utils.Verify Controller Has No Null Pointer Exceptions    ${ODL_SYSTEM_IP}
    Return From Keyword If    '${status}' == 'FAIL'    ${status}    Controller has NPE    ${host_discover_time}
    Log To Console    Check number of hosts in topology is ${hosts}
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    Wait Until Keyword Succeeds    ${hosts}    2s    FlowLib.Check Number Of Hosts
    ...    ${hosts}
    BuiltIn.Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking hosts    ${host_discover_time}
    ${end_time}=    DateTime.Get Current Date    result_format=timestamp
    ${host_discover_time}=    DateTime.Subtract Date From Date    ${end_time}    ${start_time}
    BuiltIn.Log To Console    Host Discovery Time = ${host_discover_time} seconds
    BuiltIn.Log To Console    Sleep for ${sustain_time} seconds
    BuiltIn.Sleep    ${sustain_time}
    BuiltIn.Log To Console    Stopping Mininet
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    MininetKeywords.Stop Mininet And Exit
    BuiltIn.Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail stopping mininet    ${host_discover_time}
    BuiltIn.Log To Console    Checking No Switches
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5s    1s    FlowLib.Check No Switches In Inventory
    ...    ${1}
    BuiltIn.Return From Keyword If    '${status}' == 'FAIL'    ${status}    Fail checking no switch    ${host_discover_time}
    BuiltIn.Log To Console    Checking no hosts are present in operational database
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    Wait Until Keyword Succeeds    5s    1s    FlowLib.Check No Hosts
    BuiltIn.Return From Keyword If    '${status}' == 'FAIL'    ${status}    Hosts are present    ${host_discover_time}
    ${max-hosts}    BuiltIn.Convert To String    ${hosts}
    [Return]    PASS    ${error_message}    ${host_discover_time}

Workflow Setup
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Wait Until Keyword Succeeds    3x    1s    KarafKeywords.Issue Command On Karaf Console    log:set ${log_level}

Workflow Teardown
    [Documentation]    Cleanup when workflow is interrupt
    Utils.Clean Mininet System
    RequestsLibrary.Delete All Sessions
