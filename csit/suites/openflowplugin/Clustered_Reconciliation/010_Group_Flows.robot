*** Settings ***
Documentation     Switch connections and cluster are restarted.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OvsManager.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SWITCHES}       3
${ITER}           100
${VAR_DIR}        ${CURDIR}/../../../variables/openflowplugin

*** Test Cases ***
Add Groups And Flows
    [Documentation]    Add ${ITER} groups 1&2 and flows in every switch.
    Add Groups And Flows On Member    ${ITER}

Start Mininet Multiple Connections
    [Documentation]    Start mininet linear with connection to all cluster instances.
    ${cluster_index_list}=    ClusterManagement.List All Indices
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${cluster_index_list}    --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
    BuiltIn.Set Suite Variable    ${cluster_index_list}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    ${SWITCHES*3}

Check Linear Topology
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Linear Topology On Member    ${SWITCHES}

Check Stats Are Not Frozen
    [Documentation]    Check that duration flow stat is increasing.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen

Check Flows In Operational DS
    [Documentation]    Check Flows in operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${all_flows}

Check Groups In Operational DS
    [Documentation]    Check Groups in operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${all_groups}

Check Flows In Switch
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Check Entity Owner Status And Find Owner and Successor Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${original_owner}    ${original_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${new_cluster_list}    ${original_successor_list}

Disconnect Mininet From Owner
    [Documentation]    Disconnect mininet from the owner
    ${original_owner_list}    BuiltIn.Create List    ${original_owner}
    MininetKeywords.Disconnect Cluster Mininet    break    ${original_owner_list}
    BuiltIn.Set Suite Variable    ${original_owner_list}

Check Entity Owner Status And Find Owner and Successor After Fail
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${new_owner}    ${new_successor_list}    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1
    ...    1    ${new_cluster_list}    after_stop=True
    ${owner_list}=    BuiltIn.Create List    ${original_owner}    ${new_owner}
    BuiltIn.Set Suite Variable    ${owner_list}
    BuiltIn.Set Suite Variable    ${new_owner}
    BuiltIn.Set Suite Variable    ${new_successor_list}

Check Switch Moves To New Master
    [Documentation]    Check switch s1 is connected to new Master.
    ${new_master}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${new_owner}_IP}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OvsManager.Should Be Master    s1    ${new_master}    update_data=${True}

Check Linear Topology After Disconnect
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Linear Topology On Member    ${SWITCHES}

Check Stats Are Not Frozen After Disconnect
    [Documentation]    Check that duration flow stat is increasing
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen

Remove Flows And Groups After Mininet Is Disconnected
    [Documentation]    Remove 1 group 1&2 and 1 flow in every switch.
    Remove Single Group And Flow On Member

Check Flows In Operational DS After Mininet Is Disconnected
    [Documentation]    Check Flows in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${less_flows}

Check Groups In Operational DS After Mininet Is Disconnected
    [Documentation]    Check Groups in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${less_groups}

Check Flows In Switch After Mininet Is Disconnected
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Reconnect Mininet To Owner
    [Documentation]    Reconnect mininet to switch 1 owner.
    MininetKeywords.Disconnect Cluster Mininet    restore    ${original_owner_list}

Check Entity Owner Status And Find Owner and Successor After Reconnect
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1

Add Flows And Groups After Owner Reconnect
    [Documentation]    Add 1 group type 1&2 and 1 flow in every switch.
    Add Single Group And Flow On Member

Check Stats Are Not Frozen After Owner Reconnect
    [Documentation]    Check that duration flow stat is increasing.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen

Check Flows After Owner Reconnect In Operational DS
    [Documentation]    Check Flows in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${all_flows}

Check Groups After Owner Reconnect In Operational DS
    [Documentation]    Check Groups in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${all_groups}

Check Flows After Owner Reconnect In Switch
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Check Switches Generate Slave Connection
    [Documentation]    Check switches are connected to new Slave.
    ${original_master}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${original_owner}_IP}
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    BuiltIn.Wait Until Keyword Succeeds    50s    1s    OvsManager.Should Be Slave    s${switch}    ${original_master}
    \    ...    update_data=${True}

