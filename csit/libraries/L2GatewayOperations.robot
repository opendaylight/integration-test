*** Settings ***
Documentation     L2Gateway Operations Library. This library has useful keywords for various actions on Hwvtep and Ovs connectivity. Most of the keywords expects that ovs_conn_id, hwvtep_conn_id and devstack_conn_id are available.
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
Resource          ../variables/netvirt/Variables.robot

*** Variables ***
${L2GW_VAR_BASE}    ${CURDIR}/../variables/l2gw

*** Keywords ***
Add Ovs Bridge Manager Controller And Verify
    [Documentation]    Keyword to set OVS manager and controller to ${ODL_IP} for the OVS IP connected in ${ovs_conn_id} and verify the entries in OVSDB NETWORK TOPOLOGY and NETSTAT results.
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
    Wait Until Keyword Succeeds    60s    2s    Verify Strings In Command Output    ${ovs_conn_id}    ${OVS_SHOW}    Manager "tcp:${ODL_IP}:${OVSDBPORT}"
    ...    Controller "tcp:${ODL_IP}:${ODL_OF_PORT}"
    ${output}=    Exec Command    ${ovs_conn_id}    ${NETSTAT}
    Wait Until Keyword Succeeds    30s    2s    Validate Regexp In String    ${output}    ${NETSTAT_OVSDB_REGEX}
    Wait Until Keyword Succeeds    30s    2s    Validate Regexp In String    ${output}    ${NETSTAT_OF_REGEX}
    @{list_to_check}=    Create List    bridge/${OVS_BRIDGE}    bridge/${HWVTEP_BRIDGE}
    Wait Until Keyword Succeeds    30s    2s    Check For Elements At URI    ${OVSDB_NETWORK_TOPOLOGY}    ${list_to_check}    session

Create Itm Tunnel Between Hwvtep and Ovs
    [Arguments]    ${ovs_ip}
    [Documentation]    Keyword to create ITM Tunnel Between HWVTEP and OVS connection in ${ovs_conn_id}.
    ${dpn_id}=    Get Dpnid Decimal    ${ovs_conn_id}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${ovs_ip}    .    2
    ${prefix} =    Set Variable    ${first_two_octets}.0.0/24
    TemplatedRequests.Post_As_Json_Templated    folder=${L2GW_VAR_BASE}/itm_create    mapping={"dpnid":"${dpn_id}","ip":"${ovs_ip}","prefix":"${prefix}"}    session=session
    ${output}=    ITM Get Tunnels
    Log    ${output}

Add Vtep Manager And Verify
    [Arguments]    ${odl_ip}
    [Documentation]    Keyword to add vtep manager for HWVTEP connected in ${hwvtep_conn_id} as ${odl_ip} received in argument and verify the entries in NETSTAT and HWVTEP NETWORK TOPOLOGY.
    ${set_manager_command}=    Set Variable    ${VTEP_ADD_MGR}:${odl_ip}:${OVSDBPORT}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${set_manager_command}
    Log    ${output}
    @{list_to_verify}=    Create List    ${odl_ip}    state=ACTIVE
    Wait Until Keyword Succeeds    60s    2s    Verify Vtep List    ${MANAGER_TABLE}    @{list_to_verify}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETSTAT}
    Should Contain    ${output}    ${OVSDBPORT}
    @{list_to_check}=    Create List    ${odl_ip}
    Utils.Check For Elements At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${list_to_check}    session

Create Verify L2Gateway
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    [Documentation]    Keyword to create an L2 Gateway ${gw_name} for bridge ${bridge_name} connected to interface ${intf_name} (Using Neutron CLI).
    ${l2gw_output}=    OpenStackOperations.Create L2Gateway    ${bridge_name}    ${intf_name}    ${gw_name}
    Log    ${l2gw_output}
    ${output}=    OpenStackOperations.Get All L2Gateway
    Log    ${output}
    Should Contain    ${output}    ${gw_name}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session
    [Return]    ${l2gw_output}

Delete L2Gateway
    [Arguments]    ${gw_name}
    [Documentation]    Keyword to delete the L2 Gateway ${gw_name} received in argument.
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_DELETE} ${gw_name}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements Not At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session
    Log    ${output}

