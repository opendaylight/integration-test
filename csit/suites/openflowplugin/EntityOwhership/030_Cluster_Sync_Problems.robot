*** Settings ***
Documentation     Test suite for entity ownership service and openflowplugin. Makes changes on controller side (isolating cluster node)
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Template     Isolating Node Scenario
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/ClusterOpenFlow.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Library           Collections

*** Variables ***
${SWITCHES}       1
# this is for mininet 2.2.1 ${START_CMD}    sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --controller=remote,ip=${ODL_SYSTEM_2_IP} --controller=remote,ip=${ODL_SYSTEM_3_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_CMD}      sudo mn --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
@{CONTROLLER_NODES}    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
@{cntls_idx_list}    ${1}    ${2}    ${3}

*** Test Cases ***
Start Mininet To All Nodes
    [Template]    NONE
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
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Are Switches Connected Topo

Switches To Be Connected To All Nodes
    [Documentation]    Initial check for correct connected topology.
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    15x    1s    Check All Switches Connected To All Cluster Nodes

Isolating Owner Of Switch s1
    s1

Switches Still Be Connected To All Nodes
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    15x    1s    Check All Switches Connected To All Cluster Nodes

Stop Mininet And Verify No Owners
    [Template]    NONE
    Utils.Stop Suite
    BuiltIn.Wait Until Keyword Succeeds    15x    1s    Check No Owners In Controller

*** Keywords ***
Start Suite
    ClusterManagement.ClusterManagement Setup

End Suite
    ClusterManagement.Flush Iptables From List Or All
    RequestsLibrary.Delete All Sessions

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

Isolating Node Scenario
    [Arguments]    ${switch_name}
    [Documentation]    Disconnect and connect master and follower and check switch data to be consistent
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    BuiltIn.Set Test Variable    ${idx}
    Isolate Switchs Old Owner    ${switch_name}
    Rejoin Switchs Old Owner    ${switch_name}
    Isolate Switchs Candidate    ${switch_name}
    Rejoin Switchs Candidate    ${switch_name}
    [Teardown]    Run Keyword If    "${isol_node}"!="${Empty}"    Rejoin Controller To The Cluster    ${isol_node}

