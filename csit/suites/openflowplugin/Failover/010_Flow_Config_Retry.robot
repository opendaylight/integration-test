*** Settings ***
Documentation     Test suite for FRM failover states
Test Setup        Test Start
Test Teardown     Test End
Library           SSHLibrary
Library           RequestsLibrary
Library           XML
Library           Collections
Library           String
Library           ${CURDIR}/../../../libraries/OVSFlowDumpParser.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/OvsManager.robot
Resource          ${CURDIR}/../../../libraries/ClusterKeywords.robot

*** Variables ***
${SWITCHES}             1
${FLOW_TABLE_ID}        0
${FLOW_BLAST_COUNT}     1000
# this is for mininet 2.2.1 ${START_CMD}    sudo mn --controller=remote,ip=${ODL_SYSTEM_1_IP} --controller=remote,ip=${ODL_SYSTEM_2_IP} --controller=remote,ip=${ODL_SYSTEM_3_IP} --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${START_CMD}            sudo mn --topo linear,${SWITCHES} --switch ovsk,protocols=OpenFlow13
${FLOW_BLASTER_FILE}             ${CURDIR}/../../../libraries/blast-flows.py
${FLOW_BLASTER_TEMPLATE_FILE}    ${CURDIR}/../../../variables/openflowplugin/blast_flow_template.json
${FLOW_BLASTER_ARGS}             --end-id=${FLOW_BLAST_COUNT} --node=
@{CONTROLLER_NODES}              ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
${KARAF_HOME}                    ${WORKSPACE}/${BUNDLEFOLDER}


*** Test Cases ***
RPC FlatBatch Failover
   [Documentation]    Disconnects switch leader and switch during flow configuration on switch. Checks for registering and using new leader's RPC
   ${switch_name}=    BuiltIn.Set Variable    s1
   ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
   ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
   ${follower_idx}=    BuiltIn.Evaluate    ${sw_followers_idx_list}[0]
   Blast Flows     ${follower_idx}
   OvsManager.Disconnect Switch From Controller And Verify Disconnected    ${switch_name}    ${sw_leader_ip}
   BuiltIn.Wait Until Keyword Succeeds    5x    5s    Verify New Switch Leader    ${switch_name}    ${sw_leader_ip}
   BuiltIn.Wait Until Keyword Succeeds    5x    5s    Check Flow All Nodes    ${switch_name}    @{controller_index_list}
   OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${sw_leader_ip}


FRM Failover Isolate
   [Documentation]    Isolates Datastore Leader during flow configuration on switch and then reconnects it
   ${switch_name}=    BuiltIn.Set Variable    s1
   ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
   ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
   ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${ds_leader_idx}_IP}
   ${follower_idx}=    BuiltIn.Evaluate    ${ds_followers_idx_list}[0]
   Blast Flows     ${follower_idx}
   ClusterKeywords.Isolate a Controller From Cluster     ${ds_leader_ip}    @{CONTROLLER_NODES}
   ${status_flows}    ${return_flows}=            BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Check Flow All Nodes    ${switch_name}    @{ds_followers_idx_list}
   ${status_elections}    ${return_elections}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Verify New DS Leader    ${ds_leader_ip}    @{ds_followers_idx_list}
   BuiltIn.Log    ${status_flows}
   BuiltIn.Log    ${status_elections}
   ClusterKeywords.Rejoin a Controller To Cluster     ${ds_leader_ip}    @{CONTROLLER_NODES}
   ClusterKeywords.Wait For Controller Sync     10 m    ${ds_leader_ip}
   BuiltIn.Should Be True 	  '${status_flows}' == 'PASS'
   BuiltIn.Should Be True 	  '${status_elections}' == 'PASS'


