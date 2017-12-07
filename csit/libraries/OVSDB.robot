*** Settings ***
Library           SSHLibrary
Library           String
Library           Collections
Library           RequestsLibrary
Library           ipaddress
Resource          Utils.robot
Resource          ClusterManagement.robot
Resource          ${CURDIR}/TemplatedRequests.robot
Variables         ../variables/Variables.py

*** Variables ***
${OVSDB_CONFIG_DIR}    ../variables/ovsdb
${SOUTHBOUND_CONFIG_API}    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F

*** Keywords ***
Connect To Ovsdb Node
    [Arguments]    ${mininet_ip}
    [Documentation]    This will Initiate the connection to OVSDB node from controller
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/connect.json
    ${sample1}    Replace String    ${sample}    127.0.0.1    ${mininet_ip}
    ${body}    Replace String    ${sample1}    61644    ${OVSDB_PORT}
    Log    URL is ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Disconnect From Ovsdb Node
    [Arguments]    ${mininet_ip}
    [Documentation]    This request will disconnect the OVSDB node from the controller
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Bridge To Ovsdb Node
    [Arguments]    ${mininet_ip}    ${bridge_num}    ${datapath_id}
    [Documentation]    This will create a bridge and add it to the OVSDB node.
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_bridge.json
    ${sample1}    Replace String    ${sample}    tcp:127.0.0.1:6633    tcp:${ODL_SYSTEM_IP}:6633
    ${sample2}    Replace String    ${sample1}    127.0.0.1    ${mininet_ip}
    ${sample3}    Replace String    ${sample2}    br01    ${bridge_num}
    ${sample4}    Replace String    ${sample3}    61644    ${OVSDB_PORT}
    ${body}    Replace String    ${sample4}    0000000000000001    ${datapath_id}
    Log    URL is ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}    data=${body}
    Log    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Delete Bridge From Ovsdb Node
    [Arguments]    ${mininet_ip}    ${bridge_num}
    [Documentation]    This request will delete the bridge node from the OVSDB
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Vxlan To Bridge
    [Arguments]    ${mininet_ip}    ${bridge_num}    ${vxlan_port}    ${remote_ip}    ${custom_port}=create_port.json
    [Documentation]    This request will create vxlan port for vxlan tunnel and attach it to the specific bridge
    Add Termination Point    ${mininet_ip}:${OVSDB_PORT}    ${bridge_num}    ${vxlan_port}    ${remote_ip}

Add Termination Point
    [Arguments]    ${node_id}    ${bridge_name}    ${tp_name}    ${remote_ip}=${TOOLS_SYSTEM_IP}
    [Documentation]    Using the json data body file as a template, a REST config request is made to
    ...    create a termination-point ${tp_name} on ${bridge_name} for the given ${node_id}. The ports
    ...    remote-ip defaults to ${TOOLS_SYSTEM_IP}
    ${body}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/create_port.json
    ${body}    Replace String    ${body}    192.168.0.21    ${remote_ip}
    ${body}    Replace String    ${body}    vxlanport    ${tp_name}
    ${uri}=    Set Variable    ${CONFIG_TOPO_API}/topology/ovsdb:1/node/ovsdb:%2F%2F${node_id}%2Fbridge%2F${bridge_name}
    ${resp}    RequestsLibrary.Put Request    session    ${uri}/termination-point/${tp_name}/    data=${body}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Verify OVS Reports Connected
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    Uses "vsctl show" to check for string "is_connected"
    ${output}    Verify Ovs-vsctl Output    show    is_connected    ${tools_system}
    [Return]    ${output}

Verify Ovs-vsctl Output
    [Arguments]    ${vsctl_args}    ${expected_output}    ${ovs_system}=${TOOLS_SYSTEM_IP}    ${should_match}=True
    [Documentation]    A wrapper keyword to make it easier to validate ovs-vsctl output, and gives an easy
    ...    way to check this output in a WUKS. The argument ${should_match} can control if the match should
    ...    exist (True} or not (False) or don't care (anything but True or False). ${should_match} is True by default
    ${output}=    Utils.Run Command On Mininet    ${ovs_system}    sudo ovs-vsctl ${vsctl_args}
    Log    ${output}
    Run Keyword If    "${should_match}"=="True"    Should Contain    ${output}    ${expected_output}
    Run Keyword If    "${should_match}"=="False"    Should Not Contain    ${output}    ${expected_output}
    [Return]    ${output}

