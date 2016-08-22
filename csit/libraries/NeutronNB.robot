*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py

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
    [Arguments]    ${netId}=${TNT1_NET1_ID}    ${tntId}=${TNT1_ID}    ${netName}=${TNT1_NET1_NAME}    ${netSegm}=${TNT1_NET1_SEGM}
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
