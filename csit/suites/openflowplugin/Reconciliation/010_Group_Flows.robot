*** Settings ***
Documentation     Test reconciliation of chained groups and flows after switch connection and controller are restarted.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           RequestsLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SWITCHES}       ${10}
${ITER}           ${100}
${VAR_DIR}        ${CURDIR}/../../../variables/openflowplugin

*** Test Cases ***
Enable Stale Flow Entry
    [Documentation]    Enable stale flow entry feature.
    # Stale flows/groups feature is only available in Boron onwards.
    CompareStream.Run Keyword If At Least Boron    TemplatedRequests.Put As Json Templated    folder=${VAR_DIR}/frm-config    mapping={"STALE":"true"}    session=session

Add Group 1 In Every Switch
    [Documentation]    Add ${ITER} groups of type 1 in every switch.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-group-1    mapping={"SWITCH":"${switch}"}    session=session    iterations=${ITER}

Add Group 2 In Every Switch
    [Documentation]    Add ${ITER} groups of type 2 in every switch.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-group-2    mapping={"SWITCH":"${switch}"}    session=session    iterations=${ITER}

Add Flow to Group 2 In Every Switch
    [Documentation]    Add ${ITER} flows to group type 2 in every switch.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    TemplatedRequests.Post As Json Templated    folder=${VAR_DIR}/add-flow    mapping={"SWITCH":"${switch}"}    session=session    iterations=${ITER}

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

Remove Flows And Groups While Mininet Is Disconnected
    [Documentation]    Remove some groups and flows while network is down.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/table/0/flow/1
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1000

Reconnect Mininet
    [Documentation]    Connect Mininet.
    Disconnect Controller Mininet    restore

Check Linear Topology After Mininet Reconnects
    [Documentation]    Check Linear Topology.
    BuiltIn.Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Linear Topology    ${SWITCHES}

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
    ${status}    ${result}=    BuiltIn.Run Keyword And Ignore Error    ClusterManagement.Stop_Members_From_List_Or_All
    BuiltIn.Run Keyword If    '${status}' != 'PASS'    ClusterManagement.Kill_Members_From_List_Or_All
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
    ${all_groups}=    BuiltIn.Evaluate    ${SWITCHES} * ${ITER} * 2
    ${less_groups}=    BuiltIn.Evaluate    ${all_groups} - ${SWITCHES} * 2
    # Stale flows/groups feature enabled in Boron onwards.
    ${less_groups}=    CompareStream.Set Variable If At Least Boron    ${less_groups}    ${all_groups}
    ${all_flows}=    BuiltIn.Evaluate    ${SWITCHES} * ${ITER+1}
    ${less_flows}=    BuiltIn.Evaluate    ${all_flows} - ${SWITCHES}
    # Stale flows/groups feature enabled in Boron onwards.
    ${less_flows}=    CompareStream.Set Variable If At Least Boron    ${less_flows}    ${all_flows}
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

Disconnect Controller Mininet
    [Arguments]    ${action}=break
    [Documentation]    Break and restore controller to mininet connection via iptables.
    ${rule} =    BuiltIn.Set Variable    OUTPUT -p all --source ${ODL_SYSTEM_IP} --destination ${TOOLS_SYSTEM_IP} -j DROP
    ${command} =    BuiltIn.Set Variable If    '${action}'=='restore'    sudo /sbin/iptables -D ${rule}    sudo /sbin/iptables -I ${rule}
    Utils.Run Command On Controller    cmd=${command}
    ${command} =    BuiltIn.Set Variable    sudo /sbin/iptables -L -n
    ${output} =    Utils.Run Command On Controller    cmd=${command}
    BuiltIn.Log    ${output}
