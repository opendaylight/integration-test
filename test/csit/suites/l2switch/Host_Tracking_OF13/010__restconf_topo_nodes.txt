*** Settings ***
Documentation     Test suite for Address in RESTCONF topology
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_TOPO}      /restconf/operational/network-topology:network-topology
${MAC_1}          00:00:00:00:00:01
${MAC_2}          00:00:00:00:00:02
${MAC_3}          00:00:00:00:00:03
${IP_1}           10.0.0.1
${IP_2}           10.0.0.2
${IP_3}           10.0.0.3

*** Test Cases ***
Get list of host from network topology
    [Documentation]    Get the network topology, should not contain any host address
    ${resp}    Get    session    ${REST_TOPO}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    openflow:1
    Should Contain    ${resp.content}    openflow:2
    Should Contain    ${resp.content}    openflow:3
    Should Contain X Times    ${resp.content}    link-id    4
    Should Not Contain    ${resp.content}    ${MAC_1}
    Should Not Contain    ${resp.content}    ${MAC_2}
    Should Not Contain    ${resp.content}    ${MAC_3}

Ping All
    [Documentation]    Pingall, verify no packet loss
    Write    pingall
    ${result}    Read Until    mininet>
    Should Contain    ${result}    0% dropped
    Should Not Contain    ${result}    X
    Sleep    3

Host Tracker
    [Documentation]    Get the network topology,
    ${resp}    Get    session    ${REST_TOPO}/topology/flow:1
    Should Be Equal As Strings    ${resp.status_code}    200
    Log    ${resp.content}
    Should Contain X Times    ${resp.content}    "node-id":"host:${MAC_1}"    1
    Should Contain X Times    ${resp.content}    "node-id":"host:${MAC_2}"    1
    Should Contain X Times    ${resp.content}    "node-id":"host:${MAC_3}"    1

Check host are deleted
    [Documentation]    Closing mininet this will remove the switch and the host should also be deleted
    Log    closing mininet
    write    exit
    Read Until    >
    sleep    5
    ${resp}    Get    session    ${REST_TOPO}/topology/flow:1
    Should Be Equal as Strings    ${resp.status_code}    200
    Should not Contain    ${resp.content}    "node-id":"host
    Log    ${resp.content}
