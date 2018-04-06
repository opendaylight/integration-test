*** Settings ***
Library           Collections
Library           ipaddress
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ClusterManagement.robot
Resource          Utils.robot
Resource          ${CURDIR}/TemplatedRequests.robot
Resource          ../variables/Variables.robot

*** Variables ***
${OVSDB_CONFIG_DIR}    ${CURDIR}/../variables/ovsdb
${OVSDB_NODE_PORT}    6634
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F
${SOUTHBOUND_NODE_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${TOOLS_SYSTEM_IP}:${OVSDB_NODE_PORT}

*** Keywords ***
Log Request
    [Arguments]    ${resp_content}
    ${resp_json} =    BuiltIn.Run Keyword If    '''${resp_content}''' != '${EMPTY}'    RequestsLibrary.To Json    ${resp_content}    pretty_print=True
    ...    ELSE    BuiltIn.Set Variable    ${EMPTY}
    BuiltIn.Log    ${resp_json}
    [Return]    ${resp_json}

Create OVSDB Node
    [Arguments]    ${node_ip}    ${port}=${OVSDB_NODE_PORT}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_node.json
    ${body} =    Replace String    ${body}    127.0.0.1    ${node_ip}
    ${body} =    Replace String    ${body}    61644    ${port}
    ${uri} =    Builtin.Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Post Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Connect To Ovsdb Node
    [Arguments]    ${node_ip}    ${port}=${OVSDB_NODE_PORT}
    [Documentation]    This will Initiate the connection to OVSDB node from controller
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${body} =    String.Replace String    ${body}    127.0.0.1    ${node_ip}
    ${body} =    String.Replace String    ${body}    61644    ${port}
    ${uri} =    BuiltIn.Set Variable    ${SOUTHBOUND_CONFIG_API}${node_ip}:${port}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Disconnect From Ovsdb Node
    [Arguments]    ${node_ip}    ${port}=${OVSDB_NODE_PORT}
    [Documentation]    This request will disconnect the OVSDB node from the controller
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}${node_ip}:${port}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Add Bridge To Ovsdb Node
    [Arguments]    ${node_id}    ${node_ip}    ${bridge}    ${datapath_id}    ${port}=${OVSDB_NODE_PORT}
    [Documentation]    This will create a bridge and add it to the OVSDB node.
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${body} =    String.Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://${node_id}
    ${body} =    String.Replace String    ${body}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${body} =    String.Replace String    ${body}    127.0.0.1    ${node_ip}
    ${body} =    String.Replace String    ${body}    br01    ${bridge}
    ${body} =    String.Replace String    ${body}    61644    ${port}
    ${body} =    String.Replace String    ${body}    0000000000000001    ${datapath_id}
    ${node_id_} =    BuiltIn.Evaluate    """${node_id}""".replace("/","%2F")
    ${uri} =    BuiltIn.Set Variable    ${SOUTHBOUND_CONFIG_API}${node_id_}%2Fbridge%2F${bridge}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete Bridge From Ovsdb Node
    [Arguments]    ${node_id}    ${bridge}
    [Documentation]    This request will delete the bridge node from the OVSDB
    ${resp} =    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}${node_id}%2Fbridge%2F${bridge}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200

Add Termination Point
    [Arguments]    ${node_id}    ${bridge}    ${tp_name}    ${remote_ip}=${TOOLS_SYSTEM_IP}
    [Documentation]    Using the json data body file as a template, a REST config request is made to
    ...    create a termination-point ${tp_name} on ${bridge} for the given ${node_id}. The ports
    ...    remote-ip defaults to ${TOOLS_SYSTEM_IP}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    ${body} =    String.Replace String    ${body}    192.168.0.21    ${remote_ip}
    ${body} =    String.Replace String    ${body}    vxlanport    ${tp_name}
    ${node_id_} =    BuiltIn.Evaluate    """${node_id}""".replace("/","%2F")
    ${uri} =    BuiltIn.Set Variable    ${SOUTHBOUND_CONFIG_API}${node_id_}%2Fbridge%2F${bridge}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}/termination-point/${tp_name}/    data=${body}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add Vxlan To Bridge
    [Arguments]    ${node_ip}    ${bridge}    ${vxlan_port}    ${remote_ip}    ${port}=${OVSDB_NODE_PORT}
    [Documentation]    This request will create vxlan port for vxlan tunnel and attach it to the specific bridge
    OVSDB.Add Termination Point    ${node_ip}:${port}    ${bridge}    ${vxlan_port}    ${remote_ip}

