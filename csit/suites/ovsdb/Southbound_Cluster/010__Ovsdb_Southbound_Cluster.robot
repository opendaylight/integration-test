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
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${BRIDGE}         br01
${OVSDB_PORT}     6644
@{node_list}      ${BRIDGE}    vx1

*** Test Cases ***
Create the 3 Cluster nodes
    [Documentation]  To verify the up to 3 nodes.
    Start Suite

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

Create Bridge Manually In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Add Port Manually In Owner and Verify Before Fail
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Bridge Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Port Via Controller In Owner and Verify Before Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${original_cluster_list}    ${original_owner}

Modify the destination IP of Port Before Fail
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${original_cluster_list}    ${original_owner}

Delete the Port Before Fail
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${original_cluster_list}    ${original_owner}

Delete the Bridge In Owner and Verify Before Fail
    [Documentation]    This request will delete the bridge node from the operational data store.
    Delete Bridge Manually And Verify    ${original_cluster_list}    ${original_owner}

Delete Bridge Via Rest Call And Verify In Owner Before Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${original_cluster_list}    ${original_owner}

Kill Owner Instance
    [Documentation]    Kill Owner Instance and verify it is dead
    Kill Multiple Controllers    ${original_owner}
    ${new_cluster_list}    Create Controller Index List
    Remove Values From List    ${new_cluster_list}    ${original_owner}
    Set Suite Variable    ${new_cluster_list}

Check Shards Status After Fail
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${new_cluster_list}
    Run Keyword And Continue On Failure    List Should Not Contain Value    ${new_candidates_list}    ${original_owner}    Original owner ${original_owner} still in candidate list.
    Remove Values From List    ${new_candidates_list}    ${original_owner}
    Wait Until Keyword Succeeds    20s    1s    Check Ovsdb Shards Status    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Candidate After Fail
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Wait Until Keyword Succeeds    20s    1s    Get Ovsdb Entity Owner Status For One Device    ${new_cluster_list}
>>>>>>> a435b22... Do Not Merge Patch :For adding the SouthboundCluster Port.
    ${new_candidate}=    Get From List    ${new_candidates_list}    0
    Set Suite Variable    ${new_owner}
    Set Suite Variable    ${new_candidate}

Create Bridge Manually In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${new_cluster_list}    ${new_owner}

Add Port Manually In Owner and Verify After Fail
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${new_cluster_list}    ${new_owner}
    Wait Until Keyword Succeeds    20s    1s    Add Port To The Manual Bridge And Verify    ${original_cluster_list}    ${original_owner}

Create Bridge Via Controller In Owner and Verify After Fail
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Wait Until Keyword Succeeds    20s    1s    Create Bridge And Verify    ${new_cluster_list}    ${new_owner}

Create Port Via Controller In Owner and Verify After Fail
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${original_cluster_list}    ${new_owner}

Get Config Topology with Bridge and Port After Fail
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    Wait Until Keyword Succeeds    8s    2s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${CONFIG_TOPO_API}    ${node_list}

Modify the destination IP of Port After Fail
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${original_cluster_list}    ${new_owner}

Get Operational Topology with modified Port After Fail
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE}    vx1    10.0.0.19
    Wait Until Keyword Succeeds    8s    2s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Port After Fail
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${original_cluster_list}    ${new_owner}

Delete the Bridge In Owner and Verify After Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Wait Until Keyword Succeeds    20s    1s    Delete Bridge Manually And Verify    ${new_cluster_list}    ${new_owner}

Delete Bridge Via Rest Call And Verify In Owner After Fail
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${new_cluster_list}    ${new_owner}

Start Old Owner Instance
    [Documentation]    Start Owner Instance and verify it is active
    Start Multiple Controllers    300s    ${original_owner}

Check Shards Status After Recover
    [Documentation]    Create original cluster list and check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status After Cluster Event    ${original_cluster_list}