Isolate Switchs Old Owner
    [Arguments]    ${switch_name}
    BuiltIn.Set Test Variable    ${isol_node}    ${Empty}
    Check Count Integrity    ${switch_name}    expected_controllers=3
    ${old_owner}    ${old_followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    ${old_master}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_owner}_IP}
    ${tmp_followers}=    BuiltIn.Create List    @{old_followers}
    Collections.Remove Values From List    ${tmp_followers}    ${old_owner}
    ${tmp_follower}=    Collections.Get From List    ${tmp_followers}    0
    BuiltIn.Set Suite Variable    ${active_member}    ${tmp_follower}
    Isolate Controller From The Cluster    ${old_owner}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event    ${tmp_followers}
    BuiltIn.Set Test Variable    ${isol_node}    ${old_owner}
    ${new_master}=    BuiltIn.Wait Until Keyword Succeeds    10x    3s    Verify New Master Controller Node    ${switch_name}    ${old_master}
    ${owner}    ${followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    Collections.List Should Contain Value    ${old_followers}    ${owner}
    CompareStream.Set_Variable_If_At_Least_Boron    ${expected_controllers}    3    2
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    Check Count Integrity    ${switch_name}    expected_controllers=${expected_controllers}
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Set Suite Variable    ${active_member}    ${owner}
    BuiltIn.Set Test Variable    ${old_owner}
    BuiltIn.Set Test Variable    ${old_followers}
    BuiltIn.Set Test Variable    ${old_master}
    BuiltIn.Set Test Variable    ${owner}
    BuiltIn.Set Test Variable    ${new_master}

Rejoin Switchs Old Owner
    [Arguments]    ${switch_name}
    Rejoin Controller To The Cluster    ${old_owner}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event
    BuiltIn.Set Test Variable    ${isol_node}    ${Empty}
    BuiltIn.Wait Until Keyword Succeeds    20x    3s    Verify Follower Added    ${switch_name}    ${old_owner}
    ${new_owner}    ${new_followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    Check Count Integrity    ${switch_name}    expected_controllers=3
    BuiltIn.Should Be Equal    ${owner}    ${new_owner}
    Collections.List Should Contain Value    ${new_followers}    ${old_owner}

Isolate Switchs Candidate
    [Arguments]    ${switch_name}
    ${old_owner}    ${old_followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    ${old_follower}=    Collections.Get From List    ${old_followers}    0
    ${old_slave}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_follower}_IP}
    ${tmp_members}=    BuiltIn.Create List    @{ClusterManagement__member_index_list}
    Collections.Remove Values From List    ${tmp_members}    ${old_follower}
    Isolate Controller From The Cluster    ${old_follower}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event    ${tmp_members}
    BuiltIn.Set Test Variable    ${isol_cntl}    ${old_slave}
    CompareStream.Set_Variable_If_At_Least_Boron    ${expected_controllers}    3    2
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    Check Count Integrity    ${switch_name}    expected_controllers=${expected_controllers}
    ${owner}    ${followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    BuiltIn.Should Be Equal    ${owner}    ${old_owner}
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Set Test Variable    ${old_owner}
    BuiltIn.Set Test Variable    ${old_followers}
    BuiltIn.Set Test Variable    ${old_follower}
    BuiltIn.Set Test Variable    ${old_slave}
    BuiltIn.Set Test Variable    ${owner}

Rejoin Switchs Candidate
    [Arguments]    ${switch_name}
    Rejoin Controller To The Cluster    ${old_follower}
    ClusterOpenFlow.Check OpenFlow Shards Status After Cluster Event
    BuiltIn.Wait Until Keyword Succeeds    20x    3s    Verify Follower Added    ${switch_name}    ${old_follower}
    BuiltIn.Set Test Variable    ${isol_node}    ${Empty}
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    Check Count Integrity    ${switch_name}    expected_controllers=3
    ${new_owner}    ${new_followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    BuiltIn.Should Be Equal    ${old_owner}    ${new_owner}
    Collections.List Should Contain Value    ${new_followers}    ${old_follower}

Rejoin Controller To The Cluster
    [Arguments]    ${isolated_node}
    ClusterManagement.Rejoin Member From List Or All    ${isolated_node}
    [Teardown]    SSHLibrary.Switch Connection    ${mininet_conn_id}

Isolate Controller From The Cluster
    [Arguments]    ${isolated_node}
    ClusterManagement.Isolate Member From List Or All    ${isolated_node}
    [Teardown]    SSHLibrary.Switch Connection    ${mininet_conn_id}

Check Count Integrity
    [Arguments]    ${switch_name}    ${expected_controllers}=3
    [Documentation]    Every switch must have only one master and rest must be followers and together must be of expected nodes count
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${candidates}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    ${count}=    BuiltIn.Get Length    ${candidates}
    BuiltIn.Should Be Equal As Numbers    ${expected_controllers}    ${count}

Check No Owners In Controller
    [Documentation]    Check there is no owners in controllers
    ${session} =    Resolve_Http_Session_For_Member    member_index=${active_member}
    ${data} =    TemplatedRequests.Get_As_Json_From_Uri    uri=${ENTITY_OWNER_URI}    session=${session}
    BuiltIn.Should Not Contain    ${data}    member

Verify New Master Controller Node
    [Arguments]    ${switch_name}    ${old_master}
    [Documentation]    Checks if given node is different from actual master
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    ${new_master}    BuiltIn.Set Variable    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Should Not Be Equal    ${old_master}    ${new_master}
    Return From Keyword    ${new_master}

Verify Follower Added
    [Arguments]    ${switch_name}    ${expected_node}
    [Documentation]    Checks if given node is in the list of active followers
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${followers}=    ClusterManagement.Get Owner And Candidates For Device    openflow:${idx}    openflow    ${active_member}
    Collections.List Should Contain Value    ${followers}    ${expected_node}
