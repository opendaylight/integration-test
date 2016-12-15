*** Settings ***
Documentation     Test reconciliation of chained groups and flows after switch connection is restarted.
Suite Setup       Initialization_Phase
Suite Teardown    Final_Phase
Library           RequestsLibrary
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
    [Documentation]    Check Flows after mininet starts.
    # Stale flows/groups feature is only available in Boron onwards.
    CompareStream.Run_Keyword_If_At_Least_Boron    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/frm-config    mapping={"STALE":"true"}    session=session

Add Group 1 In Every Switch
    [Documentation]    Add ${ITER} groups of type 1 in every switch.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/add-group-1    mapping={"SWITCH":"${switch}"}    session=session    iterations=${ITER}

Add Group 2 In Every Switch
    [Documentation]    Add ${ITER} groups of type 2 in every switch.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/add-group-2    mapping={"SWITCH":"${switch}"}    session=session    iterations=${ITER}

Add Flow to Group 2 In Every Switch
    [Documentation]    Add ${ITER} flows to group type 2 in every switch.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_DIR}/add-flow    mapping={"SWITCH":"${switch}"}    session=session    iterations=${ITER}

Start Mininet Linear
    [Documentation]    Start Mininet Linear with ${SWITCHES} switches.
    MininetKeywords.Start_Mininet_Linear    ${SWITCHES}

Check Linear Topology
    [Documentation]    Check Linear Topology.
    Wait_Until_Keyword_Succeeds    30s    1s    FlowLib.Check_Linear_Topology    ${SWITCHES}

Check Flows In Operational DS
    [Documentation]    Check Groups after mininet starts.
    Wait_Until_Keyword_Succeeds    30s    1s    FlowLib.Check_Number_Of_Flows    ${all_flows}

Check Groups In Operational DS
    [Documentation]    Check Flows after mininet starts.
    FlowLib.Check_Number_Of_Groups    ${all_groups}

Check Flows In Switch
    [Documentation]    Check Flows after mininet starts.
    MininetKeywords.Check_Flows_In_Mininet    ${mininet_conn_id}    ${all_flows}

Disconnect Mininet
    [Documentation]    Disconnect Mininet.
    Disconnect_Controller_Mininet

Check No Switches After Disconnect
    [Documentation]    Check no switches in topology.
    Wait_Until_Keyword_Succeeds    30s    1s    FlowLib.Check No Switches In Topology    ${SWITCHES}

Remove Flows And Groups While Mininet Is Disconnected
    [Documentation]    Remove some groups and flows while network is down.
    : FOR    ${switch}    IN RANGE    1    ${SWITCHES+1}
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/table/0/flow/1
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1
    \    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}/node/openflow:${switch}/group/1000

Reconnect Mininet
    [Documentation]    Connect Mininet.
    Disconnect_Controller_Mininet    restore

Check Linear Topology After Mininet Reconnects
    [Documentation]    Check Linear Topology.
    Wait_Until_Keyword_Succeeds    30s    1s    FlowLib.Check_Linear_Topology    ${SWITCHES}

Check Flows In Operational DS After Mininet Reconnects
    [Documentation]    Check Flows after mininet starts.
    Wait_Until_Keyword_Succeeds    30s    1s    FlowLib.Check_Number_Of_Flows    ${less_flows}

Check Groups In Operational DS After Mininet Reconnects
    [Documentation]    Check Flows after mininet starts.
    FlowLib.Check_Number_Of_Groups    ${less_groups}

Check Flows In Switch After Mininet Reconnects
    [Documentation]    Check Flows after mininet starts.
    MininetKeywords.Check_Flows_In_Mininet    ${mininet_conn_id}    ${less_flows}

Stop Mininet
    [Documentation]    Stop Mininet.
    MininetKeywords.Stop_Mininet_And_Exit

Check No Switches
    [Documentation]    Check no switches in topology.
    Wait_Until_Keyword_Succeeds    5s    1s    FlowLib.Check No Switches In Topology    ${SWITCHES}

*** Keywords ***
Initialization_Phase
    [Documentation]    Create controller session and set variables.
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${all_groups}=    Evaluate    ${SWITCHES} * ${ITER} * 2
    ${less_groups}=    Evaluate    ${all_groups} - ${SWITCHES} * 2
    # Stale flows/groups feature enabled in Boron onwards.
    ${less_groups}=    CompareStream.Set_Variable_If_At_Least_Boron    ${less_groups}    ${all_groups}
    ${all_flows}=    Evaluate    ${SWITCHES} * ${ITER+1}
    ${less_flows}=    Evaluate    ${all_flows} - ${SWITCHES}
    # Stale flows/groups feature enabled in Boron onwards.
    ${less_flows}=    CompareStream.Set_Variable_If_At_Least_Boron    ${less_flows}    ${all_flows}
    Set_Suite_variable    ${all_groups}
    Set_Suite_variable    ${less_groups}
    Set_Suite_variable    ${all_flows}
    Set_Suite_variable    ${less_flows}
    Set_Suite_variable    ${no_flows}    ${SWITCHES}

Final_Phase
    [Documentation]    Delete all sessions.
    ${command} =    BuiltIn.Set_Variable    sudo iptables -v -F
    Utils.Run_Command_On_Controller    cmd=${command}
    CompareStream.Run_Keyword_If_At_Least_Boron    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_DIR}/frm-config    mapping={"STALE":"false"}    session=session
    BuiltIn.Run Keyword_And_Ignore_Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    RequestsLibrary.Delete_All_Sessions

Disconnect_Controller_Mininet
    [Arguments]    ${action}=break
    [Documentation]    Break and restore controller to mininet connection via iptables.
    ${rule} =    BuiltIn.Set_Variable    OUTPUT -p all --source ${ODL_SYSTEM_IP} --destination ${TOOLS_SYSTEM_IP} -j DROP
    ${command} =    BuiltIn.Set_Variable_If    '${action}'=='restore'    sudo /sbin/iptables -D ${rule}    sudo /sbin/iptables -I ${rule}
    Utils.Run_Command_On_Controller    cmd=${command}
    ${command} =    BuiltIn.Set_Variable    sudo /sbin/iptables -L -n
    ${output} =    Utils.Run_Command_On_Controller    cmd=${command}
    BuiltIn.Log    ${output}
