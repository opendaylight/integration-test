*** Settings ***
Documentation     L2Gateway Operations
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          OVSDB.robot
Resource          Utils.robot
Resource          MininetKeywords.robot
Resource          VpnOperations.robot
Resource          OpenStackOperations.robot
Resource          DevstackUtils.robot
Resource          ../variables/l2gw/Variables.robot

*** Variables ***
${VAR_BASE}       ${CURDIR}/../variables/l2gw

*** Keywords ***
Add Ovs Bridge Manager Controller And Verify
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_RESTART}
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_DEL_MGR}
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_DEL_CTRLR} ${OVS_BRIDGE}
    ${output}=    Exec Command    ${ovs_conn_id}    ${DEL_OVS_BRIDGE} ${OVS_BRIDGE}
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_SHOW}
    Should Not Contain    ${output}    Manager
    Should Not Contain    ${output}    Controller
    ${output}=    Exec Command    ${ovs_conn_id}    ${CREATE_OVS_BRIDGE} ${OVS_BRIDGE}
    ${output}=    Exec Command    ${ovs_conn_id}    ${SET_FAIL_MODE} ${OVS_BRIDGE} secure
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_SET_MGR}:${ODL_IP}:${OVSDBPORT}
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_SET_CTRLR} ${OVS_BRIDGE} tcp:${ODL_IP}:${ODL_OF_PORT}
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_SHOW}
    Should Contain    ${output}    Manager "tcp:${ODL_IP}:${OVSDBPORT}"
    Should Contain    ${output}    Controller "tcp:${ODL_IP}:${ODL_OF_PORT}"
    ${output}=    Exec Command    ${ovs_conn_id}    ${NETSTAT}
    Validate Regexp In String    ${output}    ${NETSTAT_OVSDB_REGEX}
    Validate Regexp In String    ${output}    ${NETSTAT_OF_REGEX}
    @{list_to_check}=    Create List    bridge/${OVS_BRIDGE}    bridge/${HWVTEP_BRIDGE}
    Check For Elements At URI    ${OVSDB_NETWORK_TOPOLOGY}    ${list_to_check}    session

Create Itm Tunnel Between Hwvtep and Ovs
    [Arguments]    ${ovs_ip}
    ${dpn_id}=    Get Dpnid Decimal    ${ovs_conn_id}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${ovs_ip}    .    2
    ${prefix} =    Set Variable    ${first_two_octets}.0.0/24
    Log    ${ovs_ip}
    Log    ${dpn_id}
    Log    ${prefix}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/itm_create    mapping={"dpnid":"${dpn_id}","ip":"${ovs_ip}","prefix":"${prefix}"}    session=session
    ${output}=    ITM Get Tunnels
    Log    ${output}

Add Vtep Manager And Verify
    [Arguments]    ${odl_ip}
    [Documentation]    To add the vtep manager and to verify the ODL_IP present in the ovsdb client dump
    ${set_manager_command}=    Set Variable    ${VTEP_ADD_MGR}:${odl_ip}:${OVSDBPORT}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${set_manager_command}
    Verify Vtep List    ${MANAGER_TABLE}    ${odl_ip}
    ${manager_id}=    Get Vtep Field Values From Table    ${MANAGER_TABLE}    ${UUID_COL_NAME}
    Verify Vtep List    ${MANAGER_TABLE}    @{manager_id}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETSTAT}
    Should Contain    ${output}    ${OVSDBPORT}
    @{list_to_check}=    Create List    ${odl_ip}
    Check For Elements At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${list_to_check}    session

Create L2Gateway
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    ${l2gw_output}=    Exec Command    ${devstack_conn_id}    ${L2GW_CREATE} name=${bridge_name},interface_names=${intf_name} ${gw_name}
    Log    ${l2gw_output}
    ${output}=    Get All L2Gateway
    Log    ${output}
    Should Contain    ${output}    ${gw_name}
    [Return]    ${l2gw_output}

Delete L2Gateway
    [Arguments]    ${gw_name}
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_DELETE} ${gw_name}
    Log    ${output}

Create L2Gateway Connection
    [Arguments]    ${gw_name}    ${net_name}
    ${l2gw_output}=    Exec Command    ${devstack_conn_id}    ${L2GW_CONN_CREATE} ${gw_name} ${net_name}
    Log    ${l2gw_output}
    ${l2gw_id}=    Get L2gw Id    ${gw_name}
    ${output}=    Get All L2Gateway Connection
    Log    ${output}
    Should Contain    ${output}    ${l2gw_id}
    [Return]    ${l2gw_output}

Delete L2Gateway Connection
    [Arguments]    ${gw_name}
    ${l2gw_conn_id}=    Get L2gw Connection Id    ${gw_name}
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_CONN_DELETE} ${l2gw_conn_id}
    Log    ${output}

Get All L2Gateway
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_GET_YAML}
    [Return]    ${output}

Get All L2Gateway Connection
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_GET_CONN_YAML}
    [Return]    ${output}

Get L2Gateway
    [Arguments]    ${gw_id}
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_SHOW} ${gw_id}
    Log    ${output}
    Should Contain    ${output}    ${gw_id}
    [Return]    ${output}

