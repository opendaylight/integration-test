*** Settings ***
Documentation       Cluster OpenFlow library. So far this library is only to be used by OpenFlow cluster test as it is very specific for this test.

Library             Collections
Library             RequestsLibrary
Library             ${CURDIR}/ScaleClient.py
Resource            ClusterManagement.robot
Resource            CompareStream.robot
Resource            MininetKeywords.robot
Resource            Utils.robot
Resource            ../variables/openflowplugin/Variables.robot
Variables           ../variables/Variables.py


*** Variables ***
@{SHARD_OPER_LIST}          inventory    topology    default    entity-ownership
@{SHARD_CONF_LIST}          inventory    topology    default
${config_table_0}           ${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0
${operational_table_0}
...                         ${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0?${RFC8040_OPERATIONAL_CONTENT}
${operational_port_1}
...                         ${RFC8040_NODES_API}/node=openflow%3A1/node-connector=openflow%3A1%3A1?${RFC8040_OPERATIONAL_CONTENT}


*** Keywords ***
Get InventoryConfig Shard Status
    [Documentation]    Check Status for Inventory Config shard in OpenFlow application.
    [Arguments]    ${controller_index_list}=${EMPTY}
    ${inv_conf_leader}    ${inv_conf_followers_list}=    Wait Until Keyword Succeeds
    ...    10s
    ...    1s
    ...    ClusterManagement.Get_Leader_And_Followers_For_Shard
    ...    shard_name=inventory
    ...    shard_type=config
    ...    member_index_list=${controller_index_list}
    Log    config inventory Leader is ${inv_conf_leader} and followers are ${inv_conf_followers_list}
    RETURN    ${inv_conf_leader}    ${inv_conf_followers_list}

Check OpenFlow Shards Status
    [Documentation]    Check Status for all shards in OpenFlow application.
    [Arguments]    ${controller_index_list}=${EMPTY}
    CompareStream.Run_Keyword_If_At_Least_Phosphorus
    ...    Collections.Remove Values From List
    ...    ${SHARD_OPER_LIST}
    ...    entity-ownership
    Log    ${SHARD_OPER_LIST}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard
    ...    shard_name_list=${SHARD_OPER_LIST}
    ...    shard_type=operational
    ...    member_index_list=${controller_index_list}
    ClusterManagement.Verify_Leader_Exists_For_Each_Shard
    ...    shard_name_list=${SHARD_CONF_LIST}
    ...    shard_type=config
    ...    member_index_list=${controller_index_list}

Check OpenFlow Shards Status After Cluster Event
    [Documentation]    Check Shards Status after some cluster event.
    [Arguments]    ${controller_index_list}=${EMPTY}
    Wait Until Keyword Succeeds
    ...    90s
    ...    1s
    ...    ClusterOpenFlow.Check OpenFlow Shards Status
    ...    ${controller_index_list}

Get OpenFlow Entity Owner Status For One Device
    [Documentation]    Check Entity Owner Status and identify owner and successors for the device ${device}. Request is sent to controller ${controller_index}.
    [Arguments]    ${device}    ${controller_index}    ${controller_index_list}=${EMPTY}    ${after_stop}=False
    ${owner}    ${successor_list}=    Wait Until Keyword Succeeds
    ...    30s
    ...    1s
    ...    ClusterManagement.Verify_Owner_And_Successors_For_Device
    ...    device_name=${device}
    ...    device_type=openflow
    ...    member_index=${controller_index}
    ...    candidate_list=${controller_index_list}
    ...    after_stop=${after_stop}
    RETURN    ${owner}    ${successor_list}

Check OpenFlow Device Owner
    [Documentation]    Check owner and candidates for the device ${device}. Request is sent to controller ${controller_index}.
    [Arguments]    ${device}    ${controller_index}    ${expected_owner}    ${expected_candidate_list}=${EMPTY}
    ${owner}    ${successor_list}=    ClusterManagement.Verify_Owner_And_Successors_For_Device
    ...    device_name=${device}
    ...    device_type=openflow
    ...    member_index=${controller_index}
    ...    candidate_list=${expected_candidate_list}
    Should Be Equal    ${owner}    ${expected_owner}

Check OpenFlow Network Operational Information For Sample Topology
    [Documentation]    Check devices in tree,2 are in operational inventory and topology in all instances in ${controller_index_list}.
    ...    Inventory should show 1x node_id per device 1x node_id per connector. Topology should show 2x node_id per device + 3x node_id per connector
    ...    + 5x node_id per link termination. TODO: A Keyword that can calculate this based on mininet topology.
    [Arguments]    ${controller_index_list}=${EMPTY}
    ${dictionary}=    Create Dictionary    openflow:1=4    openflow:2=5    openflow:3=5
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_NODES_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}
    ${dictionary}=    Create Dictionary    openflow:1=21    openflow:2=19    openflow:3=19
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Check No OpenFlow Network Operational Information
    [Documentation]    Check device is not in operational inventory or topology in all cluster instances in ${controller_index_list}.
    [Arguments]    ${controller_index_list}=${EMPTY}
    ${dictionary}=    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_No_Content_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_NODES_API}
    ...    member_index_list=${controller_index_list}
    ${dictionary}=    Create Dictionary    openflow=0
    Wait Until Keyword Succeeds
    ...    20s
    ...    2s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Add Sample Flow And Verify
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_1.json
    # There are slight differences on the way He and Li plugin display table information. He plugin has an additional Hashmap field
    # replicating some of the matches in the flows section. Same comment applies for further keywords.
    IF    '${ODL_OF_PLUGIN}' == 'helium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"1"=1
    END
    IF    '${ODL_OF_PLUGIN}' == 'lithium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"1"=1
    END
    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All
    ...    ${config_table_0}/flow=1
    ...    ${body}
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    15s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_table_0}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Verify Sample Flow
    [Documentation]    Verify sample flow gets applied in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index_list}=${EMPTY}
    # There are slight differences on the way He and Li plugin display table information. He plugin has an additional Hashmap field
    # replicating some of the matches in the flows section. Same comment applies for further keywords.
    IF    '${ODL_OF_PLUGIN}' == 'helium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"1"=1
    END
    IF    '${ODL_OF_PLUGIN}' == 'lithium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"1"=1
    END
    Wait Until Keyword Succeeds
    ...    15s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_table_0}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Modify Sample Flow And Verify
    [Documentation]    Modify sample flow in ${controller_index} and verify it gets applied in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/sample_flow_2.json
    IF    '${ODL_OF_PLUGIN}' == 'helium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=2    "output-node-connector":"2"=1
    END
    IF    '${ODL_OF_PLUGIN}' == 'lithium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=1    "output-node-connector":"2"=1
    END
    ClusterManagement.Put_As_Json_And_Check_Member_List_Or_All
    ...    ${config_table_0}/flow=1
    ...    ${body}
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    15s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_table_0}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Delete Sample Flow And Verify
    [Documentation]    Delete sample flow in Owner and verify it gets removed from all instances.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ClusterManagement.Delete_And_Check_Member_List_Or_All
    ...    ${config_table_0}/flow=1
    ...    ${controller_index}
    ...    ${controller_index_list}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_table_0}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Send RPC Add Sample Flow And Verify
    [Documentation]    Add sample flow in ${controller_index} and verify it gets applied from all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/add_flow_rpc.json
    IF    '${ODL_OF_PLUGIN}' == 'helium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=2
    END
    IF    '${ODL_OF_PLUGIN}' == 'lithium'
        Set Test Variable    &{dictionary}    10.0.1.0/24=1
    END
    ClusterManagement.Post_As_Json_To_Member
    ...    uri=/rests/operations/sal-flow:add-flow
    ...    data=${body}
    ...    member_index=${controller_index}
    Wait Until Keyword Succeeds
    ...    15s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_table_0}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Send RPC Delete Sample Flow And Verify
    [Documentation]    Delete sample flow in ${controller_index} and verify it gets removed from all instances in ${controller_index_list}.
    [Arguments]    ${controller_index}    ${controller_index_list}=${EMPTY}
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/delete_flow_rpc.json
    ${dictionary}=    Create Dictionary    10.0.1.0/24=0
    ClusterManagement.Post_As_Json_To_Member
    ...    uri=/rests/operations/sal-flow:remove-flow
    ...    data=${body}
    ...    member_index=${controller_index}
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_table_0}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Take OpenFlow Device Link Down and Verify
    [Documentation]    Take a link down and verify port status in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index_list}=${EMPTY}
    ${dictionary}=    Create Dictionary    "link-down":true=1
    ${ouput}=    MininetKeywords.Send Mininet Command    ${mininet_conn_id}    link s1 s2 down
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_port_1}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}
    ${dictionary}=    Create Dictionary    openflow:1=16    openflow:2=14    openflow:3=19
    Wait Until Keyword Succeeds
    ...    20s
    ...    2s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Take OpenFlow Device Link Up and Verify
    [Documentation]    Take the link up and verify port status in all instances in ${controller_index_list}.
    [Arguments]    ${controller_index_list}=${EMPTY}
    ${dictionary}=    Create Dictionary    "link-down":true=0
    ${ouput}=    MininetKeywords.Send Mininet Command    ${mininet_conn_id}    link s1 s2 up
    Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${operational_port_1}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}
    ${dictionary}=    Create Dictionary    openflow:1=21    openflow:2=19    openflow:3=19
    Wait Until Keyword Succeeds
    ...    10s
    ...    1s
    ...    ClusterManagement.Check_Item_Occurrence_Member_List_Or_All
    ...    uri=${RFC8040_OPERATIONAL_TOPO_API}
    ...    dictionary=${dictionary}
    ...    member_index_list=${controller_index_list}

