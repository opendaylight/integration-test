*** Settings ***
Documentation     WIP: NetVirt scale test
Suite Setup       Scalability Suite Setup
Suite Teardown    Scalability Suite Teardown
Test Setup        Log Testcase Start To Controller Karaf
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/Scalability.robot

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${EXT_NET1_ID}    7da709ff-397f-4778-a0e8-994811272fdb
${TNT1_ID}        cde2563ead464ffa97963c59e002c0cf
${TNT1_NET1_ID}    12809f83-ccdf-422c-a20a-4ddae0712655
${TNT1_SUBNET1_ID}    6c496958-a787-4d8c-9465-f4c4176652e8
${TNT1_VM1_PORT_ID}    341ceaca-24bf-4017-9b08-c3180e86fd24
${TNT1_VM1_MAC}    FA:16:3E:8E:B8:05
${TNT1_VM1_DEVICE_ID}    20e500c3-41e1-4be0-b854-55c710a1cfb2
${TNT1_NET1_NAME}    net1
${TNT1_NET1_SEGM}    1062
${TNT1_RTR_ID}    e09818e7-a05a-4963-9927-fc1dc6f1e844
${EXT_SUBNET1_ID}    00289199-e288-464a-ab2f-837ca67101a7
${TNT1_SUBNET1_NAME}    subnet1
${NEUTRON_PORT_TNT1_RTR_GW}    8ddd29db-f417-4917-979f-b01d4b1c3e0d

${NUM_SERVERS}    5
${PORTS_PER_SERVER}    1
${PORTS_PER_NETWORK}    1
${CONCURRENT_NETWORKS}    1
${NETWORKS_PER_ROUTER}    1
${CONCURRENT_ROUTERS}    1
${FLOATING_IP_PER_NUM_PORTS}    0

*** Test Cases ***
Start Mininet
    [Documentation]    Start Mininet
    Scalability.Start Mininet Linear    ${NUM_SERVERS}

Verify OVS Switches
    [Documentation]    GET Operational Topo from ODL NB API and verify switches present
    Scalability.Check Linear Topology    ${NUM_SERVERS}

Verify No Networks
    [Documentation]    Should be able to get empty networks list
    ${networks}    Get Neutron Networks
    BuiltIn.Should Contain    ${networks}    "networks" : [ ]

Verify No Ports
    [Documentation]    Should be able to get empty port list
    ${ports}    Get Neutron Ports
    BuiltIn.Should Contain    ${ports}    "ports" : [ ]

Verify No Subnets
    [Documentation]    Should be able to get empty subnets list
    ${subnets}    Get Neutron Subnets
    BuiltIn.Should Contain    ${subnets}    "subnets" : [ ]

Create External Net
    [Documentation]    Create External Net for Tenant
    Create External Net

Create External Subnet
    [Documentation]    Create External Subnet
    Create External Subnet

Create Tenant Net
    [Documentation]    Create Tenant Net
    Create Tenant Net

Create Tenant Subnet
    [Documentation]    Create Tenant Subnet
    Create Tenant Subnet

Create Tenant Router
    [Documentation]    Create Tenant Router
    Create Tenant Router

Set Router Gateway
    [Documentation]    Set Router Gateway
    Set Router Gateway

Get Networks
    [Documentation]    Check networks at end of test
    ${networks}    Get Neutron Networks
    Log    ${networks}

Get Ports
    [Documentation]    Check networks at end of test
    ${ports}    Get Neutron Ports
    Log    ${ports}

Get Subnets
    [Documentation]    Check networks at end of test
    ${subnets}    Get Neutron Subnets
    Log    ${subnets}

OVS VSCTL Show
    ${vsctl_show}    MininetKeywords.Send Mininet Command    cmd=ovs-vsctl show
    Log    ${vsctl_show}

*** Keywords ***
Get Neutron Networks
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NETWORKS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Ports
    [Documentation]    GET Neutron Ports from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Subnets
    [Documentation]    GET Neutron Subnets from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_SUBNETS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Create External Net
    [Arguments]    ${netId}=${EXT_NET1_ID}    ${tntId}=${TNT1_ID}
    [Documentation]    Create Neutron External Network
    ${data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Create External Subnet
    [Arguments]    ${netId}=${EXT_NET1_ID}    ${tntId}=${TNT1_ID}    ${subnetId}=${EXT_SUBNET1_ID}
    [Documentation]    Create Neutron External Subnet
    ${data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_subnet.json
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    ${data}    Replace String    ${data}    {subnetId}    ${subnetId}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_SUBNETS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Create Tenant Net
    [Arguments]    ${netId}=${TNT1_NET1_ID}    ${tntId}=${TNT1_ID}    ${netName}=${TNT1_NET1_NAME}    ${netSegm}=${EXT_NET1_SEGM}
    [Documentation]    Create Neutron Tenant Network
    ${data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_tnt_net.json
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    ${data}    Replace String    ${data}    {netName}    ${netName}
    ${data}    Replace String    ${data}    {netSegm}    ${netSegm}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Create Tenant Subnet
    [Arguments]    ${netId}=${TNT1_NET1_ID}    ${tntId}=${TNT1_ID}    ${subnetId}=${TNT1_SUBNET1_ID}    ${subnetName}=${TNT1_SUBNET1_NAME}
    [Documentation]    Create Neutron Tenant Subnet
    ${data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_tnt_subnet.json
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    ${data}    Replace String    ${data}    {subnetId}    ${subnetId}
    ${data}    Replace String    ${data}    {subnetName}    ${subnetName}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_SUBNETS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Create Tenant Router
    [Arguments]    ${tntId}=${TNT1_ID}    ${rtrId}=${TNT1_RTR_ID}
    [Documentation]    Create Neutron Tenant Router
    ${data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_router.json
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    ${data}    Replace String    ${data}    {rtrId}    ${rtrId}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_ROUTERS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Set Router Gateway
    [Documentation]    Set Neutron Router Gateway
    [Arguments]    ${netId}=${EXT_NET1_ID}    ${subnetId}=${EXT_SUBNET1_ID}    ${tntId}=${TNT1_ID}    ${rtrId}=${TNT1_RTR_ID}    ${portId}=${NEUTRON_PORT_TNT1_RTR_GW}
    ${data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_rtr_gateway.json
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {subnetId}    ${subnetId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    ${data}    Replace String    ${data}    {rtrId}    ${rtrId}
    ${data}    Replace String    ${data}    {portId}    ${portId}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_PORTS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}
