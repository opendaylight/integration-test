*** Settings ***
Documentation       Cluster Ovsdb library. So far this library is only to be used by Ovsdb cluster test as it is very specific for this test.

Library             Collections
Library             RequestsLibrary
Resource            ClusterManagement.robot
Resource            CompareStream.robot
Resource            MininetKeywords.robot
Resource            Utils.robot
Resource            OVSDB.robot
Resource            ../variables/ovsdb/Variables.robot
Variables           ../variables/Variables.py


*** Variables ***
@{SHARD_OPER_LIST}      topology    default    entity-ownership
@{SHARD_CONF_LIST}      topology    default
${BRIDGE}               br01
${OVSDB_CONFIG_DIR}     ${CURDIR}/../variables/ovsdb


*** Keywords ***
Check Ovsdb Shards Status
    [Documentation]    Check Status for all shards in Ovsdb application.
    [Arguments]    ${controller_index_list}=${EMPTY}
    CompareStream.Run_Keyword_If_At_Least_Phosphorus
    ...    Collections.Remove Values From List
    ...    ${SHARD_OPER_LIST}
    ...    entity-ownership
    Log    ${SHARD_OPER_LIST}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard
    ...    shard_name_list=${SHARD_OPER_LIST}
    ...    shard_type=operational
    ...    member_index_list=${controller_index_list}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard
    ...    shard_name_list=${SHARD_CONF_LIST}
    ...    shard_type=config
    ...    member_index_list=${controller_index_list}

Check Ovsdb Shards Status After Cluster Event
    [Documentation]    Check Shard Status after some cluster event.
    [Arguments]    ${controller_index_list}=${EMPTY}
    Wait Until Keyword Succeeds    90s    1s    Check Ovsdb Shards Status    ${controller_index_list}

Get Ovsdb Entity Owner Status For One Device
    [Documentation]    Check Entity Owner Status and identify owner and successors for an ovs device ${device}. Request is sent to controller ${controller_index}.
    [Arguments]    ${device}    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${owner}    ${successor_list}    Wait Until Keyword Succeeds
    ...    20s
    ...    1s
    ...    ClusterManagement.Verify_Owner_And_Successors_For_Device
    ...    device_name=${device}
    ...    device_type=ovsdb
    ...    member_index=${controller_index}
    ...    candidate_list=${controller_index_list}
    RETURN    ${owner}    ${successor_list}

Create Sample Bridge Manually And Verify
    [Documentation]    Create bridge br-s1 using OVS command and verify it gets created in all instances in ${controller_index_list}.
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}
    Utils.Run Command On Mininet    ${ovs_system_ip}    sudo ovs-vsctl add-br br-s1
    ${dictionary_operational}    Create Dictionary    br-s1=5
    ${dictionary_config}    Create Dictionary    br-s1=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_CONFIG_TOPO_API}
    ...    dictionary=${dictionary_config}
    ...    member_index_list=${controller_index_list}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary_operational}
    ...    member_index_list=${controller_index_list}

Add Sample Port To The Manual Bridge And Verify
    [Documentation]    Add Port vx1 to br-s1 using OVS command and verify it gets added in all instances in ${controller_index_list}.
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}
    Utils.Run Command On Mininet
    ...    ${ovs_system_ip}
    ...    sudo ovs-vsctl add-port br-s1 vx1 -- set Interface vx1 type=vxlan
    ${dictionary_operational}    Create Dictionary    vx1=2
    ${dictionary_config}    Create Dictionary    vx1=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_CONFIG_TOPO_API}
    ...    dictionary=${dictionary_config}
    ...    member_index_list=${controller_index_list}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary_operational}
    ...    member_index_list=${controller_index_list}

Create Sample Tap Device
    [Documentation]    Create Tap Device vport1 and vport2 to add to the bridge br-s1 using OVS command.
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}
    Utils.Run Command On Mininet    ${ovs_system_ip}    ip tuntap add mode tap vport1
    Utils.Run Command On Mininet    ${ovs_system_ip}    ip tuntap add mode tap vport2
    Utils.Run Command On Mininet    ${ovs_system_ip}    ifconfig vport1 up
    Utils.Run Command On Mininet    ${ovs_system_ip}    ifconfig vport2 up

