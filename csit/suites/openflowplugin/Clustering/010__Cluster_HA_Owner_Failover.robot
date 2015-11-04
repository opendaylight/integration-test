*** Settings ***
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${config_table_0}    ${CONFIG_NODES_API}/node/openflow:1/table/0
${operational_table_0}    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0
${operational_port_1}    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1

*** Test Cases ***
Check OpenFlow Shards Status
    [Documentation]    Create original cluster list and Check Status for all shards in OpenFlow application.
    ${original_cluster_list}    Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    ${inv_conf_leader}    ${inv_conf_followers_list}    Get Cluster Shard Status    ${original_cluster_list}    config    inventory
    ${inv_oper_leader}    ${inv_oper_followers_list}    Get Cluster Shard Status    ${original_cluster_list}    operational    inventory
    ${topo_oper_leader}    ${topo_oper_followers_list}    Get Cluster Shard Status    ${original_cluster_list}    operational    topology
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    Log    operational inventory Leader is ${inv_oper_leader} and followers are ${inv_oper_followers_list}
    Log    operational topology Leader is ${topo_oper_leader} and followers are ${topo_oper_followers_list}

Start Mininet Multiple Connections
    [Documentation]    Start mininet with connection to all cluster instances.
    ${mininet_conn_id}=    Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn_id}

Check Entity Owner Status And Find Owner and Candidate
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Cluster Entity Owner Status    ${original_cluster_list}
    ...    openflow    openflow:1
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Check Network Operational Information
    [Documentation]    Check device is in operational inventory and topology in all cluster instances.
    ...    Inventory should show 1x node_id per device 1x node_id per connector. Topology should show 2x node_id per device + 3x node_id per connector.
    ${dictionary}    Create Dictionary    openflow:1=4
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow:1=11
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Add Flow In Owner and Verify
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/sample_flow_1.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_owner}    ${config_table_0}/flow/1    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Modify Flow In Owner and Verify
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/sample_flow_2.json
    ${dictionary}=    Create Dictionary    10.0.2.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_owner}    ${config_table_0}/flow/1    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Delete Flow In Owner and Verify
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    Delete And Check At URI In Cluster    ${original_cluster_list}    ${original_owner}    ${config_table_0}/flow/1
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Add Flow In Candidate and Verify
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/sample_flow_1.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_candidate}    ${config_table_0}/flow/1    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Modify Flow In Candidate and Verify
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/sample_flow_2.json
    ${dictionary}=    Create Dictionary    10.0.2.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_candidate}    ${config_table_0}/flow/1    ${body}    ${HEADERS}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Delete Flow In Candidate and Verify
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    Delete And Check At URI In Cluster    ${original_cluster_list}    ${original_candidate}    ${config_table_0}/flow/1
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Send RPC Add Flow to Owner and Verify
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/add_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    ${resp}    RequestsLibrary.Post Request    controller${original_owner}    /restconf/operations/sal-flow:add-flow    ${body}    ${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Send RPC Delete Flow to Owner and Verify
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ${resp}    RequestsLibrary.Post Request    controller${original_owner}    /restconf/operations/sal-flow:remove-flow    ${body}    ${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Send RPC Add Flow to Candidate and Verify
    [Documentation]    Add Flow in Candidate and verify it gets applied from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/add_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    ${resp}    RequestsLibrary.Post Request    controller${original_candidate}    /restconf/operations/sal-flow:add-flow    ${body}    ${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Send RPC Delete Flow to Candidate and Verify
    [Documentation]    Delete Flow in Candidate and verify it gets removed from all instances.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ${resp}    RequestsLibrary.Post Request    controller${original_candidate}    /restconf/operations/sal-flow:remove-flow    ${body}    ${HEADERS}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_table_0}

Take a Link Down and Verify
    [Documentation]    Take a link down and verify port status in all instances.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 down
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_port_1}

Take a Link Up and Verify
    [Documentation]    Take the link up and verify port status in all instances.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    Send Mininet Command    ${mininet_conn_id}    link s1 h1 up
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_port_1}

Stop Mininet and Exit
    [Documentation]    Stop mininet and exit connection.
    Stop Mininet And Exit    ${mininet_conn_id}
    Clean Mininet System

Check No Network Operational Information
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances.
    ${dictionary}    Create Dictionary    openflow:1=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_NODES_API}
    ${dictionary}    Create Dictionary    openflow:1=0
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}
