*** Settings ***
Library     Collections
Library     ipaddress
Library     OperatingSystem
Library     RequestsLibrary
Library     SSHLibrary
Library     String
Resource    ClusterManagement.robot
Resource    Utils.robot
Resource    ${CURDIR}/TemplatedRequests.robot
Resource    ../variables/Variables.robot
Resource    ../variables/ovsdb/Variables.robot
Resource    ../variables/netvirt/Variables.robot


*** Variables ***
${OVSDB_CONFIG_DIR}     ${CURDIR}/../variables/ovsdb


*** Keywords ***
Log Request
    [Arguments]    ${resp_content}
    IF    '''${resp_content}''' != '${EMPTY}'
        ${resp_json} =    RequestsLibrary.To Json    ${resp_content}    pretty_print=True
    ELSE
        ${resp_json} =    BuiltIn.Set Variable    ${EMPTY}
    END
    BuiltIn.Log    ${resp_json}
    RETURN    ${resp_json}

Create OVSDB Node
    [Arguments]    ${node_ip}    ${port}=${OVSDB_NODE_PORT}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_node.json
    ${body} =    Replace String    ${body}    127.0.0.1    ${node_ip}
    ${body} =    Replace String    ${body}    61644    ${port}
    ${uri} =    Builtin.Set Variable    ${RFC8040_TOPO_OVSDB1_API}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Post Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Connect To Ovsdb Node
    [Documentation]    This will Initiate the connection to OVSDB node from controller
    [Arguments]    ${node_ip}    ${port}=${OVSDB_NODE_PORT}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${body} =    String.Replace String    ${body}    127.0.0.1    ${node_ip}
    ${body} =    String.Replace String    ${body}    61644    ${port}
    ${uri} =    BuiltIn.Set Variable    ${RFC8040_SOUTHBOUND_NODE_API}${node_ip}%3A${port}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Disconnect From Ovsdb Node
    [Documentation]    This request will disconnect the OVSDB node from the controller
    [Arguments]    ${node_ip}    ${port}=${OVSDB_NODE_PORT}
    ${resp} =    RequestsLibrary.Delete Request    session    ${RFC8040_SOUTHBOUND_NODE_API}${node_ip}%3A${port}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204

Add Bridge To Ovsdb Node
    [Documentation]    This will create a bridge and add it to the OVSDB node.
    [Arguments]    ${node_id}    ${node_ip}    ${bridge}    ${datapath_id}    ${port}=${OVSDB_NODE_PORT}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${body} =    String.Replace String    ${body}    ovsdb://127.0.0.1:61644    ovsdb://${node_id}
    ${body} =    String.Replace String    ${body}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${body} =    String.Replace String    ${body}    127.0.0.1    ${node_ip}
    ${body} =    String.Replace String    ${body}    br01    ${bridge}
    ${body} =    String.Replace String    ${body}    61644    ${port}
    ${body} =    String.Replace String    ${body}    0000000000000001    ${datapath_id}
    ${node_id_} =    BuiltIn.Evaluate    """${node_id}""".replace("/","%2F").replace(":","%3A")
    ${uri} =    BuiltIn.Set Variable    ${RFC8040_SOUTHBOUND_NODE_API}${node_id_}%2Fbridge%2F${bridge}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete Bridge From Ovsdb Node
    [Documentation]    This request will delete the bridge node from the OVSDB
    [Arguments]    ${node_id}    ${bridge}
    ${resp} =    RequestsLibrary.Delete Request
    ...    session
    ...    ${RFC8040_SOUTHBOUND_NODE_API}${node_id}%2Fbridge%2F${bridge}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    204

