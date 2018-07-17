*** Settings ***
Documentation     Test suite for Cluster HA - Data Recovery at Leader Follower failover and cluster restart
Suite Setup       SetupUtils.Setup_Utils_For_Setup_And_Teardown
Suite Teardown    Delete All Sessions
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/MininetKeywords.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Check Shards Status Before Leader Restart
    [Documentation]    Check Status for all shards in OpenFlow application and set default flows variable.
    ...    Note that Boron and beyond use latest OVS 2.5 which means controller has to push table miss flow,
    ...    therefore Boron+ has 1 flow/switch more than Beryllium.
    ClusterOpenFlow.Check OpenFlow Shards Status

Get inventory Leader Before Leader Restart
    [Documentation]    Find leader in the inventory config shard
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${inventory_leader_old}    ${inventory_leader}
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node1
    [Documentation]    Start mininet with connection to Follower Node1.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_1}_IP}
    Comment    Wait until switch is available in controller
    Wait Until Keyword Succeeds    5s    1s    ClusterOpenFlow.Verify Switch Connections Running On Member    1    ${follower_node_1}
    Set Suite Variable    ${mininet_conn_id}

Add Flows In Follower Node2 and Verify Before Leader Restart
    [Documentation]    Add Flow via Follower Node2 and verify it gets applied from all instances.
    ClusterOpenFlow.Add Sample Flow And Verify    ${follower_node_2}

Stop Mininet Connected To Follower Node1 and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Leader From Cluster Node
    [Documentation]    Stop Leader Node and Start it Up, Verify it is sync with other controller node.
    ClusterManagement.Stop Single Member    ${inventory_leader}
    ClusterManagement.Start Single Member    ${inventory_leader}

Get inventory Follower After Leader Restart
    [Documentation]    Find new Followers and Leader in the inventory config shard After Leader Restart.
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Old Leader
    [Documentation]    Start mininet with connection to cluster old leader.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${inventory_leader_old}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Leader Restart
    [Documentation]    Verify flows are installed in switch after leader restart.
    ClusterOpenFlow.Verify Sample Flow

Stop Mininet Connected To Old Leader and Exit
    [Documentation]    Stop mininet and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Follower Node2
    [Documentation]    Stop Follower Node2 and Start it Up, Verify it is sync with other controller node.
    ClusterManagement.Stop Single Member    ${follower_node_2}
    ClusterManagement.Start Single Member    ${follower_node_2}

Get inventory Follower After Follower Restart
    [Documentation]    Find Followers and Leader in the inventory config shard After Follower Restart.
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Leader
    [Documentation]    Start mininet with connection to Leader.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${inventory_leader}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Follower Restart
    [Documentation]    Verify flows are installed in switch after follower restart.
    ClusterOpenFlow.Verify Sample Flow

Stop Mininet Connected To Leader and Exit
    [Documentation]    Stop mininet Connected To Other Follower and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System

Restart Full Cluster
    [Documentation]    Stop all Cluster Nodes and Start it Up All.
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All

Get inventory Status After Cluster Restart
    [Documentation]    Find New Followers and Leader in the inventory config shard After Cluster Restart.
    ${inventory_leader}    ${inventory_followers}    ClusterOpenFlow.Get InventoryConfig Shard Status
    ${follower_node_1}=    Get From List    ${inventory_followers}    0
    ${follower_node_2}=    Get From List    ${inventory_followers}    1
    Set Suite Variable    ${follower_node_1}
    Set Suite Variable    ${follower_node_2}
    Set Suite Variable    ${inventory_leader}

Start Mininet Connect To Follower Node2 After Cluster Restart
    [Documentation]    Start mininet with connection to cluster Follower Node2.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Single Controller    ${TOOLS_SYSTEM_IP}    ${ODL_SYSTEM_${follower_node_2}_IP}
    Set Suite Variable    ${mininet_conn_id}

Verify Flows In Switch After Cluster Restart
    [Documentation]    Verify flows are installed in switch after cluster restart.
    ClusterOpenFlow.Verify Sample Flow

Delete Flows In Follower Node1 and Verify After Leader Restart
    [Documentation]    Delete Flow in Follower Node1.
    ClusterOpenFlow.Delete Sample Flow and Verify    ${follower_node_1}

Stop Mininet Connected To Follower Node2 and Exit After Cluster Restart
    [Documentation]    Stop mininet Connected To Other Follower and exit connection.
    MininetKeywords.Stop Mininet And Exit    ${mininet_conn_id}
    Utils.Clean Mininet System