Disconnect Mininet From Successor
    [Documentation]    Disconnect mininet from the Successor.
    MininetKeywords.Disconnect Cluster Mininet    break    ${new_successor_list}

Check Entity Owner Status And Find New Owner and Successor After Disconnect
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${current_owner}    ${current_successor_list}    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1
    ...    1    ${owner_list}    after_stop=True
    BuiltIn.Set Suite Variable    ${current_owner}
    BuiltIn.Set Suite Variable    ${current_successor_list}

Disconnect Mininet From Current Owner
    [Documentation]    Disconnect mininet from the owner
    ${current_owner_list}=    BuiltIn.Create List    ${current_owner}
    MininetKeywords.Disconnect Cluster Mininet    break    ${current_owner_list}

Check Entity Owner Status And Find Current Owner and Successor After Disconnect
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${current_new_owner}    ${current_new_successor_list}    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1
    ...    1    ${original_owner_list}    after_stop=True
    BuiltIn.Set Suite Variable    ${current_new_owner}
    BuiltIn.Set Suite Variable    ${current_new_successor_list}

Check Switch Moves To Current Master
    [Documentation]    Check switch s1 is connected to original Master.
    ${current_new_master}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${current_new_owner}_IP}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OvsManager.Should Be Master    s1    ${current_new_master}    update_data=${True}
    BuiltIn.Should Be Equal    ${current_new_owner}    ${original_owner}

Check Linear Topology After Owner Disconnect
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Linear Topology On Member    ${SWITCHES}

Check Stats Are Not Frozen After Owner Disconnect
    [Documentation]    Check that duration flow stat is increasing.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen

Remove Flows And Groups After Owner Disconnected
    [Documentation]    Remove 1 group 1&2 and 1 flow in every switch.
    Remove Single Group And Flow On Member

Check Flows In Operational DS After Owner Disconnected
    [Documentation]    Check Flows in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${less_flows}

Check Groups In Operational DS After Owner Disconnected
    [Documentation]    Check Groups in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${less_groups}

Check Flows In Switch After Owner Disconnected
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Disconnect Mininet From Cluster
    [Documentation]    Disconnect Mininet from Cluster.
    MininetKeywords.Disconnect Cluster Mininet    break    ${original_owner_list}

Check No Switches After Disconnect
    [Documentation]    Check no switches in topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check No Switches On Member    ${SWITCHES}

Check Switch Is Not Connected
    [Documentation]    Check switch s1 is not connected to any controller.
    : FOR    ${index}    IN    @{cluster_index_list}
    \    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OvsManager.Should Be Disconnected    s1    ${ODL_SYSTEM_${index}_IP}
    \    ...    update_data=${True}

Reconnect Mininet To Cluster
    [Documentation]    Reconnect mininet to cluster by removing Iptables drop rules that were used to disconnect
    MininetKeywords.Disconnect Cluster Mininet    restore

Check Linear Topology After Mininet Reconnects
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Linear Topology On Member    ${SWITCHES}

Add Flows And Groups After Mininet Reconnects
    [Documentation]    Add 1 group type 1&2 and 1 flow in every switch.
    Add Single Group And Flow On Member

Check Flows In Operational DS After Mininet Reconnects
    [Documentation]    Check Flows in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${all_flows}

Check Groups In Operational DS After Mininet Reconnects
    [Documentation]    Check Groups in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${all_groups}

Check Flows In Switch After Mininet Reconnects
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Check Entity Owner Status And Find Owner and Successor Before Owner Stop
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${original_owner}    ${original_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1
    ${original_successor}=    Collections.Get From List    ${original_successor_list}    0
    BuiltIn.Set Suite Variable    ${original_owner}
    BuiltIn.Set Suite Variable    ${original_successor_list}
    BuiltIn.Set Suite Variable    ${original_successor}

Check Switch Generates Slave Connection Before Owner Stop
    [Documentation]    Check switch s1 is connected to Slave.
    ${original_slave}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${original_successor}_IP}
    BuiltIn.Wait Until Keyword Succeeds    50s    1s    OvsManager.Should Be Slave    s1    ${original_slave}    update_data=${True}