Add Termination Point
    [Documentation]    Using the json data body file as a template, a REST config request is made to
    ...    create a termination-point ${tp_name} on ${bridge} for the given ${node_id}. The ports
    ...    remote-ip defaults to ${TOOLS_SYSTEM_IP}
    [Arguments]    ${node_id}    ${bridge}    ${tp_name}    ${remote_ip}=${TOOLS_SYSTEM_IP}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    ${body} =    String.Replace String    ${body}    192.168.0.21    ${remote_ip}
    ${body} =    String.Replace String    ${body}    vxlanport    ${tp_name}
    ${node_id_} =    BuiltIn.Evaluate    """${node_id}""".replace("/","%2F").replace(":","%3A")
    ${uri} =    BuiltIn.Set Variable    ${RFC8040_SOUTHBOUND_NODE_API}${node_id_}%2Fbridge%2F${bridge}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}/termination-point=${tp_name}    data=${body}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add Vxlan To Bridge
    [Documentation]    This request will create vxlan port for vxlan tunnel and attach it to the specific bridge
    [Arguments]    ${node_ip}    ${bridge}    ${vxlan_port}    ${remote_ip}    ${port}=${OVSDB_NODE_PORT}
    OVSDB.Add Termination Point    ${node_ip}:${port}    ${bridge}    ${vxlan_port}    ${remote_ip}

Verify OVS Reports Connected
    [Documentation]    Uses "vsctl show" to check for string "is_connected"
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    ${output} =    Verify Ovs-vsctl Output    show    is_connected    ${tools_system}
    RETURN    ${output}

Verify Ovs-vsctl Output
    [Documentation]    A wrapper keyword to make it easier to validate ovs-vsctl output, and gives an easy
    ...    way to check this output in a WUKS. The argument ${should_match} can control if the match should
    ...    exist (True} or not (False) or don't care (anything but True or False). ${should_match} is True by default
    [Arguments]    ${vsctl_args}    ${expected_output}    ${ovs_system}=${TOOLS_SYSTEM_IP}    ${should_match}=True
    ${output} =    Utils.Run Command On Mininet    ${ovs_system}    sudo ovs-vsctl ${vsctl_args}
    BuiltIn.Log    ${output}
    IF    "${should_match}" == "True"
        BuiltIn.Should Contain    ${output}    ${expected_output}
    END
    IF    "${should_match}" == "False"
        BuiltIn.Should Not Contain    ${output}    ${expected_output}
    END
    RETURN    ${output}

Get OVSDB UUID
    [Documentation]    Queries the topology in the operational datastore and searches for the node that has
    ...    the ${ovs_system_ip} argument as the "remote-ip". If found, the value returned will be the value of
    ...    node-id stripped of "ovsdb://uuid/". If not found, ${EMPTY} will be returned.
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_http_session}=session
    ${uuid} =    Set Variable    ${EMPTY}
    ${resp} =    RequestsLibrary.Get Request    ${controller_http_session}    ${RFC8040_OPERATIONAL_TOPO_OVSDB1_API}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    200
    ${resp_json} =    RequestsLibrary.To Json    ${resp.text}
    ${topologies} =    Collections.Get From Dictionary    ${resp_json}    network-topology:topology
    ${topology} =    Collections.Get From List    ${topologies}    0
    ${node_list} =    Collections.Get From Dictionary    ${topology}    node
    BuiltIn.Log    ${node_list}
    # Since bridges are also listed as nodes, but will not have the extra "ovsdb:connection-info data,
    # we need to use "Run Keyword And Ignore Error" below.
    FOR    ${node}    IN    @{node_list}
        ${node_id} =    Collections.Get From Dictionary    ${node}    node-id
        ${node_uuid} =    String.Replace String    ${node_id}    ovsdb://uuid/    ${EMPTY}
        ${status}    ${connection_info} =    BuiltIn.Run Keyword And Ignore Error
        ...    Collections.Get From Dictionary
        ...    ${node}
        ...    ovsdb:connection-info
        ${status}    ${remote_ip} =    BuiltIn.Run Keyword And Ignore Error
        ...    Collections.Get From Dictionary
        ...    ${connection_info}
        ...    remote-ip
        ${uuid} =    Set Variable If    '${remote_ip}' == '${ovs_system_ip}'    ${node_uuid}    ${uuid}
    END
    RETURN    ${uuid}

Collect OVSDB Debugs
    [Documentation]    Used to log useful test debugs for OVSDB related system tests.
    [Arguments]    ${switch}=${INTEGRATION_BRIDGE}
    ${output} =    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    BuiltIn.Log    ${output}
    ${output} =    Utils.Run Command On Mininet
    ...    ${TOOLS_SYSTEM_IP}
    ...    sudo ovs-ofctl -O OpenFlow13 dump-flows ${switch} | cut -d',' -f3-
    BuiltIn.Log    ${output}

