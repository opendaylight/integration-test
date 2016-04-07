*** Settings ***
Documentation     Test suite for entity ownership service and openflowplugin
Suite Setup       Start Suite
Suite Teardown    End Suite
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Library           Collections

*** Variables ***
${SWITCHES}       5
${tested_switch}     s3
#${START_CMD}          sudo python DynamicMininet.py
${START_CMD}         sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --controller=remote,ip=${ODL_SYSTEM_2_IP} --controller=remote,ip=${ODL_SYSTEM_3_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
#${START_CMD}         sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13

*** Test Cases ***
Test Switches To Be Connected To All Nodes
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Check All Switches Connected To All Cluster Nodes

Get Master Node For Switch ${tested_switch}
    ${old_master_node}=     OvsManager.Get Master Node     ${tested_switch}      update_data=${True}
    Set Suite Variable   ${old_master_node}
    Run Keyword If    "${old_master_node}"=="${ODL_SYSTEM_1_IP}"    OvsManager.Should Be Master    ${tested_switch}    ${ODL_SYSTEM_1_IP}
    Run Keyword If    "${old_master_node}"!="${ODL_SYSTEM_1_IP}"    OvsManager.Should Be Slave     ${tested_switch}    ${ODL_SYSTEM_1_IP}
    Run Keyword If    "${old_master_node}"=="${ODL_SYSTEM_2_IP}"    OvsManager.Should Be Master    ${tested_switch}    ${ODL_SYSTEM_2_IP}
    Run Keyword If    "${old_master_node}"!="${ODL_SYSTEM_2_IP}"    OvsManager.Should Be Slave     ${tested_switch}    ${ODL_SYSTEM_2_IP}
    Run Keyword If    "${old_master_node}"=="${ODL_SYSTEM_3_IP}"    OvsManager.Should Be Master    ${tested_switch}    ${ODL_SYSTEM_3_IP}
    Run Keyword If    "${old_master_node}"!="${ODL_SYSTEM_3_IP}"    OvsManager.Should Be Slave     ${tested_switch}    ${ODL_SYSTEM_3_IP}

Disconnect Master Controller From Switch
    OvsManager.Disconnect Switch From Controller And Verify    ${tested_switch}     ${old_master_node}

Verify New Master Controller Node
    ${new_master_node}=      BuiltIn.Wait Until Keyword Succeeds    10s    2s    OvsManager.Get Master Node     ${tested_switch}      update_data=${True}
    BuiltIn.Should Not Be Equal    ${old_master_node}    ${new_master_node}
    Set Suite Variable   ${new_master_node}
    ${followers}=    OvsManager.Get Follower Nodes    ${tested_switch}
    Collections.List Should Not Contain Value    ${followers}    ${new_master_node}

Reconnect Old Master Controller To Switch
    OvsManager.Reconnect Switch To Controller And Verify    ${tested_switch}     ${old_master_node}
    ${mas}=   OvsManager.Get Master Node     ${tested_switch}      update_data=${True}
    ${fol}=   OvsManager.Get Follower Nodes    ${tested_switch}    update_data=${True}
    OvsManager.Should Be Connected    ${tested_switch}    ${ODL_SYSTEM_1_IP}
    OvsManager.Should Be Connected    ${tested_switch}    ${ODL_SYSTEM_2_IP}
    OvsManager.Should Be Connected    ${tested_switch}    ${ODL_SYSTEM_3_IP}
    OvsManager.Should Be Slave     ${tested_switch}     ${old_master_node}
    OvsManager.Should Be Master     ${tested_switch}     ${new_master_node}


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
    #SSHLibrary.Write    start_switches_with_cluster ${SWITCHES} ${ODL_SYSTEM_IP},${ODL_SYSTEM_2_IP},${ODL_SYSTEM_3_IP}
    #SSHLibrary.Read Until    mininet>
    RequestsLibrary.Create Session    session1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    RequestsLibrary.Create Session    session2    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    RequestsLibrary.Create Session    session3    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Wait Until Keyword Succeeds    10s    1s    Are Switches Connected Topo

End Suite
    # TODO: rest finish
    Utils.Stop Suite

Are Switches Connected Topo
    [Documentation]    Checks wheather switches are connected to controller
    ${resp}=    RequestsLibrary.Get Request    session1    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    BuiltIn.Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    BuiltIn.Should Be Equal As Numbers    ${count}    ${SWITCHES}

Check All Switches Connected To All Cluster Nodes
    OvsManager.Get Ovsdb Data
    :FOR    ${i}    IN RANGE    1   ${SWITCHES}
    \     ${sid}=   BuiltIn.Evaluate         ${i}+1
    \     OvsManager.Should Be Connected     s${sid}       ${ODL_SYSTEM_1_IP}     update_data=${False}
    \     OvsManager.Should Be Connected     s${sid}       ${ODL_SYSTEM_2_IP}     update_data=${False}
    \     OvsManager.Should Be Connected     s${sid}       ${ODL_SYSTEM_3_IP}     update_data=${False}
