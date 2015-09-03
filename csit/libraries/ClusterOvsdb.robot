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
    ${sample1}    Replace String    ${sample}    tcp:controller1:6633    tcp:${ODL_SYSTEM_1_IP}:6633
    Log    ${sample1}
    ${sample2}    Replace String    ${sample1}    tcp:controller2:6633    tcp:${ODL_SYSTEM_2_IP}:6633
    Log    ${sample2}
    ${sample3}    Replace String    ${sample2}    tcp:controller3:6633    tcp:${ODL_SYSTEM_3_IP}:6633
    Log    ${sample3}
    ${sample4}    Replace String    ${sample3}    127.0.0.1    ${TOOLS_SYSTEM_IP}
    Log    ${sample4}
    ${sample5}    Replace String    ${sample4}    br01    ${BRIDGE}
    Log    ${sample5}
    ${body}    Replace String    ${sample5}    61644    ${OVSDB_PORT}
    Log    ${body}
    ${TOOLS_SYSTEM_IP1}    Replace String    ${TOOLS_SYSTEM_IP}    ${TOOLS_SYSTEM_IP}    "${TOOLS_SYSTEM_IP}"
    ${dictionary}=    Create Dictionary    ${TOOLS_SYSTEM_IP1}=1    ${OVSDBPORT}=4    ${BRIDGE}=1
    Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${SOUTHBOUND_CONFIG_API}%2Fbridge%2F${BRIDGE}    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Take Ovsdb Device Link Down and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take a link down and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    Log    {$CONTROLLER}
    Log    ${CONTROLLER1}
    ${output}=    Send Mininet Command    ${mininet_conn_id}    sudo mn --controller=remote,ip=${CONTROLLER} --topo=linear,2 --switch ovsk,protocols=OpenFlow13
    Log    ${output}
    ${output1}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 down
    Log    ${output1}
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}

Take Ovsdb Device Link Up and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take the link up and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 up
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
