*** Settings ***
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***

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
    ${mininet_conn}=    Start Mininet Multiple Controllers    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn}

Check Entity Owner Status And Find Owner and Candidate
    [Documentation]    Check Entity Owner Status and identify owner and candidate.
    ${original_owner}    ${original_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Cluster Entity Owner Status    ${original_cluster_list}
    ...    openflow    openflow:1
    ${original_candidate}=    Get From List    ${original_candidates_list}    0
    Set Suite Variable    ${original_owner}
    Set Suite Variable    ${original_candidate}

Check Network Operational Information
    [Documentation]    Check device is in operational topology in all cluster instances.
    ${dictionary}    Create Dictionary    openflow:1=11
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Add Flow In Owner and Verify
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/simple_flow_1.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_owner}    ${config_uri}    ${body}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Modify Flow In Owner and Verify
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/simple_flow_2.json
    ${dictionary}=    Create Dictionary    10.0.2.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_owner}    ${config_uri}    ${body}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Delete Flow In Owner and Verify
    [Documentation]    Delete Flow in Owner and verify it gets applied from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    Delete And Check At URI In Cluster    ${original_cluster_list}    ${original_owner}    ${config_uri}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Add Flow In Candidate and Verify
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/simple_flow_1.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_candidate}    ${config_uri}    ${body}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Modify Flow In Candidate and Verify
    [Documentation]    Modify Flow in Owner and verify it gets applied from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/simple_flow_2.json
    ${dictionary}=    Create Dictionary    10.0.2.0/24=1
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_candidate}    ${config_uri}    ${body}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Delete Flow In Candidate and Verify
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    Delete And Check At URI In Cluster    ${original_cluster_list}    ${original_candidate}    ${config_uri}
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Send RPC Add Flow to Owner and Verify
    [Documentation]    Add Flow in Owner and verify it gets applied from all instances.
    ${rpc_uri}=    Set Variable    /restconf/operations/sal-flow:add-flow
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/add_flow_rpc.xml
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    ${resp}    RequestsLibrary.Post Request    controller${original_owner}    ${rpc_uri}    ${body}    ${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Send RPC Delete Flow to Owner and Verify
    [Documentation]    Delete Flow in Owner and verify it gets removed from all instances.
    ${rpc_uri}=    Set Variable    /restconf/operations/sal-flow:remove-flow
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/delete_flow_rpc.xml
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ${resp}    RequestsLibrary.Post Request    controller${original_owner}    ${rpc_uri}    ${body}    ${HEADERS_XML}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Wait Until Keyword Succeeds    10s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Take a Link Down and Verify
    [Documentation]    Take a link down and verify port status in all instances.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/node-connector/openflow:1:1
    ${ouput}=    Send Mininet Command    ${mininet_conn}    link s1 h1 down
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Take a Link Up and Verify
    [Documentation]    Take the link up and verify port status in all instances.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/node-connector/openflow:1:1
    ${ouput}=    Send Mininet Command    ${mininet_conn}    link s1 h1 up
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Stop Mininet and Exit
    [Documentation]    Stop mininet and exit connection.
    Stop Mininet And Exit    ${mininet_conn}