Clean OVSDB Test Environment
    [Documentation]    General Use Keyword attempting to sanitize test environment for OVSDB related
    ...    tests. Not every step will always be neccessary, but should not cause any problems for
    ...    any new ovsdb test suites.
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    Utils.Clean Mininet System    ${tools_system}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl del-manager
    Utils.Run Command On Mininet    ${tools_system}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Utils.Run Command On Mininet    ${tools_system}    sudo rm -rf /etc/openvswitch/conf.db
    Utils.Run Command On Mininet    ${tools_system}    sudo /usr/share/openvswitch/scripts/ovs-ctl start

Restart OVSDB
    [Documentation]    Restart the OVS node without cleaning the current configuration.
    [Arguments]    ${ovs_ip}
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo systemctl restart openvswitch
    BuiltIn.Log    ${output}

Set Controller In OVS Bridge
    [Documentation]    Sets controller for the OVS bridge ${bridge} using ${controller_opt} and OF version ${ofversion}.
    [Arguments]    ${tools_system}    ${bridge}    ${controller_opt}    ${ofversion}=13
    Utils.Run Command On Mininet
    ...    ${tools_system}
    ...    sudo ovs-vsctl set bridge ${bridge} protocols=OpenFlow${ofversion}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-controller ${bridge} ${controller_opt}

Check OVS OpenFlow Connections
    [Documentation]    Check OVS instance with IP ${tools_system} has ${of_connections} OpenFlow connections.
    [Arguments]    ${tools_system}    ${of_connections}
    ${output} =    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl show
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain X Times    ${output}    is_connected    ${of_connections}

Add Multiple Managers to OVS
    [Documentation]    Connect OVS to the list of controllers in the ${controller_index_list} or all if no list is provided.
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}    ${ovs_mgr_port}=6640
    ${index_list} =    ClusterManagement.List Indices Or All    given_list=${controller_index_list}
    Utils.Clean Mininet System    ${tools_system}
    ${ovs_opt} =    BuiltIn.Set Variable
    FOR    ${index}    IN    @{index_list}
        ${ovs_opt} =    BuiltIn.Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ovs_mgr_port}
        BuiltIn.Log    ${ovs_opt}
    END
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-manager ${ovs_opt}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${tools_system}
    BuiltIn.Log    ${output}
    ${controller_index} =    Collections.Get_From_List    ${index_list}    0
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${controller_index}
    ${ovsdb_uuid} =    BuiltIn.Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    OVSDB.Get OVSDB UUID
    ...    controller_http_session=${session}
    RETURN    ${ovsdb_uuid}

Get DPID
    [Documentation]    Returns the dpnid from the system at the given ip address using ovs-ofctl assuming br-int is present.
    [Arguments]    ${ip}
    ${output} =    Utils.Run Command On Remote System
    ...    ${ip}
    ...    sudo ovs-ofctl show -O Openflow13 ${INTEGRATION_BRIDGE} | head -1 | awk -F "dpid:" '{print $2}'
    ${dpnid} =    BuiltIn.Convert To Integer    ${output}    16
    BuiltIn.Log    ${dpnid}
    RETURN    ${dpnid}

Get Subnet
    [Documentation]    Return the subnet from the system at the given ip address and interface
    [Arguments]    ${ip}
    ${output} =    Utils.Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d' ' -f6
    ${interface} =    ipaddress.ip_interface    ${output}
    ${network} =    BuiltIn.Set Variable    ${interface.network.__str__()}
    RETURN    ${network}

Get Ethernet Adapter
    [Documentation]    Returns the ethernet adapter name from the system at the given ip address using ip addr show.
    [Arguments]    ${ip}
    ${adapter} =    Utils.Run Command On Remote System
    ...    ${ip}
    ...    /usr/sbin/ip addr show | grep ${ip} | cut -d " " -f 11
    BuiltIn.Log    ${adapter}
    RETURN    ${adapter}

Get Default Gateway
    [Documentation]    Returns the default gateway at the given ip address using route command.
    [Arguments]    ${ip}
    ${gateway} =    Utils.Run Command On Remote System
    ...    ${ip}
    ...    /usr/sbin/route -n | grep '^0.0.0.0' | cut -d " " -f 10
    BuiltIn.Log    ${gateway}
    RETURN    ${gateway}

