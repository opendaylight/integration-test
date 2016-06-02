*** Settings ***
Documentation     Test suite for FRM failover states
Test Setup        Test Start
Test Teardown     Test End
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Library           Collections
Library           String
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OvsManager.robot

*** Variables ***
${SWITCHES}            1
# this is for mininet 2.2.1 ${START_CMD}    sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --controller=remote,ip=${ODL_SYSTEM_2_IP} --controller=remote,ip=${ODL_SYSTEM_3_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_CMD}           sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
@{CONTROLLER_NODES}    ${ODL_SYSTEM_1_IP}
${KARAF_HOME}          ${WORKSPACE}/${BUNDLEFOLDER}
${FLOW_INVALID}        ${CURDIR}/../../../variables/openflowplugin/flow-invalid.json
${FLOW_VALID}          ${CURDIR}/../../../variables/openflowplugin/flow-valid.json


*** Test Cases ***
FRM Retry
   [Documentation]    FRM Retry test
   ${switch_name}=    BuiltIn.Set Variable    s1
   Put Flow    ${switch_name}    ${FLOW_INVALID}
   BuiltIn.Sleep    5 s
   ${resp}=    Check Flow    ${switch_name}
   BuiltIn.Should Be Equal As Integers    ${resp.status_code}    404
   Put Flow    ${switch_name}    ${FLOW_VALID}
   BuiltIn.Sleep    5 s
   ${resp}=    Check Flow    ${switch_name}
   BuiltIn.Should Be Equal As Integers    ${resp.status_code}    200


*** Keywords ***
Start Mininet
    SSHLibrary.Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    SSHLibrary.Execute Command    sudo mn -c
    SSHLibrary.Write    ${START_CMD}
    SSHLibrary.Read Until    mininet>
    BuiltIn.Wait Until Keyword Succeeds    5 x    1 m    Are Switches Connected


Test Start Without Mininet
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    alias=mininet
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${controller_ip_list}    BuiltIn.Create List    ${ODL_SYSTEM_1_IP}
    ${switch_list}    BuiltIn.Create List
    ${controller_index_list}     BuiltIn.Create List
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    Collections.Append To List    ${switch_list}    s${sid}
    RequestsLibrary.Create Session    controller    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
    BuiltIn.Set Suite Variable    ${active_session}    controller
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Set Suite Variable    ${controller_ip_list}
    BuiltIn.Set Suite Variable    ${switch_list}


Test Start
    Test Start Without Mininet
    Start Mininet


Test End
    Utils.Stop Suite
    RequestsLibrary.Delete All Sessions
    SSHLibrary.Close All Connections


Are Switches Connected
    [Documentation]    Checks wheather switches are connected to controller
    OvsManager.Get Ovsdb Data
    :FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    OvsManager.Should Be Connected    s${sid}    ${ODL_SYSTEM_1_IP}    update_data=${False}
    ${resp}=    RequestsLibrary.Get Request    ${active_session}    ${OPERATIONAL_TOPO_API}/topology/flow:1    headers=${ACCEPT_XML}
    BuiltIn.Log    ${resp.content}
    ${count}=    XML.Get Element Count    ${resp.content}    xpath=node
    BuiltIn.Should Be Equal As Numbers    ${count}    ${SWITCHES}


Put Flow
    [Arguments]    ${switch_name}    ${flow_json}
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    ${body}=    OperatingSystem.Get File    ${flow_json}
    ${resp}=    RequestsLibrary.Put Request    ${active_session}    ${CONFIG_NODES_API}/node/openflow:${idx}/table/0/flow/1    data=${body}
    BuiltIn.Log   ${resp.status_code} ${resp.content}


Check Flow
    [Arguments]    ${switch_name}
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    ${resp}=    RequestsLibrary.Get Request    ${active_session}    ${CONFIG_NODES_API}/node/openflow:${idx}
    BuiltIn.Log    Config: ${resp.status_code} ${resp.content}
    ${resp}=    RequestsLibrary.Get Request    ${active_session}    ${OPERATIONAL_NODES_API}/node/openflow:${idx}/table/0/flow/1
    BuiltIn.Log    Operational: ${resp.status_code} ${resp.content}
    [Return]    ${resp}