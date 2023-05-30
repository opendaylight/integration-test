*** Settings ***
Documentation       L2Gateway Operations Library. This library has useful keywords for various actions on Hwvtep and Ovs connectivity. Most of the keywords expects that ovs_conn_id,ovs2_conn_id, hwvtep_conn_id, hwvtep2_conn_id and OS_CNTL_CONN_ID are available.

Library             SSHLibrary
Library             Collections
Library             RequestsLibrary
Resource            OVSDB.robot
Resource            Utils.robot
Resource            MininetKeywords.robot
Resource            VpnOperations.robot
Resource            OpenStackOperations.robot
Resource            DevstackUtils.robot
Resource            ../variables/l2gw/Variables.robot
Resource            ../variables/netvirt/Variables.robot


*** Variables ***
${L2GW_VAR_BASE}    ${CURDIR}/../variables/l2gw


*** Keywords ***
Add Ovs Bridge Manager Controller And Verify
    [Documentation]    Keyword to set OVS manager and controller to ${ODL_IP} for the OVS IP connected in ${conn_id} and verify the entries in OVSDB NETWORK TOPOLOGY and NETSTAT results.
    [Arguments]    ${conn_id}=${OS_CMP1_CONN_ID}    ${hwvtep_bridge}=${HWVTEP_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${OVS_RESTART}
    ${output}=    Exec Command    ${conn_id}    ${OVS_DEL_MGR}
    ${output}=    Exec Command    ${conn_id}    ${OVS_DEL_CTRLR} ${INTEGRATION_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${DEL_OVS_BRIDGE} ${INTEGRATION_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${OVS_SHOW}
    Should Not Contain    ${output}    Manager
    Should Not Contain    ${output}    Controller
    ${output}=    Exec Command    ${conn_id}    ${CREATE_OVS_BRIDGE} ${INTEGRATION_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${SET_FAIL_MODE} ${INTEGRATION_BRIDGE} secure
    ${output}=    Exec Command    ${conn_id}    ${OVS_SET_MGR}:${ODL_IP}:${OVSDBPORT}
    ${output}=    Exec Command    ${conn_id}    ${OVS_SET_CTRLR} ${INTEGRATION_BRIDGE} tcp:${ODL_IP}:${ODL_OF_PORT}
    Wait Until Keyword Succeeds
    ...    60s
    ...    2s
    ...    Verify Strings In Command Output
    ...    ${conn_id}
    ...    ${OVS_SHOW}
    ...    Manager "tcp:${ODL_IP}:${OVSDBPORT}"
    ...    Controller "tcp:${ODL_IP}:${ODL_OF_PORT}"
    ${output}=    Exec Command    ${conn_id}    ${NETSTAT}
    Wait Until Keyword Succeeds    30s    2s    Validate Regexp In String    ${output}    ${NETSTAT_OVSDB_REGEX}
    Wait Until Keyword Succeeds    30s    2s    Validate Regexp In String    ${output}    ${NETSTAT_OF_REGEX}
    @{list_to_check}=    Create List    bridge/${INTEGRATION_BRIDGE}    bridge/${hwvtep_bridge}
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Check For Elements At URI
    ...    ${OVSDB_NETWORK_TOPOLOGY}
    ...    ${list_to_check}
    ...    session

Create Itm Tunnel Between Hwvtep and Ovs
    [Documentation]    Keyword to create ITM Tunnel Between HWVTEP and OVS connection in ${ovs_id}.
    [Arguments]    ${ovs_id}    ${ovs_ip}
    ${dpn_id}=    Get Dpnid Decimal    ${ovs_id}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${ovs_ip}    .    2
    ${prefix}=    Set Variable    ${first_two_octets}.0.0/24
    TemplatedRequests.Post_As_Json_Templated
    ...    folder=${L2GW_VAR_BASE}/itm_create
    ...    mapping={"dpnid":"${dpn_id}","ip":"${ovs_ip}","prefix":"${prefix}"}
    ...    session=session
    ${output}=    ITM Get Tunnels
    Log    ${output}

Add Vtep Manager And Verify
    [Documentation]    Keyword to add vtep manager for HWVTEP connected in ${conn_id} as ${odl_ip} received in argument and verify the entries in NETSTAT and HWVTEP NETWORK TOPOLOGY.
    [Arguments]    ${odl_ip}    ${conn_id}=${hwvtep_conn_id}
    ${set_manager_command}=    Set Variable    ${VTEP_ADD_MGR}:${odl_ip}:${OVSDBPORT}
    ${output}=    Exec Command    ${conn_id}    ${set_manager_command}
    Log    ${output}
    @{list_to_verify}=    Create List    ${odl_ip}    state=ACTIVE
    Wait Until Keyword Succeeds    60s    2s    Verify Vtep List    ${conn_id}    ${MANAGER_TABLE}    @{list_to_verify}
    ${output}=    Exec Command    ${conn_id}    ${NETSTAT}
    Should Contain    ${output}    ${OVSDBPORT}
    @{list_to_check}=    Create List    ${odl_ip}
    Wait Until Keyword Succeeds
    ...    30s
    ...    2s
    ...    Utils.Check For Elements At URI
    ...    ${HWVTEP_NETWORK_TOPOLOGY}
    ...    ${list_to_check}
    ...    session

Create Verify L2Gateway
    [Documentation]    Keyword to create an L2 Gateway ${gw_name} for bridge ${bridge_name} connected to interface ${intf_name} (Using Neutron CLI).
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    ${l2gw_output}=    OpenStackOperations.Create L2Gateway    ${bridge_name}    ${intf_name}    ${gw_name}
    Log    ${l2gw_output}
    ${output}=    OpenStackOperations.Get All L2Gateway
    Log    ${output}
    Should Contain    ${output}    ${gw_name}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session
    RETURN    ${l2gw_output}

Update And Verify L2Gateway
    [Documentation]    Keyword to add interface {intf_name_2} to an existing L2 Gateway ${gw_name} for bridge ${bridge_name} (Using Neutron CLI).
    [Arguments]    ${bridge_name}    ${gw_name}    ${intf_name_1}    ${intf_name_2}
    ${l2gw_output}=    OpenStackOperations.Update L2Gateway
    ...    ${bridge_name}
    ...    ${gw_name}
    ...    ${intf_name_1}
    ...    ${intf_name_2}
    ${output}=    OpenStackOperations.Get All L2Gateway
    Log    ${output}
    Should Contain    ${output}    ${gw_name}
    Should Contain    ${output}    ${intf_name_1}
    Should Contain    ${output}    ${intf_name_2}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session
    RETURN    ${l2gw_output}

Delete L2Gateway
    [Documentation]    Keyword to delete the L2 Gateway ${gw_name} received in argument.
    ...    If ${check_for_null} is True return of 404 is treated as empty list. From Neon onwards,
    ...    an empty list is always returned as null, giving 404 on rest call.
    [Arguments]    ${gw_name}    ${check_for_null}=False
    ${output}=    Exec Command    ${OS_CNTL_CONN_ID}    ${L2GW_DELETE} ${gw_name}
    Log    ${output}
    @{list_to_check}=    Create List    ${gw_name}
    BuiltIn.Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    Utils.Check For Elements Not At URI
    ...    ${L2GW_LIST_REST_URL}
    ...    ${list_to_check}
    ...    session
    ...    check_for_null=${check_for_null}

Create Verify L2Gateway Connection
    [Documentation]    Keyword to create a new L2 Gateway Connection for ${gw_name} to ${net_name} (Using Neutron CLI).
    [Arguments]    ${gw_name}    ${net_name}
    ${l2gw_output}=    OpenStackOperations.Create L2Gateway Connection    ${gw_name}    ${net_name}
    Log    ${l2gw_output}
    ${l2gw_id}=    OpenStackOperations.Get L2gw Id    ${gw_name}
    ${output}=    OpenStackOperations.Get All L2Gateway Connection
    Log    ${output}
    Should Contain    ${output}    ${l2gw_id}
    @{list_to_check}=    Create List    ${l2gw_id}
    Utils.Check For Elements At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session
    RETURN    ${l2gw_output}

Verify L2Gateway Connection
    [Documentation]    Keyword to verify existing L2 Gateway Connection for ${gw_name} to ${net_name} $(Using Neutron CLI).
    [Arguments]    ${gw_name}    ${net_name}
    ${l2gw_id}=    OpenStackOperations.Get L2gw Id    ${gw_name}
    ${output}=    OpenStackOperations.Get All L2Gateway Connection
    Log    ${output}
    Should Contain    ${output}    ${l2gw_id}
    @{list_to_check}=    Create List    ${l2gw_id}
    Utils.Check For Elements At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session

Delete L2Gateway Connection
    [Documentation]    Delete the L2 Gateway connection existing for Gateway ${gw_name} received in argument (Using Neutron CLI).
    ...    If ${check_for_null} is True return of 404 is treated as empty list. From Neon onwards, an empty list is always
    ...    returned as null, giving 404 on rest call.
    [Arguments]    ${gw_name}    ${check_for_null}=False
    ${l2gw_conn_id}=    OpenStackOperations.Get L2gw Connection Id    ${gw_name}
    ${output}=    Exec Command    ${OS_CNTL_CONN_ID}    ${L2GW_CONN_DELETE} ${l2gw_conn_id}
    Log    ${output}
    @{list_to_check}=    Create List    ${l2gw_conn_id}
    BuiltIn.Wait Until Keyword Succeeds
    ...    5s
    ...    1s
    ...    Utils.Check For Elements Not At URI
    ...    ${L2GW_CONN_LIST_REST_URL}
    ...    ${list_to_check}
    ...    session
    ...    check_for_null=${check_for_null}

Update Port For Hwvtep
    [Documentation]    Keyword to update the Neutron Ports for specific configuration required to connect to HWVTEP (Using REST).
    [Arguments]    ${port_name}
    ${port_id}=    Get Port Id    ${port_name}
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
    RETURN    ${return}

Attach Port To Hwvtep Namespace
    [Documentation]    Keyword to assign the ${port_mac} to the tap port ${tap_name} in namespace ${ns_name}
    [Arguments]    ${port_mac}    ${ns_name}    ${tap_name}    ${conn_id}=${hwvtep_conn_id}
    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF} ${tap_name} ${HW_ETHER} ${port_mac}
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Should Contain    ${output}    ${port_mac}

Namespace Dhclient Verify
    [Documentation]    Keyword to run dhclient for the tap port ${ns_tap} and verify if it has got assigned with ${ns_port_ip}.
    [Arguments]    ${ns_name}    ${ns_tap}    ${ns_port_ip}    ${conn_id}=${hwvtep_conn_id}    ${hwvtep_ip}=${HWVTEP_IP}
    Start Command In Hwvtep    ${NETNS_EXEC} ${ns_name} dhclient ${ns_tap}    ${hwvtep_ip}
    Wait Until Keyword Succeeds
    ...    60s
    ...    2s
    ...    Verify Strings In Command Output
    ...    ${conn_id}
    ...    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    ...    ${ns_port_ip}

Verify Strings In Command Output
    [Documentation]    Keyword to run the ${command} in ${conn_id} and verify if the output contains the list @{string_list}.
    [Arguments]    ${conn_id}    ${command}    @{string_list}
    ${output}=    Exec Command    ${conn_id}    ${command}
    FOR    ${item}    IN    @{string_list}
        Should Contain    ${output}    ${item}
    END

Verify Ping In Namespace Extra Timeout
    [Documentation]    Keyword to ping the IP ${vm_ip} from ${ns_name} and verify MCAS Local Table contains ${ns_port_mac}.
    [Arguments]    ${ns_name}    ${ns_port_mac}    ${vm_ip}    ${conn_id}=${hwvtep_conn_id}    ${hwvtep_ip}=${HWVTEP_IP}
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Log    ${output}
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ping -c3 ${vm_ip}    30s
    Log    ${output}
    Should Not Contain    ${output}    ${PACKET_LOSS}
    Wait Until Keyword Succeeds    30s    2s    Verify Macs Local Table While Ping    ${ns_port_mac}    ${conn_id}

Verify Ping Fails In Namespace
    [Documentation]    Keyword to ping the IP ${vm_ip} from ${ns_name} and should verify that it fails
    [Arguments]    ${ns_name}    ${ns_port_mac}    ${vm_ip}    ${conn_id}=${hwvtep_conn_id}    ${hwvtep_ip}=${HWVTEP_IP}
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ping -c3 ${vm_ip}    30s
    Log    ${output}
    Should Contain    ${output}    ${PACKET_LOSS}

Verify Macs Local Table While Ping
    [Documentation]    Keyword to check if ${mac} is available under UCAST_MACS_LOCALE_TABLE of HWVTEP dump table.
    [Arguments]    ${mac}    ${conn_id}
    Verify Vtep List    ${conn_id}    ${UCAST_MACS_LOCALE_TABLE}    ${mac}

Verify Nova VM IP
    [Documentation]    Keyword to verify if the VM has received IP, and to verify it is not null.
    [Arguments]    ${vm_name}
    @{vm_ip}    ${dhcp_ip}=    Get VM IPs    ${vm_name}
    Should Not Contain    ${vm_ip}    None
    Should Not Contain    ${dhcp_ip}    None
    RETURN    ${vm_ip}[0]

Get L2gw Debug Info
    [Documentation]    Keyword to collect the general debug information required for HWVTEP Test Suite.
    Exec Command    ${hwvtep_conn_id}    ${OVSDB_CLIENT_DUMP}
    OpenStackOperations.Get Test Teardown Debugs
    ${resp}=    RequestsLibrary.Get Request    session    ${CONFIG_API}/itm-state:external-tunnel-list/
    Log    ${resp.text}
    ${resp}=    RequestsLibrary.Get Request
    ...    session
    ...    ${CONFIG_API}/network-topology:network-topology/topology/hwvtep:1
    Log    ${resp.text}
    ${resp}=    RequestsLibrary.Get Request
    ...    session
    ...    ${OPERATIONAL_API}/network-topology:network-topology/topology/hwvtep:1
    Log    ${resp.text}
    Exec Command    ${OS_CNTL_CONN_ID}    cat /etc/neutron/neutron.conf
    Exec Command    ${OS_CNTL_CONN_ID}    cat /etc/neutron/l2gw_plugin.ini
    Exec Command    ${OS_CNTL_CONN_ID}    ps -ef | grep neutron-server

Start Command In Hwvtep
    [Documentation]    Keyword to execute Start Command in HWVTEP IP.
    [Arguments]    ${command}    ${hwvtep_ip}
    ${conn_id}=    SSHLibrary.Open Connection    ${hwvtep_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Log    ${conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Start Command    ${command}
    ${output}=    Exec Command    ${conn_id}    sudo ovs-ofctl dump-flows ${INTEGRATION_BRIDGE} -O Openflow13
    Log    ${output}
    close connection

Verify Vtep List
    [Documentation]    Keyword to run vtep-ctl list for the table ${table_name} and verify the list @{list} contents exists in output.
    [Arguments]    ${conn_id}    ${table_name}    @{list}
    ${output}=    Exec Command    ${conn_id}    ${VTEP LIST} ${table_name}
    FOR    ${item}    IN    @{list}
        Should Contain    ${output}    ${item}
    END

Get Vtep List
    [Documentation]    Keyword to return the contents of vtep-ctl list for table ${table_name}.
    [Arguments]    ${table_name}    ${conn_id}=${hwvtep_conn_id}
    ${output}=    Exec Command    ${conn_id}    ${VTEP LIST} ${table_name}
    RETURN    ${output}

Get Dpnid Decimal
    [Documentation]    Keyword to return DPN ID in decimal for the br-int in IP connected via ${conn_id}.
    [Arguments]    ${conn_id}
    ${output}=    Exec Command    ${conn_id}    ${GET_DPNID}
    Log    ${output}
    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    ${dpn_id}=    Get from List    ${splitted_output}    0
    Log    ${dpn_id}
    RETURN    ${dpn_id}

Verify Ovs Tunnel
    [Documentation]    Keyword to verify that the OVS tunnel entries are configured for OVS and HWVTEP.
    [Arguments]    ${hwvtep_ip}    ${ovs_ip}    ${seg_id}=${NET_1_SEGID}    ${conn_id}=${hwvtep_conn_id}
    ${output}=    Exec Command    ${conn_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key="${seg_id}", remote_ip="${ovs_ip}"
    ${output}=    Exec Command    ${OS_CMP1_CONN_ID}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key=flow, local_ip="${ovs_ip}", remote_ip="${hwvtep_ip}"

Get Vtep Field Values From Table
    [Documentation]    Keyword to return specific field value received in ${column_name} from the vtep-ctl list for ${table_name}.
    [Arguments]    ${table_name}    ${column_name}    ${conn_id}=${hwvtep_conn_id}
    ${output}=    Exec Command    ${conn_id}    ${VTEP_LIST_COLUMN}${column_name} list ${table_name} | awk '{print $3}'
    Log    ${output}
    @{keys}=    Split String    ${output}
    Log    ${keys}
    RETURN    ${keys}

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
    RETURN    ${output}

Verify Elan Flow Entries
    [Documentation]    Verify Flows Are Present For ELAN service
    [Arguments]    ${ip}    ${srcMacAddrs}    ${destMacAddrs}
    ${flow_output}=    Run Command On Remote System
    ...    ${ip}
    ...    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=50
    ${sMac_output}=    Get Lines Containing String    ${flow_output}    table=50
    Log    ${sMac_output}
    FOR    ${sMacAddr}    IN    @{srcMacAddrs}
        ${resp}=    Should Contain    ${sMac_output}    dl_src=${sMacAddr}
    END
    Should Contain    ${flow_output}    table=51
    ${dMac_output}=    Get Lines Containing String    ${flow_output}    table=51
    Log    ${dMac_output}
    FOR    ${dMacAddr}    IN    @{destMacAddrs}
        ${resp}=    Should Contain    ${dMac_output}    dl_dst=${dMacAddr}
    END
    Should Contain    ${flow_output}    table=52
    ${sMac_output}=    Get Lines Containing String    ${flow_output}    table=52
    Log    ${sMac_output}

Cleanup L2GW Optional Resources
    [Documentation]    Cleanup resources that are only allocated on certain combos...
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_3}