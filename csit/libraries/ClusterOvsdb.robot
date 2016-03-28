*** Settings ***
Documentation     Cluster Ovsdb library. So far this library is only to be used by Ovsdb cluster test as it is very specific for this test.
Library           RequestsLibrary
Resource          ClusterKeywords.robot
Resource          MininetKeywords.robot
Resource          Utils.robot
Resource          OVSDB.robot
Variables         ../variables/Variables.py

*** Variables ***
${BRIDGE}         br01
${OVSDB_CONFIG_DIR}    ${CURDIR}/../variables/ovsdb

*** Keywords ***
Check Ovsdb Shards Status
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Status for all shards in Ovsdb application.
    ${topo_conf_leader}    ${topo_conf_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    config    topology
    ${topo_oper_leader}    ${topo_oper_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    topology
    ${owner_oper_leader}    ${owner_oper_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    entity-ownership
    Log    config topology Leader is ${topo_conf_leader} and followers are ${topo_conf_followers_list}
    Log    operational topology Leader is ${topo_oper_leader} and followers are ${topo_oper_followers_list}
    Log    operational entity-ownership Leader is ${owner_oper_leader} and followers are ${owner_oper_followers_list}

Check Ovsdb Shards Status After Cluster Event
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Shard Status after some cluster event.
    Wait Until Keyword Succeeds    90s    1s    Check Ovsdb Shards Status    ${controller_index_list}

Get Ovsdb Entity Owner Status For One Device
    [Arguments]    ${controller_index_list}    ${device}
    [Documentation]    Check Entity Owner Status and identify owner and candidate for an ovs device ${device}.
    ${owner}    ${candidates_list}    Wait Until Keyword Succeeds    20s    1s    ClusterKeywords.Get Cluster Entity Owner    ${controller_index_list}
    ...    ovsdb    ${device}
    [Return]    ${owner}    ${candidates_list}

Create Sample Bridge Manually And Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Create bridge br-s1 using OVS command and verify it gets created in all instances in ${controller_index_list}.
    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-br br-s1
    ${dictionary_operational}=    Create Dictionary    br-s1=5
    ${dictionary_config}=    Create Dictionary    br-s1=0
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary_config}    ${CONFIG_TOPO_API}
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary_operational}    ${OPERATIONAL_TOPO_API}

Add Sample Port To The Manual Bridge And Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Add Port vx1 to br-s1 using OVS command and verify it gets added in all instances in ${controller_index_list}.
    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl add-port br-s1 vx1 -- set Interface vx1 type=vxlan
    ${dictionary_operational}=    Create Dictionary    vx1=2
    ${dictionary_config}=    Create Dictionary    vx1=0
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary_config}    ${CONFIG_TOPO_API}
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary_operational}    ${OPERATIONAL_TOPO_API}

Delete Sample Bridge Manually And Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Delete bridge br-s1 using OVS command and verify it gets applied in all instances in ${controller_index_list}.
    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-br br-s1
    ${dictionary}=    Create Dictionary    br-s1=0
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Create Sample Bridge And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Create bridge ${BRIDGE} in controller ${controller_index} and verify it gets created in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/ovsdb/create_bridge_3node.json
    ${body}    Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://uuid/${ovsdb_uuid}
    ${body}    Replace String    ${body}    tcp:controller1:6633    tcp:${ODL_SYSTEM_1_IP}:6633
    ${body}    Replace String    ${body}    tcp:controller2:6633    tcp:${ODL_SYSTEM_2_IP}:6633
    ${body}    Replace String    ${body}    tcp:controller3:6633    tcp:${ODL_SYSTEM_3_IP}:6633
    ${body}    Replace String    ${body}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    ${body}    Replace String    ${body}    br01    ${BRIDGE}
    ${body}    Replace String    ${body}    61644    ${OVSDB_PORT}
    Log    ${body}
    ${TOOLS_SYSTEM_IP1}    Replace String    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_IP}    "${TOOLS_SYSTEM_IP}"
    ${dictionary}=    Create Dictionary    ${TOOLS_SYSTEM_IP1}=1    ${OVSDBPORT}=4    ${BRIDGE}=1
    Wait Until Keyword Succeeds    20s    1s    ClusterKeywords.Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}
    ...    ${body}
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}

Create Sample Port And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add Port vx2 to bridge ${BRIDGE} in controller ${controller_index} and verify it gets added in all instances in ${controller_index_list}.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_3node.json
    ${body}    Replace String    ${sample}    192.168.1.10    ${TOOLS_SYSTEM_IP}
    Log    ${body}
    Log    URL is ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point/vx2/
    ${port_dictionary}=    Create Dictionary    ${BRIDGE}=7    vx2=3
    ClusterKeywords.Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point/vx2/    ${body}
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${port_dictionary}    ${OPERATIONAL_TOPO_API}

Modify the destination IP of Sample Port
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Modify the dst ip of port vx2 in bridge ${BRIDGE} in controller ${controller_index}.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port_3node.json
    ${body}    Replace String    ${sample}    192.168.1.10    10.0.0.19
    Log    URL is ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point/vx2/
    Log    ${body}
    ClusterKeywords.Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point/vx2/    ${body}

Verify Sample Port Is Modified
    [Arguments]    ${controller_index_list}
    [Documentation]    Verify dst ip of port vx2 in bridge ${BRIDGE} gets modified in all instances in ${controller_index_list}.
    ${port_dictionary}    Create Dictionary    br01=7    vx2=3    10.0.0.19=1
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${port_dictionary}    ${OPERATIONAL_TOPO_API}

Delete Sample Port And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete port vx2 from bridge ${BRIDGE} in controller ${controller_index} and verify it gets deleted in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    vx2=0
    ClusterKeywords.Delete And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}/termination-point/vx2/
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Delete Sample Bridge And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete bridge ${BRIDGE} in ${controller_index} and verify it gets deleted in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    ${BRIDGE}=0
    Wait Until Keyword Succeeds    20s    1s    ClusterKeywords.Delete And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}%2Fbridge%2F${BRIDGE}
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2Fuuid%2F${ovsdb_uuid}

Configure Exit OVSDB Connection
    [Arguments]    ${controller_index_list}
    [Documentation]    Cleans up test environment, close existing sessions.
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    ${dictionary}=    Create Dictionary    ovsdb://uuid=0
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}
