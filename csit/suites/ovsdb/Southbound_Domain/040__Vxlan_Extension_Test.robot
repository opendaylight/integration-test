*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Vxlan Extension Test Suite Setup
Suite Teardown    Vxlan Extension Test Suite Teardown
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
@{node_list1}     ovsdb://${ODL_TOOLS_SYSTEM_1_IP}:${OVSDB_PORT}    ${ODL_TOOLS_SYSTEM_1_IP}    ${OVSDB_PORT}    ovsdb://${ODL_TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${ODL_TOOLS_SYSTEM_IP}    ${OVSDB_PORT}
${start1}         sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --switch=ovsk,protocols=OpenFlow13 --custom ovsdb.py --topo host,1
${start2}         sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --switch=ovsk,protocols=OpenFlow13 --custom ovsdb.py --topo host,2

*** Test Cases ***
Make the OVS instance to listen for connection
    Run Command On Remote System    ${ODL_TOOLS_SYSTEM_1_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${ODL_TOOLS_SYSTEM_1_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    Run Command On Remote System    ${ODL_TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${ODL_TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}

Connect controller to OVSDB Node1
    [Documentation]    Initiate the connection to OVSDB node from controller
    Connect To Ovsdb Node    ${ODL_TOOLS_SYSTEM_1_IP}

Connect controller to OVSDB Node2
    [Documentation]    Initiate the connection to OVSDB node from controller
    Connect To Ovsdb Node    ${ODL_TOOLS_SYSTEM_IP}

Get Operational Topology from OVSDB Node1 and OVSDB Node2
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list1}

Start the Mininet and create custom topology
    [Documentation]    This will start mininet with custom topology on both the Virtual Machines
    ${conn_id1}    Start Mininet    ${ODL_TOOLS_SYSTEM_1_IP}    ${start1}    ${OVSDB_CONFIG_DIR}/ovsdb.py
    Set Global Variable    ${conn_id1}
    ${conn_id2}    Start Mininet    ${ODL_TOOLS_SYSTEM_IP}    ${start2}    ${OVSDB_CONFIG_DIR}/ovsdb.py
    Set Global Variable    ${conn_id2}

Get Operational Topology with custom topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to make sure the mininet created custom topology
    @{list}    Create List    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add the bridge s1 in the config datastore of OVSDB Node1
    [Documentation]    This request will add already operational bridge to the config data store of the OVSDB node.
    Add Bridge To Ovsdb Node    ${ODL_TOOLS_SYSTEM_1_IP}    s1    0000000000000001

Add the bridge s2 in the config datastore of OVSDB Node2
    [Documentation]    This request will add already operational bridge to the config data store of the OVSDB node.
    Add Bridge To Ovsdb Node    ${ODL_TOOLS_SYSTEM_IP}    s2    0000000000000002

Get Config Topology with s1 and s2 Bridges
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the config data store
    @{list}    Create List    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${CONFIG_TOPO_API}    ${list}

Create Vxlan Port and attach to s1 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s1 of OVSDB node 1
    Add Vxlan To Bridge    ${ODL_TOOLS_SYSTEM_IP}    s2    vxlanport    ${ODL_TOOLS_SYSTEM_1_IP}

Create Vxlan Port and attach to s2 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s2 of OVSDB node 2
    Add Vxlan To Bridge    ${ODL_TOOLS_SYSTEM_1_IP}    s1    vxlanport    ${ODL_TOOLS_SYSTEM_IP}

Get Operational Topology with vxlan tunnel
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify that the vxlan tunnel is created
    @{list}    Create List    vxlanport    ${ODL_TOOLS_SYSTEM_1_IP}    ${ODL_TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Disconnect controller connection from the connected OVSDBs nodes
    [Documentation]    This request will disconnect the controller from the connected OVSDB node for clean startup for next suite.
    [Tags]    Southbound
    Disconnect From Ovsdb Node    ${ODL_TOOLS_SYSTEM_IP}
    Disconnect From Ovsdb Node    ${ODL_TOOLS_SYSTEM_1_IP}

Verify that the operational topology is clean
    [Documentation]    This request will verify the operational toplogy after the mininet is cleaned.
    [Tags]    Southbound
    @{list}    Create List    ${ODL_TOOLS_SYSTEM_IP}    ${ODL_TOOLS_SYSTEM_1_IP}    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Check For Bug 4756
    [Documentation]  bug 4756 has been seen in the OVSDB Southbound suites.  This test case should be the last test
    ...    case executed.
    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    SimpleShardDataTreeCohort.*Unexpected failure in validation phase
    [Teardown]    Report_Failure_Due_To_Bug    4756

*** Keywords ***
Vxlan Extension Test Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Vxlan Extension Test Suite Teardown
    [Documentation]  Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${ODL_TOOLS_SYSTEM_IP}
    Clean OVSDB Test Environment    ${ODL_TOOLS_SYSTEM_1_IP}
    Delete All Sessions