RPC FlatBatch And FRM Failover Isolate
   [Documentation]    Isolates Datastore Leader during flow configuration on switch and then reconnects it
   ${switch_name}=    BuiltIn.Set Variable    s1
   ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
   ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
   ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${ds_leader_idx}_IP}
   ${follower_idx}=    BuiltIn.Evaluate    ${ds_followers_idx_list}[0]
   Blast Flows     ${follower_idx}
   ClusterKeywords.Isolate a Controller From Cluster     ${ds_leader_ip}    @{CONTROLLER_NODES}
   OvsManager.Disconnect Switch From Controller And Verify Disconnected    ${switch_name}    ${sw_leader_ip}
   ${status_flows}    ${return_flows}=            BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Check Flow All Nodes    ${switch_name}    @{ds_followers_idx_list}
   ${status_elections_ds}    ${return_elections_ds}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Verify New DS Leader    ${ds_leader_ip}    @{ds_followers_idx_list}
   ${status_elections_sw}    ${return_elections_sw}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Verify New Switch Leader    ${switch_name}    ${sw_leader_ip}
   BuiltIn.Log    ${status_flows}
   BuiltIn.Log    ${status_elections_ds}
   BuiltIn.Log    ${status_elections_sw}
   ClusterKeywords.Rejoin a Controller To Cluster     ${ds_leader_ip}    @{CONTROLLER_NODES}
   ClusterKeywords.Wait For Controller Sync     10 m    ${ds_leader_ip}
   OvsManager.Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${sw_leader_ip}
   BuiltIn.Should Be True 	  '${status_flows}' == 'PASS'
   BuiltIn.Should Be True 	  '${status_elections_ds}' == 'PASS'
   BuiltIn.Should Be True 	  '${status_elections_sw}' == 'PASS'


FRM Failover Kill
   [Documentation]    Kills Datastore Leader karaf during flow configuration on switch and then restarts it
   ${switch_name}=    BuiltIn.Set Variable    s1
   ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
   ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
   ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${ds_leader_idx}_IP}
   ${follower_idx}=    BuiltIn.Evaluate    ${ds_followers_idx_list}[0]
   @{kill_controler_idx_list}=    BuiltIn.Create List     ${ds_leader_idx}
   BuiltIn.Set Suite Variable    ${active_session}    controller${follower_idx}
   Blast Flows     ${follower_idx}
   ClusterKeywords.Kill Multiple Controllers     @{kill_controler_idx_list}
   ${status_flows}    ${return_flows}=            BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Check Flow All Nodes    ${switch_name}    @{ds_followers_idx_list}
   ${status_elections}    ${return_elections}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    3s    Verify New DS Leader    ${ds_leader_ip}    @{ds_followers_idx_list}
   BuiltIn.Log    ${status_flows}
   BuiltIn.Log    ${status_elections}
   ClusterKeywords.Start Controller Node And Verify     ${ds_leader_ip}    5 m
   BuiltIn.Should Be True 	  '${status_flows}' == 'PASS'
   BuiltIn.Should Be True 	  '${status_elections}' == 'PASS'


SW Restart Node Isolate Reconciliation
    [Setup]    Test Start Without Mininet
    ${ctrl_idx}=    BuiltIn.Evaluate    ${controller_index_list}[0]
    ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
    ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${ds_leader_idx}_IP}
    ${switch_name}=    BuiltIn.Set Variable    s1
    Blast Flows     ${ctrl_idx}
    Start Mininet
    BuiltIn.Wait Until Keyword Succeeds    10x    1m    Are All Flows In Operational    controller${ds_leader_idx}    ${switch_name}
    Restart Switch
    ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
    ClusterKeywords.Isolate a Controller From Cluster     ${sw_leader_ip}    @{CONTROLLER_NODES}
    ${status_flows}    ${return_flows}=            BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Check Flow All Nodes    ${switch_name}    @{ds_followers_idx_list}
    ${status_elections_sw}    ${return_elections_sw}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Verify New Switch Leader    ${switch_name}    ${sw_leader_ip}
    BuiltIn.Log    ${status_flows}
    BuiltIn.Log    ${status_elections_sw}
    ClusterKeywords.Rejoin a Controller To Cluster     ${ds_leader_ip}    @{CONTROLLER_NODES}
    ClusterKeywords.Wait For Controller Sync     10 m    ${ds_leader_ip}
    BuiltIn.Should Be True 	  '${status_flows}' == 'PASS'
    BuiltIn.Should Be True 	  '${status_elections_sw}' == 'PASS'


