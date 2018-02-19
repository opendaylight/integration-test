*** Settings ***
Documentation     Collection of test cases to validate OVSDB projects bugs.
...
...               TODO: there seems to be some thoughts around never having one-off bug reproduction
...               test cases, but rather they should exist as another test case in some appropriate
...               suite. Also it was suggested that using bug ids for test case names was not ideal
...               this to-do is written in case it's decided to refactor all of these test cases out
...               of this suite and/or to rename the test cases at a later time.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Force Tags        Southbound
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../variables/Variables.robot
Resource          ../Ovsdb.robot

*** Variables ***
${BRIDGE}         ovsbug_br

*** Test Cases ***
Bug 7414 Same Endpoint Name
    [Documentation]    To help validate bug 7414, this test case will send a single rest request to create two
    ...    ports (one for each of two OVS instances connected). The port names will be the same.
    ...    If the bug happens, the request would be accepted, but internally the two creations are seen as the
    ...    same and there is a conflict such that neither ovs will receive the port create.
    [Tags]    7414
    [Setup]    BuiltIn.Run Keywords    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}
    # connect two ovs
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected    ${TOOLS_SYSTEM_2_IP}
    # add brtest to both
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    # send one rest request to create a TP endpoint on each ovs (same name)
    ${body} =    Modify Multi Port Body    vtep1    vtep1
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}    data=${body}
    ${resp_json} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${resp_json}
    # check that each ovs has the correct endpoint
    ${ovs_1_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${ovs_1_output}
    ${ovs_2_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${ovs_2_output}
    BuiltIn.Should Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    BuiltIn.Should Not Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    BuiltIn.Should Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    BuiltIn.Should Not Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    [Teardown]    BuiltIn.Run Keywords    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}    data=${body}
    ...    AND    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}

Bug 7414 Different Endpoint Name
    [Documentation]    This test case is supplemental to the other test case for bug 7414. Even when the other
    ...    test case would fail and no ovs would receive a port create because the port names are the same, this
    ...    case should still be able to create ports on the ovs since the port names are different. However,
    ...    another symptom of this bug is that multiple creations in the same request would end up creating
    ...    all the ports on all of the ovs, which is incorrect. Both test cases check for this, but in the
    ...    case where the other test case were to fail this would also help understand if this symptom is still
    ...    happening
    [Tags]    7414
    [Setup]    OVSDB.Clean OVSDB Test Environment
    # connect two ovs
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected    ${TOOLS_SYSTEM_2_IP}
    # add brtest to both
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl add-br ${BRIDGE}
    # send one rest request to create a TP endpoint on each ovs (different name)
    ${body} =    OVSDB.Modify Multi Port Body    vtep1    vtep2
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}    data=${body}
    ${resp_json} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${resp_json}
    # check that each ovs has the correct endpoint
    ${ovs_1_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${ovs_1_output}
    ${ovs_2_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_2_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${ovs_2_output}
    BuiltIn.Should Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    BuiltIn.Should Not Contain    ${ovs_1_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    BuiltIn.Should Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_2_IP}", remote_ip="${TOOLS_SYSTEM_IP}"
    BuiltIn.Should Not Contain    ${ovs_2_output}    local_ip="${TOOLS_SYSTEM_IP}", remote_ip="${TOOLS_SYSTEM_2_IP}"
    [Teardown]    BuiltIn.Run Keywords    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}    data=${body}
    ...    AND    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ...    AND    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_2_IP}

Bug 5221
    [Documentation]    In the case that an ovs node is rebooted, or the ovs service is
    ...    otherwise restarted, a controller initiated connection should reconnect when
    ...    the ovs is ready and available.
    [Setup]    OVSDB.Clean OVSDB Test Environment
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_NODE_PORT}
    OVSDB.Connect To OVSDB Node
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected
    @{list} =    BuiltIn.Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Ovsdb.Add Bridge To Ovsdb Node    ${TOOLS_SYSTEM_IP}    ${BRIDGE}    0000000000000010
    @{list} =    BuiltIn.Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}/bridge/${BRIDGE}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements Not At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    # Depending on when the retry timers are firing, it may take some 10s of seconds to reconnect, so setting to 30 to cover that.
    BuiltIn.Wait Until Keyword Succeeds    30s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    [Teardown]    BuiltIn.Run Keywords    OVSDB.Clean OVSDB Test Environment
    ...    AND    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:6634%2Fbridge%2F${BRIDGE}
    ...    AND    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:6634
    ...    AND    Utils.Report_Failure_Due_To_Bug    5221

Bug 5177
    [Documentation]    This test case will recreate the bug using the same basic steps as
    ...    provided in the bug, and noted here:
    ...    1) create bridge in config using the UUID determined in Suite Setup
    ...    2) connect ovs (vsctl set-manager)
    ...    3) Fail if node is not discovered in Operational Store
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected
    ${ovsdb_uuid} =    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    # Suite teardown wants this ${ovsdb_uuid} variable for it's best effort cleanup, so making it visible at suite level.
    BuiltIn.Set Suite Variable    ${ovsdb_uuid}
    ${node} =    BuiltIn.Set Variable    uuid/${ovsdb_uuid}
    OVSDB.Add Bridge To Ovsdb Node With NodeId    ${node}    ${TOOLS_SYSTEM_IP}    ${BRIDGE}    0000000000005177
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    ${resp_json} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${resp_json}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    BuiltIn.Should Contain    ${resp.content}    ${node}/bridge/${BRIDGE}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    @{list} =    BuiltIn.Create List    ${BRIDGE}
    BuiltIn.Wait Until Keyword Succeeds    8s    2s    Utils.Check For Elements At URI And Print    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    [Teardown]    BuiltIn.Run Keywords    OVSDB.Clean OVSDB Test Environment
    ...    AND    Utils.Report_Failure_Due_To_Bug    5177

