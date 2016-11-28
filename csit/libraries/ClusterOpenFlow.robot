*** Settings ***
Documentation     Cluster OpenFlow library. So far this library is only to be used by OpenFlow cluster test as it is very specific for this test.
Library           RequestsLibrary
Library           ${CURDIR}/ScaleClient.py
Resource          ClusterManagement.robot
Resource          MininetKeywords.robot
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
@{SHARD_OPER_LIST}    inventory    topology    default    entity-ownership
@{SHARD_CONF_LIST}    inventory    topology    default
${config_table_0}    ${CONFIG_NODES_API}/node/openflow:1/table/0
${operational_table_0}    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0
${operational_port_1}    ${OPERATIONAL_NODES_API}/node/openflow:1/node-connector/openflow:1:1

*** Keywords ***
Get InventoryConfig Shard Status
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check Status for Inventory Config shard in OpenFlow application.
    ${inv_conf_leader}    ${inv_conf_followers_list}    Wait Until Keyword Succeeds    10s    1s    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=inventory
    ...    shard_type=config    member_index_list=${controller_index_list}
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    [Return]    ${inv_conf_leader}    ${inv_conf_followers_list}

Check OpenFlow Shards Status
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_OPER_LIST}    shard_type=operational    member_index_list=${controller_index_list}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard    shard_name_list=${SHARD_CONF_LIST}    shard_type=config    member_index_list=${controller_index_list}

Check OpenFlow Shards Status After Cluster Event
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check Shards Status after some cluster event.
    Wait Until Keyword Succeeds    90s    1s    ClusterOpenFlow.Check OpenFlow Shards Status    ${controller_index_list}

Get OpenFlow Entity Owner Status For One Device
    [Arguments]    ${device}    ${controller_index}    ${controller_index_list}=${EMPTY}    ${after_stop}=False
    [Documentation]    Check Entity Owner Status and identify owner and successors for the device ${device}. Request is sent to controller ${controller_index}.
    ${owner}    ${successor_list}    Wait Until Keyword Succeeds    10s    1s    ClusterManagement.Verify_Owner_And_Successors_For_Device    device_name=${device}
    ...    device_type=openflow    member_index=${controller_index}    candidate_list=${controller_index_list}    ${after_stop}
    [Return]    ${owner}    ${successor_list}

Check OpenFlow Device Owner
    [Arguments]    ${device}    ${controller_index}    ${expected_owner}    ${expected_candidate_list}=${EMPTY}
    [Documentation]    Check owner and candidates for the device ${device}. Request is sent to controller ${controller_index}.
    ${owner}    ${successor_list}    ClusterManagement.Verify_Owner_And_Successors_For_Device    device_name=${device}    device_type=openflow    member_index=${controller_index}    candidate_list=${expected_candidate_list}
    Should Be Equal    ${owner}    ${expected_owner}

