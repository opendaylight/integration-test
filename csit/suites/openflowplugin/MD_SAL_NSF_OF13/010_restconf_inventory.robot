*** Settings ***
Documentation     Test suite for RESTCONF inventory
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${VENDOR}         Nicira, Inc.
${HARDWARE}       Open vSwitch
@{node_list}      openflow:1    openflow:2    openflow:3
${SW_IPADDRESS}    "flow-node-inventory:ip-address":"${TOOLS_SYSTEM_IP}"
${SW_VENDOR}      "flow-node-inventory:manufacturer":"${VENDOR}"
${SW_HARDWARE}    "flow-node-inventory:hardware":"${HARDWARE}"
@{SW_CAPABILITIES}    "flow-node-inventory:flow-feature-capability-flow-stats"    "flow-node-inventory:flow-feature-capability-table-stats"    "flow-node-inventory:flow-feature-capability-port-stats"    "flow-node-inventory:flow-feature-capability-queue-stats"

*** Test Cases ***
Get list of nodes
    [Documentation]    Get the inventory
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}    ${node_list}

Check No Link Down
    [Documentation]    Check there is no link down. We have 8 ports in total: s1=2, s2=3, s3=3.
    Wait Until Keyword Succeeds    10s    2s    Check For Specific Number Of Elements At URI    ${OPERATIONAL_NODES_API}    "link-down":false    8

Get node 1 inventory
    [Documentation]    Get the inventory for a node
    ${list}    Create List    @{SW_CAPABILITIES}    ${SW_VENDOR}    ${SW_IPADDRESS}    ${SW_HARDWARE}    openflow:1:1
    ...    openflow:1:2
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1    ${list}

Get node 2 inventory
    [Documentation]    Get the inventory for a node
    ${list}    Create List    @{SW_CAPABILITIES}    ${SW_VENDOR}    ${SW_IPADDRESS}    ${SW_HARDWARE}    openflow:2:1
    ...    openflow:2:2    openflow:2:3
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:2    ${list}

Get node 3 inventory
    [Documentation]    Get the inventory for a node
    ${list}    Create List    @{SW_CAPABILITIES}    ${SW_VENDOR}    ${SW_IPADDRESS}    ${SW_HARDWARE}    openflow:3:1
    ...    openflow:3:2    openflow:3:3
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:3    ${list}

Link Down
    [Documentation]    Take link s1-s2 down
    Write    link s1 s2 down
    Read Until    mininet>
    @{list}    Create List    "link-down":true
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1    ${list}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:2/node-connector/openflow:2:3    ${list}

Link Up
    [Documentation]    Take link s1-s2 up
    Write    link s1 s2 up
    Read Until    mininet>
    @{list}    Create List    "link-down":false
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1    ${list}
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}/node/openflow:2/node-connector/openflow:2:3    ${list}

Remove Port
    [Documentation]    Remove port s2-eth1
    [Tags]    exclude
    Write    sh ovs-vsctl del-port s2 s2-eth1
    Read Until    mininet>
    @{list}    Create List    openflow:2:1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${OPERATIONAL_NODES_API}    ${list}

Add Port
    [Documentation]    Add port s2-eth1, new id 4
    [Tags]    exclude
    Write    sh ovs-vsctl add-port s2 s2-eth1
    Read Until    mininet>
    @{list}    Create List    openflow:2:4
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${OPERATIONAL_NODES_API}    ${list}
