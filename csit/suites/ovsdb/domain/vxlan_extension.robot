*** Settings ***
Documentation     Test suite for Connection Manager
Suite Setup       Ovsdb Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           Collections
Library           SSHLibrary
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/Variables.robot
Resource          Ovsdb.robot

*** Variables ***
@{NODE_LIST}     ${OVSDB_PORT}    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_PORT}    ovsdb://${TOOLS_SYSTEM_2_IP}:${OVSDB_PORT}    ${TOOLS_SYSTEM_2_IP}
${MN_OPTS_S1}         --switch=ovsk,protocols=OpenFlow13 --custom ovsdb.py --topo host,1
${MN_OPTS_S2}         --switch=ovsk,protocols=OpenFlow13 --custom ovsdb.py --topo host,2

*** Test Cases ***
Make the OVS instance to listen for connection
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl del-manager
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}

Connect controller to OVSDB Node1
    [Documentation]    Initiate the connection to OVSDB node from controller
    OVSDB.Connect To Ovsdb Node    ${TOOLS_SYSTEM_IP}

Connect controller to OVSDB Node2
    [Documentation]    Initiate the connection to OVSDB node from controller
    OVSDB.Connect To Ovsdb Node    ${TOOLS_SYSTEM_2_IP}

Get Operational Topology from OVSDB Node1 and OVSDB Node2
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${NODE_LIST}

Start the Mininet and create custom topology
    [Documentation]    This will start mininet with custom topology on both the Virtual Machines
    ${conn_id1} =    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${MN_OPTS_S1}    ${OVSDB_CONFIG_DIR}/ovsdb.py
    ${conn_id2} =    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_2_IP}    ${ODL_SYSTEM_IP}    ${MN_OPTS_S2}    ${OVSDB_CONFIG_DIR}/ovsdb.py

Get Operational Topology with custom topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to make sure the mininet created custom topology
    @{list} =    BuiltIn.Create List    s1    s2
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Add the bridge s1 in the config datastore of OVSDB Node1
    [Documentation]    This request will add already operational bridge to the config data store of the OVSDB node.
    OVSDB.Add Bridge To Ovsdb Node    ${TOOLS_SYSTEM_2_IP}    s1    0000000000000001

Add the bridge s2 in the config datastore of OVSDB Node2
    [Documentation]    This request will add already operational bridge to the config data store of the OVSDB node.
    OVSDB.Add Bridge To Ovsdb Node    ${TOOLS_SYSTEM_IP}    s2    0000000000000002

Get Config Topology with s1 and s2 Bridges
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the config data store
    @{list} =    BuiltIn.Create List    s1    s2
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${CONFIG_TOPO_API}    ${list}

Create Vxlan Port and attach to s1 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s1 of OVSDB node 1
    OVSDB.Add Vxlan To Bridge    ${TOOLS_SYSTEM_IP}    s1    vxlanport    ${TOOLS_SYSTEM_2_IP}

Create Vxlan Port and attach to s2 Bridge
    [Documentation]    This request will create vxlan port/interface for vxlan tunnel and attach it to the specific bridge s2 of OVSDB node 2
    OVSDB.Add Vxlan To Bridge    ${TOOLS_SYSTEM_2_IP}    s2    vxlanport    ${TOOLS_SYSTEM_IP}

Get Operational Topology with vxlan tunnel
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify that the vxlan tunnel is created
    @{list} =    BuiltIn.Create List    vxlanport    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${list}

Delete Bridges from config datastore
    [Documentation]    This request will delete the bridges from config data store.
    [Tags]    Southbound
    OVSDB.Delete Bridge From Ovsdb Node    ${TOOLS_SYSTEM_IP}    s1
    OVSDB.Delete Bridge From Ovsdb Node    ${TOOLS_SYSTEM_2_IP}    s2

Disconnect controller connection from the connected OVSDBs nodes
    [Documentation]    This request will disconnect the controller from the connected OVSDB node for clean startup for next suite.
    [Tags]    Southbound
    OVSDB.Disconnect From Ovsdb Node    ${TOOLS_SYSTEM_IP}
    OVSDB.Disconnect From Ovsdb Node    ${TOOLS_SYSTEM_2_IP}

Verify that the operational topology is clean
    [Documentation]    This request will verify the operational toplogy after the mininet is cleaned.
    [Tags]    Southbound
    @{list} =    BuiltIn.Create List    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_2_IP}    s1    s2
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}    ${list}

Check For Bug 4756
    [Documentation]    bug 4756 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed.
    Utils.Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    SimpleShardDataTreeCohort.*Unexpected failure in validation phase
    [Teardown]    Report_Failure_Due_To_Bug    4756

Check For Bug 4794
    [Documentation]    bug 4794 has been seen in the OVSDB Southbound suites. This test case should be one of the last test
    ...    case executed.
    Utils.Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    [Teardown]    Report_Failure_Due_To_Bug    4794

*** Keywords ***
Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    BuiltIn.Log    ${resp.content}
    RequestsLibrary.Delete All Sessions