Check Entity Owner Status After Recover
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${new_owner}    ${new_candidates_list}    Get Ovsdb Entity Owner Status For One Device    ${original_cluster_list}
    Set Suite Variable    ${new_owner}

Create Bridge Manually In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge Manually And Verify    ${original_cluster_list}    ${new_owner}

Add Port Manually In Owner and Verify After Recover
    [Documentation]    Add Port in Owner and verify it gets applied from all instances.
    Add Port To The Manual Bridge And Verify    ${original_cluster_list}    ${new_owner}

Create Bridge Via Controller In Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Create Bridge And Verify    ${original_cluster_list}    ${new_owner}

Create Port Via Controller In Owner and Verify After Recover
    [Documentation]    Create Port in Owner and verify it gets applied from all instances.
    Create Port Via Controller    ${original_cluster_list}    ${new_owner}

Get Config Topology with Bridge and Port After Recover
    [Documentation]    This will fetch the configuration topology from configuration data store to verify the bridge is added to the data store
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${CONFIG_TOPO_API}    ${node_list}

Modify the destination IP of Port After Recover
    [Documentation]    This will modify the dst ip of existing port
    Modify the destination IP of Port    ${original_cluster_list}    ${new_owner}

Get Operational Topology with modified Port After Recover
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE}    vx1    10.0.0.19
    Wait Until Keyword Succeeds    8s    2s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${OPERATIONAL_TOPO_API}    ${list}

Delete the Port After Recover
    [Documentation]    This request will delete the port node from the bridge node and data store.
    Delete Port And Verify    ${original_cluster_list}    ${new_owner}

Delete the Bridge In Owner and Verify After Recover
    [Documentation]    This request will delete the bridge node from the operational data store.
    Delete Bridge Manually And Verify    ${original_cluster_list}    ${new_owner}

Delete Bridge Via Rest Call And Verify In Owner After Recover
    [Documentation]    This request will delete the bridge node from the config data store and operational data store.
    Delete Bridge Via Rest Call And Verify    ${original_cluster_list}    ${new_owner}

Create Bridge Via Controller In Old Owner and Verify After Recover
    [Documentation]    Create Bridge in Owner and verify it gets applied from all instances.
    Wait Until Keyword Succeeds    20s    1s    Create Bridge And Verify    ${original_cluster_list}    ${original_owner}
    [Teardown]    Report_Failure_Due_To_Bug    4908

Configure 3 OVSDB Node Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Create Session    session    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Make the OVS instance to listen for connection
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}


Connect to OVSDB Node for controller one
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    6644   ${OVSDB_PORT}
    ${TOOLS_SYSTEM_IP1}    Replace String    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_IP}    "${TOOLS_SYSTEM_IP}"
    ${dictionary}=    Create Dictionary    ${TOOLS_SYSTEM_IP1}=1    ${OVSDBPORT}=4    ${BRIDGE}=1
    Put And Check At URI In Cluster    ${controller_index_list}    1    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}    ${body}
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}

Get Operational Topology
    [Documentation]    This request will fetch the operational topology from the connected OVSDB nodes
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}

Create a Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}

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
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port ${BRIDGE} vx1 -- set Interface vx1 type=vxlan

Get Operational Topology with Port
    [Documentation]    This request will fetch the operational topology after the Port is added to the bridge
    @{list}    Create List    ${BRIDGE}  vxlanport
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}

Delete the Port
    [Documentation]    This request will delete the port node from the bridge node and data store.
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}/termination-point/vxlanport/
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

Start Suite
    Log    Start the test on the base edition
    ${mininet_conn_id}=    Open Connection    ${MININET}    prompt=>
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Put File    ${CURDIR}/../../../libraries/DynamicMininet.py    .
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start}
    Read Until    mininet>
    Write    start_with_cluster ${CONTROLLER},${CONTROLLER1},${CONTROLLER2}
    Read Until    mininet>
