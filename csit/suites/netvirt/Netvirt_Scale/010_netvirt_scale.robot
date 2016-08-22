*** Settings ***
Documentation     Basic OVS-based NetVirt scale test
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    RequestsLibrary.Delete_All_Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${OVSDB_PORT}     6634
@{node_list}      ovsdb://${TOOLS_SYSTEM_IP}:${OVSDB_PORT}    ${TOOLS_SYSTEM_IP}    ${OVSDB_PORT}
${NUM_SERVERS}     1
${PORTS_PER_SERVER}     1
${PORTS_PER_NETWORK}     1
${CONCURRENT_NETWORKS}     1
${NETWORKS_PER_ROUTER}     1
${CONCURRENT_ROUTERS}     1
${FLOATING_IP_PER_NUM_PORTS}     0

*** Test Cases ***
Foo Test
    [Documentation]    Test under dev
    [Tags]    OVSDB netvirt
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ptcp:${OVSDB_PORT}
    OVSDB.Connect To Ovsdb Node ${TOOLS_SYSTEM_IP}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1    ${node_list}