Create Verify L2Gateway Connection
    [Arguments]    ${gw_name}    ${net_name}
    [Documentation]    Keyword to create a new L2 Gateway Connection for ${gw_name} to ${net_name} (Using Neutron CLI).
    ${l2gw_output}=    OpenStackOperations.Create L2Gateway Connection    ${gw_name}    ${net_name}
    Log    ${l2gw_output}
    ${l2gw_id}=    OpenStackOperations.Get L2gw Id    ${gw_name}
    ${output}=    OpenStackOperations.Get All L2Gateway Connection
    Log    ${output}
    Should Contain    ${output}    ${l2gw_id}
    @{list_to_check}=    Create List    ${l2gw_id}
    Utils.Check For Elements At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session
    [Return]    ${l2gw_output}

Delete L2Gateway Connection
    [Arguments]    ${gw_name}
    [Documentation]    Delete the L2 Gateway connection existing for Gateway ${gw_name} received in argument (Using Neutron CLI).
    ${l2gw_conn_id}=    OpenStackOperations.Get L2gw Connection Id    ${gw_name}
    ${output}=    Exec Command    ${devstack_conn_id}    ${L2GW_CONN_DELETE} ${l2gw_conn_id}
    @{list_to_check}=    Create List    ${l2gw_conn_id}
    Utils.Check For Elements Not At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session
    Log    ${output}

Update Port For Hwvtep
    [Arguments]    ${port_name}
    [Documentation]    Keyword to update the Neutron Ports for specific configuration required to connect to HWVTEP (Using REST).
    ${port_id}=    Get Port Id    ${port_name}    ${devstack_conn_id}
    Log    ${port_id}
    ${json_data}=    Get Neutron Port Rest    ${port_id}
    Should Contain    ${json_data}    ${STR_VIF_TYPE}
    Should Contain    ${json_data}    ${STR_VNIC_TYPE}
    ${json_data}=    Replace String    ${json_data}    ${STR_VIF_TYPE}    ${STR_VIF_REPLACE}
    ${json_data}=    Replace String    ${json_data}    ${STR_VNIC_TYPE}    ${STR_VNIC_REPLACE}
    ${return}=    OpenStackOperations.Update Port Rest    ${port_id}    ${json_data}
    ${output}=    OpenStackOperations.Get Neutron Port Rest    ${port_id}
    Log    ${output}
    Should Contain    ${output}    ${STR_VIF_REPLACE}
    Should Contain    ${output}    ${STR_VNIC_REPLACE}
    Should Not Contain    ${output}    ${STR_VIF_TYPE}
    Should Not Contain    ${output}    ${STR_VNIC_TYPE}
    [Return]    ${return}

Attach Port To Hwvtep Namespace
    [Arguments]    ${port_mac}    ${ns_name}    ${tap_name}
    [Documentation]    Keyword to assign the ${port_mac} to the tap port ${tap_name} in namespace ${ns_name}
    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF} ${tap_name} ${HW_ETHER} ${port_mac}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Should Contain    ${output}    ${port_mac}

Namespace Dhclient Verify
    [Arguments]    ${ns_name}    ${ns_tap}    ${ns_port_ip}
    [Documentation]    Keyword to run dhclient for the tap port ${ns_tap} and verify if it has got assigned with ${ns_port_ip}.
    Start Command In Hwvtep    ${NETNS_EXEC} ${ns_name} dhclient ${ns_tap}

Namespace Static Ip Assign
    [Arguments]    ${ns_name}    ${ns_tap}    ${ns_port_ip}
    [Documentation]    Keyword to assign IP address to TAP port manually
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF} ${ns_tap} ${ns_port_ip}/24 UP
    Log    ${output}

Verify Strings In Command Output
    [Arguments]    ${conn_id}    ${command}    @{string_list}
    [Documentation]    Keyword to run the ${command} in ${conn_id} and verify if the output contains the list @{string_list}.
    ${output}=    Exec Command    ${conn_id}    ${command}
    : FOR    ${item}    IN    @{string_list}
    \    Should Contain    ${output}    ${item}

Verify Ping In Namespace Background
    [Arguments]    ${ns_name}    ${ns_port_mac}    ${vm_ip}
    [Documentation]    Keyword to ping the IP ${vm_ip} from ${ns_name} and verify MCAS Local Table contains ${ns_port_mac}.
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Log    ${output}
    Start Command In Hwvtep    ${NETNS_EXEC} ${ns_name} ping ${vm_ip}
    Wait Until Keyword Succeeds    30s    2s    Verify Mcas Local Table While Ping    ${ns_port_mac}

Verify Ping In Namespace Extra Timeout
    [Arguments]    ${ns_name}    ${ns_port_mac}    ${vm_ip}
    [Documentation]    Keyword to ping the IP ${vm_ip} from ${ns_name} and verify MCAS Local Table contains ${ns_port_mac}.
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Log    ${output}
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${NETNS_EXEC} ${ns_name} ping -c3 ${vm_ip}    30s
    Log    ${output}
    Wait Until Keyword Succeeds    30s    2s    Verify Mcas Local Table While Ping    ${ns_port_mac}

