*** Settings ***
Documentation     Cluster Ovsdb library. So far this library is only to be used by Ovsdb cluster test as it is very specific for this test.
Library           RequestsLibrary
Resource          ClusterKeywords.robot
Resource          MininetKeywords.robot
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Check Ovsdb Shards Status
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Status for all shards in Ovsdb application.
    ${topo_conf_leader}    ${topo_conf_followers_list}    Wait Until Keyword Succeeds    10s    1s    Get Cluster Shard Status    ${controller_index_list}
    ...    config    topology
    ${topo_oper_leader}    ${topo_oper_followers_list}    Wait Until Keyword Succeeds    10s    1s    Get Cluster Shard Status    ${controller_index_list}
    ...    operational    topology
    Log    config topology Leader is ${topo_conf_leader} and followers are ${topo_conf_followers_list}
    Log    operational topology Leader is ${topo_oper_leader} and followers are ${topo_oper_followers_list}

Get Ovsdb Entity Owner Status For One Device
    [Arguments]    ${controller_index_list}
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${owner}    ${candidates_list}    Wait Until Keyword Succeeds    10s    1s    Get Cluster Entity Owner For Ovsdb    ${controller_index_list}
    ...    ovsdb    ovsdb:1
    [Return]    ${owner}    ${candidates_list}

Get Cluster Entity Owner For Ovsdb
    [Arguments]    ${controller_index_list}    ${device_type}    ${device}
    [Documentation]    Checks Entity Owner status for a ${device} and returns owner index and list of candidates from a ${controller_index_list}.
    ...    ${device_type} is openflow, ovsdb, etc...
    ${length}=    Get Length    ${controller_index_list}
    ${candidates_list}=    Create List
    ${data}=    Get Data From URI    controller@{controller_index_list}[0]    /restconf/operational/entity-owners:entity-owners
    Log    ${data}
    ${data}=    Replace String    ${data}    /network-topology:network-topology/network-topology:topology[network-topology:topology-id='    ${EMPTY}
    ${data}=    Replace String    ${data}    /network-topology:node[network-topology:node-id='ovsdb://uuid/a96ec4e2-c457-4a2c-963c-1e6300210032    ${EMPTY}
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
    \    List Should Contain Value    ${controller_index_list}    ${candidate}    Candidate ${candidate} not exisiting in ${controller_index_list}
    \    Run Keyword If    '${candidate}' != '${owner}'    Append To List    ${candidates_list}    ${candidate}
    [Return]    ${owner}    ${candidates_list}

Create Bridge And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Create bridge in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${sample}=    OperatingSystem.Get File    ${CURDIR}/../variables/ovsdb/create_bridge_3node.json
    Log    ${sample}
    ${sample1}    Replace String    ${sample}    tcp:controller1:6633    tcp:${ODL_SYSTEM_1_IP}:6640
    Log    ${sample1}
    ${sample2}    Replace String    ${sample1}    tcp:controller2:6633    tcp:${ODL_SYSTEM_2_IP}:6640
    Log    ${sample2}
    ${sample3}    Replace String    ${sample2}    tcp:controller3:6633    tcp:${ODL_SYSTEM_3_IP}:6640
    Log    ${sample3}
    ${sample4}    Replace String    ${sample3}    127.0.0.1    ${MININET}
    Log    ${sample4}
    ${sample5}    Replace String    ${sample4}    br01    ${BRIDGE}
    Log    ${sample5}
    ${body}    Replace String    ${sample5}    61644    ${OVSDB_PORT}
    Log    ${body}
    ${dictionary}=    Create Dictionary    ${MININET}=1    ${OVSDBPORT}=4    ${BRIDGE}=1
    Put And Check At URI In Cluster Ovsdb    ${controller_index_list}    ${controller_index}    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Put And Check At URI In Cluster Ovsdb
    [Arguments]    ${controller_index_list}    ${controller_index}    ${uri}    ${body}    ${headers}=${HEADERS}
    [Documentation]    Send a PUT with the supplied ${uri} and ${body} to a ${controller_index}
    ...    and check the data is replicated in all instances in ${controller_index_list}.
    ${expected_body}=    To Json    ${body}
    ${resp}    RequestsLibrary.Put Request    controller${controller_index}    ${uri}    ${body}    ${headers}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${data}    Wait Until Keyword Succeeds    5s    1s    Get Data From URI    controller${i}
    \    ...    ${uri}    ${headers}
    \    Log    ${data}
    \    ${received_body}    To Json    ${data}
    \    Check Expected And Received Body    ${expected_body}    ${received_body}

Check Expected And Received Body
    [Arguments]    ${expected_body}    ${received_body}
    [Documentation]    Checks whether the expected data and the actual received data are equal.
    Log    ${expected_body}
    Log    ${received_body}
    ${content1}    Get From Dictionary    ${expected_body}    node
    Log    ${content1}
    ${node1}    Get From List    ${content1}    0
    Log    ${node1}
    ${expected_bridge_name}    Get From Dictionary    ${node1}    ovsdb:bridge-name
    Log    ${expected_bridge_name}
    ${expected_target_ips}    Get From Dictionary    ${node1}    ovsdb:controller-entry
    Log    ${expected_target_ips}
    Sort List    ${expected_target_ips}
    Log    ${expected_target_ips}
    ${content2}    Get From Dictionary    ${received_body}    node
    Log    ${content2}
    ${node2}    Get From List    ${content2}    0
    Log    ${node2}
    ${received_bridge_name}    Get From Dictionary    ${node2}    ovsdb:bridge-name
    Log    ${received_bridge_name}
    ${received_target_ips}    Get From Dictionary    ${node2}    ovsdb:controller-entry
    Log    ${received_target_ips}
    Sort List    ${received_target_ips}
    Log    ${received_target_ips}
    Should Be Equal As Strings    ${received_bridge_name}    ${expected_bridge_name}
    Lists Should be Equal    ${received_target_ips}    ${expected_target_ips}
