*** Settings ***
Documentation     Test suite connecting ODL to Mininet
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           String
Library           DateTime
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${OVSDB_PORT}     6640
${OF_PORT}    6653
${FLOWS_TABLE_20}    actions=goto_table:20
${FLOW_CONTROLLER}    actions=CONTROLLER:65535
${FLOWS_TABLE_30}    actions=goto_table:30
${FLOWS_TABLE_40}    actions=goto_table:40
${FLOWS_TABLE_50}    actions=goto_table:50
${FLOWS_TABLE_60}    actions=goto_table:60
${FLOWS_TABLE_70}    actions=goto_table:70
${FLOWS_TABLE_80}    actions=goto_table:80
${FLOWS_TABLE_90}    actions=goto_table:90
${FLOWS_TABLE_100}    actions=goto_table:100
${FLOWS_TABLE_110}    actions=goto_table:110
${FLOW_DROP}      actions=drop
${PING_NOT_CONTAIN}    Destination Host Unreachable
@{node_list}      ovsdb://uuid/

*** Test Cases ***
Make the OVS instance to listen for connection
    [Documentation]    Connect OVS to ODL
    [Tags]    OVSDB netvirt
    Clean Up Ovs   ${MININET}
    Run Command On Remote System    ${MININET}    sudo ovs-vsctl set-manager tcp:${CONTROLLER}:${OVSDB_PORT}
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    ${pingresult}   Run Command On Remote System    ${MININET}    ping ${CONTROLLER} -c 4
    Should Not Contain    ${pingresult}    ${PING_NOT_CONTAIN}
    Wait Until Keyword Succeeds    8s    2s    Check For Elements At URI    ${OPERATIONAL_TOPO_API}    ${node_list}

Get manager connection
    [Documentation]    This will verify if the OVS manager is connected
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    ${lines}=    Get Lines Containing String    ${output}    is_connected
    ${manager}=    Get Line    ${lines}    0
    Should Contain    ${manager}    true

Get controller connection
    [Documentation]    This will make sure the controller is correctly set up/connected
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Manager "tcp:${CONTROLLER}:${OVSDB_PORT}"
    Should Contain    ${output}    is_connected: true

Get bridge setup
    [Documentation]    This request is verifying that the br-int bridge has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Controller "tcp:${CONTROLLER}:${OF_PORT}"
    Should Contain    ${output}    Bridge br-int

Get port setup
    [Documentation]    This will check the port br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Port br-int

Get interface setup
    [Documentation]    This verify the interface br-int has been created
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-vsctl show
    Should Contain    ${output}    Interface br-int

Get the bridge flows
    [Documentation]    This request fetch the OF13 flow tables to verify the flows are correctly added
    [Tags]    OVSDB netvirt
    ${output}    Run Command On Remote System    ${MININET}    sudo ovs-ofctl -O Openflow13 dump-flows br-int
    Should Contain    ${output}    ${FLOWS_TABLE_20}
    Should Contain    ${output}    ${FLOW_CONTROLLER}
    Should Contain    ${output}    ${FLOWS_TABLE_30}
    Should Contain    ${output}    ${FLOWS_TABLE_40}
    Should Contain    ${output}    ${FLOWS_TABLE_50}
    Should Contain    ${output}    ${FLOWS_TABLE_60}
    Should Contain    ${output}    ${FLOWS_TABLE_70}
    Should Contain    ${output}    ${FLOWS_TABLE_80}
    Should Contain    ${output}    ${FLOWS_TABLE_90}
    Should Contain    ${output}    ${FLOWS_TABLE_100}
    Should Contain    ${output}    ${FLOWS_TABLE_110}
    Should Contain    ${output}    ${FLOW_DROP}