SW Restart Node Kill Reconciliation
    [Setup]    Test Start Without Mininet
    ${ctrl_idx}=    BuiltIn.Evaluate    ${controller_index_list}[0]
    ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
    ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${ds_leader_idx}_IP}
    ${switch_name}=    BuiltIn.Set Variable    s1
    @{kill_controler_idx_list}=    BuiltIn.Create List     ${ds_leader_idx}
    ${follower_idx}=    BuiltIn.Evaluate    ${ds_followers_idx_list}[0]
    BuiltIn.Set Suite Variable    ${active_session}    controller${follower_idx}
    Blast Flows     ${ctrl_idx}
    Start Mininet
    BuiltIn.Wait Until Keyword Succeeds    10x    1m    Are All Flows In Operational    controller${ds_leader_idx}    ${switch_name}
    Restart Switch
    ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
    ClusterKeywords.Kill Multiple Controllers     @{kill_controler_idx_list}
    ${status_elections_sw}    ${return_elections_sw}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Verify New Switch Leader    ${switch_name}    ${sw_leader_ip}
    ${status_flows}    ${return_flows}=            BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    5x    5s    Check Flow All Nodes    ${switch_name}    @{ds_followers_idx_list}
    BuiltIn.Log    ${status_flows}
    BuiltIn.Log    ${status_elections_sw}
    ClusterKeywords.Start Controller Node And Verify     ${ds_leader_ip}    5 m
    BuiltIn.Should Be True    '${status_flows}' == 'PASS'
    BuiltIn.Should Be True    '${status_elections_sw}' == 'PASS'


RPC FlatBatch And FRM Failover Isolate With New Flows
    [Documentation]    Isolates Datastore Leader during flow configuration on switch and then reconnects it, then adds new flow group to test that isolated node was disabled
    ${switch_name}=    BuiltIn.Set Variable    s1
    ${sw_leader_ip}    ${sw_leader_idx}    ${sw_followers_idx_list}=    Get Switch Leader    ${switch_name}
    ${old_ds_leader_idx}    ${old_ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${controller_index_list}    operational    inventory
    ${old_ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_ds_leader_idx}_IP}
    ${follower_idx}=    BuiltIn.Evaluate    ${old_ds_followers_idx_list}[0]
    Blast Flows     ${old_ds_leader_idx}    ${FLOW_BLASTER_TEMPLATE_FILE}
    ClusterKeywords.Isolate a Controller From Cluster     ${old_ds_leader_ip}    @{CONTROLLER_NODES}
    ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${old_ds_followers_idx_list}    operational    inventory
    ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${old_ds_leader_idx}_IP}
    ${status_elections_ds}    ${return_elections_ds}=    BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    10x    5s    Verify New DS Leader    ${old_ds_leader_ip}    @{old_ds_followers_idx_list}
    Blast Flows     ${ds_leader_idx}    ${FLOW_BLASTER_TEMPLATE_FILE}
    ${status_flows}    ${return_flows}=            BuiltIn.Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    10x    5s    Check Flow All Nodes    ${switch_name}    @{ds_followers_idx_list}
    BuiltIn.Log    ${status_elections_ds}
    BuiltIn.Log    ${status_flows}
    ClusterKeywords.Rejoin a Controller To Cluster     ${old_ds_leader_ip}    @{CONTROLLER_NODES}
    ClusterKeywords.Wait For Controller Sync     30 m    ${old_ds_leader_ip}
    BuiltIn.Should Be True       '${status_elections_ds}' == 'PASS'
    BuiltIn.Should Be True       '${status_flows}' == 'PASS'


