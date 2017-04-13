*** Settings ***
Documentation     Switch connections and cluster are restarted.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           RequestsLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/ClusterOpenFlow.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SWITCHES}       3
${ITER}           100
${VAR_DIR}        ${CURDIR}/../../../variables/openflowplugin

*** Test Cases ***
Enable Stale Flow Entry
    [Documentation]    Enable stale flow entry feature.
    # Stale flows/groups feature is only available in Boron onwards.
    CompareStream.Run Keyword If At Least Boron    TemplatedRequests.Put As Json Templated    folder=${VAR_DIR}/frm-config    mapping={"STALE":"true"}    session=session

Add Groups And Flows
    [Documentation]    Add ${ITER} groups 1&2 and flows in every switch.
    Add Groups And Flows    ${ITER}

Start Mininet Multiple Connections
    [Documentation]    Start mininet linear with connection to all cluster instances.
    ${mininet_conn_id}=    MininetKeywords.Start Mininet Multiple Controllers    ${TOOLS_SYSTEM_IP}    ${ClusterManagement__member_index_list}    --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    OVSDB.Check OVS OpenFlow Connections    ${TOOLS_SYSTEM_IP}    ${SWITCHES*3}

Check Linear Topology
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Linear Topology    ${SWITCHES}

Check Flows In Operational DS
    [Documentation]    Check Groups after mininet starts.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Number Of Flows    ${all_flows}

Check Groups In Operational DS
    [Documentation]    Check Flows after mininet starts.
    FlowLib.Check Number Of Groups    ${all_groups}

Check Flows In Switch
    [Documentation]    Check Flows after mininet starts.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Check Entity Owner Status And Find Owner and Successor Before Fail
    [Documentation]    Check Entity Owner Status and identify owner and successor for first switch s1.
    ${original_owner}    ${original_successor_list}    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:1    1
    BuiltIn.Set Suite Variable    ${original_owner}

Disconnect Mininet From Owner
    [Documentation]    Disconnect mininet from the owner
    ${owner_list}    BuiltIn.Create List    ${original_owner}
    Disconnect Cluster Mininet    break    ${owner_list}
    BuiltIn.Set Suite Variable    ${owner_list}

Check Linear Topology After Disconnect
    [Documentation]    Check Linear Topology After Disconnecting mininet from owner.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Linear Topology    ${SWITCHES}

Remove Flows And Groups After Mininet Is Disconnected
    [Documentation]    Remove 1 group 1&2 and 1 flow in every switch after mininet is disconnected.
    Remove Single Group And Flow

Check Flows In Operational DS After Mininet Is Disconnected
    [Documentation]    Check Flows in Operational DS after mininet is disconnected.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Number Of Flows    ${less_flows}

Check Groups In Operational DS After Mininet Is Disconnected
    [Documentation]    Check Groups in Operational DS after mininet is disconnected.
    FlowLib.Check Number Of Groups    ${less_groups}

Check Flows In Switch After Mininet Is Disconnected
    [Documentation]    Check Flows in switch after mininet is disconnected
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Reconnect Mininet To Owner
    [Documentation]    Reconnect mininet to switch 1 owner.
    Disconnect Cluster Mininet    restore    ${owner_list}

Check Linear Topology After Reconnect
    [Documentation]    Check Linear Topology After Reconnect.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Linear Topology    ${SWITCHES}

Add Flows And Groups After Reconnect
    [Documentation]    Add 1 group type 1&2 and 1 flow in every switch.
    Add Single Group And Flow

Check Flows After Reconnect In Operational DS
    [Documentation]    Check Flows in Operational DS after mininet is reconnected.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Number Of Flows    ${all_flows}

Check Groups After Reconnect In Operational DS
    [Documentation]    Check Groups in Operational DS after mininet is reconnected.
    FlowLib.Check Number Of Groups    ${all_groups}

Check Flows After Reconnect In Switch
    [Documentation]    Check Flows in switch after mininet is reconnected.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${all_flows}

Disconnect Mininet From Cluster
    [Documentation]    Disconnect Mininet from Cluster.
    Disconnect Cluster Mininet

Check No Switches After Disconnect
    [Documentation]    Check no switches in topology after disconnecting mininet from cluster.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check No Switches In Topology    ${SWITCHES}

Remove Flows And Groups While Mininet Is Disconnected
    [Documentation]    Remove a group and flow while mininet Is Disconnected from cluster.
    Remove Single Group And Flow

Reconnect Mininet To Cluster
    [Documentation]    Reconnect mininet to cluster by removing Iptables drop rules that were used to disconnect
    Disconnect Cluster Mininet    restore

Check Linear Topology After Mininet Reconnects
    [Documentation]    Check Linear Topology after reconnect.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Linear Topology    ${SWITCHES}

Check Flows In Operational DS After Mininet Reconnects
    [Documentation]    Check Flows in Operational DS after mininet is reconnected.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Number Of Flows    ${less_flows}

