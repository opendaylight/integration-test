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

${NUM_SERVERS}    1
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

Get OVS Switches
    [Documentation]    GET Operational Topo from ODL NB API and verify switches present
    Scalability.Check Linear Topology    ${NUM_SERVERS}

Get Ports
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    BuiltIn.Should Contain    ${resp.content}    "ports" : [ ]

Create Ports
    [Documentation]    Create Ports
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_vm.json
    ${Data}    Replace String    ${Data}    {BIND_HOST_ID}    ${ODL_SYSTEM_IP}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${TNT1_VM1_PORT_ID}
    ${Data}    Replace String    ${Data}    {macAddr}    ${TNT1_VM1_MAC}
    ${Data}    Replace String    ${Data}    {deviceId}    ${TNT1_VM1_DEVICE_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_PORTS_API}    data=${Data}    headers=${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    201

Get Neutron Networks
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NETWORKS_API}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    BuiltIn.Should Contain    ${resp.content}    "networks" : [ ]

Create Neutron External Net
    [Documentation]    Create External Net for Tenant
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

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
    Should Be Equal As Strings    ${resp.status_code}    201

Create Tenant Router
    [Documentation]    Create Tenant Router
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_router.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_ROUTERS_API}    data=${Data}    headers=${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

*** Keywords ***
