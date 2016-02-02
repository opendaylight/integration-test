*** Settings ***
Documentation     Collection of test cases to validate OVSDB projects bugs.
...               -  https://bugs.opendaylight.org/show_bug.cgi?id=4794
...               -  https://bugs.opendaylight.org/show_bug.cgi?id=5177
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
Bug 5177
    [Documentation]    This test case will recreate the bug using the same basic steps as
    ...    provided in the bug, and noted here:
    ...    1) create bridge in config using the UUID determined in Suite Setup
    ...    2) connect ovs (vsctl set-manager)
    ...    3) Fail if node is not discovered in Operational Store
    Create Bridge
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Should Contain    ${resp.content}    ovsdb://uuid/${ovsdb_uuid}/bridge/${BRIDGE}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager tcp:${ODL_SYSTEM_IP}:6640
    @{list}    Create List    ${BRIDGE}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${list}
    [Teardown]    Report_Failure_Due_To_Bug    5177

Bug 4794
    [Documentation]    This test is dependent on the work done in the Bug 5177 test case so should
    ...    always be executed immediately after.
    ...    1) delete bridge in config
    ...    2) Poll and Fail if exception is seen in karaf.log
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    # If the exception is seen in karaf.log within 10s, the following line will FAIL, which is the point.
    Verify_Keyword_Does_Not_Fail_Within_Timeout    10s    1s
    ...    Check Karaf Log File Does Not Have Messages    ${ODL_SYSTEM_IP}    Shard.*shard-topology-operational An exception occurred while preCommitting transaction
    [Teardown]    Report_Failure_Due_To_Bug    4794

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
    RequestsLibrary.Delete Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    Log    ${resp.content}
    Delete All Sessions

Create Bridge
    [Documentation]    This will create bridge on the specified OVSDB node.
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${body}    Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://uuid/${ovsdb_uuid}
    ${body}    Replace String    ${body}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6640
    ${body}    Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    br01    ${BRIDGE}
    ${body}    Replace String    ${body}    61644    ${OVSDB_PORT}
    ${uri}=    Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}
    Log    URL is ${uri}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200
