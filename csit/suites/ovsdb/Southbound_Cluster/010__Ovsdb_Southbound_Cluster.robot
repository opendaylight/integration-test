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
${BRIDGE}         br01
${OVSDB_PORT}     6634
${BRIDGE1}         ovsdb-csit-test-bridge1
${BRIDGE2}         ovsdb-csit-test-bridge2
@{node_list}      ${BRIDGE1}    vx1


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

Connecting an OVS instance to the controller
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_1_IP}:6640 tcp:${ODL_SYSTEM_2_IP}:6640 tcp:${ODL_SYSTEM_3_IP}:6640
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE1} vx1 -- set Interface vx1 type=vxlan
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected

Create Bridge Manually And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Create bridge in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br br-s1
    ${dictionary_operational}=    Create Dictionary    br-s1=5
    ${dictionary_config}=    Create Dictionary    br-s1=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary_config}    ${CONFIG_TOPO_API}
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary_operational}    ${OPERATIONAL_TOPO_API}


*** Keywords ***
Verify OVS Reports Connected
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    Uses "vsctl show" to check for string "is_connected"
    ${output}=    Run Command On Remote System    ${tools_system}    sudo ovs-vsctl show
    Should Contain    ${output}    is_connected