Verify OVS Reports Connected
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    Uses "vsctl show" to check for string "is_connected"
    ${output} =    Verify Ovs-vsctl Output    show    is_connected    ${tools_system}
    [Return]    ${output}

Verify Ovs-vsctl Output
    [Arguments]    ${vsctl_args}    ${expected_output}    ${ovs_system}=${TOOLS_SYSTEM_IP}    ${should_match}=True
    [Documentation]    A wrapper keyword to make it easier to validate ovs-vsctl output, and gives an easy
    ...    way to check this output in a WUKS. The argument ${should_match} can control if the match should
    ...    exist (True} or not (False) or don't care (anything but True or False). ${should_match} is True by default
    ${output} =    Utils.Run Command On Mininet    ${ovs_system}    sudo ovs-vsctl ${vsctl_args}
    BuiltIn.Log    ${output}
    BuiltIn.Run Keyword If    "${should_match}" == "True"    BuiltIn.Should Contain    ${output}    ${expected_output}
    BuiltIn.Run Keyword If    "${should_match}" == "False"    BuiltIn.Should Not Contain    ${output}    ${expected_output}
    [Return]    ${output}

Get OVSDB UUID
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_http_session}=session
    [Documentation]    Queries the topology in the operational datastore and searches for the node that has
    ...    the ${ovs_system_ip} argument as the "remote-ip". If found, the value returned will be the value of
    ...    node-id stripped of "ovsdb://uuid/". If not found, ${EMPTY} will be returned.
    ${uuid} =    Set Variable    ${EMPTY}
    ${resp} =    RequestsLibrary.Get Request    ${controller_http_session}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${resp_json} =    RequestsLibrary.To Json    ${resp.content}
    ${topologies} =    Collections.Get From Dictionary    ${resp_json}    topology
    ${topology} =    Collections.Get From List    ${topologies}    0
    ${node_list} =    Collections.Get From Dictionary    ${topology}    node
    BuiltIn.Log    ${node_list}
    # Since bridges are also listed as nodes, but will not have the extra "ovsdb:connection-info data,
    # we need to use "Run Keyword And Ignore Error" below.
    : FOR    ${node}    IN    @{node_list}
    \    ${node_id} =    Collections.Get From Dictionary    ${node}    node-id
    \    ${node_uuid} =    String.Replace String    ${node_id}    ovsdb://uuid/    ${EMPTY}
    \    ${status}    ${connection_info} =    BuiltIn.Run Keyword And Ignore Error    Collections.Get From Dictionary    ${node}    ovsdb:connection-info
    \    ${status}    ${remote_ip} =    BuiltIn.Run Keyword And Ignore Error    Collections.Get From Dictionary    ${connection_info}    remote-ip
    \    ${uuid} =    Set Variable If    '${remote_ip}' == '${ovs_system_ip}'    ${node_uuid}    ${uuid}
    [Return]    ${uuid}

Collect OVSDB Debugs
    [Arguments]    ${switch}=br-int
    [Documentation]    Used to log useful test debugs for OVSDB related system tests.
    ${output} =    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${output}
    ${output} =    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${switch} | cut -d',' -f3-
    BuiltIn.Log    ${output}

Clean OVSDB Test Environment
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    General Use Keyword attempting to sanitize test environment for OVSDB related
    ...    tests. Not every step will always be neccessary, but should not cause any problems for
    ...    any new ovsdb test suites.
    Utils.Clean Mininet System    ${tools_system}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl del-manager
    Utils.Run Command On Mininet    ${tools_system}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Utils.Run Command On Mininet    ${tools_system}    sudo rm -rf /etc/openvswitch/conf.db
    Utils.Run Command On Mininet    ${tools_system}    sudo /usr/share/openvswitch/scripts/ovs-ctl start