Get Port Number
    [Documentation]    Get the port number for the given sub-port id
    [Arguments]    ${subportid}    ${ip_addr}
    ${command} =    Set Variable
    ...    sudo ovs-ofctl -O OpenFlow13 show ${INTEGRATION_BRIDGE} | grep ${subportid} | awk '{print$1}'
    BuiltIn.Log    sudo ovs-ofctl -O OpenFlow13 show ${INTEGRATION_BRIDGE} | grep ${subportid} | awk '{print$1}'
    ${output} =    Utils.Run Command On Remote System    ${ip_addr}    ${command}
    ${port_number} =    BuiltIn.Should Match Regexp    ${output}    [0-9]+
    RETURN    ${port_number}

Get Port Metadata
    [Documentation]    Get the Metadata for a given port
    [Arguments]    ${ip_addr}    ${port}
    ${cmd} =    Set Variable
    ...    sudo ovs-ofctl dump-flows -O Openflow13 ${INTEGRATION_BRIDGE} | grep table=0 | grep in_port=${port}
    ${output} =    Utils.Run Command On Remote System    ${ip_addr}    ${cmd}
    @{list_any_matches} =    String.Get_Regexp_Matches    ${output}    metadata:(\\w{12})    1
    ${metadata} =    Builtin.Convert To String    @{list_any_matches}
    ${output} =    String.Get Substring    ${metadata}    2
    RETURN    ${output}

Log Config And Operational Topology
    [Documentation]    For debugging purposes, this will log both config and operational topo data stores
    ${resp} =    RequestsLibrary.Get Request    session    ${RFC8040_CONFIG_TOPO_API}
    OVSDB.Log Request    ${resp.text}
    ${resp} =    RequestsLibrary.Get Request    session    ${RFC8040_OPERATIONAL_TOPO_API}
    OVSDB.Log Request    ${resp.text}

Config and Operational Topology Should Be Empty
    [Documentation]    This will check that only the expected output is there for both operational and config
    ...    topology data stores. Empty probably means that only ovsdb:1 is there.
    ${config_resp} =    RequestsLibrary.Get Request    session    ${RFC8040_CONFIG_TOPO_API}
    ${operational_resp} =    RequestsLibrary.Get Request    session    ${RFC8040_OPERATIONAL_TOPO_API}
    BuiltIn.Should Contain    ${config_resp.text}    {"topology-id":"ovsdb:1"}
    BuiltIn.Should Contain    ${operational_resp.text}    {"topology-id":"ovsdb:1"}

Modify Multi Port Body
    [Documentation]    Updates two port names for the given ${bridge} in config store
    [Arguments]    ${ovs_1_port_name}    ${ovs_2_port_name}    ${bridge}
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
    ${uri} =    Builtin.Set Variable    ${RFC8040_TOPO_API}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    RETURN    ${body}

Create Qos
    [Arguments]    ${qos}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qos.json
    ${uri} =    BuiltIn.Set Variable    ${RFC8040_SOUTHBOUND_NODE_HOST1_API}/ovsdb:qos-entries=${qos}
    ${body} =    Replace String    ${body}    QOS-1    ${qos}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create Queue
    [Arguments]    ${queue}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_qoslinkedqueue.json
    ${body} =    Replace String    ${body}    QUEUE-1    ${queue}
    ${uri} =    BuiltIn.Set Variable    ${RFC8040_SOUTHBOUND_NODE_HOST1_API}/ovsdb:queues=${queue}
    BuiltIn.Log    URI is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Update Qos
    [Arguments]    ${qos}
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/update_existingqos.json
    ${uri} =    BuiltIn.Set Variable    ${RFC8040_SOUTHBOUND_NODE_HOST1_API}/ovsdb:qos-entries=${QOS}
    BuiltIn.Log    URL is ${uri}
    BuiltIn.Log    data: ${body}
    ${resp} =    RequestsLibrary.Put Request    session    ${uri}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Create Qos Linked Queue
    ${body} =    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/bug_7160/create_qoslinkedqueue.json
    ${resp} =    RequestsLibrary.Put Request    session    ${RFC8040_SOUTHBOUND_NODE_HOST1_API}    data=${body}
    OVSDB.Log Request    ${resp.text}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Add OVS Logging
    [Documentation]    Add higher levels of OVS logging
    [Arguments]    ${conn_id}
    SSHLibrary.Switch Connection    ${conn_id}
    @{modules} =    BuiltIn.Create List
    ...    bridge:file:dbg
    ...    connmgr:file:dbg
    ...    inband:file:dbg
    ...    ofp_actions:file:dbg
    ...    ofp_errors:file:dbg
    ...    ofp_msgs:file:dbg
    ...    ovsdb_error:file:dbg
    ...    rconn:file:dbg
    ...    tunnel:file:dbg
    ...    vconn:file:dbg
    FOR    ${module}    IN    @{modules}
        Utils.Write Commands Until Expected Prompt
        ...    sudo ovs-appctl --target ovs-vswitchd vlog/set ${module}
        ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    END
    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-appctl --target ovs-vswitchd vlog/list
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}

