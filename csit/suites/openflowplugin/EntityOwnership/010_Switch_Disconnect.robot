*** Settings ***
Documentation     Test suite for entity ownership service and openflowplugin. Makes changes on switch side.
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Template     Reconnecting Switch Scenario
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/FlowLib.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/ClusterOpenFlow.robot
Library           Collections

*** Variables ***
${SWITCHES}       1
${START_CMD}      sudo mn --switch ovsk,protocols=OpenFlow13 --topo linear,${SWITCHES}
@{cntls_idx_list}    ${1}    ${2}    ${3}

*** Test Cases ***
Switches To Be Connected To All Nodes
    [Documentation]    Initial check for correct connected topology.
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Check All Switches Connected To All Cluster Nodes

Reconnecting Switch s1
    s1

Switches Still Be Connected To All Nodes
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Check All Switches Connected To All Cluster Nodes

*** Keywords ***
Start Suite
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    SSHLibrary.Put File    ${CURDIR}/../../../libraries/DynamicMininet.py    .
    SSHLibrary.Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    SSHLibrary.Execute Command    sudo mn -c
    SSHLibrary.Write    ${START_CMD}
    SSHLibrary.Read Until    mininet>
    ${cntls_list}    BuiltIn.Create List    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    ${switch_list}    BuiltIn.Create List
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    Collections.Append To List    ${switch_list}    s${sid}
    BuiltIn.Set Suite Variable    ${active_member}    1
    OvsManager.Setup Clustered Controller For Switches    ${switch_list}    ${cntls_list}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    ClusterOpenFlow.Verify Switch Connections Running On Member    ${SWITCHES}    1

End Suite
    RequestsLibrary.Delete All Sessions
    Utils.Stop Mininet

Check All Switches Connected To All Cluster Nodes
    [Documentation]    Verifies all switches are connected to all cluster nodes
    OvsManager.Get Ovsdb Data
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_1_IP}    update_data=${False}
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_2_IP}    update_data=${False}
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_3_IP}    update_data=${False}

Reconnecting Switch Scenario
    [Arguments]    ${switch_name}
    [Documentation]    Disconnect and connect master and slave and check switch data to be consistent
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    BuiltIn.Set Test Variable    ${idx}
    Disconnect Switchs Old Master    ${switch_name}
    Reconnect Switchs Old Master    ${switch_name}
    Disconnect Switchs Slave    ${switch_name}
    Reconnect Switchs Slave    ${switch_name}
    [Teardown]    Run Keyword If    "${disc_cntl}"!="${Empty}"    OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${disc_cntl}

Disconnect Switchs Old Master
    [Arguments]    ${switch_name}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${Empty}
    ${old_owner}    ${old_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    ${old_master}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_owner}_IP}
    OvsManager.Disconnect Switch From Controller And Verify Disconnected    ${switch_name}    ${old_master}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${old_master}
    ${new_master}=    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Verify New Master Controller Node    ${switch_name}    ${old_master}
    ${owner}    ${successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}    ${old_successors}    after_stop=True
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Set Test Variable    ${old_owner}
    BuiltIn.Set Test Variable    ${old_successors}
    BuiltIn.Set Test Variable    ${old_master}
    BuiltIn.Set Test Variable    ${owner}
    BuiltIn.Set Test Variable    ${new_master}

Reconnect Switchs Old Master
    [Arguments]    ${switch_name}
    OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${old_master}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${Empty}
    ${new_owner}    ${new_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    BuiltIn.Should Be Equal    ${owner}    ${new_owner}

Disconnect Switchs Slave
    [Arguments]    ${switch_name}
    ${old_owner}    ${old_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    ${old_successor}=    Collections.Get From List    ${old_successors}    0
    ${old_slave}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_successor}_IP}
    OvsManager.Disconnect Switch From Controller And Verify Disconnected    ${switch_name}    ${old_slave}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${old_slave}
    ${tmp_candidates}=    BuiltIn.Create List    @{ClusterManagement__member_index_list}
    Collections.Remove Values From List    ${tmp_candidates}    ${old_successor}
    ${owner}    ${successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}    ${tmp_candidates}    after_stop=True
    BuiltIn.Should Be Equal    ${owner}    ${old_owner}
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Set Test Variable    ${old_owner}
    BuiltIn.Set Test Variable    ${old_successors}
    BuiltIn.Set Test Variable    ${old_successor}
    BuiltIn.Set Test Variable    ${old_slave}
    BuiltIn.Set Test Variable    ${owner}

Reconnect Switchs Slave
    [Arguments]    ${switch_name}
    OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${old_slave}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${Empty}
    ${new_owner}    ${new_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    BuiltIn.Should Be Equal    ${old_owner}    ${new_owner}

Verify New Master Controller Node
    [Arguments]    ${switch_name}    ${old_master}
    [Documentation]    Checks if given node is different from actual master
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${successors}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    ${new_master}    BuiltIn.Set Variable    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Should Not Be Equal    ${old_master}    ${new_master}
    Return From Keyword    ${new_master}
