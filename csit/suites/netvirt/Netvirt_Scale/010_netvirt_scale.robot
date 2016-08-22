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
Resource          ../../../libraries/Scalability.robot
Resource          ../../../libraries/ClusterManagement.robot

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
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_subnet.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_SUBNETS_API}    data=${Data}    headers=${HEADERS}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    201

Create Tenant Net
    [Documentation]    Create Tenant Net
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_tnt_net.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {netName}    ${TNT1_NET1_NAME}
    ${Data}    Replace String    ${Data}    {netSegm}    ${TNT1_NET1_SEGM}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    201

Create Tenant Subnet
    [Documentation]    Create Tenant Subnet
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_tnt_subnet.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {subnetName}    ${TNT1_SUBNET1_NAME}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_SUBNETS_API}    data=${Data}    headers=${HEADERS}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    201

Create Tenant Router
    [Documentation]    Create Tenant Router
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_router.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_ROUTERS_API}    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    201

Set Router Gateway
    [Documentation]    Set Router Gateway
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_rtr_gateway.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${NEUTRON_PORT_TNT1_RTR_GW}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NB_API}/ports    ${Data}
    Should Be Equal As Strings    ${resp.status_code}    201

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

*** Keywords ***
Get Neutron Networks
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NETWORKS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Ports
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Subnets
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_SUBNETS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Create External Net
    [Arguments]    ${netId}=${EXT_NET1_ID}    ${tntId}=${TNT1_ID}
    [Documentation]    Create Neutron External Network
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${netId}
    ${Data}    Replace String    ${Data}    {tntId}    ${tntId}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${Data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
