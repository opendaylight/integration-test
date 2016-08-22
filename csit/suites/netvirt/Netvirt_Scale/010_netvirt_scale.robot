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
    ${switches}    Set Variable    5
    Scalability.Start Mininet Linear    ${switches}

Get OVS Switches
    [Documentation]    GET Operational Topo from ODL NB API and verify switches present
    ${switches}    Set Variable    5
    Scalability.Check Linear Topology    ${switches}

# TODO: Put in library
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
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API} ${Data}
    Log    ${resp.status_code}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

Create Tenant Router
    [Documentation]    Create Tenant Router
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_router.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_ROUTERS_API} ${Data}
    Log    ${resp.status_code}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

*** Keywords ***
