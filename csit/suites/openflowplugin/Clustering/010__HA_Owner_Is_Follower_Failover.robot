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
    ${original_leader}    ${original_followers_list}    Get Shard Status    inventory    ${original_cluster_list}
    ${original_follower}=    Get From List    ${original_followers_list}    0
    Set Suite Variable    ${original_cluster_list}
    Set Suite Variable    ${original_leader}
    Set Suite Variable    ${original_follower}

Start Mininet Primary Connection To Follower
    [Documentation]    Start mininet primary connection to follower and checks this becomes the device owner.
    ${mininet_conn}=    Start Mininet Multiple Controllers    ${original_follower}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn}
    ${original_owner}    ${original_candidates_list}    Wait Until Keyword Succeeds    5s    1s    Get Entity Owner Status    ${original_cluster_list}
    ...    openflow    openflow:1
    Should Be Equal    ${original_owner}    ${original_follower}    Owner is not the expect follower

Stop Mininet and Exit
    Stop Mininet And Exit    ${mininet_conn}
