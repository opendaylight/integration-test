*** Settings ***
Documentation     Example Robot suite used for the CSIT tutorial at the 2016 OpenDaylight Summit
Suite Setup       Local Suite Setup
Suite Teardown    Local Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Variables         ../../variables/Variables.py
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/SetupUtils.robot

*** Variables ***
${switch_name}    odl_summit_switch

*** Test Cases ***
Verify Ovs Is Discovered In Operational
    [Documentation]    The test case setup will connect ovs to the controller and the test case itself
    ...    will verify specific elements are discovered in the operational toplogy.
    [Setup]    Connect Ovs To Controller
    Wait Until Keyword Succeeds    5s    1s    Verify Ovs Reports Connected
    # very basic list of things we expect to find in the output of from operational's topology response
    @{elements_to_verify}    Create List    openflow:    node-id
    Wait Until Keyword Succeeds    5s    1s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${elements_to_verify}

Verify There Is No Topology In Config Store
    [Documentation]    Only the operational store should have any topology info at this point, as it was
    ...    populated when the ovs was connected to the openflow southbound.
    No Content From URI    session    ${CONFIG_TOPO_API}

Add Openflow Rule
    [Documentation]    TODO
    [Tags]    exclude
    Log    This test case is not implemented yet

Delete Openflow Rule
    [Documentation]    TODO
    [Tags]    exclude
    Log    This test case is not implemented yet

*** Keywords ***
Connect Ovs To Controller
    [Documentation]    Will set the ovs manager to point at the ODL IP on the openflow port
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br ${switch_name}
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set bridge ${switch_name} protocols=OpenFlow13
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set bridge ${switch_name} other-config:hwaddr=00:00:00:00:00:01
    Set Controller In OVS Bridge    ${TOOLS_SYSTEM_IP}    ${switch_name}    tcp:${ODL_SYSTEM_IP}:${ODL_OF_PORT}

Local Suite Setup
    [Documentation]    Make sure the environment is in a clean state.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    # the variable named "session" has grandfathered it's way in to CSIT such that some keywords expect
    # it to be the name of the session with which it should make it's rest calls with.    There is no other
    # good reason than that.
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    Clean OVSDB Test Environment

Local Suite Teardown
    [Documentation]    Ensure the system is clean and all connections are closed
    Clean OVSDB Test Environment
    Close All Connections