Add Sample Tap Device To The Manual Bridge And Verify
    [Documentation]    Add Tap Device vport1 and vport2 to br-s1 using OVS command and verify it gets added in all instances in ${controller_index_list}.
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}
    Utils.Run Command On Mininet    ${ovs_system_ip}    sudo ovs-vsctl add-port br-s1 vport1 -- add-port br-s1 vport2
    ${dictionary_operational}    Create Dictionary    vport1=2    vport2=2
    ${dictionary_config}    Create Dictionary    vport1=0    vport2=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_CONFIG_TOPO_API}
    ...    dictionary=${dictionary_config}
    ...    member_index_list=${controller_index_list}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary_operational}
    ...    member_index_list=${controller_index_list}

Delete Sample Bridge Manually And Verify
    [Documentation]    Delete bridge br-s1 using OVS command and verify it gets applied in all instances in ${controller_index_list}.
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}
    Utils.Run Command On Mininet    ${ovs_system_ip}    sudo ovs-vsctl del-br br-s1
    ${dictionary}    Create Dictionary    br-s1=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Create Sample Bridge And Verify
    [Documentation]    Create bridge ${BRIDGE} in controller ${controller_index} and verify it gets created in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${body}    OperatingSystem.Get File    ${CURDIR}/../variables/ovsdb/create_bridge_3node.json
    ${body}    Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://uuid/${ovsdb_uuid}
    ${body}    Replace String    ${body}    tcp:controller1:6633    tcp:${ODL_SYSTEM_1_IP}:6633
    ${body}    Replace String    ${body}    tcp:controller2:6633    tcp:${ODL_SYSTEM_2_IP}:6633
    ${body}    Replace String    ${body}    tcp:controller3:6633    tcp:${ODL_SYSTEM_3_IP}:6633
    ${body}    Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    br01    ${BRIDGE}
    ${body}    Replace String    ${body}    61644    ${OVSDB_PORT}
    Log    ${body}
    ${TOOLS_SYSTEM_IP1}    Replace String    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_IP}    "${TOOLS_SYSTEM_IP}"
    ${dictionary}    Create Dictionary    ${TOOLS_SYSTEM_IP1}=1    ${OVSDBPORT}=4    ${BRIDGE}=1
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All
    ...    ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}
    ...    ${body}
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}?${RFC8040_OPERATIONAL_CONTENT}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Create Sample Port And Verify
    [Documentation]    Add Port vx2 to bridge ${BRIDGE} in controller ${controller_index} and verify it gets added in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_3node.json
    ${body}    Replace String    ${sample}    192.168.1.10    ${TOOLS_SYSTEM_IP}
    Log    ${body}
    Log    URL is ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point=vx2
    ${port_dictionary}    Create Dictionary    ${BRIDGE}=1    vx2=3
    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All
    ...    ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point=vx2
    ...    ${body}
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point=vx2?${RFC8040_OPERATIONAL_CONTENT}
    ...    dictionary=${port_dictionary}
    ...    member_index_list=${controller_index_list}

Modify the destination IP of Sample Port
    [Documentation]    Modify the dst ip of port vx2 in bridge ${BRIDGE} in controller ${controller_index}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_3node.json
    ${body}    Replace String    ${sample}    192.168.1.10    10.0.0.19
    Log    URL is ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point=vx2
    Log    ${body}
    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All
    ...    ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point=vx2
    ...    ${body}
    ...    ${controller_index}
    ...    ${controller_index_list}

Verify Sample Port Is Modified
    [Documentation]    Verify dst ip of port vx2 in bridge ${BRIDGE} gets modified in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index_list}=${EMPTY}
    ${port_dictionary}    Create Dictionary    br01=6    vx2=3    10.0.0.19=1
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}?${RFC8040_OPERATIONAL_CONTENT}
    ...    dictionary=${port_dictionary}
    ...    member_index_list=${controller_index_list}

Delete Sample Port And Verify
    [Documentation]    Delete port vx2 from bridge ${BRIDGE} in controller ${controller_index} and verify it gets deleted in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${dictionary}    Create Dictionary    vx2=0
    ClusterManagement.Delete_And_Check_Member_List_Or_All
    ...    ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point=vx2
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}?${RFC8040_OPERATIONAL_CONTENT}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Delete Sample Bridge And Verify
    [Documentation]    Delete bridge ${BRIDGE} in ${controller_index} and verify it gets deleted in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${dictionary}    Create Dictionary    ${BRIDGE}=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Delete_And_Check_Member_List_Or_All
    ...    ${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_SOUTHBOUND_NODE_API}uuid%2F${ovsdb_uuid}?${RFC8040_OPERATIONAL_CONTENT}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Configure Exit OVSDB Connection
    [Documentation]    Cleans up test environment, close existing sessions.
    [Arguments]    ${controller_index_list}=${EMPTY}
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ${dictionary}    Create Dictionary    ovsdb://uuid=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}
