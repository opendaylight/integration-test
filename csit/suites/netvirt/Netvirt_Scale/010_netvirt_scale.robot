*** Settings ***
Documentation     WIP: NetVirt scale test
Suite Setup       Scalability Suite Setup
Suite Teardown    Scalability Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Scalability.robot
Variables         ../../../variables/neutronnb/Variables.py
Resource          ../../../libraries/NeutronNB.robot
Variables         ../../../variables/neutronnb/Variables.py
Variables         ../../../variables/Variables.py

*** Variables ***
${NUM_SERVERS}    5
${PORTS_PER_SERVER}    1
${PORTS_PER_NETWORK}    1
${CONCURRENT_NETWORKS}    1
${NETWORKS_PER_ROUTER}    1
${CONCURRENT_ROUTERS}    1
${FLOATING_IP_PER_NUM_PORTS}    0

*** Test Cases ***
Verify No OVS
    [Documentation]    Verify OVS Mininet network is down at test start
    Log    ${CURDIR}
    Log    ${OVSDB_CONFIG_DIR}
    Scalability.Check No Switches    ${NUM_SERVERS}
    Scalability.Check No Topology    ${NUM_SERVERS}

Start Mininet
    [Documentation]    Start Mininet linear topology
    Scalability.Start Mininet Linear    ${NUM_SERVERS}

Verify OVS
    [Documentation]    Verify OVS Mininet network up and connected to ODL
    OVSDB.Verify OVS Reports Connected
    Scalability.Check Linear Topology    ${NUM_SERVERS}
    Scalability.Check Every Switch    ${NUM_SERVERS}

Verify Clean Neutron NB
    [Documentation]    Should be no networks, ports or subests at test start
    NeutronNB.Assert No Networks
    NeutronNB.Assert No Ports
    NeutronNB.Assert No Subnets

Create External Net
    [Documentation]    Create External Net for Tenant
    NeutronNB.Create External Net

Create External Subnet
    [Documentation]    Create External Subnet
    NeutronNB.Create External Subnet

Create Tenant Net
    [Documentation]    Create Tenant Net
    NeutronNB.Create Tenant Net

Create Tenant Subnet
    [Documentation]    Create Tenant Subnet
    NeutronNB.Create Tenant Subnet

Create Tenant Router
    [Documentation]    Create Tenant Router
    NeutronNB.Create Tenant Router

Set Router Gateway
    [Documentation]    Set Router Gateway
    NeutronNB.Set Router Gateway

Get Neutron NB Final State
    [Documentation]    Check networks, ports, subests at end of test
    NeutronNB.Get Neutron Networks
    NeutronNB.Get Neutron Ports
    NeutronNB.Get Neutron Subnets

Get OVS Final State
    OvsManager.Execute OvsVsctl Show Command
    OVSDB.Collect OVSDB Debugs

*** Keywords ***
