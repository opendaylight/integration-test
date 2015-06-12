*** Settings ***
Documentation     Checking Network created in OVSDB are pushed to OpenDaylight
Suite Setup       Create Session    ODLSession    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
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
${ODLREST}        /controller/nb/v2/neutron
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${TNT1_ID}        cde2563ead464ffa97963c59e002c0cf
${EXT_NET1_ID}    7da709ff-397f-4778-a0e8-994811272fdb
${EXT_SUBNET1_ID}    00289199-e288-464a-ab2f-837ca67101a7
${TNT1_RTR_ID}    e09818e7-a05a-4963-9927-fc1dc6f1e844
${NEUTRON_PORT_TNT1_RTR_GW}    8ddd29db-f417-4917-979f-b01d4b1c3e0d
${NEUTRON_PORT_TNT1_RTR_NET1}    9cc1af22-108f-40bb-b938-f1da292236bf
${TNT1_NET1_NAME}    net1
${TNT1_NET1_SEGM}    1062
${TNT1_NET1_ID}    12809f83-ccdf-422c-a20a-4ddae0712655
${TNT1_SUBNET1_NAME}    subnet1
${TNT1_SUBNET1_ID}    6c496958-a787-4d8c-9465-f4c4176652e8
${TNT1_NET1_DHCP_PORT_ID}    79adcba5-19e0-489c-9505-cc70f9eba2a1
${TNT1_NET1_DHCP_MAC}    FA:16:3E:8F:70:A9
${TNT1_NET1_DHCP_DEVICE_ID}    dhcp58155ae3-f2e7-51ca-9978-71c513ab02ee-${TNT1_NET1_ID}
${TNT1_NET1_DHCP_OVS_PORT}    tap79adcba5-19
${TNT1_VM1_PORT_ID}    341ceaca-24bf-4017-9b08-c3180e86fd24
${TNT1_VM1_MAC}    FA:16:3E:8E:B8:05
${TNT1_VM1_DEVICE_ID}    20e500c3-41e1-4be0-b854-55c710a1cfb2
${TNT1_NET1_VM1_OVS_PORT}    tap341ceaca-24
${TNT1_VM1_VM_ID}    20e500c3-41e1-4be0-b854-55c710a1cfb2
${FLOAT_IP1_ID}    f013bef4-9468-494d-9417-c9d9e4abb97c
${FLOAT_IP1_PORT_ID}    01671703-695e-4497-8a11-b5da989d2dc3
${FLOAT_IP1_MAC}    FA:16:3E:3F:37:BB
${FLOAT_IP1_DEVICE_ID}    f013bef4-9468-494d-9417-c9d9e4abb97c
${FLOAT_IP1_ADDRESS}    192.168.111.22

*** Test Cases ***
Check External Net for Tenant
    [Documentation]    Check External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${resp}    RequestsLibrary.Get    ODLSession    ${ODLREST}/networks
    log    http://${CONTROLLER}:${RESTCONFPORT}${ODLREST}
    Should be Equal As Strings    ${resp.status_code}    200

Create External Net for Tenant
    [Documentation]    Create External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/networks    data=${Data}    headers=${HEADERS}
    log    ${resp.status_code}
    Should be Equal As Strings    ${resp.status_code}    201

Create External Subnet
    [Documentation]    Create External Subnet
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_subnet.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/subnets    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Create Tenant Router
    [Documentation]    Create Tenant Router
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_router.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/routers    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Set Router Gateway
    [Documentation]    Set Router Gateway
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_rtr_gateway.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${NEUTRON_PORT_TNT1_RTR_GW}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/ports    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Update Router Port Gateway
    [Documentation]    Update Router Port Gateway
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/update_router_port_gateway.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${NEUTRON_PORT_TNT1_RTR_GW}
    log    ${Data}
    ${resp}    RequestsLibrary.Put    ODLSession    ${ODLREST}/routers/${TNT1_RTR_ID}    ${Data}
    Should be Equal As Strings    ${resp.status_code}    200

