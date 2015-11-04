*** Settings ***
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Find Leader and Select Follower For Inventory
    [Documentation]    Create original cluster list and find OpenFlow Inventory Leader and Followers.
    ${original_cluster_list}    Create Original Cluster List
    ${original_leader}    ${original_followers_list}    Get Cluster Shard Status    ${original_cluster_list}    inventory
    ${original_follower}=    Get From List    ${original_followers_list}    0
    Set Suite Variable    ${original_cluster_list}
    Set Suite Variable    ${original_leader}
    Set Suite Variable    ${original_follower}

Start Mininet Primary Connection To Follower
    [Documentation]    Start mininet primary connection to follower and checks this becomes the device owner.
    ${mininet_conn}=    Start Mininet Multiple Controllers    ${original_follower}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn}
    ${original_owner}    ${original_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Cluster Entity Owner Status    ${original_cluster_list}
    ...    openflow    openflow:1
    Should Be Equal    ${original_owner}    ${original_follower}    Owner is not the expected follower
    Set Suite Variable    ${original_owner}

Check Operational Network
    [Documentation]    Check Device in Operational topology information.
    ${dictionary}    Create Dictionary    openflow:1=11
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${OPERATIONAL_TOPO_API}

Add Flow In Leader And Verify
    [Documentation]    Add Flow in Leader and verify it gets applied from all instances.
    ${config_uri}=    Set Variable    /restconf/config/opendaylight-inventory:nodes/node/openflow:1/table/0/flow/1
    ${operational_uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/openflowplugin/simple_flow_1.json
    Put And Check At URI In Cluster    ${original_cluster_list}    ${original_leader}    ${config_uri}    ${body}
    ${dictionary}=    Create Dictionary    10.0.1.0/24=1
    Wait Until Keyword Succeeds    5s    1s    Check Item Occurrence At URI In Cluster    ${original_cluster_list}    ${dictionary}    ${operational_uri}

Stop Mininet and Exit
    [Documentation]    Stop mininet and exit connection.
    Stop Mininet And Exit    ${mininet_conn}
