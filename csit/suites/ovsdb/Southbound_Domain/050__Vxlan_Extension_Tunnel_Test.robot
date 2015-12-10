*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Vxlan Extension Tunnel Test Suite Setup
Suite Teardown    Vxlan Extension Tunnel Test Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Force Tags        Southbound
Library           OperatingSystem
Library           String
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
@{node_list1}     ovsdb://${MININET1}:${OVSDB_PORT}    ${MININET1}    ${OVSDB_PORT}    ovsdb://${MININET}:${OVSDB_PORT}    ${MININET}    ${OVSDB_PORT}
${start1}         sudo mn --controller=remote,ip=${CONTROLLER} --switch=ovsk,protocols=OpenFlow13 --custom ovsdb.py --topo host,1
${start2}         sudo mn --controller=remote,ip=${CONTROLLER} --switch=ovsk,protocols=OpenFlow13 --custom ovsdb.py --topo host,2

*** Test Cases ***
Make the OVS instance to listen for connection
    Run Command On Remote System    ${MININET1}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${MININET1}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}

Connect controller to OVSDB Node1 and OVSDB Node2
    [Documentation]    Initiate the connection to OVSDB node from controller
    Connect To Ovsdb Node    ${MININET1}
    Connect To Ovsdb Node    ${MININET}

Get Operational Topology from OVSDB Node1 and OVSDB Node2
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list1}

Start the Mininet and create custom topology
    [Documentation]    This will start mininet with custom topology on both the Virtual Machines
    ${conn_id1}    Start Mininet    ${MININET1}    ${start1}    ${OVSDB_CONFIG_DIR}/ovsdb.py
    Set Global Variable    ${conn_id1}
    ${conn_id2}    Start Mininet    ${MININET}    ${start2}    ${OVSDB_CONFIG_DIR}/ovsdb.py
    Set Global Variable    ${conn_id2}

Get Operational Topology with custom topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to make sure the mininet created custom topology
    @{list}    Create List    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add the bridge s1 in the config datastore of OVSDB Node1
    [Documentation]    This request will add already operational bridge to the config data store of the OVSDB node.
    Add Bridge To Ovsdb Node    ${MININET1}    s1    0000000000000001

Add the bridge s2 in the config datastore of OVSDB Node2
    [Documentation]    This request will add already operational bridge to the config data store of the OVSDB node.
    Add Bridge To Ovsdb Node    ${MININET}    s2    0000000000000002

Get Config Topology with s1 and s2 Bridges
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the config data store
    @{list}    Create List    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${CONFIG_TOPO_API}    ${list}

Create Vxlan Port and attach to s1 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s1 of OVSDB node 1
    Add Vxlan To Bridge    ${MININET}    s2    vxlanport    ${MININET1}    create_port_key.json

Create Vxlan Port and attach to s2 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s2 of OVSDB node 2
    Add Vxlan To Bridge    ${MININET1}    s1    vxlanport    ${MININET}    create_port_key.json

Get Operational Topology with vxlan tunnel
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify that the vxlan tunnel is created
    @{list}    Create List    vxlanport    ${MININET1}    ${MININET}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Disconnect controller connection from the connected OVSDBs nodes
    [Documentation]    This request will disconnect the controller from the connected OVSDB node for clean startup for next suite.
    Disconnect From Ovsdb Node    ${MININET}
    Disconnect From Ovsdb Node    ${MININET1}

Verify that the operational topology is clean
    [Documentation]    This request will verify the operational toplogy after the mininet is cleaned.
    @{list}    Create List    ${MININET}    ${MININET1}    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

*** Keywords ***
Vxlan Extension Tunnel Test Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Vxlan Extension Tunnel Test Suite Teardown
    [Documentation]  Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${MININET}
    Clean OVSDB Test Environment    ${MININET1}
    Delete All Sessions