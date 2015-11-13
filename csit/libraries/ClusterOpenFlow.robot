*** Settings ***
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
    [Documentation]    Create original cluster list and check Status for all shards in OpenFlow application.
    ${inv_conf_leader}    ${inv_conf_followers_list}    Wait Until Keyword Succeeds    10s    1s    Get Cluster Shard Status    ${controller_index_list}
    ...    config    inventory
    ${inv_oper_leader}    ${inv_oper_followers_list}    Wait Until Keyword Succeeds    10s    1s    Get Cluster Shard Status    ${controller_index_list}
    ...    operational    inventory
    ${topo_oper_leader}    ${topo_oper_followers_list}    Wait Until Keyword Succeeds    10s    1s    Get Cluster Shard Status    ${controller_index_list}
    ...    operational    topology
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    Log    operational inventory Leader is ${inv_oper_leader} and followers are ${inv_oper_followers_list}
    Log    operational topology Leader is ${topo_oper_leader} and followers are ${topo_oper_followers_list}

Check Network Operational Information
    [Arguments]    ${controller_index_list}
    [Documentation]    Check device is in operational inventory and topology in all instances in ${controller_index_list}.
    ...    Inventory should show 1x node_id per device 1x node_id per connector. Topology should show 2x node_id per device + 3x node_id per connector.
    ${dictionary}    Create Dictionary    openflow:1=4
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow:1=11
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Check No Network Operational Information
    [Arguments]    ${controller_index_list}
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances in ${controller_index_list}.
    ${dictionary}    Create Dictionary    openflow:1=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow:1=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Add Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add Flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_1.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Modify Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Modify Flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_2.json
    ${dictionary}=    Create Dictionary    10.0.2.0/24=1
    Put And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Delete Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    Delete And Check At URI In Cluster    ${controller_index_list}    ${controller_index}    ${config_table_0}/flow/1
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Send RPC Add Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Add Flow in ${controller_index} and verify it gets applied from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/add_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    ${resp}    RequestsLibrary.Post Request    controller${controller_index}    /restconf/operations/sal-flow:add-flow    ${body}    ${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Send RPC Delete Flow And Verify
    [Arguments]    ${controller_index_list}    ${controller_index}
    [Documentation]    Delete Flow in ${controller_index} and verify it gets removed from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ${resp}    RequestsLibrary.Post Request    controller${controller_index}    /restconf/operations/sal-flow:remove-flow    ${body}    ${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_table_0}

Take a Link Down and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take a link down and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 down
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_port_1}

Take a Link Up and Verify
    [Arguments]    ${controller_index_list}
    [Documentation]    Take the link up and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 up
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${controller_index_list}    ${dictionary}    ${operational_port_1}