Restart OVSDB
    [Arguments]    ${ovs_ip}
    [Documentation]    Restart the OVS node without cleaning the current configuration.
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    BuiltIn.Log    ${output}
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    BuiltIn.Log    ${output}

Set Controller In OVS Bridge
    [Arguments]    ${tools_system}    ${bridge}    ${controller_opt}    ${ofversion}=13
    [Documentation]    Sets controller for the OVS bridge ${bridge} using ${controller_opt} and OF version ${ofversion}.
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set bridge ${bridge} protocols=OpenFlow${ofversion}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-controller ${bridge} ${controller_opt}

Check OVS OpenFlow Connections
    [Arguments]    ${tools_system}    ${of_connections}
    [Documentation]    Check OVS instance with IP ${tools_system} has ${of_connections} OpenFlow connections.
    ${output} =    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl show
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain X Times    ${output}    is_connected    ${of_connections}

Add Multiple Managers to OVS
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}    ${ovs_mgr_port}=6640
    [Documentation]    Connect OVS to the list of controllers in the ${controller_index_list} or all if no list is provided.
    ${index_list} =    ClusterManagement.List Indices Or All    given_list=${controller_index_list}
    Utils.Clean Mininet System    ${tools_system}
    ${ovs_opt} =    BuiltIn.Set Variable
    : FOR    ${index}    IN    @{index_list}
    \    ${ovs_opt} =    BuiltIn.Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ovs_mgr_port}
    \    BuiltIn.Log    ${ovs_opt}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-manager ${ovs_opt}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${tools_system}
    BuiltIn.Log    ${output}
    ${controller_index} =    Collections.Get_From_List    ${index_list}    0
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${controller_index}
    ${ovsdb_uuid} =    BuiltIn.Wait Until Keyword Succeeds    30s    2s    OVSDB.Get OVSDB UUID    controller_http_session=${session}
    [Return]    ${ovsdb_uuid}

Get DPID
    [Arguments]    ${ip}
    [Documentation]    Returns the dpnid from the system at the given ip address using ovs-ofctl assuming br-int is present.
    ${output} =    Utils.Run Command On Remote System    ${ip}    sudo ovs-ofctl show -O Openflow13 br-int | head -1 | awk -F "dpid:" '{print $2}'
    ${dpnid} =    BuiltIn.Convert To Integer    ${output}    16
    BuiltIn.Log    ${dpnid}
    [Return]    ${dpnid}

Get Subnet
    [Arguments]    ${ip}
    [Documentation]    Return the subnet from the system at the given ip address and interface
    ${output} =    Utils.Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d' ' -f6
    ${interface} =    ipaddress.ip_interface    ${output}
    ${network} =    BuiltIn.Set Variable    ${interface.network.__str__()}
    [Return]    ${network}

Get Ethernet Adapter
    [Arguments]    ${ip}
    [Documentation]    Returns the ethernet adapter name from the system at the given ip address using ip addr show.
    ${adapter} =    Builtin.Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d " " -f 11
    BuiltIn.Log    ${adapter}
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway at the given ip address using route command.
    ${gateway} =    Builtin.Run Command On Remote System    ${ip}    /usr/sbin/route -n | grep '^0.0.0.0' | cut -d " " -f 10
    BuiltIn.Log    ${gateway}
    [Return]    ${gateway}

Log Config And Operational Topology
    [Documentation]    For debugging purposes, this will log both config and operational topo data stores
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.content}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    OVSDB.Log Request    ${resp.content}

Config and Operational Topology Should Be Empty
    [Documentation]    This will check that only the expected output is there for both operational and config
    ...    topology data stores. Empty probably means that only ovsdb:1 is there.
    ${config_resp}    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    ${operational_resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_TOPO_API}
    BuiltIn.Should Contain    ${config_resp.content}    {"topology-id":"ovsdb:1"}
    BuiltIn.Should Contain    ${operational_resp.content}    {"topology-id":"ovsdb:1"}

