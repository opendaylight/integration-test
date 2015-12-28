
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
${BRIDGE3}         ovsdb-csit-test-bridge2
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
    ${mininet_conn_id}    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
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
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge_3node.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_1_IP}:6633
    ${sample2}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_2_IP}:6633
    ${sample3}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_3_IP}:6633
    ${sample4}    Replace String    ${sample1}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${sample5}    Replace String    ${sample2}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${sample6}    Replace String    ${sample3}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${sample7}    Replace String    ${sample4}    br01    ${BRIDGE1}
    ${sample8}    Replace String    ${sample5}    br02    ${BRIDGE2}
    ${sample9}    Replace String    ${sample6}    br03    ${BRIDGE3}
    ${body1}    Replace String    ${sample7}    61644    ${OVSDB_PORT}
    ${body2}    Replace String    ${sample8}    61644    ${OVSDB_PORT}
    ${body3}    Replace String    ${sample9}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE1}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE2}
    Log    URL is ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE3}
    Log    data: ${body1}
    Log    data: ${body2}
    Log    data: ${body3}
    ${resp_1}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE1}    data=${body1}
    ${resp_2}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE2}    data=${body2}
    ${resp_3}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE3}    data=${body3}
    Log    ${resp_1.content}
    Log    ${resp_2.content}
    Log    ${resp_3.content}
    Should Be Equal As Strings    ${resp_1.status_code}    200
    Should Be Equal As Strings    ${resp_2.status_code}    200
    Should Be Equal As Strings    ${resp_3.status_code}    200

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

