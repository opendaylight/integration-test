*** Settings ***
Documentation     Test suite for LACP Link Resiliency
Suite Setup       LACP Inventory Suite Setup
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           String
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${node1}          openflow:1
${agg-id1}        1
${agg-id2}        2
${agg1-connector-id1}    1
${agg1-connector-id2}    2
${agg2-connector-id1}    3
${agg2-connector-id2}    4

*** Test Cases ***
Verify the Group tables data for Switch(S1)
    [Documentation]    Functionality would check the presence of group tables entries on OVS Switch(S1) initially
    Verify Switch S1 Group Table    select    1    2    up
    Verify Switch S1 Group Table    select    3    4    up

Generate port down scenario of one of the LAG interface on the Host H2 side and check functionality
    [Documentation]    Generate the link failure on Host H2 LAG Membership-port and verify functionality
    Set Host interface state    h2-eth1    down

Verify information of lacp-aggregator associated with Host H2 after link down scenario
    [Documentation]    Get lacp-aggregator data for node associated with Host H2
    Wait Until Keyword Succeeds    15s    1s    Verify LACP aggregator data is updated post link down scenario

Verify the Switch(S1) Group tables data after H2 link down scenario
    [Documentation]    Functionality to check if the corresponding group entries are updated on OVS Switch(S1) after port-down scenario on the Host H2
    Verify Switch S1 Group Table    select    3    4    down

Generate port up scenario of the LAG interface on the Host H2 side and check functionality
    [Documentation]    Generate the link up scenario on Host H2 LAG Membership-port and verify functionality
    Set Host interface state    h2-eth1    up

Verify information of lacp-aggregator associated with Host H2 after link up scenario
    [Documentation]    Get lacp-aggregator data for node associated with Host H2
    Wait Until Keyword Succeeds    15s    1s    Verify LACP aggregator data is updated post link up scenario

Verify Switch(S1) Flow and Group tables data after H2 link up scenario
    [Documentation]    Functionality to check if the corresponding group entries are updated on OVS Switch(S1) after port-bringup scenario on the Host H2
    Verify Switch S1 Group Table    select    3    4    up

*** Keywords ***
Verify LACP RESTAPI Response Code for node
    [Documentation]    Will check for the response code of the REST query
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${node1}

Verify LACP RESTAPI Aggregator and Tag Contents
    [Arguments]    ${resp.content}    ${content-lookup}
    [Documentation]    Will check for the LACP Specific tags or Aggregator ID for node
    Should Contain    ${resp.content}    ${content-lookup}

Verify LACP RESTAPI connector associated for aggregator
    [Arguments]    ${resp.content}    ${node}    ${agg-connector-id}
    [Documentation]    Will check for the LACP connector info for each aggregator
    Should Contain    ${resp.content}    ${node}:${agg-connector-id}

Verify LACP aggregator data is updated post link down scenario
    [Documentation]    Functionality will verify the node conenctor data on the lacp-agg api after link down scenario
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/lacp-aggregators/${agg-id2}
    Verify LACP RESTAPI Response Code for node
    Verify LACP RESTAPI connector associated for aggregator    ${resp.content}    ${node1}    ${agg2-connector-id1}
    Should not Contain    ${resp.content}    ${node1}:${agg2-connector-id2}
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    lag-groupid

Verify LACP aggregator data is updated post link up scenario
    [Documentation]    Functionality will verify the node connector data on the lacp-agg api after link up scenario
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}/node/${node1}/lacp-aggregators/${agg-id2}
    Verify LACP RESTAPI Response Code for node
    Verify LACP RESTAPI connector associated for aggregator    ${resp.content}    ${node1}    ${agg2-connector-id1}
    Verify LACP RESTAPI connector associated for aggregator    ${resp.content}    ${node1}    ${agg2-connector-id2}
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    lag-groupid

Verify LACP Tags Are Formed
    [Documentation]    Fundamental Check That LACP is working
    ${resp}    RequestsLibrary.Get    session    ${OPERATIONAL_NODES_API}
    Verify LACP RESTAPI Response Code for node
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    non-lag-groupid
    Verify LACP RESTAPI Aggregator and Tag Contents    ${resp.content}    lacp-aggregators

LACP Inventory Suite Setup
    [Documentation]    If these basic checks fail, there is no need to continue any of the other test cases
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Wait Until Keyword Succeeds    15s    1s    Verify LACP Tags Are Formed

Set Host interface state
    [Arguments]    ${port-id}    ${port-state}
    [Documentation]    Will configure the port state of the Host to either up or down
    Open Connection    ${MININET}    prompt=${DEFAULT_LINUX_PROMPT}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Execute Command    sudo ./m h2
    Execute Command    sudo ifconfig ${port-id} ${port-state}
    Execute Command    sudo ifconfig ${port-id}

Verify Switch S1 Group Table
    [Arguments]    ${group-type}    ${port-id1}    ${port-id2}    ${port-id2-state}
    [Documentation]    Functionality to verify the presence of LACP group entries on the OVS Switch(S1) Group table
    ${group_output}=    Run Command on Remote System    ${MININET}    sudo ovs-ofctl dump-groups s1 -O OpenFlow13   ${MININET_USER}   #
    Log    ${group_output}
    Comment    ${group_output}    Read Until    mininet>
    ${result}=    Get Lines Containing String    ${group_output}    output:${port-id1}
    Should Contain    ${result}    type=${group-type}
    Should Contain    ${result}    output:${port-id1}
    Run Keyword If    "${port-id2-state}" == "up"    Should Contain    ${result}    output:${port-id2}    ELSE    Should not Contain
    ...    ${result}    output:${port-id2}
