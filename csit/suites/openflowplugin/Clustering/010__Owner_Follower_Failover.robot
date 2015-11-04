*** Settings ***
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Find Leader and Select Follower For Inventory
    @{cluster_list}    Create Original Cluster List
    ${leader}    @{followers}    Get Shard Status    inventory    @{cluster_list}
    ${follower}=    Get From List    ${followers}    0
    Set Suite Variable    @{original_cluster_list}    @{cluster_list}
    Set Suite Variable    ${original_leader}    ${leader}

