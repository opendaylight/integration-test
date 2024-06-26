*** Settings ***
Documentation       Test reconciliation of chained groups and flows after switch connection and controller are restarted.

Library             RequestsLibrary
Resource            ../../../libraries/ClusterManagement.robot
Resource            ../../../libraries/TemplatedRequests.robot
Resource            ../../../libraries/MininetKeywords.robot
Resource            ../../../libraries/FlowLib.robot
Resource            ../../../libraries/Utils.robot
Resource            ../../../variables/Variables.robot
Resource            ../../../variables/openflowplugin/Variables.robot

Suite Setup         Initialization Phase
Suite Teardown      Final Phase


*** Variables ***
${SWITCHES}     3
${ITER}         100
${VAR_DIR}      ${CURDIR}/../../../variables/openflowplugin


*** Test Cases ***
Add Group 1 In Every Switch
    [Documentation]    Add ${ITER} groups of type 1 in every switch.
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        &{mapping}    BuiltIn.Create_Dictionary    NODE=openflow:${switch}
        TemplatedRequests.Post As Json Templated
        ...    folder=${VAR_DIR}/add-group-1
        ...    mapping=${mapping}
        ...    session=session
        ...    iterations=${iter}
    END

Add Group 2 In Every Switch
    [Documentation]    Add ${ITER} groups of type 2 in every switch.
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        &{mapping}    BuiltIn.Create_Dictionary    NODE=openflow:${switch}
        TemplatedRequests.Post As Json Templated
        ...    folder=${VAR_DIR}/add-group-2
        ...    mapping=${mapping}
        ...    session=session
        ...    iterations=${iter}
    END

Add Flow to Group 2 In Every Switch
    [Documentation]    Add ${ITER} flows to group type 2 in every switch.
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        &{mapping}    BuiltIn.Create_Dictionary    NODE=openflow:${switch}
        TemplatedRequests.Post As Json Templated
        ...    folder=${VAR_DIR}/add-flow
        ...    mapping=${mapping}
        ...    session=session
        ...    iterations=${ITER}
    END

Start Mininet Linear
    [Documentation]    Start Mininet Linear with ${SWITCHES} switches.
    MininetKeywords.Start Mininet Linear    ${SWITCHES}

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

Disconnect Mininet
    [Documentation]    Disconnect Mininet.
    Disconnect Controller Mininet

Check No Switches After Disconnect
    [Documentation]    Check no switches in topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check No Switches In Topology    ${SWITCHES}

Reconnect Mininet
    [Documentation]    Connect Mininet.
    Disconnect Controller Mininet    restore

Check Linear Topology After Mininet Reconnects
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Linear Topology    ${SWITCHES}

Remove Flows And Groups After Mininet Reconnects
    [Documentation]    Remove some groups and flows while network is down.
    FOR    ${switch}    IN RANGE    1    ${switches+1}
        RequestsLibrary.DELETE On Session
        ...    session
        ...    url=${RFC8040_NODES_API}/node=openflow%3A${switch}/flow-node-inventory:table=0/flow=1
        RequestsLibrary.DELETE On Session
        ...    session
        ...    url=${RFC8040_NODES_API}/node=openflow%3A${switch}/flow-node-inventory:group=1
        RequestsLibrary.DELETE On Session
        ...    session
        ...    url=${RFC8040_NODES_API}/node=openflow%3A${switch}/flow-node-inventory:group=1000
    END

Check Flows In Operational DS After Mininet Reconnects
    [Documentation]    Check Flows after mininet starts.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Number Of Flows    ${less_flows}

Check Groups In Operational DS After Mininet Reconnects
    [Documentation]    Check Flows after mininet starts.
    FlowLib.Check Number Of Groups    ${less_groups}

Check Flows In Switch After Mininet Reconnects
    [Documentation]    Check Flows after mininet starts.
    MininetKeywords.Check Flows In Mininet    ${mininet_conn_id}    ${less_flows}

Restart Controller
    [Documentation]    Stop and Start controller.
    # Try to stop contoller, if stop does not work or takes too long, kill controller.
    ${status}    ${result}    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop_Members_From_List_Or_All
    IF    '${status}' != 'PASS'
        ClusterManagement.Kill_Members_From_List_Or_All
    END
    ClusterManagement.Start_Members_From_List_Or_All    wait_for_sync=False

Check Linear Topology After Controller Restarts
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    300s    2s    FlowLib.Check Linear Topology    ${SWITCHES}

Check Flows In Operational DS After Controller Restarts
    [Documentation]    Check Flows after mininet starts.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Number Of Flows    ${less_flows}

Check Groups In Operational DS After Controller Restarts
    [Documentation]    Check Flows after mininet starts.
    FlowLib.Check Number Of Groups    ${less_groups}

Check Flows In Switch After Controller Restarts
    [Documentation]    Check Flows after mininet starts.
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
    ${all_groups}    BuiltIn.Evaluate    ${switches} * ${iter} * 2
    ${less_groups}    BuiltIn.Evaluate    ${all_groups} - ${switches} * 2
    # Stale flows/groups feature enabled in Boron onwards.
    ${all_flows}    BuiltIn.Evaluate    ${switches} * ${iter+1}
    ${less_flows}    BuiltIn.Evaluate    ${all_flows} - ${switches}
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
    ${command}    BuiltIn.Set Variable    sudo iptables -v -F
    Utils.Run Command On Controller    cmd=${command}
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.DELETE On Session    session    url=${RFC8040_NODES_API}
    RequestsLibrary.Delete All Sessions

Disconnect Controller Mininet
    [Documentation]    Break and restore controller to mininet connection via iptables.
    [Arguments]    ${action}=break
    ${rule}    BuiltIn.Set Variable    OUTPUT -p all --source ${ODL_SYSTEM_IP} --destination ${TOOLS_SYSTEM_IP} -j DROP
    ${command}    BuiltIn.Set Variable If
    ...    '${action}'=='restore'
    ...    sudo /sbin/iptables -D ${rule}
    ...    sudo /sbin/iptables -I ${rule}
    Utils.Run Command On Controller    cmd=${command}
    ${command}    BuiltIn.Set Variable    sudo /sbin/iptables -L -n
    ${output}    Utils.Run Command On Controller    cmd=${command}
    BuiltIn.Log    ${output}
