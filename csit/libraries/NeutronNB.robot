*** Settings ***
Documentation     Neutron Northbound API library
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Resource          Utils.robot
Variables         ../variables/Variables.py
Variables         ../variables/neutronnb/Variables.py

*** Variables ***

*** Keywords ***
Get Neutron Networks
    [Documentation]    GET Neutron Networks from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NETWORKS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Assert No Networks
    [Documentation]    GET Neutron Networks list and assert it's empty
    ${networks}    NeutronNB.Get Neutron Networks
    BuiltIn.Should Contain    ${networks}    "networks" : [ ]

Get Neutron Ports
    [Documentation]    GET Neutron Ports from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Assert No Ports
    [Documentation]    GET Neutron Ports list and assert it's empty
    ${ports}    NeutronNB.Get Neutron Ports
    BuiltIn.Should Contain    ${ports}    "ports" : [ ]

Get Neutron Subnets
    [Documentation]    GET Neutron Subnets from ODL NB API
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_SUBNETS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Assert No Subnets
    [Documentation]    GET Neutron Subnets list and assert it's empty
    ${subnets}    NeutronNB.Get Neutron Subnets
    BuiltIn.Should Contain    ${subnets}    "subnets" : [ ]

Create External Net
    [Arguments]    ${netId}=${EXT_NET1_ID}    ${tntId}=${TNT1_ID}
    [Documentation]    Create Neutron External Network
    ${data}    OperatingSystem.Get File    ${CREATE_EXT_NET_TEMPLATE}
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Verify External Net
    [Arguments]    ${netId}=${EXT_NET1_ID}    ${tntId}=${TNT1_ID}
    [Documentation]    Verify Neutron External Network
    ${networks}    NeutronNB.Get Neutron Networks
    BuiltIn.Should Contain    ${networks}    "networks" : [ {
    BuiltIn.Should Contain    ${networks}    "id" : ${netId}
    BuiltIn.Should Contain    ${networks}    "tenant_id" : ${tntId}

Create External Subnet
    [Arguments]    ${subnetId}=${EXT_SUBNET1_ID}    ${tntId}=${TNT1_ID}    ${netId}=${EXT_NET1_ID}
    [Documentation]    Create Neutron External Subnet
    ${data}    OperatingSystem.Get File    ${CREATE_EXT_SUBNET_TEMPLATE}
    ${data}    Replace String    ${data}    {netId}    ${netId}
    ${data}    Replace String    ${data}    {tntId}    ${tntId}
    ${data}    Replace String    ${data}    {subnetId}    ${subnetId}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_SUBNETS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Verify External Subnet
    [Arguments]    ${subnetId}=${EXT_SUBNET1_ID}    ${tntId}=${TNT1_ID}    ${netId}=${EXT_NET1_ID}
    [Documentation]    Verify Neutron External Subnet
    ${networks}    NeutronNB.Get Neutron Subnets
    BuiltIn.Should Contain    ${networks}    "subnets" : [ {
    BuiltIn.Should Contain    ${networks}    "id" : ${subnetId}
    BuiltIn.Should Contain    ${networks}    "tenant_id" : ${tntId}
    BuiltIn.Should Contain    ${networks}    "network_id" : ${netId}

Create Tenant Net
    [Arguments]    ${netId}=${TNT1_NET1_ID}    ${tntId}=${TNT1_ID}    ${netName}=${TNT1_NET1_NAME}    ${netSegm}=${TNT1_NET1_SEGM}
    [Documentation]    Create Neutron Tenant Network
    ${data}    OperatingSystem.Get File    ${CREATE_TNT_NET_TEMPLATE}
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
    ${data}    OperatingSystem.Get File    ${CREATE_TNT_SUBNET_TEMPLATE}
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
    ${data}    OperatingSystem.Get File    ${CREATE_ROUTER_TEMPLATE}
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
    ${data}    OperatingSystem.Get File    ${CREATE_PORT_RTR_GATEWAY_TEMPLATE}
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