Create Tenant Internal Net
    [Documentation]    Create Tenant Internal Net
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_tnt_net.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {netName}    ${TNT1_NET1_NAME}
    ${Data}    Replace String    ${Data}    {netSegm}    ${TNT1_NET1_SEGM}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/networks    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Create Tenant Internal Subnet
    [Documentation]    Create Tenant Internal Subnet
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_tnt_subnet.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {subnetName}    ${TNT1_SUBNET1_NAME}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/subnets    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Create Port DHCP
    [Documentation]    Create Port DHCP
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_dhcp.json
    ${Data}    Replace String    ${Data}    {BIND_HOST_ID}    ${CONTROLLER}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {dhcpDeviceId}    ${TNT1_NET1_DHCP_DEVICE_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {dhcpMac}    ${TNT1_NET1_DHCP_MAC}
    ${Data}    Replace String    ${Data}    {dhcpId}    ${TNT1_NET1_DHCP_PORT_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/ports    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Update Port DHCP
    [Documentation]    Update Port DHCP
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/update_port_dhcp.json
    ${Data}    Replace String    ${Data}    {BIND_HOST_ID}    ${CONTROLLER}
    ${Data}    Replace String    ${Data}    {dhcpDeviceId}    ${TNT1_NET1_DHCP_DEVICE_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Put    ODLSession    ${ODLREST}/ports/${TNT1_NET1_DHCP_PORT_ID}    ${Data}
    Should be Equal As Strings    ${resp.status_code}    200

Create Router Interface on Tenant Internal Subnet
    [Documentation]    Create Router Interface on Tenant Internal Subnet
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_rtr_interface.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${NEUTRON_PORT_TNT1_RTR_NET1}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/ports    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Update Router Interface on Tenant Internal Subnet
    [Documentation]    Update Router Interface on Tenant Internal Subnet
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/update_router_interface.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${NEUTRON_PORT_TNT1_RTR_NET1}
    log    ${Data}
    ${resp}    RequestsLibrary.Put    ODLSession    ${ODLREST}/routers/${TNT1_RTR_ID}/add_router_interface    ${Data}
    Should be Equal As Strings    ${resp.status_code}    200

Create Port VM
    [Documentation]    Create Port VM
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_vm.json
    ${Data}    Replace String    ${Data}    {BIND_HOST_ID}    ${CONTROLLER}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${TNT1_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${TNT1_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${TNT1_VM1_PORT_ID}
    ${Data}    Replace String    ${Data}    {macAddr}    ${TNT1_VM1_MAC}
    ${Data}    Replace String    ${Data}    {deviceId}    ${TNT1_VM1_DEVICE_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/ports    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Create Port Floating IP
    [Documentation]    Create Port Floating IP
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_floating_ip.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    ${Data}    Replace String    ${Data}    {portId}    ${FLOAT_IP1_PORT_ID}
    ${Data}    Replace String    ${Data}    {macAddress}    ${FLOAT_IP1_MAC}
    ${Data}    Replace String    ${Data}    {deviceId}    ${FLOAT_IP1_DEVICE_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/ports    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Create Floating IP
    [Documentation]    Create Floating IP
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_floating_ip.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {floatIpId}    ${FLOAT_IP1_ID}
    ${Data}    Replace String    ${Data}    {floatIpAddress}    ${FLOAT_IP1_ADDRESS}
    log    ${Data}
    ${resp}    RequestsLibrary.Post    ODLSession    ${ODLREST}/floatingips    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201

Associate the Floating IP with Tenant VM
    [Documentation]    Associate the Floating IP with Tenant VM
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/associate_floating_ip.json
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {rtrId}    ${TNT1_RTR_ID}
    ${Data}    Replace String    ${Data}    {floatIpId}    ${FLOAT_IP1_ID}
    ${Data}    Replace String    ${Data}    {floatIpAddress}    ${FLOAT_IP1_ADDRESS}
    ${Data}    Replace String    ${Data}    {vmPortId}    ${TNT1_VM1_PORT_ID}
    log    ${Data}
    ${resp}    RequestsLibrary.Put    ODLSession    ${ODLREST}/floatingips/${FLOAT_IP1_ID}    ${Data}
    Should be Equal As Strings    ${resp.status_code}    201