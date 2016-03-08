*** Settings ***
Documentation     Cluster OpenFlow library. So far this library is only to be used by OpenFlow cluster test as it is very specific for this test.
Library           RequestsLibrary
Resource          ClusterKeywords.robot
Resource          MininetKeywords.robot
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${config_table_0}    ${CONFIG_NODES_API}/node/openflow:1/table/0
${operational_table_0}    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0
${operational_port_1}    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1

*** Keywords ***
Get InventoryConfig Shard Status
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Status for Inventory Config shard in OpenFlow application.
    ${inv_conf_leader}    ${inv_conf_followers_list}    Wait Until Keyword Succeeds    10s    1s    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}
    ...    config    inventory
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    [Return]    ${inv_conf_leader}    ${inv_conf_followers_list}

Check OpenFlow Shards Status
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Status for all shards in OpenFlow application.
    ${inv_conf_leader}    ${inv_conf_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    config    inventory
    ${inv_oper_leader}    ${inv_oper_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
    ${topo_oper_leader}    ${topo_oper_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    topology
    ${owner_oper_leader}    ${owner_oper_followers_list}    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    entity-ownership
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    Log    operational inventory Leader is ${inv_oper_leader} and followers are ${inv_oper_followers_list}
    Log    operational topology Leader is ${topo_oper_leader} and followers are ${topo_oper_followers_list}
    Log    operational entity-ownership Leader is ${owner_oper_leader} and followers are ${owner_oper_followers_list}

Check OpenFlow Shards Status After Cluster Event
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Shards Status after some cluster event.
    Wait Until Keyword Succeeds    90s    1s    ClusterOpenFlow.Check OpenFlow Shards Status    ${controller_index_list}

Get OpenFlow Entity Owner Status For One Device
    [Arguments]    ${controller_index_list}    ${device}
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${owner}    ${candidates_list}    Wait Until Keyword Succeeds    10s    1s    ClusterKeywords.Get Cluster Entity Owner    ${controller_index_list}
    ...    openflow    ${device}
    [Return]    ${owner}    ${candidates_list}

Check OpenFlow Network Operational Information For Sample Topology
    [Arguments]    ${controller_index_list}
    [Documentation]    Check devices in tree,2 are in operational inventory and topology in all instances in ${controller_index_list}.
    ...    Inventory should show 1x node_id per device 1x node_id per connector. Topology should show 2x node_id per device + 3x node_id per connector
    ...    + 5x node_id per link termination. TODO: A Keyword that can calculate this based on mininet topology.
    ${dictionary}    Create Dictionary    openflow:1=4    openflow:2=5    openflow:3=5
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow:1=21    openflow:2=19    openflow:3=19
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Check No OpenFlow Network Operational Information
    [Arguments]    ${controller_index_list}
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances in ${controller_index_list}.
    ${dictionary}    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Add Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_1.json
    # There are slight differences on the way He and Li plugin display table information. He plugin has an additional Hashmap field
    # replicating some of the matches in the flows section. Same comment applies for further keywords.
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"1"=1
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"1"=1
    ClusterKeywords.Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1    ${body}
    Wait Until Keyword Succeeds    15s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Modify Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Modify sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_2.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"2"=1
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"2"=1
    ClusterKeywords.Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1    ${body}
    Wait Until Keyword Succeeds    15s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Delete Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete sample flow in Owner and verify it gets removed from all instances.
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    ClusterKeywords.Delete And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Send RPC Add Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/add_flow_rpc.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1
    ${resp}    RequestsLibrary.Post Request    controller${controller_index}    /restconf/operations/sal-flow:add-flow    data=${body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    15s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Send RPC Delete Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete sample flow in ${controller_index} and verify it gets removed from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ${resp}    RequestsLibrary.Post Request    controller${controller_index}    /restconf/operations/sal-flow:remove-flow    data=${body}    headers=${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Take OpenFlow Device Link Down and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take a link down and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${ouput}=    MininetKeywords.Send Mininet Command    ${mininet_conn_id}    link s1 s2 down
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_port_1}
    ${dictionary}    Create Dictionary    openflow:1=16    openflow:2=14    openflow:3=19
    Wait Until Keyword Succeeds    20s    2s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Take OpenFlow Device Link Up and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take the link up and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    MininetKeywords.Send Mininet Command    ${mininet_conn_id}    link s1 s2 up
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_port_1}
    ${dictionary}    Create Dictionary    openflow:1=21    openflow:2=19    openflow:3=19
    Wait Until Keyword Succeeds    5s    1s    ClusterKeywords.Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}