Get OVSDB UUID
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_http_session}=session
    [Documentation]    Queries the topology in the operational datastore and searches for the node that has
    ...    the ${ovs_system_ip} argument as the "remote-ip". If found, the value returned will be the value of
    ...    node-id stripped of "ovsdb://uuid/". If not found, ${EMPTY} will be returned.
    ${uuid}=    Set Variable    ${EMPTY}
    ${resp}=    RequestsLibrary.Get Request    ${controller_http_session}    ${OPERATIONAL_TOPO_API}/topology/ovsdb:1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${resp_json}=    To Json    ${resp.content}
    ${topologies}=    Get From Dictionary    ${resp_json}    topology
    ${topology}=    Get From List    ${topologies}    0
    ${node_list}=    Get From Dictionary    ${topology}    node
    Log    ${node_list}
    # Since bridges are also listed as nodes, but will not have the extra "ovsdb:connection-info data,
    # we need to use "Run Keyword And Ignore Error" below.
    : FOR    ${node}    IN    @{node_list}
    \    ${node_id}=    Get From Dictionary    ${node}    node-id
    \    ${node_uuid}=    Replace String    ${node_id}    ovsdb://uuid/    ${EMPTY}
    \    ${status}    ${connection_info}    Run Keyword And Ignore Error    Get From Dictionary    ${node}    ovsdb:connection-info
    \    ${status}    ${remote_ip}    Run Keyword And Ignore Error    Get From Dictionary    ${connection_info}    remote-ip
    \    ${uuid}=    Set Variable If    '${remote_ip}' == '${ovs_system_ip}'    ${node_uuid}    ${uuid}
    [Return]    ${uuid}

Collect OVSDB Debugs
    [Arguments]    ${switch}=br-int
    [Documentation]    Used to log useful test debugs for OVSDB related system tests.
    ${output}=    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl show
    Log    ${output}
    ${output}=    Utils.Run Command On Mininet    ${TOOLS_SYSTEM_IP}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${switch} | cut -d',' -f3-
    Log    ${output}

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
    Log    ${output}
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}

Set Controller In OVS Bridge
    [Arguments]    ${tools_system}    ${bridge}    ${controller_opt}
    [Documentation]    Sets controller for a given OVS ${bridge} using controller options in ${controller_opt}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-controller ${bridge} ${controller_opt}

Check OVS OpenFlow Connections
    [Arguments]    ${tools_system}    ${of_connections}
    [Documentation]    Check OVS instance with IP ${tools_system} has ${of_connections} OpenFlow connections.
    ${output}=    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl show
    Log    ${output}
    BuiltIn.Should Contain X Times    ${output}    is_connected    ${of_connections}

Add Multiple Managers to OVS
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}    ${controller_index_list}=${EMPTY}    ${ovs_mgr_port}=6640
    [Documentation]    Connect OVS to the list of controllers in the ${controller_index_list} or all if no list is provided.
    ${index_list} =    ClusterManagement.List Indices Or All    given_list=${controller_index_list}
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${tools_system}
    ${ovs_opt}=    Set Variable
    : FOR    ${index}    IN    @{index_list}
    \    ${ovs_opt}=    Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ovs_mgr_port}
    \    Log    ${ovs_opt}
    Log    Configure OVS Managers in the OVS
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-manager ${ovs_opt}
    Log    Check OVS configuration
    ${output}=    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${tools_system}
    Log    ${output}
    ${controller_index}=    Collections.Get_From_List    ${index_list}    0
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${controller_index}
    ${ovsdb_uuid}=    Wait Until Keyword Succeeds    30s    2s    Get OVSDB UUID    controller_http_session=${session}
    [Return]    ${ovsdb_uuid}