Verify Switch Connections Running On Member
    [Documentation]    Check if number of Switch connections on member of given index is equal to ${switch_count}.
    [Arguments]    ${switch_count}    ${member_index}
    ${count}=    ScaleClient.Get_Switches_Count    controller=${ODL_SYSTEM_${member_index}_IP}
    BuiltIn.Should_Be_Equal_As_Numbers    ${switch_count}    ${count}

Check Flows Operational Datastore On Member
    [Documentation]    Check if number of Operational Flows on member of given index is equal to ${flow_count}.
    [Arguments]    ${flow_count}    ${member_index}
    ${sw}    ${reported_flow}    ${found_flow}=    ScaleClient.Flow Stats Collected
    ...    controller=${ODL_SYSTEM_${member_index}_IP}
    BuiltIn.Should_Be_Equal_As_Numbers    ${flow_count}    ${found_flow}

Check Linear Topology On Member
    [Documentation]    Check Linear topology.
    [Arguments]    ${switches}    ${member_index}=1
    ${session}=    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${resp}=    RequestsLibrary.GET On Session
    ...    ${session}
    ...    url=${RFC8040_OPERATIONAL_TOPO_API}
    ...    expected_status=200
    Log    ${resp.text}
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        Should Contain    ${resp.text}    "node-id":"openflow:${switch}"
        Should Contain    ${resp.text}    "tp-id":"openflow:${switch}:1"
        Should Contain    ${resp.text}    "tp-id":"openflow:${switch}:2"
        Should Contain    ${resp.text}    "source-tp":"openflow:${switch}:2"
        Should Contain    ${resp.text}    "dest-tp":"openflow:${switch}:2"
        ${edge}=    Evaluate    ${switch}==1 or ${switch}==${switches}
        IF    not ${edge}
            Should Contain    ${resp.text}    "tp-id":"openflow:${switch}:3"
        END
        IF    not ${edge}
            Should Contain    ${resp.text}    "source-tp":"openflow:${switch}:3"
        END
        IF    not ${edge}
            Should Contain    ${resp.text}    "dest-tp":"openflow:${switch}:3
        END
    END