Check Groups In Operational DS After Mininet Reconnects
    [Documentation]    Check Groups in Operational DS after mininet is reconnected to cluster.
    FlowLib.Check Number Of Groups    ${less_groups}

Check Flows In Switch After Mininet Reconnects
    [Documentation]    Check Flows in switch after mininet is reconnected to cluster.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Restart Cluster
    [Documentation]    Stop and Start cluster.
    # Try to stop contoller, if stop does not work or takes too long, kill controller.
    ${status}    ${result}=    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop_Members_From_List_Or_All
    BuiltIn.Run Keyword If    '${status}' != 'PASS'    ClusterManagement.Kill_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=False

Check Linear Topology After Controller Restarts
    [Documentation]    Check Linear Topology after controller restarts.
    BuiltIn.Wait Until Keyword Succeeds    300s    2s    FlowLib.Check Linear Topology    ${SWITCHES}

Check Flows In Operational DS After Controller Restarts
    [Documentation]    Check Flows in Operational DS after controller is restarted.
    BuiltIn.Wait Until Keyword Succeeds    300s    2s    FlowLib.Check Number Of Flows    ${less_flows}

Check Groups In Operational DS After Controller Restarts
    [Documentation]    Check Groups in Operational DS after controller is restarted.
    FlowLib.Check Number Of Groups    ${less_groups}

Check Flows In Switch After Controller Restarts
    [Documentation]    Check Flows in switch after controller is restarted..
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Stop Mininet
    [Documentation]    Stop Mininet.
    MininetKeywords.Stop Mininet And Exit

Check No Switches
    [Documentation]    Check no switches in topology.
    BuiltIn.Wait Until Keyword Succeeds    5s    1s    FlowLib.Check No Switches In Topology    ${SWITCHES}

*** Keywords ***
Initialization Phase
    [Documentation]    Create controller session and set variables.
    ClusterManagement.ClusterManagement_Setup
    # Still need to open controller HTTP session with name session because of old FlowLib.robot library dependency.
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${switches}    Convert To Integer    ${SWITCHES}
    ${iter}    Convert To Integer    ${ITER}
    ${all_groups}=    BuiltIn.Evaluate    ${switches} * ${iter} * 2
    ${less_groups}=    BuiltIn.Evaluate    ${all_groups} - ${switches} * 2
    # Stale flows/groups feature enabled in Boron onwards.
    ${less_groups}=    CompareStream.Set Variable If At Least Boron    ${less_groups}    ${all_groups}
    ${all_flows}=    BuiltIn.Evaluate    ${switches} * ${iter+1}
    ${less_flows}=    BuiltIn.Evaluate    ${all_flows} - ${switches}
    # Stale flows/groups feature enabled in Boron onwards.
    ${less_flows}=    CompareStream.Set Variable If At Least Boron    ${less_flows}    ${all_flows}
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
    Utils.Run Command On Controller    cmd=${command}
    CompareStream.Run Keyword If At Least Boron    TemplatedRequests.Put As Json Templated    folder=${VAR_DIR}/frm-config    mapping={"STALE":"false"}    session=session
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    RequestsLibrary.Delete All Sessions

Disconnect Cluster Mininet
    [Arguments]    ${action}=break    ${member_index_list}=${EMPTY}
    [Documentation]    Break and restore controller to mininet connection via iptables.
    ${index_list} =    ClusterManagement.List_Indices_Or_All    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}
    \    ${rule} =    BuiltIn.Set Variable    OUTPUT -p all --source ${ODL_SYSTEM_${index}_IP} --destination ${TOOLS_SYSTEM_IP} -j DROP
    \    ${command} =    BuiltIn.Set Variable If    '${action}'=='restore'    sudo /sbin/iptables -D ${rule}    sudo /sbin/iptables -I ${rule}
    \    Log To Console    ${ODL_SYSTEM_${index}_IP}
    \    Utils.Run Command On Controller    ${ODL_SYSTEM_${index}_IP}    cmd=${command}
    \    ${command} =    BuiltIn.Set Variable    sudo /sbin/iptables -L -n
    \    ${output} =    Utils.Run Command On Controller    cmd=${command}
    \    BuiltIn.Log    ${output}

Add Groups And Flows
    [Arguments]    ${iter}=1
    [Documentation]    Add ${ITER} groups type 1 & 2 and flows in every switch.
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-group-1    mapping={"SWITCH":"${switch}"}    session=session    iterations=${iter}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-group-2    mapping={"SWITCH":"${switch}"}    session=session    iterations=${iter}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-flow    mapping={"SWITCH":"${switch}"}    session=session    iterations=${iter}

Add Single Group And Flow
    [Documentation]    Add 1 group 1&2 and 1 flow in every switch.
    Add Groups And Flows    1

Remove Single Group And Flow
    [Documentation]    Remove 1 group 1&2 and 1 flow in every switch.
    : FOR    ${switch}    IN RANGE    1    ${switches+1}
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/table/0/flow/1
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1000