Get DPID
    [Arguments]    ${ip}
    [Documentation]    Returns the dpnid from the system at the given ip address using ovs-ofctl assuming br-int is present.
    ${output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl show -O Openflow13 br-int | head -1 | awk -F "dpid:" '{print $2}'
    ${dpnid} =    Convert To Integer    ${output}    16
    Log    ${dpnid}
    [Return]    ${dpnid}

Get Subnet
    [Arguments]    ${ip}
    [Documentation]    Return the subnet from the system at the given ip address and interface
    ${output} =    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d' ' -f6
    ${interface} =    ipaddress.ip_interface    ${output}
    ${network}=    Set Variable    ${interface.network.__str__()}
    [Return]    ${network}

Get Ethernet Adapter
    [Arguments]    ${ip}
    [Documentation]    Returns the ethernet adapter name from the system at the given ip address using ip addr show.
    ${adapter} =    Run Command On Remote System    ${ip}    /usr/sbin/ip addr show | grep ${ip} | cut -d " " -f 11
    Log    ${adapter}
    [Return]    ${adapter}

Get Default Gateway
    [Arguments]    ${ip}
    [Documentation]    Returns the default gateway at the given ip address using route command.
    ${gateway} =    Run Command On Remote System    ${ip}    /usr/sbin/route -n | grep '^0.0.0.0' | cut -d " " -f 10
    Log    ${gateway}
    [Return]    ${gateway}

Add OVS Logging
    [Arguments]    ${conn_id}
    [Documentation]    Add higher levels of OVS logging
    SSHLibrary.Switch Connection    ${conn_id}
    @{modules} =    BuiltIn.Create List    bridge:file:dbg    connmgr:file:dbg    inband:file:dbg    ofp_actions:file:dbg    ofp_errors:file:dbg
    ...    ofp_msgs:file:dbg    ovsdb_error:file:dbg    rconn:file:dbg    tunnel:file:dbg    vconn:file:dbg
    : FOR    ${module}    IN    @{modules}
    \    Write Commands Until Expected Prompt    sudo ovs-appctl --target ovs-vswitchd vlog/set ${module}    ${DEFAULT_LINUX_PROMPT_STRICT}
    Write Commands Until Expected Prompt    sudo ovs-appctl --target ovs-vswitchd vlog/list    ${DEFAULT_LINUX_PROMPT_STRICT}

Reset OVS Logging
    [Arguments]    ${conn_id}
    [Documentation]    Reset the OVS logging
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ovs-appctl --target ovs-vswitchd vlog/set :file:info    ${DEFAULT_LINUX_PROMPT_STRICT}

Delete OVS Controller
    [Arguments]    ${node}
    [Documentation]    Delete controller from OVS
    ${del_ctr}=    Run Command On Remote System    ${node}    sudo ovs-vsctl del-controller br-int
    Log    ${del_ctr}

Delete OVS Manager
    [Arguments]    ${node}
    [Documentation]    Delete manager from OVS
    ${del_mgr}=    Run Command On Remote System    ${node}    sudo ovs-vsctl del-manager
    Log    ${del_mgr}

Delete Groups
    [Arguments]    ${node}    ${br}
    [Documentation]    Delete OVS groups from br-int
    ${del_grp}=    Run Command On Remote System    ${node}    sudo ovs-ofctl -O Openflow13 del-groups ${br}
    Log    ${del_grp}

Get Ports
    [Arguments]    ${node}    ${br}    ${type}
    [Documentation]    Get ${type} ports for a bridge ${br} on node ${node}.
    ${ports}=    Run Command On Remote System    ${node}    sudo ovs-vsctl list-ports ${br} | grep "${type}"
    Log    ${ports}
    ${datatype}=    Evaluate    type($ports)
    Log    ${datatype}
    ${port_list}=    BuiltIn.Create List    ${ports}
    ${list_port}=    String.Split to lines    ${ports}
    : FOR    ${listed_port}    IN    ${list_port}
    \    Log    ${listed_port}
    \    Collections.Append To List    ${port_list}    ${listed_port}
    Log    ${list_port}
    Log    ${port_list}
    [Return]    ${port_list}

Delete Ports
    [Arguments]    ${node}    ${br}    ${type}
    [Documentation]    List all ports of ${br} and delete ${type} ports
    ${ports_present}=    Get Ports    ${node}    ${br}    ${type}
    : FOR    ${port}    IN    @{ports_present}
    \    ${del-ports}=    Run Command On Remote System    ${node}    sudo ovs-vsctl del-port ${br} ${port}
    \    Log    ${del-ports}

Get Info From Bridge
    [Arguments]    ${openstack_node_ip}    ${br}    ${log_file}
    [Documentation]    Get the OvsConfig, Flow entries and group info from OVS ${br} from the Openstack Node and log it for ${log_file}
    OperatingSystem.Create File    ${log_file}
    OperatingSystem.Append To File    ${log_file}    ${openstack_node_ip}
    SSHLibrary.Open Connection    ${openstack_node_ip}    prompt=${DEFAULT_LINUX_PROMPT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=${default_devstack_prompt_timeout}
    ${output}=    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl show ${br} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${output}
    ${output}=    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows ${br} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${output}
    ${output}=    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups ${br} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    OperatingSystem.Append To File    ${log_file}    ${output}
    Log File    ${log_file}
