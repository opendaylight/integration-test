*** Settings ***
Documentation     Test reconciliation of chained groups and flows after switch is restart.
Suite Setup       Initialization Phase
Suite Teardown    Final Phase
Library           XML
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/MininetKeywords.robot
Resource          ../../../libraries/FlowLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SWITCHES}       ${10}
${ITER}           ${200}
${VAR_DIR}        ${CURDIR}/../../../variables/openflowplugin

*** Test Cases ***
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
    Wait Until Keyword Succeeds    30s    1s    FlowLib.Check_Linear_Topology    ${SWITCHES}

Check Flows In Operational DS
    [Documentation]    Check Flows after mininet starts.
    Wait Until Keyword Succeeds    30s    1s    FlowLib.Check Flows Operational Datastore    ${all_flows}

Stop Mininet
    [Documentation]    Start Mininet Linear with ${SWITCHES} switches.
    MininetKeywords.Stop_Mininet_And_Exit

Remove Flow And Verify In Config Datastore
    [Documentation]    Remove the flow and verify.
    FlowLib.Remove Flow From Controller And Verify    openflow:1    0    1

Verify After Removing Flow In Operational DataStore
    [Documentation]    Get the flow stats in operational.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:1/table/0/flow/1

Remove Group 2 And Verify In Config Datastore
    [Documentation]    Remove the group and verify.
    FlowLib.Remove Group From Controller And Verify    openflow:1    2

Verify After Removing Group 2 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:1/group/2

Remove Group 1 And Verify In Config Datastore
    [Documentation]    Remove the group and verify.
    FlowLib.Remove Group From Controller And Verify    openflow:1    1

Verify After Removing Group 1 In Operational DataStore
    [Documentation]    Get the group stats in operational.
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Utils.No Content From URI    session    ${OPERATIONAL_NODES_API}/node/openflow:1/group/1

*** Keywords ***
Initialization Phase
    [Documentation]    Create controller session and set variables.
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${flows_ovs_20}=    Evaluate    ${SWITCHES} * ${ITER}
    ${flows_ovs_25}=    Evaluate    ${flows_ovs_20} + ${SWITCHES}
    ${no_flows}=    CompareStream.Set_Variable_If_At_Least_Boron    ${SWITCHES}    ${0}
    ${all_flows}=    CompareStream.Set_Variable_If_At_Least_Boron    ${flows_ovs_25}    ${flows_ovs_20}
    Set Suite variable    ${no_flows}
    Set Suite variable    ${all_flows}

Final Phase
    [Documentation]    Delete all sessions.
    BuiltIn.Run Keyword And Ignore Error    RequestsLibrary.Delete Request    session    ${CONFIG_NODES_API}
    RequestsLibrary.Delete All Sessions