Check Shards Status Before Owner Stop
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status

Stop Owner Instance
    [Documentation]    Stop Owner Instance and verify it is shutdown
    ClusterManagement.Stop Single Member    ${original_owner}
    BuiltIn.Set Suite Variable    ${new_cluster_list}    ${original_successor_list}

Check Shards Status After Stop
    [Documentation]    Check Status for all shards in OpenFlow application.
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event    ${new_cluster_list}

Check Entity Owner Status And Find Owner and Successor After Stop
    [Documentation]    Check Entity Owner Status and identify owner and successor.
    ${new_owner}    ${new_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    ${original_successor}    ${new_cluster_list}    after_stop=True
    BuiltIn.Set Suite Variable    ${new_owner}

Check Stats Are Not Frozen After Owner Stop
    [Documentation]    Check that duration flow stat is increasing in new owner.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen    ${new_owner}

Remove Configuration In Owner and Verify After Owner Stop
    [Documentation]    Remove 1 group 1&2 and 1 flow in every switch.
    Remove Single Group And Flow On Member    ${new_owner}

Check Flows After Owner Stop In Operational DS
    [Documentation]    Check Flows in Operational DS in new owner.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${less_flows}    ${new_owner}

Check Groups After Owner Stop In Operational DS
    [Documentation]    Check Groups in Operational DS in new owner.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${less_groups}    ${new_owner}

Check Flows In Switch After Owner Stop
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Start Old Owner Instance
    [Documentation]    Start old Owner Instance and verify it is up.
    ClusterManagement.Start Single Member    ${original_owner}

Check Entity Owner Status And Find Owner and Successor After Start Owner
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${owner}    ${successor_list}    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1
    ...    1

Check Linear Topology After Owner Restart
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Linear Topology On Member    ${SWITCHES}

Add Configuration In Owner and Verify After Owner Restart
    [Documentation]    Add 1 group type 1&2 and 1 flow in every switch.
    Add Single Group And Flow On Member    ${new_owner}

Check Stats Are Not Frozen After Owner Restart
    [Documentation]    Check that duration flow stat is increasing.
    Log    ${new_owner}
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen

Check Flows In Operational DS After Owner Restart
    [Documentation]    Check Flows in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${all_flows}

Check Groups In Operational DS After Owner Restart
    [Documentation]    Check Groups in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${all_groups}

Check Flows In Switch After Owner Restart
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Restart Cluster
    [Documentation]    Stop and Start cluster.
    # Try to stop contoller, if stop does not work or takes too long, kill controller.
    ${status}    ${result}=    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop_Members_From_List_Or_All
    BuiltIn.Run Keyword If    '${status}' != 'PASS'    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=False

Check Linear Topology After Controller Restarts
    [Documentation]    Check Linear Topology
    BuiltIn.Wait Until Keyword Succeeds    300s    2s    ClusterOpenFlow.Check Linear Topology On Member    ${SWITCHES}

Check Stats Are Not Frozen After Cluster Restart
    [Documentation]    Check that duration flow stat is increasing.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    Check Flow Stats Are Not Frozen

Check Flows In Operational DS After Controller Restarts
    [Documentation]    Check Flows in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    ClusterOpenFlow.Check Number Of Flows On Member    ${all_flows}

Check Groups In Operational DS After Controller Restarts
    [Documentation]    Check Groups in Operational DS.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Check Number Of Groups On Member    ${all_groups}

Check Flows In Switch After Controller Restarts
    [Documentation]    Check Flows in switch.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Stop Mininet
    [Documentation]    Stop Mininet.
    MininetKeywords.Stop Mininet And Exit

Check No Switches
    [Documentation]    Check no switches in topology.
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    ClusterOpenFlow.Check No Switches On Member    ${SWITCHES}

*** Keywords ***
Initialization Phase
    [Documentation]    Create controller session and set variables.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${switches}    Convert To Integer    ${SWITCHES}
    ${iter}    Convert To Integer    ${ITER}
    ${all_groups}=    BuiltIn.Evaluate    ${switches} * ${iter} * 2
    ${less_groups}=    BuiltIn.Evaluate    ${all_groups} - ${switches} * 2
    # Stale flows/groups feature enabled in Boron onwards.
    ${all_flows}=    BuiltIn.Evaluate    ${switches} * ${iter+1}
    ${less_flows}=    BuiltIn.Evaluate    ${all_flows} - ${switches}
    # Stale flows/groups feature enabled in Boron onwards.
    BuiltIn.Set Suite Variable    ${switches}
    BuiltIn.Set Suite Variable    ${iter}
    BuiltIn.Set Suite Variable    ${all_groups}
    BuiltIn.Set Suite Variable    ${less_groups}
    BuiltIn.Set Suite Variable    ${all_flows}
    BuiltIn.Set Suite Variable    ${less_flows}
    BuiltIn.Set Suite Variable    ${no_flows}    ${SWITCHES}

Final Phase
    [Documentation]    Delete all sessions.
    ${command} =    BuiltIn.Set Variable    sudo iptables -v -F
    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Run_Bash_Command_On_List_Or_All    ${command}
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    RequestsLibrary.Delete All Sessions

Add Groups And Flows On Member
    [Arguments]    ${iter}=1    ${member_index}=1
    [Documentation]    Add ${ITER} groups type 1 & 2 and flows in every switch.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-group-1    mapping={"SWITCH":"${switch}"}    session=${session}    iterations=${iter}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-group-2    mapping={"SWITCH":"${switch}"}    session=${session}    iterations=${iter}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-flow    mapping={"SWITCH":"${switch}"}    session=${session}    iterations=${iter}

Add Single Group And Flow On Member
    [Arguments]    ${member_index}=1
    [Documentation]    Add 1 group 1&2 and 1 flow in every switch.
    Add Groups And Flows On Member    1    ${member_index}

Remove Single Group And Flow On Member
    [Arguments]    ${member_index}=1
    [Documentation]    Remove 1 group 1&2 and 1 flow in every switch.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    RequestsLibrary.Delete Request    ${session}    ${CONFIG_NODES_API}/node/openflow:${switch}/table/0/flow/1
    \    RequestsLibrary.Delete Request    ${session}    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1
    \    RequestsLibrary.Delete Request    ${session}    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1000

Check Flow Stats Are Not Frozen
    [Arguments]    ${member_index}=1    ${period_in_seconds}=5
    [Documentation]    Verify flow stats are not frozen for flow 1 and switch 1.
    ${duration_1} =    Extract Flow Duration    ${member_index}
    ${duration_1}    Builtin.Convert To Integer    ${duration_1}
    BuiltIn.Sleep    ${period_in_seconds}
    ${duration_2} =    Extract Flow Duration    ${member_index}
    ${duration_2}    Builtin.Convert To Integer    ${duration_2}
    Should Not Be Equal As Integers    ${duration_1}    ${duration_2}

Extract Flow Duration
    [Arguments]    ${member_index}
    [Documentation]    Extract duration for flow 1 in switch 1.
    ${session} =    Resolve_Http_Session_For_Member    member_index=${member_index}
    ${resp}    RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/flow/1    headers=${headers}
    Log    ${resp.content}
    ${json_resp} =    RequestsLibrary.To_Json    ${resp.content}
    ${flow_list} =    Collections.Get_From_Dictionary    ${json_resp}    flow-node-inventory:flow
    ${flow_stats} =    Collections.Get_From_Dictionary    @{flow_list}[0]    opendaylight-flow-statistics:flow-statistics
    ${duration} =    Collections.Get_From_Dictionary    &{flow_stats}[duration]    second
    Return From Keyword    ${duration}
