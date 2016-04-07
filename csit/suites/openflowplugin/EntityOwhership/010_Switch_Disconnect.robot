*** Settings ***
Documentation     Test suite for entity ownership service and openflowplugin. Makes changes on switch side.
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Template     Reconnecting Switch Scenario
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Resource          ${CURDIR}/../../../libraries/ClusterKeywords.robot
Library           Collections

*** Variables ***
${SWITCHES}       5
# this is for mininet 2.2.1 ${START_CMD}    sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --controller=remote,ip=${ODL_SYSTEM_2_IP} --controller=remote,ip=${ODL_SYSTEM_3_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_CMD}      sudo mn --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
@{cntls_idx_list}    ${1}    ${2}    ${3}

*** Test Cases ***
Switches To Be Connected To All Nodes
    [Documentation]    Initial check for correct connected topology.
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check All Switches Connected To All Cluster Nodes

Reconnecting Switch s1
    s1
    #Reconnecting Switch s2
    #    s2
    #Reconnecting Switch s3
    #    s3
    #Reconnecting Switch s4
    #    s4
    #Reconnecting Switch s5
    #    s5

Switches Still Be Connected To All Nodes
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check All Switches Connected To All Cluster Nodes

*** Keywords ***
Start Suite
    BuiltIn.Log    Start the test on the base edition
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
    \    Collections.Append To List   ${switch_list}    s${sid}
    : FOR    ${i}    IN RANGE    0    ${NUM_ODL_SYSTEM}
    \    ${cid}=    BuiltIn.Evaluate    ${i}+1
    \    RequestsLibrary.Create Session    controller${cid}    http://${ODL_SYSTEM_${cid}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Set Suite Variable    ${active_session}    controller1
    OvsManager.Setup Clustered Controller For Switches    ${switch_list}     ${cntls_list}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

End Suite
    RequestsLibrary.Delete All Sessions
    Utils.Stop Suite

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get Request    ${active_session}    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    BuiltIn.Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    BuiltIn.Should Be Equal As Numbers    ${count}    ${SWITCHES}

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
    [Documentation]    Disconnect and connect master and follower and check switch data to be consistent
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    # disconnection master part
    BuiltIn.Set Test Variable    ${disc_cntl}    ${Empty}
    Check Count Integrity    ${switch_name}    expected_controllers=3
    ${old_owner}    ${old_candidates}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    Collections.List Should Not Contain Value    ${old_candidates}    ${old_owner}
    ${old_master}=     BuiltIn.Set Variable    ${ODL_SYSTEM_${old_owner}_IP}
    OvsManager.Disconnect Switch From Controller And Verify Disconnected    ${switch_name}    ${old_master}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${old_master}
    ${new_master}=    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Verify New Master Controller Node    ${switch_name}    ${old_master}
    ${owner}    ${candidates}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    Collections.List Should Not Contain Value    ${candidates}    ${owner}
    Collections.List Should Contain Value    ${old_candidates}    ${owner}
    Check Count Integrity    ${switch_name}    expected_controllers=2
    BuiltIn.Should Be Equal As Strings    ${new_master}    ${ODL_SYSTEM_${owner}_IP}
    # reconnection old master part
    OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${old_master}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${Empty}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Verify Follower Added    ${switch_name}    ${old_owner}
    ${new_owner}    ${new_candidates}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    Collections.List Should Not Contain Value    ${new_candidates}    ${new_owner}
    Check Count Integrity    ${switch_name}    expected_controllers=3
    BuiltIn.Should Be Equal     ${owner}    ${new_owner}
    Collections.List Should Contain Value    ${new_candidates}    ${old_owner}
    # disconnect any follower, old and new prefixes are reset again
    ${old_owner}    ${old_candidates}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    ${old_candidate}=    Collections.Get From List    ${old_candidates}    0
    ${old_slave}=      BuiltIn.Set Variable    ${ODL_SYSTEM_${old_candidate}_IP}
    OvsManager.Disconnect Switch From Controller And Verify Disconnected    ${switch_name}    ${old_slave}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${old_slave}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check Count Integrity    ${switch_name}    expected_controllers=2
    ${owner}    ${candidates}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    BuiltIn.Should Be Equal    ${owner}    ${old_owner}
    Collections.List Should Not Contain Value    ${candidates}    ${old_candidate}
    # reconnect follower again
    OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${old_slave}
    BuiltIn.Set Test Variable    ${disc_cntl}    ${Empty}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check Count Integrity    ${switch_name}    expected_controllers=3
    ${new_owner}    ${new_candidates}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    Collections.List Should Not Contain Value    ${new_candidates}    ${new_owner}
    BuiltIn.Should Be Equal    ${old_owner}    ${new_owner}
    Collections.List Should Contain Value    ${new_candidates}    ${old_candidate}
    [Teardown]    Run Keyword If    "${disc_cntl}"!="${Empty}"    OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${disc_cntl}

Check Count Integrity
    [Arguments]    ${switch_name}    ${expected_controllers}=3
    [Documentation]    Every switch must have only one master and rest must be followers and together must be of expected nodes count
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${followers}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    Collections.Append To List    ${followers}    ${owner}
    ${count}=    BuiltIn.Get Length    ${followers}
    BuiltIn.Should Be Equal As Numbers    ${expected_controllers}    ${count}

Verify New Master Controller Node
    [Arguments]    ${switch_name}    ${old_master}
    [Documentation]    Checks if given node is different from actual master
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${followers}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    ${new_master}    BuiltIn.Set Variable    ${ODL_SYSTEM_${owner}_IP}
    BuiltIn.Should Not Be Equal    ${old_master}    ${new_master}
    Return From Keyword    ${new_master}

Verify Follower Added
    [Arguments]    ${switch_name}    ${expected_node}
    [Documentation]    Checks if given node is in the list of active followers
    ${idx}=    BuiltIn.Evaluate    "${switch_name}"[1:]
    ${owner}    ${followers}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    Collections.List Should Contain Value    ${followers}    ${expected_node}
