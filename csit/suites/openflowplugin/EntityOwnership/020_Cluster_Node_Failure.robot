*** Settings ***
Documentation     Test suite for entity ownership service and openflowplugin. Makes changes on controller side (restart karaf)
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Template     Restarting Karaf Scenario
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/ClusterOpenFlow.robot
Library           Collections

*** Variables ***
${SWITCHES}       1
# this is for mininet 2.2.1 ${START_CMD}    sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --controller=remote,ip=${ODL_SYSTEM_2_IP} --controller=remote,ip=${ODL_SYSTEM_3_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_CMD}      sudo mn --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${KARAF_HOME}     ${WORKSPACE}${/}${BUNDLEFOLDER}

*** Test Cases ***
Switches To Be Connected To All Nodes
    [Documentation]    Initial check for correct connected topology.
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Check All Switches Connected To All Cluster Nodes

Restarting Owner Of Switch s1
    s1

Switches Still Be Connected To All Nodes
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Check All Switches Connected To All Cluster Nodes

*** Keywords ***
Start Suite
    ClusterManagement.ClusterManagement Setup
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
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

End Suite
    RequestsLibrary.Delete All Sessions
    Utils.Stop Mininet

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    ClusterManagement.Get From Member    ${OPERATIONAL_TOPO_API}/topology/flow:1    ${active_member}    access=${ACCEPT_XML}
    BuiltIn.Log    ${resp}
    ${count}=    XML.Get Element Count    ${resp}    xpath=node
    BuiltIn.Should Be Equal As Numbers    ${count}    ${SWITCHES}

Check All Switches Connected To All Cluster Nodes
    [Documentation]    Verifies all switches are connected to all cluster nodes
    OvsManager.Get Ovsdb Data
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_1_IP}    update_data=${False}
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_2_IP}    update_data=${False}
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_3_IP}    update_data=${False}

Restarting Karaf Scenario
    [Arguments]    ${switch_name}
    [Documentation]    Disconnect and connect owner and successor and check switch data to be consistent
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    BuiltIn.Set Test Variable    ${idx}
    Kill Switchs Old Owner    ${switch_name}
    Restart Switchs Old Owner    ${switch_name}
    Kill Switchs Successor    ${switch_name}
    Restart Switchs Successor    ${switch_name}
    [Teardown]    Run Keyword If    "${stopped_karaf}"!="${Empty}"    Start Controller Node And Verify    ${stopped_karaf}

Kill Switchs Old Owner
    [Arguments]    ${switch_name}
    BuiltIn.Set Test Variable    ${stopped_karaf}    ${Empty}
    ${old_owner}    ${old_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    ${old_master}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_owner}_IP}
    ${active_member}=    Collections.Get From List    ${old_successors}    0
    BuiltIn.Set Suite Variable    ${active_member}
    Stop Controller Node And Verify    ${old_owner}
    BuiltIn.Set Test Variable    ${stopped_karaf}    ${old_owner}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event    ${old_successors}
    ${new_master}=    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Verify New Master Controller Node    ${switch_name}    ${old_master}
    ${owner}    ${successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}    ${old_successors}
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Set Suite Variable    ${active_member}    ${owner}
    BuiltIn.Set Test Variable    ${old_owner}
    BuiltIn.Set Test Variable    ${old_successors}
    BuiltIn.Set Test Variable    ${old_master}
    BuiltIn.Set Test Variable    ${owner}
    BuiltIn.Set Test Variable    ${new_master}

Restart Switchs Old Owner
    [Arguments]    ${switch_name}
    Start Controller Node And Verify    ${old_owner}
    BuiltIn.Set Test Variable    ${stopped_karaf}    ${Empty}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event
    ${new_owner}    ${new_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    BuiltIn.Should Be Equal    ${owner}    ${new_owner}

Kill Switchs Successor
    [Arguments]    ${switch_name}
    ${old_owner}    ${old_successors}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}
    ${old_successor}=    Collections.Get From List    ${old_successors}    0
    ${old_slave}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_successor}_IP}
    Stop Controller Node And Verify    ${old_successor}
    BuiltIn.Set Test Variable    ${stopped_karaf}    ${old_successor}
    ${tmp_candidates}=    BuiltIn.Create List    @{ClusterManagement__member_index_list}
    Collections.Remove Values From List    ${tmp_candidates}    ${old_successor}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event    ${tmp_candidates}
    ${owner}    ${successor}=    ClusterOpenFlow.Get OpenFlow Entity Owner Status For One Device    openflow:${idx}    ${active_member}    ${tmp_candidates}
    BuiltIn.Should Be Equal    ${owner}    ${old_owner}
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Set Test Variable    ${old_owner}
    BuiltIn.Set Test Variable    ${old_successors}
    BuiltIn.Set Test Variable    ${old_successor}
    BuiltIn.Set Test Variable    ${old_slave}
    BuiltIn.Set Test Variable    ${owner}

Restart Switchs Successor
    [Arguments]    ${switch_name}
    Start Controller Node And Verify    ${old_successor}
    BuiltIn.Set Test Variable    ${stopped_karaf}    ${Empty}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event
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

Stop Controller Node And Verify
    [Arguments]    ${node}
    [Documentation]    Stops the given node
    ClusterManagement.Kill Single Member    ${node}
    [Teardown]    SSHLibrary.Switch Connection    ${mininet_conn_id}

Start Controller Node And Verify
    [Arguments]    ${node}
    [Documentation]    Starts the given node
    ClusterManagement.Start Single Member    ${node}
    [Teardown]    SSHLibrary.Switch Connection    ${mininet_conn_id}
