*** Settings ***
Documentation     Collection of test cases to validate OVSDB projects bugs.
...               - https://bugs.opendaylight.org/show_bug.cgi?id=5221
...               - https://bugs.opendaylight.org/show_bug.cgi?id=5177
...               - https://bugs.opendaylight.org/show_bug.cgi?id=4794
Suite Setup       OVSDB Connection Manager Suite Setup
Suite Teardown    OVSDB Connection Manager Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Force Tags        Southbound
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
${BRIDGE}         ovsdb-csit-test-5177
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb

*** Test Cases ***
Bug 5221
    [Documentation]    In the case that an ovs node is rebooted, or the ovs service is
    ...    otherwise restarted, a controller initiated connection should reconnect when
    ...    the ovs is ready and available.
    [Setup]    Clean OVSDB Test Environment
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    Connect Controller To OVSDB Node
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Create Bridge    ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${BRIDGE}
    @{list}    Create List    ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}/bridge/${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Wait Until Keyword Succeeds    8s    2s    Check For Elements Not At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    [Teardown]    Run Keywords    Clean OVSDB Test Environment
    ...    AND    Report_Failure_Due_To_Bug    5221

Bug 5177
    [Documentation]    This test case will recreate the bug using the same basic steps as
    ...    provided in the bug, and noted here:
    ...    1) create bridge in config using the UUID determined in Suite Setup
    ...    2) connect ovs (vsctl set-manager)
    ...    3) Fail if node is not discovered in Operational Store
    ${node}    Set Variable    ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}
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
    ${node}    Set Variable    ovsdb://uuid/${ovsdb_uuid}
    ${resp}    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    # If the exception is seen in karaf.log within 10s, the following line will FAIL, which is the point.
    Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    # TODO: Bug 5178
    [Teardown]    Run Keywords    Clean OVSDB Test Environment
    ...    AND    Report_Failure_Due_To_Bug    4794

*** Keywords ***
OVSDB Connection Manager Suite Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected
    ${ovsdb_uuid}=    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    Set Suite Variable    ${ovsdb_uuid}
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
    [Arguments]    ${node}    ${bridge}
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${body}    Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://209.132.179.50:6634
    ${body}    Replace String    ${body}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6640
    ${body}    Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    br01    ${bridge}
    ${body}    Replace String    ${body}    61644    ${OVSDB_PORT}
    ${uri}=    Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/${node}%2Fbridge%2F${bridge}
    Log    URL is ${uri}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Connect Controller To OVSDB Node
    [Documentation]    Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    3s    1s    Verify OVS Reports Connected
