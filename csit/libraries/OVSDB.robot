*** Settings ***
Library           SSHLibrary
Resource          Utils.robot
Library           String
Library           Collections
Variables         ../variables/Variables.py
Library           RequestsLibrary

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
    Should Be Equal As Strings    ${resp.status_code}    200

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
    Should Be Equal As Strings    ${resp.status_code}    200

Delete Bridge From Ovsdb Node
    [Arguments]    ${mininet_ip}    ${bridge_num}
    [Documentation]    This request will delete the bridge node from the OVSDB
    ${resp}    RequestsLibrary.Delete Request    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}
    Should Be Equal As Strings    ${resp.status_code}    200

Add Vxlan To Bridge
    [Arguments]    ${mininet_ip}    ${bridge_num}    ${vxlan_port}    ${remote_ip}    ${custom_port}=create_port.json
    [Documentation]    This request will create vxlan port for vxlan tunnel and attach it to the specific bridge
    ${sample}    OperatingSystem.Get File    ${OVSDB_CONFIG_DIR}/${custom_port}
    ${body}    Replace String    ${sample}    192.168.0.21    ${remote_ip}
    Log    URL is ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}/termination-point/${vxlan_port}/
    Log    data: ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${SOUTHBOUND_CONFIG_API}${mininet_ip}:${OVSDB_PORT}%2Fbridge%2F${bridge_num}/termination-point/${vxlan_port}/    data=${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify OVS Reports Connected
    [Arguments]    ${tools_system}=${TOOLS_SYSTEM_IP}
    [Documentation]    Uses "vsctl show" to check for string "is_connected"
    ${output}=    Utils.Run Command On Remote System    ${tools_system}    sudo ovs-vsctl show
    Should Contain    ${output}    is_connected

Get OVSDB UUID
    [Arguments]    ${ovs_system_ip}=${TOOLS_SYSTEM_IP}    ${controller_ip}=${ODL_SYSTEM_IP}    ${controller_http_session}=session
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

Set Controller In OVS Bridge
    [Arguments]    ${tools_system}    ${bridge}    ${controller_opt}
    [Documentation]    Sets controller for a given OVS ${bridge} using controller options in ${controller_opt}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl del-controller ${bridge}
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-controller ${bridge} ${controller_opt}

Add Multiple Managers to OVS
    [Arguments]    ${tools_system}    ${controller_index_list}    ${ovs_mgr_port}=6640
    [Documentation]    Connect OVS to all controllers in the ${controller_index_list}.
    Log    Clear any existing mininet
    Utils.Clean Mininet System    ${tools_system}
    ${ovs_opt}=    Set Variable
    : FOR    ${index}    IN    @{controller_index_list}
    \    ${ovs_opt}=    Catenate    ${ovs_opt}    ${SPACE}tcp:${ODL_SYSTEM_${index}_IP}:${ovs_mgr_port}
    \    Log    ${ovs_opt}
    Log    Configure OVS Managers in the OVS
    Utils.Run Command On Mininet    ${tools_system}    sudo ovs-vsctl set-manager ${ovs_opt}
    Log    Check OVS configuration
    ${output}=    Wait Until Keyword Succeeds    5s    1s    Verify OVS Reports Connected    ${tools_system}
    Log    ${output}
    ${ovsdb_uuid}=    Wait Until Keyword Succeeds    5s    1s    Get OVSDB UUID    controller_http_session=controller1
    [Return]    ${ovsdb_uuid}
