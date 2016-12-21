*** Settings ***
Documentation     Collection of test cases to validate OVSDB projects bugs.
...               - https://bugs.opendaylight.org/show_bug.cgi?id=5221
...               - https://bugs.opendaylight.org/show_bug.cgi?id=5177
...               - https://bugs.opendaylight.org/show_bug.cgi?id=4794
Suite Setup       OVSDB Connection Manager Suite Setup
Suite Teardown    OVSDB Connection Manager Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
${BRIDGE}         ovsdb-csit-bug-validation
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb

*** Test Cases ***
Bug 7414 Same Endpoint Name
    [Documentation]    To help validate bug 7414, this test case will send a single rest request to create two
    ...    ports (one for each of two OVS instances connected). The port names will be the same.
    ...    If the bug happens, the request would be accepted, but internally the two creations are seen as the
    ...    same and there is a conflict such that neither ovs will receive the port create.
    [Tags]    7414
    [Setup]    Run Keywords    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}
    # connect two ovs
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${TOOLS_SYSTEM_2_IP}
    # add brtest to both
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    # send one rest request to create a TP endpoint on each ovs (same name)
    ${body}=    Modify Multi Port Body    vtep1    vtep1
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}    data=${body}
    Log    ${resp.content}
    # check that each ovs has the correct endpoint
    ${ovs_1_output}=    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${ovs_1_output}
    ${ovs_2_output}=    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl show
    Log    ${ovs_2_output}
    ${ovs_2_output}=    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl show
    Should Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    Should Not Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    Should Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    Should Not Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    [Teardown]    Run Keywords    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}    data=${body}
    ...    AND    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}

Bug 7414 Different Endpoint Name
    [Documentation]    This test case is supplemental to the other test case for bug 7414. Even when the other
    ...    test case would fail and no ovs would receive a port create because the port names are the same, this
    ...    case should still be able to create ports on the ovs since the port names are different. However,
    ...    another symptom of this bug is that multiple creations in the same request would end up creating
    ...    all the ports on all of the ovs, which is incorrect. Both test cases check for this, but in the
    ...    case where the other test case were to fail this would also help understand if this symptom is still
    ...    happening
    [Tags]    7414
    [Setup]    Clean OVSDB Test Environment
    # connect two ovs
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${TOOLS_SYSTEM_2_IP}
    # add brtest to both
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    # send one rest request to create a TP endpoint on each ovs (different name)
    ${body}=    Modify Multi Port Body    vtep1    vtep2
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}    data=${body}
    Log    ${resp.content}
    # check that each ovs has the correct endpoint
    ${ovs_1_output}=    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${ovs_1_output}
    ${ovs_2_output}=    Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl show
    Log    ${ovs_2_output}
    Should Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    Should Not Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    Should Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    Should Not Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    [Teardown]    Run Keywords    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}    data=${body}
    ...    AND    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}

Bug 5221
    [Documentation]    In the case that an ovs node is rebooted, or the ovs service is
    ...    otherwise restarted, a controller initiated connection should reconnect when
    ...    the ovs is ready and available.
    [Setup]    Clean OVSDB Test Environment
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    Connect Controller To OVSDB Node
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Create Bridge    ${TOOLS_SYSTEM_IP}:6634    ${BRIDGE}
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}/bridge/${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    # Depending on when the retry timers are firing, it may take some 10s of seconds to reconnect, so setting to 30 to cover that.
    Wait Until Keyword Succeeds    30s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    [Teardown]    Run Keywords    Clean OVSDB Test Environment
    ...    AND    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:6634%2Fbridge%2F${BRIDGE}
    ...    AND    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:6634
    ...    AND    Report_Failure_Due_To_Bug    5221

Bug 5177
    [Documentation]    This test case will recreate the bug using the same basic steps as
    ...    provided in the bug, and noted here:
    ...    1) create bridge in config using the UUID determined in Suite Setup
    ...    2) connect ovs (vsctl set-manager)
    ...    3) Fail if node is not discovered in Operational Store
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected
    ${ovsdb_uuid}=    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    # Suite teardown wants this ${ovsdb_uuid} variable for it's best effort cleanup, so making it visible at suite level.
    Set Suite Variable    ${ovsdb_uuid}
    ${node}    Set Variable    uuid/${ovsdb_uuid}
    Create Bridge    ${node}    ${BRIDGE}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ${node}/bridge/${BRIDGE}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    [Teardown]    Run Keywords    Clean OVSDB Test Environment
    ...    AND    Report_Failure_Due_To_Bug    5177

