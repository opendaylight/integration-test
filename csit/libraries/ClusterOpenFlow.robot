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
Check OpenFlow Shards Status
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Status for all shards in OpenFlow application.
    ${inv_conf_leader}    ${inv_conf_followers_list}    Get Cluster Shard Status    ${controller_index_list}    config    inventory
    ${inv_oper_leader}    ${inv_oper_followers_list}    Get Cluster Shard Status    ${controller_index_list}    operational    inventory
    ${topo_oper_leader}    ${topo_oper_followers_list}    Get Cluster Shard Status    ${controller_index_list}    operational    topology
    ${owner_oper_leader}    ${owner_oper_followers_list}    Get Cluster Shard Status    ${controller_index_list}    operational    entity-ownership
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    Log    operational inventory Leader is ${inv_oper_leader} and followers are ${inv_oper_followers_list}
    Log    operational topology Leader is ${topo_oper_leader} and followers are ${topo_oper_followers_list}
    Log    operational entity-ownership Leader is ${owner_oper_leader} and followers are ${owner_oper_followers_list}

Check OpenFlow Shards Status After Cluster Event
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    Wait Until Keyword Succeeds    90s    1s    Check OpenFlow Shards Status    ${controller_index_list}

Get OpenFlow Cluster Entity Owner Status
    [Arguments]    ${controller_index_list}    ${device_type}    ${device}
    [Documentation]    Checks OpenFlow Entity Owner status for a ${device} and returns owner index and list of candidates from a ${controller_index_list}.
    ...    ${device_type} is normally openflow.
    ${length}=    Get Length    ${controller_index_list}
    ${candidates_list}=    Create List
    ${data}=    Get Data From URI    controller@{controller_index_list}[0]    /restconf/operational/entity-owners:entity-owners
    Log    ${data}
    ${data}=    Replace String    ${data}    /general-entity:entity[general-entity:name='    ${EMPTY}
    ${clear_data}=    Replace String    ${data}    ']    ${EMPTY}
    Log    ${clear_data}
    ${json}=    To Json    ${clear_data}
    ${entity_type_list}=    Get From Dictionary    &{json}[entity-owners]    entity-type
    ${entity_type_index}=    Get Index From List Of Dictionaries    ${entity_type_list}    type    ${device_type}
    Should Not Be Equal    ${entity_type_index}    -1    No Entity Owner found for ${device_type}
    ${entity_list}=    Get From Dictionary    @{entity_type_list}[${entity_type_index}]    entity
    ${entity_index}=    Get Index From List Of Dictionaries    ${entity_list}    id    ${device}
    Should Not Be Equal    ${entity_index}    -1    Device ${device} not found in Entity Owner ${device_type}
    ${entity_owner}=    Get From Dictionary    @{entity_list}[${entity_index}]    owner
    Should Not Be Empty    ${entity_owner}    No owner found for ${device}
    ${owner}=    Replace String    ${entity_owner}    member-    ${EMPTY}
    ${owner}=    Convert To Integer    ${owner}
    List Should Contain Value    ${controller_index_list}    ${owner}    Owner ${owner} not exisiting in ${controller_index_list}
    ${entity_candidates_list}=    Get From Dictionary    @{entity_list}[${entity_index}]    candidate
    ${list_length}=    Get Length    ${entity_candidates_list}
    : FOR    ${entity_candidate}    IN    @{entity_candidates_list}
    \    ${candidate}=    Replace String    &{entity_candidate}[name]    member-    ${EMPTY}
    \    ${candidate}=    Convert To Integer    ${candidate}
    \    Run Keyword If    '${candidate}' != '${owner}'    Append To List    ${candidates_list}    ${candidate}
    [Return]    ${owner}    ${candidates_list}

Get OpenFlow Entity Owner Status For One Device
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${owner}    ${candidates_list}    Wait Until Keyword Succeeds    10s    1s    Get OpenFlow Cluster Entity Owner Status    ${controller_index_list}
    ...    openflow    openflow:1
    [Return]    ${owner}    ${candidates_list}

Check OpenFlow Network Operational Information For One Device
    [Arguments]    ${controller_index_list}
    [Documentation]    Check device openflow:1 is in operational inventory and topology in all instances in ${controller_index_list}.
    ...    Inventory should show 1x node_id per device 1x node_id per connector. Topology should show 2x node_id per device + 3x node_id per connector.
    ${dictionary}    Create Dictionary    openflow:1=4
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow:1=11
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Check No OpenFlow Network Operational Information
    [Arguments]    ${controller_index_list}
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances in ${controller_index_list}.
    ${dictionary}    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Add Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_1.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1
    Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1    ${body}
    Wait Until Keyword Succeeds    15s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Modify Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Modify sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_2.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.2.0/24=2
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.2.0/24=1
    Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1    ${body}
    Wait Until Keyword Succeeds    15s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Delete Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete sample flow in Owner and verify it gets removed from all instances.
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    Delete And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Send RPC Add Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/add_flow_rpc.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1
    ${resp}    RequestsLibrary.Post Request    controller${controller_index}    /restconf/operations/sal-flow:add-flow    ${body}    ${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    15s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Send RPC Delete Sample Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete sample flow in ${controller_index} and verify it gets removed from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ${resp}    RequestsLibrary.Post Request    controller${controller_index}    /restconf/operations/sal-flow:remove-flow    ${body}    ${HEADERS_YANG_JSON}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Take OpenFlow Device Link Down and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take a link down and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 down
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_port_1}

Take OpenFlow Device Link Up and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take the link up and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 up
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_port_1}