Reset OVS Logging
    [Documentation]    Reset the OVS logging
    [Arguments]    ${conn_id}
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-appctl --target ovs-vswitchd vlog/set :file:info
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}

Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Open Controller Karaf Console On Background
    RequestsLibrary.Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS}
    OVSDB.Log Config And Operational Topology

Suite Teardown
    [Documentation]    Cleans up test environment, close existing sessions.
    [Arguments]    ${uris}=@{EMPTY}
    OVSDB.Clean OVSDB Test Environment    ${TOOLS_SYSTEM_IP}
    FOR    ${uri}    IN    @{uris}
        RequestsLibrary.Delete Request    session    ${uri}
    END
    ${resp} =    RequestsLibrary.Get Request    session    ${RFC8040_CONFIG_TOPO_API}
    OVSDB.Log Config And Operational Topology
    RequestsLibrary.Delete All Sessions

Get DumpFlows And Ovsconfig
    [Documentation]    Get the OvsConfig and Flow entries from OVS
    [Arguments]    ${conn_id}    ${bridge}
    SSHLibrary.Switch Connection    ${conn_id}
    Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl show ${bridge} -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl dump-flows ${bridge} -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl dump-groups ${bridge} -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl dump-group-stats ${bridge} -OOpenFlow13
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-vsctl list interface    ${DEFAULT_LINUX_PROMPT_STRICT}

Start OVS
    [Documentation]    start the OVS node.
    [Arguments]    ${ovs_ip}
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    BuiltIn.Log    ${output}

Stop OVS
    [Documentation]    Stop the OVS node.
    [Arguments]    ${ovs_ip}
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    BuiltIn.Log    ${output}

Get Bridge Data
    [Documentation]    This keyword returns first bridge name and UUID from list of bridges.
    ${result} =    SSHLibrary.Execute Command    sudo ovs-vsctl show
    ${uuid} =    String.Get Line    ${result}    0
    ${line}    ${bridge_name} =    Builtin.Should Match Regexp    ${result}    Bridge ([\\w-]+)
    RETURN    ${uuid}    ${bridge_name}

Delete OVS Controller
    [Documentation]    Delete controller from OVS
    [Arguments]    ${ovs_ip}    ${bridge}=${INTEGRATION_BRIDGE}
    ${del_ctr} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl del-controller ${bridge}
    BuiltIn.Log    ${del_ctr}

Delete OVS Manager
    [Documentation]    Delete manager from OVS
    [Arguments]    ${ovs_ip}
    ${del_mgr} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl del-manager
    BuiltIn.Log    ${del_mgr}

Delete Groups On Bridge
    [Documentation]    Delete OVS groups from ${br}
    [Arguments]    ${ovs_ip}    ${br}=${INTEGRATION_BRIDGE}
    ${del_grp} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-ofctl -O Openflow13 del-groups ${br}
    BuiltIn.Log    ${del_grp}

Get Ports From Bridge By Type
    [Documentation]    Get ${type} ports for a bridge ${br} on node ${ovs_ip}.
    [Arguments]    ${ovs_ip}    ${br}    ${type}
    ${ports} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl list-ports ${br} | grep "${type}"
    ${ports_list} =    String.Split to lines    ${ports}
    RETURN    ${ports_list}