Check No Switches On Member
    [Documentation]    Check no switch is in topology
    [Arguments]    ${switches}    ${member_index}=1
    ${session}=    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${resp}=    RequestsLibrary.GET On Session
    ...    ${session}
    ...    url=${RFC8040_OPERATIONAL_TOPO_API}
    ...    expected_status=200
    Log    ${resp.text}
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        Should Not Contain    ${resp.text}    openflow:${switch}
    END

Check Number Of Flows On Member
    [Documentation]    Check number of flows in the inventory.
    [Arguments]    ${flows}    ${member_index}=1
    ${session}=    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${resp}=    RequestsLibrary.GET On Session
    ...    ${session}
    ...    url=${RFC8040_OPERATIONAL_NODES_API}
    ...    expected_status=200
    Log    ${resp.text}
    ${count}=    Get Count    ${resp.text}    "priority"
    Should Be Equal As Integers    ${count}    ${flows}

Check Number Of Groups On Member
    [Documentation]    Check number of groups in the inventory.
    [Arguments]    ${groups}    ${member_index}=1
    ${session}=    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${resp}=    RequestsLibrary.GET On Session
    ...    ${session}
    ...    url=${RFC8040_OPERATIONAL_NODES_API}
    ...    expected_status=200
    Log    ${resp.text}
    ${group_count}=    Get Count    ${resp.text}    "group-type"
    Should Be Equal As Integers    ${group_count}    ${groups}
