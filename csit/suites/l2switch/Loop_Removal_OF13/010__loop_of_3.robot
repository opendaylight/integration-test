*** Settings ***
Documentation     Test suite for Ring/Loop topology of size 3
Suite Setup       Start Suite
Suite Teardown    Utils.Stop Suite
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${FORWARD}        "stp-status-aware-node-connector:status":"forwarding"
${DISCARD}        "stp-status-aware-node-connector:status":"discarding"

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

Check Ports
    [Documentation]    Check all ports are present
    @{list}    Create List    openflow:1:1    openflow:1:2    openflow:1:3    openflow:2:1    openflow:2:2
    ...    openflow:2:3    openflow:3:1    openflow:3:2    openflow:3:3
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}    ${list}

Check Ports STP status
    [Documentation]    Check the stp status of the ports (forwarding/discarding)
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    ${FORWARD}    4
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    ${DISCARD}    2

Ping Test
    [Documentation]    Ping h1 to h2, verify no packet loss or duplicates
    # This sleep is needed because if the ping in the below WUKS is launched before the STP effectively removes the link,
    # it produces a packet storm in mininet that makes the test unresponsive.
    Sleep    1
    Wait Until Keyword Succeeds    10s    2s    Ping Works Good

Link Down
    [Documentation]    Take link s1-s2 down and verify ping works
    [Tags]    exclude
    Write    link s1 s2 down
    Read Until    mininet>
    @{list}    Create List    ${DISCARD}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_NODES_API}    ${list}
    Wait Until Keyword Succeeds    10s    2s    Ping Works Good

Link Up
    [Documentation]    Take link s1-s2 up and verify ping works
    [Tags]    exclude
    Write    link s1 s2 up
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    ${FORWARD}    4
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    ${DISCARD}    2
    Wait Until Keyword Succeeds    10s    2s    Ping Works Good

Remove Port
    [Documentation]    Remove port s1-eth2 and verify ping works
    Write    sh ovs-vsctl del-port s1 s1-eth2
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    2s    Ping Works Good

Add Port
    [Documentation]    Add port s1-eth2 and verify ping works
    Write    sh ovs-vsctl add-port s1 s1-eth2 -- set interface s1-eth2 ofport=2
    Read Until    mininet>
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    ${FORWARD}    4
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    ${DISCARD}    2
    Wait Until Keyword Succeeds    10s    2s    Ping Works Good

*** Keywords ***
Start Suite
    [Documentation]    Open controller session & mininet connection and start mininet custom topo
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    ${start}=    Set Variable    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --custom customtopo.py --topo ring --switch ovsk,protocols=OpenFlow13
    ${mininet_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/${SSH_KEY}    any
    Put File    ${CURDIR}/../topologies/customtopo.py
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start}
    Read Until    mininet>

Ping Works Good
    Write    h1 ping -w 1 h2
    ${result}    Read Until    mininet>
    Should Contain    ${result}    received, 0% packet loss
    Should Not Contain    ${result}    duplicates
