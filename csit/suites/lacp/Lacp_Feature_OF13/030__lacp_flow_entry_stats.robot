*** Settings ***
Documentation     Test suite to verify if the PDU count for the LACP flow entry is getting updated
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

*** Test Cases ***
Verify Switch S1 LACP flow entry packet hit doesn't display zero value
    [Documentation]    Verify the LACP flow entry packet hit stats doesn't display zero value on the Switch S1
    ${result}=    Run Command On Remote System    ${MININET}    sudo ovs-ofctl dump-flows s1 -O OpenFlow13
    Comment    ${result}    Read Until    mininet>
    Should Not Contain    ${result}    n_packets=0
    Should Not Contain    ${result}    n_bytes=0

Verify Switch S1 Port stats doesn't display zero value
    [Documentation]    Verify the port stats for the Switch S1 doesn't display value with zero
    ${result}=    Run Command On Remote System    ${MININET}    sudo ovs-ofctl dump-ports s1 -O OpenFlow13   ${MININET_USER}    #
    Comment    ${result}    Read Until    mininet>
    ${port1}=    Get Lines Containing String    ${result}    1:
    Should Not Contain    ${port1}    rx pkts=0
    Should Not Contain    ${port1}    bytes=0
    ${port2}=    Get Lines Containing String    ${result}    2:
    Should Not Contain    ${port2}    rx pkts=0
    Should Not Contain    ${port2}    bytes=0
    ${port3}=    Get Lines Containing String    ${result}    3:
    Should Not Contain    ${port3}    rx pkts=0
    Should Not Contain    ${port3}    bytes=0
    ${port4}=    Get Lines Containing String    ${result}    4:
    Should Not Contain    ${port4}    rx pkts=0
    Should Not Contain    ${port4}    bytes=0

*** Keywords ***
Verify LACP RESTAPI Response Code for node
    [Documentation]    Will check for the response code of the REST query
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${node1}

Verify LACP RESTAPI Aggregator and Tag Contents
    [Arguments]    ${resp.content}    ${content-lookup}
    [Documentation]    Will check for the LACP Specific tags or Aggregator ID for node
    Should Contain    ${resp.content}    ${content-lookup}

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
