*** Settings ***
Documentation     Test suite for Address in RESTCONF topology
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${MAC_1}          00:00:00:00:00:01
${MAC_2}          00:00:00:00:00:02
${MAC_3}          00:00:00:00:00:03
${IP_1}           10.0.0.1
${IP_2}           10.0.0.2
${IP_3}           10.0.0.3

*** Test Cases ***
Check Stats for node 1
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow:1

Check Stats for node 2
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow:2

Check Stats for node 3
    [Documentation]    Get the stats for a node
    Wait Until Keyword Succeeds    10s    2s    Check Nodes Stats    openflow:3

Check Switch Links
    [Documentation]    Get the topology and check links
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    link-id    4

Check No Host Is Present
    [Documentation]    Get the network topology, should not contain any host address
    @{list}    Create List    ${MAC_1}    ${MAC_2}    ${MAC_3}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    link-id    4

Ping All
    [Documentation]    Pingall, verify no packet loss
    Write    pingall
    ${result}    Read Until    mininet>
    Should Contain    ${result}    Results: 0% dropped

Check Host Links
    [Documentation]    Get the topology and check links
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    link-id    10

Host Tracker host1
    [Documentation]    Get the network topology, should contain host1 one time
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    "node-id":"host:${MAC_1}"    1

Host Tracker host2
    [Documentation]    Get the network topology, should contain host 2 one time
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    "node-id":"host:${MAC_2}"    1

Host Tracker host3
    [Documentation]    Get the network topology, should contain hos 3 one time
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    "node-id":"host:${MAC_3}"    1

Link Down
    [Documentation]    Take link s1-h1 down and verify host1 goes away
    Write    link s1 h1 down
    Read Until    mininet>
    @{list}    Create List    "link-down":true
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1    ${list}
    @{list}    Create List    ${MAC_1}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Link Up
    [Documentation]    Take link s1-h1 up and verify host1 comes back
    Write    link s1 h1 up
    Read Until    mininet>
    @{list}    Create List    "link-down":false
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1    ${list}
    Write    pingall
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    "node-id":"host:${MAC_1}"    1

Remove Port
    [Documentation]    Remove port s1-eth1 and verify host1 goes away
    Write    sh ovs-vsctl del-port s1 s1-eth1
    Read Until    mininet>
    @{list}    Create List    ${MAC_1}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add Port
    [Documentation]    Add port s2-eth1 and verify host1 comes back
    Write    sh ovs-vsctl add-port s1 s1-eth1 -- set interface s1-eth1 ofport=1
    Read Until    mininet>
    @{list}    Create List    "link-down":false
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1    ${list}
    Write    pingall
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_TOPO_API}    "node-id":"host:${MAC_1}"    1
