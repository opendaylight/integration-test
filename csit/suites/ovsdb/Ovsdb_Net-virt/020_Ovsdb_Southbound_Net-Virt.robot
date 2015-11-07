*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot

*** Variables ***
${ODLREST}        /controller/nb/v2/neutron
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${MININET}:${OVSDBPORT}
${OVSDB_CONFIG_DIR}    ${CURDIR}/../../../variables/ovsdb
${BRIDGE}         br01
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
@{node_list}      ovsdb://uuid/
@{netvirt}        1

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Check Shards Status Before Fail
    [Documentation]    Check Status for all shards in Ovsdb application.
    Check Ovsdb Shards Status    ${original_cluster_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}    Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}
    Log    ${mininet_conn_id}

Ensure controller is running
    [Documentation]    Check if the cluster controllers are running before sending restconf requests
    [Tags]    Check controller reachability
    ${node}    Create Dictionary    node-id=ovsdb://uuid/
     Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${node}    ${OPERATIONAL_TOPO_API}

Check netvirt is Created
    [Documentation]    Check if the netvirt piece has been loaded into the cluster karaf instance
    [Tags]    Ensure netvirt is loaded
    ${topology-id}    Create Dictionary    netvirt=1
    Wait Until Keyword Succeeds    300s    4s    Check Item Occurrence At URI In Cluster       ${original_cluster_list}    ${topology-id}    ${OPERATIONAL_NODES_NETVIRT}

Check External Net for Tenant
    [Documentation]    Check External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${resp}    Get Data From URI    controller1    ${ODLREST}/networks    ${HEADER}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Create External Net for Tenant
    [Documentation]    Create External Net for Tenant
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_net.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Put Request    controller1    ${ODLREST}/networks    ${Data}    ${headers}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    201

Create External Subnet
    [Documentation]    Create External Subnet
    [Tags]    OpenStack Call Flow
    ${Data}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_ext_subnet.json
    ${Data}    Replace String    ${Data}    {netId}    ${EXT_NET1_ID}
    ${Data}    Replace String    ${Data}    {tntId}    ${TNT1_ID}
    ${Data}    Replace String    ${Data}    {subnetId}    ${EXT_SUBNET1_ID}
    Log    ${Data}
    ${resp}    RequestsLibrary.Put Request    controller1    ${ODLREST}/subnets    ${Data}    ${headers}
    Should Be Equal As Strings    ${resp.status_code}    201