Delete Ports On Bridge By Type
    [Documentation]    List all ports of ${br} and delete ${type} ports
    [Arguments]    ${ovs_ip}    ${br}    ${type}
    ${ports_present} =    Get Ports From Bridge By Type    ${ovs_ip}    ${br}    ${type}
    FOR    ${port}    IN    @{ports_present}
        ${del-ports} =    Utils.Run Command On Remote System    ${ovs_ip}    sudo ovs-vsctl del-port ${br} ${port}
        BuiltIn.Log    ${del-ports}
    END
    ${ports_present_after_delete} =    Get Ports From Bridge By Type    ${ovs_ip}    ${br}    ${type}
    BuiltIn.Log    ${ports_present_after_delete}

Get Tunnel Id And Packet Count
    [Documentation]    Get tunnel id and packet count from specified table id
    ...    Using regex get the n_packet and the tunnel_id from the table flow.
    [Arguments]    ${conn_id}    ${table_id}    ${tun_id}    ${mac}=""
    ${tun_id} =    BuiltIn.Convert To Hex    ${tun_id}    prefix=0x    lowercase=yes
    IF    "${table_id}" == "${INTERNAL_TUNNEL_TABLE}"
        ${cmd} =    BuiltIn.Set Variable
        ...    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | grep ${mac} | grep tun_id=${tun_id} | grep goto_table:${ELAN_DMACTABLE}
    ELSE
        ${cmd} =    BuiltIn.Set Variable
        ...    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | grep ${mac}
    END
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split to lines    ${output}
    ${output} =    Set Variable    ${list}[0]
    ${output} =    String.Get Regexp Matches
    ...    ${output}
    ...    n_packets=([0-9]+),.*set_field:(0x[0-9a-z]+)|n_packets=([0-9]+),.*tun_id=(0x[0-9a-z]+)
    ...    1
    ...    2
    ...    3
    ...    4
    ${output} =    BuiltIn.Set Variable    ${output}[0]
    ${output} =    Convert To List    ${output}
    IF    "${table_id}" == "${ELAN_DMACTABLE}"
        ${packet_count}    ${tunnel_id} =    BuiltIn.Set Variable    ${output}[0]    ${output}[1]
    ELSE IF    "${table_id}" == "${INTERNAL_TUNNEL_TABLE}"
        ${packet_count}    ${tunnel_id} =    BuiltIn.Set Variable    ${output}[2]    ${output}[3]
    ELSE IF    "${table_id}" == "${L3_TABLE}"
        ${packet_count}    ${tunnel_id} =    BuiltIn.Set Variable    ${output}[0]    ${output}[1]
    ELSE
        ${packet_count}    ${tunnel_id} =    Set Variable    ${None}    ${None}
    END
    ${tunnel_id} =    Convert To Integer    ${tunnel_id}    16
    RETURN    ${tunnel_id}    ${packet_count}

Verify Dump Flows For Specific Table
    [Documentation]    To Verify flows are present for the corresponding table Number
    [Arguments]    ${compute_ip}    ${table_num}    ${flag}    ${additional_args}=${EMPTY}    @{matching_paras}
    ${flow_output} =    Utils.Run Command On Remote System
    ...    ${compute_ip}
    ...    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}|grep table=${table_num} ${additional_args}
    Log    ${flow_output}
    FOR    ${matching_str}    IN    @{matching_paras}
        IF    ${flag}==True
            BuiltIn.Should Contain    ${flow_output}    ${matching_str}
        ELSE
            BuiltIn.Should Not Contain    ${flow_output}    ${matching_str}
        END
    END

