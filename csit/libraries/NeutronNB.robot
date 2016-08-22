*** Settings ***
Documentation     Neutron Northbound API library
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Resource          SSHKeywords.robot
Resource          Utils.robot
Variables         ${CURDIR}/../variables/Variables.py
Variables         ${CURDIR}/../variables/neutronnb/Variables.py

*** Variables ***

*** Keywords ***
Get Neutron Networks Manually
    [Documentation]    GET Neutron Networks from ODL NB API by manually building/sending REST
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_NETWORKS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Networks
    [Documentation]    GET Neutron Networks from ODL NB API using Neutron Python client
    [Arguments]    ${neutron_client_ip}=${TOOLS_SYSTEM_IP}
    ${rc}    ${output}    OperatingSystem.Run And Return Rc And Output    sudo find / -name activate
    ${rc}    ${output}    OperatingSystem.Run And Return Rc And Output    find / -name activate
    ${output}    Utils.Run Command On Remote System    system=${neutron_client_ip}    cmd=sudo find / -name activate
    ${output}    Utils.Run Command On Remote System    system=${neutron_client_ip}    cmd=sudo find /tmp/ -name activate
    ${output}    Utils.Run Command On Remote System    system=${neutron_client_ip}    cmd=sudo ls -R /tmp
    ${output}    Utils.Run Command On Remote System    system=${neutron_client_ip}    cmd=find / -name activate
    ${output}    Utils.Run Command On Remote System    system=${neutron_client_ip}    cmd=find /tmp/ -name activate
    ${output}    Utils.Run Command On Remote System    system=${neutron_client_ip}    cmd=ls -R /tmp
    #SSHKeywords.Virtual_Env_Set_Path    venv_path=${WORKSPACE}/robot_venv
    #SSHKeywords.Virtual_Env_Freeze
    #SSHKeywords.Virtual_Env_Run_Cmd_At_Cwd    cmd=command -v neutron
    [Return]    ${output}

Assert No Networks
    [Documentation]    GET Neutron Networks list and assert it's empty
    ${networks}    NeutronNB.Get Neutron Networks
    BuiltIn.Should Contain    ${networks}    "networks" : [ ]

Get Neutron Ports Manually
    [Documentation]    GET Neutron Ports from ODL NB API by manually building/sending REST
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Ports
    [Documentation]    GET Neutron Ports from ODL NB API using Neutron Python client
    ${output}    Utils.Write Commands Until Expected Prompt    cmd=neutron port-list    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${output}
    [Return]    ${output}

Assert No Ports
    [Documentation]    GET Neutron Ports list and assert it's empty
    ${ports}    NeutronNB.Get Neutron Ports
    BuiltIn.Should Contain    ${ports}    "ports" : [ ]

Get Neutron Subnets Manually
    [Documentation]    GET Neutron Subnets from ODL NB API by manually building/sending REST
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_SUBNETS_API}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Get Neutron Subnets
    [Documentation]    GET Neutron Subnets from ODL NB API using Neutron Python client
    ${output}    Utils.Write Commands Until Expected Prompt    cmd=neutron subnet-list    prompt=${DEFAULT_LINUX_PROMPT}
    Log    ${output}
    [Return]    ${output}

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
    BuiltIn.Should Contain    ${networks}    "id" : "${netId}"
    BuiltIn.Should Contain    ${networks}    "tenant_id" : "${tntId}"

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
    BuiltIn.Should Contain    ${networks}    "id" : "${subnetId}"
    BuiltIn.Should Contain    ${networks}    "tenant_id" : "${tntId}"
    BuiltIn.Should Contain    ${networks}    "network_id" : "${netId}"

Create Tenant Net
    [Arguments]    ${id}=${TNT1_NET1_ID}    ${tenant_id}=${TNT1_ID}    ${name}=${TNT1_NET1_NAME}    ${provider_segmentation_id}=${TNT1_NET1_SEGM}
    [Documentation]    Create Neutron Tenant Network
    ${data}    OperatingSystem.Get File    ${CREATE_TNT_NET_TEMPLATE}
    ${data}    Replace String    ${data}    {id}    ${id}
    ${data}    Replace String    ${data}    {tenant_id}    ${tenant_id}
    ${data}    Replace String    ${data}    {name}    ${name}
    ${data}    Replace String    ${data}    {provider_segmentation_id}    ${provider_segmentation_id}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_NETWORKS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Verify Tenant Net
    [Arguments]    ${id}=${TNT1_NET1_ID}    ${tenant_id}=${TNT1_ID}    ${name}=${TNT1_NET1_NAME}    ${provider_segmentation_id}=${TNT1_NET1_SEGM}
    [Documentation]    Verify Neutron Tenant Network
    ${networks}    NeutronNB.Get Neutron Networks
    BuiltIn.Should Contain    ${networks}    "networks" : [ {
    BuiltIn.Should Contain    ${networks}    "id" : "${id}"
    BuiltIn.Should Contain    ${networks}    "tenant_id" : "${tenant_id}"
    BuiltIn.Should Contain    ${networks}    "name" : "${name}"
    BuiltIn.Should Contain    ${networks}    "provider:segmentation_id" : "${provider_segmentation_id}"

Create Tenant Subnet
    [Arguments]    ${id}=${TNT1_SUBNET1_ID}    ${network_id}=${TNT1_NET1_ID}    ${tenant_id}=${TNT1_ID}    ${name}=${TNT1_SUBNET1_NAME}
    [Documentation]    Create Neutron Tenant Subnet
    ${data}    OperatingSystem.Get File    ${CREATE_TNT_SUBNET_TEMPLATE}
    ${data}    Replace String    ${data}    {id}    ${id}
    ${data}    Replace String    ${data}    {network_id}    ${network_id}
    ${data}    Replace String    ${data}    {tenant_id}    ${tenant_id}
    ${data}    Replace String    ${data}    {name}    ${name}
    Log    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${NEUTRON_SUBNETS_API}    data=${data}    headers=${HEADERS}
    Log    ${resp}
    Log    ${resp.content}
    BuiltIn.Should Match    "${resp.status_code}"    "20?"
    [Return]    ${resp.content}

Verify Tenant Subnet
    [Arguments]    ${network_id}=${TNT1_NET1_ID}    ${tenant_id}=${TNT1_ID}    ${id}=${TNT1_SUBNET1_ID}    ${name}=${TNT1_SUBNET1_NAME}
    [Documentation]    Verify Neutron Tenant Subnet
    ${networks}    NeutronNB.Get Neutron Networks
    BuiltIn.Should Contain    ${networks}    "networks" : [ {
    BuiltIn.Should Contain    ${networks}    "id" : "${id}"
    BuiltIn.Should Contain    ${networks}    "tenant_id" : "${tenant_id}"
    BuiltIn.Should Contain    ${networks}    "name" : "${name}"
    BuiltIn.Should Contain    ${networks}    "provider:segmentation_id" : "${provider_seg_id}"

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

NeutronNB Setup
    Open Controller Karaf Console On Background
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${mininet_conn_id}    SSHKeywords.Open_Connection_To_Tools_System
    ${tools_sys_con_id}    SSHKeywords.Open_Connection_To_Tools_System