*** Keywords ***
Start Mininet
    SSHLibrary.Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    SSHLibrary.Execute Command    sudo mn -c
    SSHLibrary.Write    ${START_CMD}
    SSHLibrary.Read Until    mininet>
    OvsManager.Setup Clustered Controller For Switches    ${switch_list}    ${controller_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    20 x    1 m    Are Switches Connected Topo
    BuiltIn.Wait Until Keyword Succeeds    20 x    1 m    Check All Switches Connected To All Cluster Nodes


Test Start
    Test Start Without Mininet
    Start Mininet


Test Start Without Mininet
    ${tools_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    timeout=1 m    alias=tools
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${TOOLS_SYSTEM_PROMPT}    alias=mininet
    SSHLibrary.Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${controller_ip_list}    BuiltIn.Create List    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    ${switch_list}    BuiltIn.Create List
    ${controller_index_list}     BuiltIn.Create List
    : FOR    ${i}    IN RANGE    0    ${SWITCHES}
    \    ${sid}=    BuiltIn.Evaluate    ${i}+1
    \    Collections.Append To List    ${switch_list}    s${sid}
    : FOR    ${i}    IN RANGE    0    ${NUM_ODL_SYSTEM}
    \    ${cid}=    BuiltIn.Evaluate    ${i}+1
    \    Collections.Append To List    ${controller_index_list}    ${cid}
    \    RequestsLibrary.Create Session    controller${cid}    http://${ODL_SYSTEM_${cid}_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
    BuiltIn.Set Suite Variable    ${active_session}    controller1
    BuiltIn.Set Suite Variable    ${mininet_conn_id}
    BuiltIn.Set Suite Variable    ${tools_conn_id}
    BuiltIn.Set Suite Variable    ${controller_index_list}
    BuiltIn.Set Suite Variable    ${controller_ip_list}
    BuiltIn.Set Suite Variable    ${switch_list}
    [Return]    ${switch_list}    ${controller_ip_list}


Test End
    ${localhost_conn_id}=    SSHLibrary.Open Connection    127.0.0.1    prompt=${DEFAULT_LINUX_PROMPT}    alias=localhost
    SSHLibrary.Login With Public Key    ${DEFAULT_USER}    ${USER_HOME}/.ssh/id_rsa    any
    ${resp}=    RequestsLibrary.Delete Request    ${active_session}    ${CONFIG_NODES_API}
    BuiltIn.Log    ${resp.status_code}
    Utils.Stop Suite
    BuiltIn.Wait Until Keyword Succeeds    20 x    30 s    Verify Cluster DS Cleared
    RequestsLibrary.Delete All Sessions
    SSHLibrary.Close All Connections


Restart Switch
    ${current_conn_id}=     SSHLibrary.Get Connection    index=True
    SSHLibrary.Switch Connection     ${mininet_conn_id}
    BuiltIn.Log    Exiting mininet
    SSHLibrary.Read
    SSHLibrary.Write    exit
    SSHLibrary.Read Until Prompt
    BuiltIn.Log    Restarting mininet
    Start Mininet
    BuiltIn.Run Keyword Unless      ${current_conn_id}==${None}    SSHLibrary.Switch Connection    ${current_conn_id}


Cleanup Config Flows
    [Arguments]     ${session}    ${config_flows}
    ${flow_ids_list}=     Extract Property    ${config_flows}     id
    Variable Should Exist


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


Get Config And Oper DS Flows
    [Arguments]    ${session}    ${node}    ${table_id}
    ${config_resp}=    RequestsLibrary.Get Request    ${session}    ${CONFIG_NODES_API}/node/${node}/table/${table_id}
    BuiltIn.Log    ${config_resp}
    Should Be Equal As Integers    ${config_resp.status_code}    200
    ${oper_resp}=    RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_NODES_API}/node/${node}/table/${table_id}
    BuiltIn.Log    ${oper_resp}
    Should Be Equal As Integers    ${oper_resp.status_code}    200
    [Return]    ${config_resp.content}    ${oper_resp.content}


Read Until Promt Without Timeout
    [Arguments]    ${prompt}    ${delay}=5 s
    ${output}=    Read    delay=${delay}
    Should Contain 	${output} 	${prompt}
    [Return]    ${output}


Get Switch Leader
    [Arguments]    ${switch_name}
    ${idx}=    BuiltIn.Evaluate    str("${switch_name}"[1:])
    ${leader_idx}    ${followers_idx_list}=    ClusterKeywords.Get Device Entity Owner And Followers Indexes    ${active_session}    openflow    openflow:${idx}
    ${leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${leader_idx}_IP}
    [Return]    ${leader_ip}    ${leader_idx}    ${followers_idx_list}


Verify New Switch Leader
    [Arguments]    ${switch_name}    ${old_leader_ip}
    ${leader_ip}    ${leader_idx}    ${followers_idx_list}=    Get Switch Leader    ${switch_name}
    BuiltIn.Should Not Be Equal    ${leader_ip}    ${old_leader_ip}


Verify New DS Leader
    [Arguments]    ${old_leader_ip}    @{cluster_node_idx_list}
    ${ds_leader_idx}    ${ds_followers_idx_list}=    ClusterKeywords.Get Cluster Shard Status    ${cluster_node_idx_list}    operational    inventory
    ${ds_leader_ip}=    BuiltIn.Set Variable    ${ODL_SYSTEM_${ds_leader_idx}_IP}
    BuiltIn.Should Not Be Equal    ${ds_leader_ip}    ${old_leader_ip}


Get Flow Dump
    [Arguments]    ${switch_name}
    ${current_conn_id}=     SSHLibrary.Get Connection    index=True
    SSHLibrary.Switch Connection     ${tools_conn_id}
    SSHLibrary.Write    sudo ovs-ofctl dump-flows ${switch_name} -O OpenFlow13
#    ${dump}=    SSHLibrary.Read Until Prompt
    ${dump}=    Read Until Promt Without Timeout    ${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Log    ${dump}
    BuiltIn.Run Keyword Unless      ${current_conn_id}==${None}    SSHLibrary.Switch Connection    ${current_conn_id}
    [Return]    ${dump}


Check OVS Flow By Cookie
    [Arguments]    ${switch_name}    ${cookie}
    ${cookie_hex_upper}=    Convert To Hex 	${cookie} 	prefix=0x
    ${cookie_hex}=    String.Convert To Lowercase    ${cookie_hex_upper}
    ${current_conn_id}=     SSHLibrary.Get Connection    index=True
    SSHLibrary.Switch Connection     ${tools_conn_id}
    SSHLibrary.Write    sudo ovs-ofctl dump-flows ${switch_name} cookie=${cookie_hex}/-1 -O OpenFlow13
    ${dump}=    SSHLibrary.Read Until Prompt
#    ${dump}=    Read Until Promt Without Timeout    ${TOOLS_SYSTEM_PROMPT}
    BuiltIn.Log    ${dump}
    BuiltIn.Should Contain    ${dump}    cookie=${cookie_hex}
    BuiltIn.Run Keyword Unless      ${current_conn_id}==${None}    SSHLibrary.Switch Connection    ${current_conn_id}
    [Return]    ${dump}


Blast Flows
    [Arguments]    ${odl_system_num}    ${template_file}=''
    ${current_conn_id}=     SSHLibrary.Get Connection    index=True
    ${localhost_conn_id}=    SSHLibrary.Open Connection    127.0.0.1    prompt=${DEFAULT_LINUX_PROMPT}
    SSHLibrary.Login With Public Key    ${DEFAULT_USER}    ${USER_HOME}/.ssh/id_rsa    any
    SSHLibrary.Start Command    python ${FLOW_BLASTER_FILE} ${FLOW_BLASTER_ARGS}${ODL_SYSTEM_${odl_system_num}_IP} --template-file=${template_file}
    BuiltIn.Run Keyword Unless      ${current_conn_id}==${None}    SSHLibrary.Switch Connection    ${current_conn_id}


Check Flow All Nodes
    [Arguments]    ${switch_name}     @{cluster_nodes_idx_list}
    : FOR    ${cid}    IN    @{cluster_nodes_idx_list}
    \    Check Flows DS To SW Dump    controller${cid}    ${switch_name}


Check Flows DS To SW Dump
    [Arguments]     ${session}    ${switch_name}    ${flow_count}=${FLOW_BLAST_COUNT}
    ${switch_idx}=     BuiltIn.Evaluate    "${switch_name}"[1:]
#    ${flow_dump}=      Get Flow Dump    ${switch_name}
#    BuiltIn.Log    ${flow_dump}
#    ${flow_list}=      Parse Flow Dump    ${flow_dump}
#    BuiltIn.Log    ${flow_list}
    ${config}    ${oper}=    Get Config And Oper DS Flows    ${session}    openflow:${switch_idx}    ${FLOW_TABLE_ID}
    ${config_flows}=     Get Table Flows From Response    ${config}
    ${oper_flows}=       Get Table Flows From Response    ${oper}
    ${cookie_list}=      Extract Property    ${config_flows}     cookie
    BuiltIn.Log    ${config_flows} with cookies list ${cookie_list}
    BuiltIn.Log    ${oper_flows}
    Length Should Be    ${cookie_list}    ${flow_count}
    : FOR    ${cookie}     IN    @{cookie_list}
    \    ${entries}=    Get Elements With Parameter Value    ${oper_flows}    cookie    ${cookie}
    \    BuiltIn.Log    Operational flows with cookie=${cookie}: ${entries}
#    \    ${entries}=    Get Elements With Parameter Value    ${flow_list}    cookie    ${cookie}
#    \    BuiltIn.Log    Flow dump flows with cookie=${cookie}: ${entries}
#    \    BuiltIn.Should Not Be Empty    ${entries}
    \    Check OVS Flow By Cookie    ${switch_name}    ${cookie}
    \    BuiltIn.Should Not Be Empty    ${entries}


Are All Flows In Operational
    [Arguments]     ${session}    ${switch_name}    ${table_id}=${FLOW_TABLE_ID}     ${flow_count}=${FLOW_BLAST_COUNT}
    ${switch_idx}=       BuiltIn.Evaluate    str("${switch_name}"[1:])
    ${resp}=      RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_TOPO_API}
    BuiltIn.Log    Operational Topology: ${resp.content}
    ${resp}=      RequestsLibrary.Get Request    ${session}    ${CONFIG_NODES_API}
    BuiltIn.Log    Config Inventory: ${resp.content}
    ${resp}=      RequestsLibrary.Get Request    ${session}    ${OPERATIONAL_NODES_API}/node/openflow:${switch_idx}/table/${table_id}
    BuiltIn.Log    Operational Inventory: ${resp.content}
    ${flows}=     Get Table Flows From Response    ${resp.content}
    ${cookie_list}=      Extract Property    ${flows}     cookie
    ${cookie_list}=      Sort Cookie List    ${cookie_list}
    Collections.Log List    ${cookie_list}
    Should Be Equal As Integers    ${resp.status_code}    200
    Length Should Be    ${cookie_list}    ${flow_count}


Verify Cluster DS Cleared
    : FOR    ${i}    IN    @{controller_index_list}
    \    ${resp}=    RequestsLibrary.Get Request    controller${i}    ${CONFIG_NODES_API}
    \    BuiltIn.Log    Config: ${resp.content}
    \    ${resp}=    RequestsLibrary.Get Request    controller${i}    ${OPERATIONAL_NODES_API}
    \    BuiltIn.Log    Operational: ${resp.content}
    \    ${resp}=    RequestsLibrary.Get Request    controller${i}    /restconf/operational/entity-owners:entity-owners
    \    BuiltIn.Log    Entity owners: ${resp.content}