Bug 4794
    [Documentation]    This test is dependent on the work done in the Bug 5177 test case so should
    ...    always be executed immediately after.
    ...    1) delete bridge in config
    ...    2) Poll and Fail if exception is seen in karaf.log
    ${node} =    BuiltIn.Set Variable    ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}
    ${resp} =    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    Builtin.Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    # If the exception is seen in karaf.log within 10s, the following line will FAIL, which is the point.
    BuiltIn.Should Be Equal As Strings.Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Utils.Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    # TODO: Bug 5178
    [Teardown]    BuiltIn.Run Keywords    OVSDB.Clean OVSDB Test Environment
    ...    AND    Utils.Report_Failure_Due_To_Bug    4794

Bug 8280
    [Documentation]    Any config created for a bridge (e.g. added ports) should be reconciled when a bridge is
    ...    reconnected. This test case will create two ports via REST and validate that the bridge has those
    ...    ports. At that point, the bridge will be disconnected from the controller and the 2nd created port
    ...    will be manually removed. The bridge will be reconnected and the 2nd port should be re-added to the
    ...    bridge. If not, then bug 8280 will be found and the test case will fail
    [Tags]    8280
    [Setup]    BuiltIn.Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ...    AND    OVSDB.Clean OVSDB Test Environment
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected    ${TOOLS_SYSTEM_IP}
    ${ovsdb_uuid} =    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    ${node} =    BuiltIn.Set Variable    uuid/${ovsdb_uuid}
    OVSDB.Add Bridge To Ovsdb Node With NodeId    ${node}    ${TOOLS_SYSTEM_IP}    ${BRIDGE}    0000000000008280
    OVSDB.Add Termination Point    uuid%2F${ovs_uuid}    ${BRIDGE}    port1
    OVSDB.Add Termination Point    uuid%2F${ovs_uuid}    ${BRIDGE}    port2
    ${config_store_elements} =    BuiltIn.Create List    ${BRIDGE}    port1    port2
    Utils.Check For Elements At URI And Print    ${CONFIG_TOPO_API}    ${config_store_elements}
    ${ovs_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${ovs_output}
    ${ovs_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    ${ovs_output} =    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-port ${BRIDGE} port2
    OVSDB.Verify Ovs-vsctl Output    show    Port "port2"    ${TOOLS_SYSTEM_IP}    False
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected    ${TOOLS_SYSTEM_IP}
    Utils.Check For Elements At URI And Print    ${CONFIG_TOPO_API}    ${config_store_elements}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    Verify Ovs-vsctl Output    show    Port "port2"
    [Teardown]    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovs_uuid}%2Fbridge%2F${BRIDGE}

Bug 7160
    [Documentation]    If this bug is reproduced, it's possible that the operational store will be
    ...    stuck with leftover nodes and further system tests could fail. It's advised to run this
    ...    test last if possible. See the bug description for high level steps to reproduce
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=7160#c0
    [Setup]    BuiltIn.Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    ...    AND    OVSDB.Clean OVSDB Test Environment
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_NODE_PORT}
    OVSDB.Connect To OVSDB Node    ${TOOLS_SYSTEM_IP}
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected
    ${qos} =    BuiltIn.Set Variable    QOS-1
    ${queue} =    BuiltIn.Set Variable    QUEUE-1
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_node.json
    ${body}    String.Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    String.Replace String    ${body}    61644    ${OVSDB_NODE_PORT}
    ${resp}    RequestsLibrary.Post Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1    data=${body}
    OVSDB.Log Config And Operational Topology
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qos.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${qos}/    data=${body}
    OVSDB.Log Config And Operational Topology
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_queue.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${queue}/    data=${body}
    OVSDB.Log Config And Operational Topology
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/bug_7160/create_qoslinkedqueue.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1    data=${body}
    OVSDB.Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${qos}/queue-list/0/
    OVSDB.Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${qos}/
    OVSDB.Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${queue}/
    OVSDB.Log Config And Operational Topology
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1
    OVSDB.Log Config And Operational Topology
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    ${node}    BuiltIn.Set Variable    ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}
    OVSDB.Log Config And Operational Topology
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Config and Operational Topology Should Be Empty
    [Teardown]    BuiltIn.Run Keywords    OVSDB.Clean OVSDB Test Environment
    ...    AND    Utils.Report_Failure_Due_To_Bug    7160

*** Keywords ***
Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Open Controller Karaf Console On Background
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    OVSDB.Verify OVS Reports Connected
    Utils.Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager

Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    # Best effort to clean config store, by deleting all the types of nodes that are used in this suite
    ${node} =    BuiltIn.Set Variable    ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    ${node} =    BuiltIn.Set Variable    ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    ${resp_json} =    RequestsLibrary.To Json    ${resp.content}    pretty_print=True
    BuiltIn.Log    ${resp_json}
    Delete All Sessions
