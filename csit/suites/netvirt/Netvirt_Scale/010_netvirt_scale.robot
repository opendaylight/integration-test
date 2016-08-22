*** Settings ***
Documentation     WIP: NetVirt scale test
Suite Setup       Scalability Suite Setup
Suite Teardown    Scalability Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/Scalability.robot
Resource          ../../../libraries/NeutronNB.robot

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

Verify External Net
    [Documentation]    Verify External Net exists with expected properties
    NeutronNB.Verify External Net

Create External Subnet
    [Documentation]    Create External Subnet
    NeutronNB.Create External Subnet

Verify External Subnet
    [Documentation]    Verify External Subnet exists with expected properties
    NeutronNB.Verify External Subnet

Create Tenant Net
    [Documentation]    Create Tenant Net
    NeutronNB.Create Tenant Net

Verify Tenant Net
    [Documentation]    Verify Tenant Network exists with expected properties
    NeutronNB.Verify Tenant Net

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
