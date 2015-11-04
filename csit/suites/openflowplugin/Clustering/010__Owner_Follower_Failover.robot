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
    ${original_cluster_list}    Create Original Cluster List
    ${original_leader}    ${original_followers_list}    Get Shard Status    inventory    ${original_cluster_list}
    ${original_follower}=    Get From List    ${original_followers_list}    0
    Set Suite Variable    ${original_cluster_list}
    Set Suite Variable    ${original_leader}
    Set Suite Variable    ${original_follower}

Start Mininet with Primary Connection To Follower
    ${mininet_conn}=    Start Mininet Multiple Controllers    ${original_follower}    ${original_cluster_list}
    Set Suite Variable    ${mininet_conn}
    Sleep    5

Stop Mininet and Exit
    Stop Mininet And Exit    ${mininet_conn}