Get L2gw Id
    [Arguments]    ${l2gw_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    ${L2GW_GET} | grep "${l2gw_name}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${l2gw_id}=    Get from List    ${splitted_output}    0
    Log    ${l2gw_id}
    [Return]    ${l2gw_id}

Get L2gw Connection Id
    [Arguments]    ${l2gw_name}
    [Documentation]    Retrieve the net id for the given network name to create specific vm instance
    Switch Connection    ${devstack_conn_id}
    ${l2gw_id}=    Get L2gw Id    ${l2gw_name}
    ${output}=    Write Commands Until Prompt    ${L2GW_GET_CONN} | grep "${l2gw_id}" | awk '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${l2gw_conn_id}=    Get from List    ${splitted_output}    0
    Log    ${l2gw_conn_id}
    [Return]    ${l2gw_conn_id}

Neutron Port List Rest
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/${GET_ALL_PORTS_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Get Neutron Port Rest
    [Arguments]    ${port_id}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Update Port For Hwvtep
    [Arguments]    ${port_name}
    ${port_id}=    Get Port Id    ${port_name}    ${devstack_conn_id}
    Log    ${port_id}
    ${json_data}=    Get Neutron Port Rest    ${port_id}
    Should Contain    ${json_data}    ${STR_VIF_TYPE}
    Should Contain    ${json_data}    ${STR_VNIC_TYPE}
    ${json_data}=    Replace String    ${json_data}    ${STR_VIF_TYPE}    ${STR_VIF_REPLACE}
    ${json_data}=    Replace String    ${json_data}    ${STR_VNIC_TYPE}    ${STR_VNIC_REPLACE}
    ${return}=    Update Port Rest    ${port_id}    ${json_data}
    ${output}=    Get Neutron Port Rest    ${port_id}
    Log    ${output}
    Should Contain    ${output}    ${STR_VIF_REPLACE}
    Should Contain    ${output}    ${STR_VNIC_REPLACE}
    Should Not Contain    ${output}    ${STR_VIF_TYPE}
    Should Not Contain    ${output}    ${STR_VNIC_TYPE}
    [Return]    ${return}

Update Port Rest
    [Arguments]    ${port_id}    ${json_data}
    Log    ${json_data}
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/${GET_PORT_URL}/${port_id}    ${json_data}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.content}

Get Port Mac
    [Arguments]    ${port_name}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron port-list | grep "${port_name}" | awk '{print $6}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${port_mac}=    Get from List    ${splitted_output}    0
    Log    ${port_mac}
    [Return]    ${port_mac}

Get Port Ip
    [Arguments]    ${port_name}
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron port-list | grep "${port_name}" | awk '{print $11}' | awk -F "\\"" '{print $2}'    30s
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${port_ip}=    Get from List    ${splitted_output}    0
    Log    ${port_ip}
    [Return]    ${port_ip}

Attach Port To Hwvtep Namespace
    [Arguments]    ${port_name}    ${ns_name}    ${tap_name}
    ${port_mac}=    Get Port Mac    ${port_name}
    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF} ${tap_name} ${HW_ETHER} ${port_mac}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Should Contain    ${output}    ${port_mac}

Namespace Dhclient Verify
    [Arguments]    ${ns_name}    ${ns_tap}    ${port_mac}
    Start Command In Hwvtep    ${NETNS_EXEC} ${ns_name} dhclient ${ns_tap}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Log    ${output}
    Verify Vtep List    ${UCAST_MACS_LOCALE_TABLE}    ${port_mac}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Log    ${output}
    [Return]    ${output}

DUMP
    Exec Command    ${hwvtep_conn_id}    ${OVSDB_CLIENT_DUMP}

Start Command In Hwvtep
    [Arguments]    ${command}
    ${conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Log    ${conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Start Command    ${command}

Verify Vtep List
    [Arguments]    ${table_name}    @{list}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${VTEP LIST} ${table_name}
    : FOR    ${item}    IN    @{list}
    \    Should Contain    ${output}    ${item}

Get Vtep List
    [Arguments]    ${table_name}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${VTEP LIST} ${table_name}
    [Return]    ${output}

Get Dpnid Decimal
    [Arguments]    ${conn_id}
    ${output}=    Exec Command    ${conn_id}    ${GET_DPNID}
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${dpn_id}=    Get from List    ${splitted_output}    0
    Log    ${dpn_id}
    [Return]    ${dpn_id}

Verify Ovs Tunnel
    [Arguments]    ${hwvtep_ip}    ${ovs_ip}    ${seg_id}=${NET_1_SEGID}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key="${seg_id}", remote_ip="${ovs_ip}"
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key=flow, local_ip="${ovs_ip}", remote_ip="${hwvtep_ip}"

Get Vtep Field Values From Table
    [Arguments]    ${table_name}    ${column_name}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${VTEP_LIST_COLUMN}${column_name} list ${table_name} | awk '{print $3}'
    Log    ${output}
    @{keys}=    Split String    ${output}
    Log    ${keys}
    [Return]    ${keys}

Verify Namespace Ping
    [Arguments]    ${ip}    ${ns}=${HWVTEP_NS1}
    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns} ping -c 3 ${ip}

Validate Regexp In String
    [Arguments]    ${string}    ${regexp}    ${verify_count}=1
    @{occr}=    Get Regexp Matches    ${string}    ${regexp}
    ${count}=    Get Length    ${occr}
    Should Be Equal As Integers    ${count}    ${verify_count}

Exec Command
    [Arguments]    ${conn_id}    ${command}
    Switch Connection    ${conn_id}
    ${output}=    DevstackUtils.Write Commands Until Prompt    ${command}
    Log    ${output}
    [Return]    ${output}