Bug 4794
    [Documentation]    This test is dependent on the work done in the Bug 5177 test case so should
    ...    always be executed immediately after.
    ...    1) delete bridge in config
    ...    2) Poll and Fail if exception is seen in karaf.log
    ${node}    Set Variable    ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    # If the exception is seen in karaf.log within 10s, the following line will FAIL, which is the point.
    Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    # TODO: Bug 5178
    [Teardown]    Run Keywords    Clean OVSDB Test Environment
    ...    AND    Report_Failure_Due_To_Bug    4794

Bug 7160
    [Documentation]    If this bug is reproduced, it's possible that the operational store will be
    ...    stuck with leftover nodes and further system tests could fail. It's advised to run this
    ...    test last if possible. See the bug description for high level steps to reproduce
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=7160#c0
    [Setup]    Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ...    AND    Clean OVSDB Test Environment
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    Connect Controller To OVSDB Node
    ${QOS}=    Set Variable    QOS-1
    ${QUEUE}=    Set Variable    QUEUE-1
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_node.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1    data=${body}
    Log Config And Operational Topology
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qos.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/    data=${body}
    Log Config And Operational Topology
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_queue.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${QUEUE}/    data=${body}
    Log Config And Operational Topology
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/bug_7160/create_qoslinkedqueue.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1    data=${body}
    Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/queue-list/0/
    Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/
    Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${QUEUE}/
    Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1
    Log Config And Operational Topology
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    ${node}    Set Variable    ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}
    Log Config And Operational Topology
    Wait Until Keyword Succeeds    5s    1s    Config and Operational Topology Should Be Empty
    [Teardown]    Run Keywords    Clean OVSDB Test Environment
    ...    AND    Report_Failure_Due_To_Bug    7160

*** Keywords ***
OVSDB Connection Manager Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager

OVSDB Connection Manager Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    # Best effort to clean config store, by deleting all the types of nodes that are used in this suite
    ${node}    Set Variable    ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    ${node}    Set Variable    ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Delete All Sessions
    # TODO: both Create Bridge and Connect Controller To OVSDB Node keywords below should be moved to a library
    #    and all the suites using this kind of work can move to using the library instead of
    #    doing all this work each time.

Create Bridge
    [Arguments]    ${node_string}    ${bridge}
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${body}    Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://${node_string}
    ${body}    Replace String    ${body}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${body}    Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    br01    ${bridge}
    ${body}    Replace String    ${body}    61644    ${OVSDB_PORT}
    ${node_string}    Replace String    ${node_string}    /    %2F
    ${uri}=    Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${node_string}%2Fbridge%2F${bridge}
    Log    URL is ${uri}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Connect Controller To OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected

Log Config And Operational Topology
    [Documentation]    For debugging purposes, this will log both config and operational topo data stores
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Log    ${resp.content}

Config and Operational Topology Should Be Empty
    [Documentation]    This will check that only the expected output is there for both operational and config
    ...    topology data stores. Empty probably means that only ovsdb:1 is there.
    ${config_resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    ${operational_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    Should Contain    ${config_resp.content}    {"topology-id":"ovsdb:1"}
    Should Contain    ${operational_resp.content}    {"topology-id":"ovsdb:1"}

Modify Multi Port Body
    [Arguments]    ${ovs_1_port_name}    ${ovs_2_port_name}
    [Documentation]    these steps are needed multiple times in bug reproductions above.
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/bug_7414/create_multiple_ports.json
    ${ovs_1_ovsdb_uuid}=    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    ${ovs_2_ovsdb_uuid}=    Get OVSDB UUID    ${TOOLS_SYSTEM_2_IP}
    ${body}    Replace String    ${body}    OVS_1_UUID    ${ovs_1_ovsdb_uuid}
    ${body}    Replace String    ${body}    OVS_2_UUID    ${ovs_2_ovsdb_uuid}
    ${body}    Replace String    ${body}    OVS_1_BRIDGE_NAME    ${BRIDGE}
    ${body}    Replace String    ${body}    OVS_2_BRIDGE_NAME    ${BRIDGE}
    ${body}    Replace String    ${body}    OVS_1_IP    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    OVS_2_IP    ${TOOLS_SYSTEM_2_IP}
    ${body}    Replace String    ${body}    OVS_1_PORT_NAME    ${ovs_1_port_name}
    ${body}    Replace String    ${body}    OVS_2_PORT_NAME    ${ovs_2_port_name}
    Log    ${body}
    [Return]    ${body}
