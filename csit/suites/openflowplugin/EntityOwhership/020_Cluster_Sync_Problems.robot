*** Settings ***
Documentation     Test suite for entity ownership service and openflowplugin. Makes changes on controller side (isolating cluster node)
Suite Setup       Start Suite
Suite Teardown    End Suite
Test Template     Restarting Karaf Scenario
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
@{CONTROLLER_NODES}    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}

*** Test Cases ***
Switches To Be Connected To All Nodes
    [Documentation]    Initial check for correct connected topology.
    [Template]    NONE
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check All Switches Connected To All Cluster Nodes

Isolating Owner Of Switch s1
    s1

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
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    OvsManager.Set Bridge Controllers    s${sid}    ${cntls_list}
    RequestsLibrary.Create Session    ${ODL_SYSTEM_1_IP}    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    RequestsLibrary.Create Session    ${ODL_SYSTEM_2_IP}    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    RequestsLibrary.Create Session    ${ODL_SYSTEM_3_IP}    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Set Suite Variable    ${active_session}    ${ODL_SYSTEM_1_IP}
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

Restarting Karaf Scenario
    [Arguments]    ${switch_name}
    [Documentation]    Disconnect and connect master and follower and check switch data to be consistent
    # disconnection master part
    BuiltIn.Set Test Variable    ${isol_node}    ${None}
    Check Count Integrity    ${switch_name}    expected_controllers=3
    ${old_master}=    OvsManager.Get Master Node    ${switch_name}    update_data=${False}
    ${old_followers}=    OvsManager.Get Follower Nodes    ${switch_name}    update_data=${False}
    ClusterKeywords.Isolate a Controller From Cluster    ${old_master}    @{CONTROLLER_NODES}
    BuiltIn.Set Test Variable    ${isol_node}    ${old_master}
    ${new_master}=    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Verify New Master Controller Node    ${switch_name}    ${old_master}
    Collections.List Should Contain Value    ${old_followers}    ${new_master}
    Check Count Integrity    ${switch_name}    expected_controllers=2
    # reconnection old master part
    ClusterKeywords.Rejoin a Controller To Cluster    ${old_master}    @{CONTROLLER_NODES}
    BuiltIn.Set Test Variable    ${isol_node}    ${None}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Verify Follower Added    ${switch_name}    ${old_master}
    ${new_master_prove}=    OvsManager.Get Master Node    ${switch_name}    update_data=${True}
    BuiltIn.Should Be Equal    ${new_master}    ${new_master_prove}
    Check Count Integrity    ${switch_name}    expected_controllers=3
    # disconnect any follower, old and new prefixes are reset again
    ${old_master}=    OvsManager.Get Master Node    ${switch_name}    update_data=${False}
    ${old_followers}=    OvsManager.Get Follower Nodes    ${switch_name}    update_data=${False}
    ${old_follower}=    Collections.Get From List    ${old_followers}    0
    ClusterKeywords.Isolate a Controller From Cluster    ${old_follower}    @{CONTROLLER_NODES}
    BuiltIn.Set Test Variable    ${isol_node}    ${old_follower}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check Count Integrity    ${switch_name}    expected_controllers=2
    ${master}=    OvsManager.Get Master Node    ${switch_name}    update_data=${False}
    ${followers}=    OvsManager.Get Follower Nodes    ${switch_name}    update_data=${False}
    BuiltIn.Should Be Equal    ${master}    ${old_master}
    Collections.List Should Not Contain Value    ${followers}    ${old_follower}
    # reconnect follower again
    ClusterKeywords.Rejoin a Controller To Cluster    ${old_follower}    @{CONTROLLER_NODES}
    BuiltIn.Set Test Variable    ${isol_node}    ${None}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Check Count Integrity    ${switch_name}    expected_controllers=3
    ${master}=    OvsManager.Get Master Node    ${switch_name}    update_data=${False}
    ${followers}=    OvsManager.Get Follower Nodes    ${switch_name}    update_data=${False}
    BuiltIn.Should Be Equal    ${master}    ${old_master}
    Collections.List Should Contain Value    ${followers}    ${old_follower}
    [Teardown]    Run Keyword If    "${isol_node}"!=${None}    ClusterKeywords.Rejoin a Controller To Cluster    ${isol_cntl}    @{CONTROLLER_NODES}

Check Count Integrity
    [Arguments]    ${switch_name}    ${expected_controllers}=3
    [Documentation]    Every switch must have only one master and rest must be followers and together must be of expected nodes count
    SSHLibrary.Switch Connection    ${mininet_conn_id}
    OvsManager.Get Ovsdb Data
    ${master}=    OvsManager.Get Master Node    ${switch_name}    update_data=${False}
    ${followers}=    OvsManager.Get Follower Nodes    ${switch_name}    update_data=${False}
    Collections.Append To List    ${followers}    ${master}
    ${count}=    BuiltIn.Get Length    ${followers}
    BuiltIn.Should Be Equal As Numbers    ${expected_controllers}    ${count}

Verify New Master Controller Node
    [Arguments]    ${switch_name}    ${old_master}
    [Documentation]    Checks if given node is different from actual master
    SSHLibrary.Switch Connection    ${mininet_conn_id}
    ${new_master}=    OvsManager.Get Master Node    ${switch_name}    update_data=${True}
    BuiltIn.Should Not Be Equal    ${old_master}    ${new_master}
    Return From Keyword    ${new_master}

Verify Follower Added
    [Arguments]    ${switch_name}    ${expected_node}
    [Documentation]    Checks if given node is in the list of active followers
    SSHLibrary.Switch Connection    ${mininet_conn_id}
    ${followers}=    OvsManager.Get Follower Nodes    ${switch_name}    update_data=${True}
    Collections.List Should Contain Value    ${followers}    ${expected_node}