Verify Mcas Local Table While Ping
    [Arguments]    ${mac}
    [Documentation]    Keyword to check if ${mac} is available under UCAST_MACS_LOCALE_TABLE of HWVTEP dump table.
    Verify Vtep List    ${UCAST_MACS_LOCALE_TABLE}    ${mac}

Verify Nova VM IP
    [Arguments]    ${vm_name}
    [Documentation]    Keyword to verify if the VM has received IP, and to vefiry it is not null.
    ${vm_ip}    ${dhcp_ip}    Verify VMs Received DHCP Lease    ${vm_name}
    Log    ${vm_ip}
    Should Not Contain    ${vm_ip}    None
    [Return]    ${vm_ip}

Get L2gw Debug Info
    [Documentation]    Keyword to collect the general debug information required for HWVTEP Test Suite.
    Exec Command    ${hwvtep_conn_id}    ${OVSDB_CLIENT_DUMP}
    OpenStackOperations.Get Test Teardown Debugs
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:external-tunnel-list/
    Log    ${resp.content}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/network-topology:network-topology/topology/hwvtep:1
    Log    ${resp.content}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/network-topology:network-topology/topology/hwvtep:1
    Log    ${resp.content}

Start Command In Hwvtep
    [Arguments]    ${command}
    [Documentation]    Keyword to execute Start Command in HWVTEP IP.
    ${conn_id}=    SSHLibrary.Open Connection    ${HWVTEP_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Log    ${conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Start Command    ${command}
    ${output}=    Exec Command    ${conn_id}    sudo ovs-ofctl dump-flows br-int -O Openflow13
    Log    ${output}
    close connection

Verify Vtep List
    [Arguments]    ${table_name}    @{list}
    [Documentation]    Keyword to run vtep-ctl list for the table ${table_name} and verify the list @{list} contents exists in output.
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${VTEP LIST} ${table_name}
    : FOR    ${item}    IN    @{list}
    \    Should Contain    ${output}    ${item}

Get Vtep List
    [Arguments]    ${table_name}
    [Documentation]    Keyword to return the contents of vtep-ctl list for table ${table_name}.
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${VTEP LIST} ${table_name}
    [Return]    ${output}

Get Dpnid Decimal
    [Arguments]    ${conn_id}
    [Documentation]    Keyword to return DPN ID in decimal for the br-int in IP connected via ${conn_id}.
    ${output}=    Exec Command    ${conn_id}    ${GET_DPNID}
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${dpn_id}=    Get from List    ${splitted_output}    0
    Log    ${dpn_id}
    [Return]    ${dpn_id}

Verify Ovs Tunnel
    [Arguments]    ${hwvtep_ip}    ${ovs_ip}    ${seg_id}=${NET_1_SEGID}
    [Documentation]    Keyword to verify that the OVS tunnel entries are configured for OVS and HWVTEP.
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key="${seg_id}", remote_ip="${ovs_ip}"
    ${output}=    Exec Command    ${ovs_conn_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key=flow, local_ip="${ovs_ip}", remote_ip="${hwvtep_ip}"

Get Vtep Field Values From Table
    [Arguments]    ${table_name}    ${column_name}
    [Documentation]    Keyword to return specific field value received in ${column_name} from the vtep-ctl list for ${table_name}.
    ${output}=    Exec Command    ${hwvtep_conn_id}    ${VTEP_LIST_COLUMN}${column_name} list ${table_name} | awk '{print $3}'
    Log    ${output}
    @{keys}=    Split String    ${output}
    Log    ${keys}
    [Return]    ${keys}

Validate Regexp In String
    [Arguments]    ${string}    ${regexp}    ${verify_count}=1
    @{occr}=    Get Regexp Matches    ${string}    ${regexp}
    ${count}=    Get Length    ${occr}
    Should Be Equal As Integers    ${count}    ${verify_count}

Exec Command
    [Arguments]    ${conn_id}    ${command}    ${timeout}=10s
    Switch Connection    ${conn_id}
    ${output}=    DevstackUtils.Write Commands Until Prompt    ${command}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Verify Elan Flow Entries
    [Arguments]    ${ip}    ${srcMacAddrs}    ${destMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN service
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=50
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log    ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    dl_src=${sMacAddr}
    Should Contain    ${flow_output}    table=51
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log    ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{destMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    dl_dst=${dMacAddr}
    Should Contain    ${flow_output}    table=52
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    Log    ${sMac_output}