Check OpenFlow Network Operational Information For Sample Topology
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check devices in tree,2 are in operational inventory and topology in all instances in ${controller_index_list}.
    ...    Inventory should show 1x node_id per device 1x node_id per connector. Topology should show 2x node_id per device + 3x node_id per connector
    ...    + 5x node_id per link termination. TODO: A Keyword that can calculate this based on mininet topology.
    ${dictionary}    Create Dictionary    openflow:1=4    openflow:2=5    openflow:3=5
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_NODES_API}    dictionary=${dictionary}    member_index_list=${controller_index_list}
    ${dictionary}    Create Dictionary    openflow:1=21    openflow:2=19    openflow:3=19
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_TOPO_API}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Check No OpenFlow Network Operational Information
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances in ${controller_index_list}.
    ${dictionary}    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_NODES_API}    dictionary=${dictionary}    member_index_list=${controller_index_list}
    ${dictionary}    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_TOPO_API}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Add Sample Flow And Verify
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_1.json
    # There are slight differences on the way He and Li plugin display table information. He plugin has an additional Hashmap field
    # replicating some of the matches in the flows section. Same comment applies for further keywords.
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"1"=1
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"1"=1
    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All    ${config_table_0}/flow/1    ${body}    ${controller_index}    ${controller_index_list}
    Wait Until Keyword Succeeds    15s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_table_0}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Verify Sample Flow
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Verify sample flow gets applied in all instances in ${controller_index_list}.
    # There are slight differences on the way He and Li plugin display table information. He plugin has an additional Hashmap field
    # replicating some of the matches in the flows section. Same comment applies for further keywords.
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"1"=1
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"1"=1
    Wait Until Keyword Succeeds    15s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_table_0}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Modify Sample Flow And Verify
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    [Documentation]    Modify sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_2.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"2"=1
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"2"=1
    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All    ${config_table_0}/flow/1    ${body}    ${controller_index}    ${controller_index_list}
    Wait Until Keyword Succeeds    15s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_table_0}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Delete Sample Flow And Verify
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    [Documentation]    Delete sample flow in Owner and verify it gets removed from all instances.
    ${dictionary}=    Create Dictionary    10.0.2.0/24=0
    ClusterManagement.Delete_And_Check_Member_List_Or_All    ${config_table_0}/flow/1    ${controller_index}    ${controller_index_list}
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_table_0}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Send RPC Add Sample Flow And Verify
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/add_flow_rpc.json
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'helium'    Set Test Variable    &{dictionary}    10.0.1.0/24=2
    Run Keyword If    '${ODL_OF_PLUGIN}' == 'lithium'    Set Test Variable    &{dictionary}    10.0.1.0/24=1
    ClusterManagement.Post_As_Json_To_Member    uri=/restconf/operations/sal-flow:add-flow    data=${body}    member_index=${controller_index}
    Wait Until Keyword Succeeds    15s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_table_0}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Send RPC Delete Sample Flow And Verify
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    [Documentation]    Delete sample flow in ${controller_index} and verify it gets removed from all instances in ${controller_index_list}.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ClusterManagement.Post_As_Json_To_Member    uri=/restconf/operations/sal-flow:remove-flow    data=${body}    member_index=${controller_index}
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_table_0}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Take OpenFlow Device Link Down and Verify
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Take a link down and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${ouput}=    MininetKeywords.Send Mininet Command    ${mininet_conn_id}    link s1 s2 down
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_port_1}    dictionary=${dictionary}    member_index_list=${controller_index_list}
    ${dictionary}    Create Dictionary    openflow:1=16    openflow:2=14    openflow:3=19
    Wait Until Keyword Succeeds    20s    2s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_TOPO_API}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Take OpenFlow Device Link Up and Verify
    [Arguments]    ${controller_index_list}=${EMPTY}
    [Documentation]    Take the link up and verify port status in all instances in ${controller_index_list}.
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    MininetKeywords.Send Mininet Command    ${mininet_conn_id}    link s1 s2 up
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${operational_port_1}    dictionary=${dictionary}    member_index_list=${controller_index_list}
    ${dictionary}    Create Dictionary    openflow:1=21    openflow:2=19    openflow:3=19
    Wait Until Keyword Succeeds    5s    1s    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All    uri=${OPERATIONAL_TOPO_API}    dictionary=${dictionary}    member_index_list=${controller_index_list}

Verify_Switch_Connections_Running_On_Member
    [Arguments]    ${switch_count}    ${member_index}
    [Documentation]    Check if number of Switch connections on member of given index is equal to ${switch_count}.
    ${count} =    ScaleClient.Get_Switches_Count    controller=${ODL_SYSTEM_${member_index}_IP}
    BuiltIn.Should_Be_Equal_As_Numbers    ${switch_count}    ${count}

Check_Flows_Operational_Datastore_On_Member
    [Arguments]    ${flow_count}    ${member_index}
    [Documentation]    Check if number of Operational Flows on member of given index is equal to ${flow_count}.
    ${sw}    ${reported_flow}    ${found_flow}=    ScaleClient.Flow Stats Collected    controller=${ODL_SYSTEM_${member_index}_IP}
    BuiltIn.Should_Be_Equal_As_Numbers    ${flow_count}    ${found_flow}
