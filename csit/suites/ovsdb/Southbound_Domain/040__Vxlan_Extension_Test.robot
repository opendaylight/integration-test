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
${OVSDB_PORT}     6640
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

Connect controller to OVSDB Node1
    [Documentation]    Initiate the connection to OVSDB node from controller
    Connect To Ovsdb Node    ${MININET1}

Connect controller to OVSDB Node2
    [Documentation]    Initiate the connection to OVSDB node from controller
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
    Add Vxlan To Bridge    ${MININET}    s2    vxlanport    ${MININET1}

Create Vxlan Port and attach to s2 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s2 of OVSDB node 2
    Add Vxlan To Bridge    ${MININET1}    s1    vxlanport    ${MININET}

Get Operational Topology with vxlan tunnel
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify that the vxlan tunnel is created
    @{list}    Create List    vxlanport    ${MININET1}    ${MININET}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add Flow1 Rule for s1 and verify
    [Documentation]    This request will add flow to the switch and after that verify through the config datastore flow
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/add_flow_rule1.xml
    Set Suite Variable    ${body}
    Log    URL is ${CONFIG_NODES_API}/node/openflow:1/table/0/flow/1
    ${resp}    RequestsLibrary.Put Request   session    ${CONFIG_NODES_API}/node/openflow:1/table/0/flow/1    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/openflow:1/table/0/flow/1    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Add Flow2 Rule for s1 and verify
    [Documentation]    This request will add flow to the switch and after that verify through the config datastore flow
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/add_flow_rule2.xml
    Log    URL is ${CONFIG_NODES_API}/node/openflow:1/table/0/flow/2
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_NODES_API}/node/openflow:1/table/0/flow/2    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/openflow:1/table/0/flow/2    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Get Operational Topology to verify the flows successfully installed in the bridge s1
    [Documentation]    This request will fetch the operational topology and verify that the flows has been installed in the switch
    @{list}    Create List    openflow:1
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add Flow1 Rule for s2 and verify
    [Documentation]    This request will add flow to the switch and after that verify through the config datastore flow
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/add_flow_rule1.xml
    Log    URL is ${CONFIG_NODES_API}/node/openflow:2/table/0/flow/1
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_NODES_API}/node/openflow:2/table/0/flow/1    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/openflow:2/table/0/flow/1    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Add Flow2 Rule for s2 and verify
    [Documentation]    This request will add flow to the switch and after that verify through the config datastore flow
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/add_flow_rule2.xml
    Log    URL is ${CONFIG_NODES_API}/node/openflow:2/table/0/flow/2
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_NODES_API}/node/openflow:2/table/0/flow/2    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_NODES_API}/node/openflow:2/table/0/flow/2    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Get Operational Topology to verify the flows successfully installed in the bridge s2
    [Documentation]    This request will fetch the operational topology and verify that the flows has been installed in the switch
    @{list}    Create List    openflow:2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Ping host2 to IP of host1
    [Documentation]    This step will verify the functionality of the vxlan tunnel between two OVSDB nodes. Ping h2(10.0.0.2)---> 10.0.0.1 , verify no packet loss
    Switch Connection    ${conn_id2}
    SSHLibrary.Write    h2 ping -w 1 10.0.0.1
    ${result}    Read Until    mininet>
    Should Contain    ${result}    1 received, 0% packet loss

Disconnect controller connection from the connected OVSDBs nodes
    [Documentation]    This request will disconnect the controller from the connected OVSDB node for clean startup for next suite.
    [Tags]    Southbound
    Disconnect From Ovsdb Node    ${MININET}
    Disconnect From Ovsdb Node    ${MININET1}

Verify that the operational topology is clean
    [Documentation]    This request will verify the operational toplogy after the mininet is cleaned.
    [Tags]    Southbound
    @{list}    Create List    ${MININET}    ${MININET1}    s1    s2
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

*** Keywords ***
Vxlan Extension Test Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Vxlan Extension Test Suite Teardown
    [Documentation]  Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${MININET}
    Clean OVSDB Test Environment    ${MININET1}
    Delete All Sessions
