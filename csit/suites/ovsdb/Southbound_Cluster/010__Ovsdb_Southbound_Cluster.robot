*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDBPORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${OVSDB_PORT}     6634
${BRIDGE1}         ovsdb-csit-test-bridge1
${BRIDGE2}         ovsdb-csit-test-bridge2
${BRIDGE3}         ovsdb-csit-test-bridge3
@{node_list}      ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_PORT}


*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Collections In Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Configure 3 OVSDB Node Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Make the OVS instance to listen for connection
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}

Connect to OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    3s    1s    Verify OVS Reports Connected

Get Operational Topology
    [Documentation]    This request will  fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE1}

Get Operational Topology with Bridge
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes to verify the bridge is added to the data store
    @{list}    Create List    ${BRIDGE1}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Get Config Topology with Bridge
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ${BRIDGE1}

Create Port Manually
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE1} vx1 -- set Interface vx1 type=vxlan
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE2} vx1 -- set Interface vx1 type=vxlan

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE1}  vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete the Port
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE1}/termination-point/vxlanport/
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error

Delete bridge manually
    [Documentation]    This request will delete the bridge node from the config data store.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-br ${BRIDGE1}

Configure 3 OVSDB Node Suite Teardown
    [Documentation]  Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Delete All Sessions

*** keywords ***
Clean OVSDB Test Environment
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    General Use Keyword attempting to sanitize test environment for OVSDB related
    ...    tests.  Not every step will always be neccessary, but should not cause any problems for
    ...    any new ovsdb test suites.
    Clean Mininet System    ${tools_system}
    Run Command On Remote System    ${tools_system}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${tools_system}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Run Command On Remote System    ${tools_system}    sudo rm -rf /etc/openvswitch/conf.db
    Run Command On Remote System    ${tools_system}    sudo /usr/share/openvswitch/scripts/ovs-ctl start

Verify OVS Reports Connected
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    Uses "vsctl show" to check for string "is_connected"
    ${output}=    Run Command On Remote System    ${tools_system}    sudo ovs-vsctl show
    Should Contain    ${output}    is_connected

Add Multiple Collections In Managers to OVS
    [Arguments]    ${mininet}    ${controller_index_list}    ${ovs_mgr_port}=6634
    [Documentation]    Start Mininet with custom topology and connect to all controllers in the ${controller_index_list}.
    Log    Clear any existing mininet
    Clean Mininet System    ${mininet}
    ${mininet_conn_id}=    Open Connection    ${mininet}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=${DEFAULT_TIMEOUT}
    Set Suite Variable    ${mininet_conn_id}
    Flexible Mininet Login
    ${ovs_opt}=    Set Variable
    : FOR    ${index}    IN    @{controller_index_list}
    \    ${ovs_opt}=    Catenate    ${ovs_opt}    ${SPACE}ptcp:${ovs_mgr_port}
    \    Log    ${ovs_opt}
    Log    Configure OVS Managers in the OVS
    Run Command On Mininet    ${mininet}    sudo ovs-vsctl set-manager ${ovs_opt}
    Log    Check OVS configuratiom
    ${output}=    Run Command On Mininet    ${mininet}    sudo ovs-vsctl show
    Log    ${output}
    [Return]    ${mininet_conn_id}