Modify Multi Port Body
    [Arguments]    ${ovs_1_port_name}    ${ovs_2_port_name}    ${bridge}
    [Documentation]    Updates two port names for the given ${bridge} in config store
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/bug_7414/create_multiple_ports.json
    ${ovs_1_ovsdb_uuid} =    Get OVSDB UUID    ${TOOLS_SYSTEM_IP}
    ${ovs_2_ovsdb_uuid} =    Get OVSDB UUID    ${TOOLS_SYSTEM_2_IP}
    ${body} =    Replace String    ${body}    OVS_1_UUID    ${ovs_1_ovsdb_uuid}
    ${body} =    Replace String    ${body}    OVS_2_UUID    ${ovs_2_ovsdb_uuid}
    ${body} =    Replace String    ${body}    OVS_1_BRIDGE_NAME    ${bridge}
    ${body} =    Replace String    ${body}    OVS_2_BRIDGE_NAME    ${bridge}
    ${body} =    Replace String    ${body}    OVS_1_IP    ${TOOLS_SYSTEM_IP}
    ${body} =    Replace String    ${body}    OVS_2_IP    ${TOOLS_SYSTEM_2_IP}
    ${body} =    Replace String    ${body}    OVS_1_PORT_NAME    ${ovs_1_port_name}
    ${body} =    Replace String    ${body}    OVS_2_PORT_NAME    ${ovs_2_port_name}
    ${uri} =    Builtin.Set Variable    ${CONFIG_TOPO_API}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    [Return]    ${body}

Create Qos
    [Arguments]    ${qos}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qos.json
    ${uri} =    BuiltIn.Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${qos}/
    ${body} =    Replace String    ${body}    QOS-1    ${qos}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create Queue
    [Arguments]    ${queue}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qoslinkedqueue.json
    ${body} =    Replace String    ${body}    QUEUE-1    ${queue}
    ${uri} =    BuiltIn.Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:queues/${queue}/
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Update Qos
    [Arguments]    ${qos}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/update_existingqos.json
    ${uri} =    BuiltIn.Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1/ovsdb:qos-entries/${QOS}/
    BuiltIn.Log    URL is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create Qos Linked Queue
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/bug_7160/create_qoslinkedqueue.json
    ${resp}    RequestsLibrary.Put Request    session    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:HOST1    data=${body}
    OVSDB.Log Request    ${resp.content}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add OVS Logging
    [Arguments]    ${conn_id}
    [Documentation]    Add higher levels of OVS logging
    SSHLibrary.Switch Connection    ${conn_id}
    @{modules} =    BuiltIn.Create List    bridge:file:dbg    connmgr:file:dbg    inband:file:dbg    ofp_actions:file:dbg    ofp_errors:file:dbg
    ...    ofp_msgs:file:dbg    ovsdb_error:file:dbg    rconn:file:dbg    tunnel:file:dbg    vconn:file:dbg
    : FOR    ${module}    IN    @{modules}
    \    Utils.Write Commands Until Expected Prompt    sudo ovs-appctl --target ovs-vswitchd vlog/set ${module}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-appctl --target ovs-vswitchd vlog/list    ${DEFAULT_LINUX_PROMPT_STRICT}

Reset OVS Logging
    [Arguments]    ${conn_id}
    [Documentation]    Reset the OVS logging
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    sudo ovs-appctl --target ovs-vswitchd vlog/set :file:info    ${DEFAULT_LINUX_PROMPT_STRICT}

Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Open Controller Karaf Console On Background
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    OVSDB.Log Config And Operational Topology

Suite Teardown
    [Arguments]    ${uris}=@{EMPTY}
    [Documentation]    Cleans up test environment, close existing sessions.
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    : FOR    ${uri}    IN    @{uris}
    \    RequestsLibrary.Delete Request    session    ${uri}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_TOPO_API}
    OVSDB.Log Config And Operational Topology
    RequestsLibrary.Delete All Sessions

Get DumpFlows And Ovsconfig
    [Arguments]    ${conn_id}    ${bridge}
    [Documentation]    Get the OvsConfig and Flow entries from OVS
    SSHLibrary.Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl show ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-ofctl dump-group-stats ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}

Start OVS
    [Arguments]    ${ovs_ip}
    [Documentation]    start the OVS node.
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    BuiltIn.Log    ${output}

Stop OVS
    [Arguments]    ${ovs_ip}
    [Documentation]    Stop the OVS node.
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    BuiltIn.Log    ${output}