Verify Vni Segmentation Id and Tunnel Id
    [Documentation]    Get tunnel id and packet count from specified table id and destination port mac address
    [Arguments]    ${port1}    ${port2}    ${net1}    ${net2}    ${vm1_ip}    ${vm2_ip}
    ...    ${ip}=""
    ${port_mac1} =    OpenStackOperations.Get Port Mac    ${port1}
    ${port_mac2} =    OpenStackOperations.Get Port Mac    ${port2}
    ${segmentation_id1} =    OpenStackOperations.Get Network Segmentation Id    ${net1}
    ${segmentation_id2} =    OpenStackOperations.Get Network Segmentation Id    ${net2}
    ${egress_tun_id}    ${before_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP1_CONN_ID}
    ...    ${L3_TABLE}
    ...    tun_id=${segmentation_id2}
    ...    mac=${port_mac2}
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id2}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP2_CONN_ID}
    ...    ${L3_TABLE}
    ...    tun_id=${segmentation_id1}
    ...    mac=${port_mac1}
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id1}    ${egress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port1} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP1_CONN_ID}
    ...    ${INTERNAL_TUNNEL_TABLE}
    ...    tun_id=${segmentation_id1}
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id1}    ${ingress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port2} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP2_CONN_ID}
    ...    ${INTERNAL_TUNNEL_TABLE}
    ...    tun_id=${segmentation_id2}
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id2}    ${ingress_tun_id}
    IF    '${ip}'=='ipv4'
        ${ping_cmd} =    BuiltIn.Set Variable    ping -c ${DEFAULT_PING_COUNT} ${vm2_ip}
    ELSE
        ${ping_cmd} =    BuiltIn.Set Variable    ping6 -c ${DEFAULT_PING_COUNT} ${vm2_ip}
    END
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net1}    ${vm1_ip}    ${ping_cmd}
    BuiltIn.Should Contain    ${output}    64 bytes
    BuiltIn.Wait Until Keyword Succeeds
    ...    60s
    ...    5s
    ...    OVSDB.Verify Vni Packet Count After Traffic
    ...    ${before_count_egress_port1}
    ...    ${before_count_egress_port2}
    ...    ${before_count_ingress_port1}
    ...    ${before_count_ingress_port2}
    ...    ${segmentation_id1}
    ...    ${segmentation_id2}
    ...    ${port_mac1}
    ...    ${port_mac2}

Verify Vni Packet Count After Traffic
    [Documentation]    Verify the packet count after the traffic sent
    [Arguments]    ${before_count_egress_port1}    ${before_count_egress_port2}    ${before_count_ingress_port1}    ${before_count_ingress_port2}    ${segmentation_id1}    ${segmentation_id2}
    ...    ${port_mac1}    ${port_mac2}
    ${tun_id}    ${after_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP2_CONN_ID}
    ...    ${L3_TABLE}
    ...    tun_id=${segmentation_id1}
    ...    mac=${port_mac1}
    ${tun_id}    ${after_count_ingress_port2} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP2_CONN_ID}
    ...    ${INTERNAL_TUNNEL_TABLE}
    ...    tun_id=${segmentation_id2}
    ${tun_id}    ${after_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP1_CONN_ID}
    ...    ${L3_TABLE}
    ...    tun_id=${segmentation_id2}
    ...    mac=${port_mac2}
    ${tun_id}    ${after_count_ingress_port1} =    OVSDB.Get Tunnel Id And Packet Count
    ...    ${OS_CMP1_CONN_ID}
    ...    ${INTERNAL_TUNNEL_TABLE}
    ...    tun_id=${segmentation_id1}
    ${diff_count_egress_port1} =    BuiltIn.Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_ingress_port1} =    BuiltIn.Evaluate    ${after_count_ingress_port1} - ${before_count_ingress_port1}
    ${diff_count_egress_port2} =    BuiltIn.Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    ${diff_count_ingress_port2} =    BuiltIn.Evaluate    ${after_count_ingress_port2} - ${before_count_ingress_port2}
    BuiltIn.Should Be True    ${diff_count_egress_port1} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_ingress_port1} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_egress_port2} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_ingress_port2} >= ${DEFAULT_PING_COUNT}

Get Flow Entries On Node
    [Documentation]    Return flow entries on the given Node.
    [Arguments]    ${conn_id}    ${switch}=${INTEGRATION_BRIDGE}
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt
    ...    sudo ovs-ofctl -O OpenFlow13 dump-flows ${switch}
    ...    ${DEFAULT_LINUX_PROMPT_STRICT}
    BuiltIn.Log    ${output}
    RETURN    ${output}

Verify Ovsdb State
    [Documentation]    Verify ovsdb state for the given DPN
    [Arguments]    ${dpn_ip}    ${state}=ACTIVE
    ${output} =    Utils.Run Command On Remote System And Log
    ...    ${dpn_ip}
    ...    sudo ovsdb-client dump -f list Open_vSwitch Controller | grep state
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    state=${state}

Verify Flows Are Present On Node
    [Documentation]    Verify Flows Are Present On The Given Node
    [Arguments]    ${conn_id}    ${match}
    ${output} =    OVSDB.Get Flow Entries On Node    ${conn_id}
    BuiltIn.Should Contain    ${output}    ${match}
