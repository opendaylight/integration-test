*** Settings ***
Documentation     L2Gateway Operations Library. This library has useful keywords for various actions on Hwvtep and Ovs connectivity. Most of the keywords expects that ovs_conn_id,ovs2_conn_id, hwvtep_conn_id, hwvtep2_conn_id and OS_CNTL_CONN_ID are available.
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
Resource          ../variables/Variables.robot
Resource          DataModels.robot
Resource          Genius.robot
Variables         ../variables/l2gw/l2gw_datastore_dumps.py

*** Variables ***
${L2GW_VAR_BASE}    ${CURDIR}/../variables/l2gw

*** Keywords ***
Add Ovs Bridge Manager Controller And Verify
    [Arguments]    ${conn_id}=${OS_CMP1_CONN_ID}    ${hwvtep_bridge}=${HWVTEP_BRIDGE}
    [Documentation]    Keyword to set OVS manager and controller to ${ODL_IP} for the OVS IP connected in ${conn_id} and verify the entries in OVSDB NETWORK TOPOLOGY and NETSTAT results.
    ${output}=    Exec Command    ${conn_id}    ${OVS_RESTART}
    ${output}=    Exec Command    ${conn_id}    ${OVS_DEL_MGR}
    ${output}=    Exec Command    ${conn_id}    ${OVS_DEL_CTRLR} ${OVS_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${DEL_OVS_BRIDGE} ${OVS_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${OVS_SHOW}
    Should Not Contain    ${output}    Manager
    Should Not Contain    ${output}    Controller
    ${output}=    Exec Command    ${conn_id}    ${CREATE_OVS_BRIDGE} ${OVS_BRIDGE}
    ${output}=    Exec Command    ${conn_id}    ${SET_FAIL_MODE} ${OVS_BRIDGE} secure
    ${output}=    Exec Command    ${conn_id}    ${OVS_SET_MGR}:${ODL_IP}:${OVSDBPORT}
    ${output}=    Exec Command    ${conn_id}    ${OVS_SET_CTRLR} ${OVS_BRIDGE} tcp:${ODL_IP}:${ODL_OF_PORT}
    Wait Until Keyword Succeeds    60s    2s    Verify Strings In Command Output    ${conn_id}    ${OVS_SHOW}    Manager "tcp:${ODL_IP}:${OVSDBPORT}"
    ...    Controller "tcp:${ODL_IP}:${ODL_OF_PORT}"
    ${output}=    Exec Command    ${conn_id}    ${NETSTAT}
    Wait Until Keyword Succeeds    30s    2s    Validate Regexp In String    ${output}    ${NETSTAT_OVSDB_REGEX}
    Wait Until Keyword Succeeds    30s    2s    Validate Regexp In String    ${output}    ${NETSTAT_OF_REGEX}
    @{list_to_check}=    Create List    bridge/${OVS_BRIDGE}    bridge/${hwvtep_bridge}
    Wait Until Keyword Succeeds    30s    2s    Check For Elements At URI    ${OVSDB_NETWORK_TOPOLOGY}    ${list_to_check}    session

Create Itm Tunnel Between Hwvtep and Ovs
    [Arguments]    ${ovs_id}    ${ovs_ip}
    [Documentation]    Keyword to create ITM Tunnel Between HWVTEP and OVS connection in ${ovs_id}.
    ${dpn_id}=    Get Dpnid Decimal    ${ovs_id}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${ovs_ip}    .    2
    ${prefix} =    Set Variable    ${first_two_octets}.0.0/24
    TemplatedRequests.Post_As_Json_Templated    folder=${L2GW_VAR_BASE}/itm_create    mapping={"dpnid":"${dpn_id}","ip":"${ovs_ip}","prefix":"${prefix}"}    session=session
    ${output}=    ITM Get Tunnels
    Log    ${output}

Add Vtep Manager And Verify
    [Arguments]    ${odl_ip}    ${conn_id}=${hwvtep_conn_id}
    [Documentation]    Keyword to add vtep manager for HWVTEP connected in ${conn_id} as ${odl_ip} received in argument and verify the entries in NETSTAT and HWVTEP NETWORK TOPOLOGY.
    ${set_manager_command}=    Set Variable    ${VTEP_ADD_MGR}:${odl_ip}:${OVSDBPORT}
    ${output}=    Exec Command    ${conn_id}    ${set_manager_command}
    Log    ${output}
    ${list_to_verify}=    Create List    ${odl_ip}    state=ACTIVE
    Wait Until Keyword Succeeds    60s    2s    Verify Vtep List    ${conn_id}    ${MANAGER_TABLE}    ${list_to_verify}
    ${output}=    Exec Command    ${conn_id}    ${NETSTAT}
    Should Contain    ${output}    ${OVSDBPORT}
    @{list_to_check}=    Create List    ${odl_ip}
    Wait Until Keyword Succeeds    30s    2s    Utils.Check For Elements At URI    ${HWVTEP_NETWORK_TOPOLOGY}    ${list_to_check}    session

Create Verify L2Gateway
    [Arguments]    ${bridge_name}    ${intf_name}    ${gw_name}
    [Documentation]    Keyword to create an L2 Gateway ${gw_name} for bridge ${bridge_name} connected to interface ${intf_name} (Using Neutron CLI).
    ${l2gw_output}=    OpenStackOperations.Create L2Gateway    ${bridge_name}    ${intf_name}    ${gw_name}
    ${output}=    OpenStackOperations.Get All L2Gateway
    Should Contain    ${output}    ${gw_name}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session

Update And Verify L2Gateway
    [Arguments]    ${bridge_name}    ${gw_name}    ${intf_name_1}    ${intf_name_2}
    [Documentation]    Keyword to add interface {intf_name_2} to an existing L2 Gateway ${gw_name} for bridge ${bridge_name} (Using Neutron CLI).
    ${l2gw_output}=    OpenStackOperations.Update L2Gateway    ${bridge_name}    ${gw_name}    ${intf_name_1}    ${intf_name_2}
    ${output}=    OpenStackOperations.Get All L2Gateway
    Log    ${output}
    Should Contain    ${output}    ${gw_name}
    Should Contain    ${output}    ${intf_name_1}
    Should Contain    ${output}    ${intf_name_2}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session
    [Return]    ${l2gw_output}

Delete L2Gateway
    [Arguments]    ${gw_name}
    [Documentation]    Keyword to delete the L2 Gateway ${gw_name} received in argument.
    ${output}=    Openstack CLI    ${L2GW_DELETE} ${gw_name}
    @{list_to_check}=    Create List    ${gw_name}
    Utils.Check For Elements Not At URI    ${L2GW_LIST_REST_URL}    ${list_to_check}    session

Create Verify L2Gateway Connection
    [Arguments]    ${gw_name}    ${net_name}    ${additional_args}=${EMPTY}
    [Documentation]    Keyword to create a new L2 Gateway Connection for ${gw_name} to ${net_name} (Using Neutron CLI).
    OpenStackOperations.Create L2Gateway Connection    ${gw_name}    ${net_name}    ${additional_args}
    ${l2gw_id}=    OpenStackOperations.Get L2gw Id    ${gw_name}
    ${output}=    OpenStackOperations.Get All L2Gateway Connection
    Log    ${output}
    Should Contain    ${output}    ${l2gw_id}
    @{list_to_check}=    Create List    ${l2gw_id}
    Utils.Check For Elements At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session

Verify L2Gateway Connection
    [Arguments]    ${gw_name}    ${net_name}
    [Documentation]    Keyword to verify existing L2 Gateway Connection for ${gw_name} to ${net_name} $(Using Neutron CLI).
    ${l2gw_id}=    OpenStackOperations.Get L2gw Id    ${gw_name}
    ${output}=    OpenStackOperations.Get All L2Gateway Connection
    Log    ${output}
    Should Contain    ${output}    ${l2gw_id}
    @{list_to_check}=    Create List    ${l2gw_id}
    Utils.Check For Elements At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session

Delete L2Gateway Connection
    [Arguments]    ${gw_name}
    [Documentation]    Delete the L2 Gateway connection existing for Gateway ${gw_name} received in argument (Using Neutron CLI).
    ${l2gw_conn_id}=    OpenStackOperations.Get L2gw Connection Id    ${gw_name}
    ${output}=    Openstack CLI    ${L2GW_CONN_DELETE} ${l2gw_conn_id}
    @{list_to_check}=    Create List    ${l2gw_conn_id}
    Utils.Check For Elements Not At URI    ${L2GW_CONN_LIST_REST_URL}    ${list_to_check}    session
    Log    ${output}

Update Port For Hwvtep
    [Arguments]    ${port_name}
    [Documentation]    Keyword to update the Neutron Ports for specific configuration required to connect to HWVTEP (Using REST).
    ${port_id}=    Get Port Id    ${port_name}
    Log    ${port_id}
    ${json_data}=    Get Neutron Port Rest    ${port_id}
    Should Contain    ${json_data}    ${STR_VIF_TYPE}
    ${json_data}=    Replace String    ${json_data}    ${STR_VIF_TYPE}    ${STR_VIF_REPLACE}
    ${return}=    OpenStackOperations.Update Port Rest    ${port_id}    ${json_data}
    ${output}=    OpenStackOperations.Get Neutron Port Rest    ${port_id}
    Log    ${output}
    Should Contain    ${output}    ${STR_VIF_REPLACE}
    Should Not Contain    ${output}    ${STR_VIF_TYPE}
    [Return]    ${return}

Attach Port To Hwvtep Namespace
    [Arguments]    ${port_mac}    ${ns_name}    ${tap_name}    ${conn_id}    ${ip}=${EMPTY}    ${vlan_id}=${EMPTY}
    [Documentation]    Configuring mac and ip address to the port attached to hwvtep node for based on use case.
    ...
    ...    1. If the port is emulating baremetal server connection, configure static mac and ip address.
    ...
    ...    2. If the port is emulating neutron direct type port used for SR-IOV VMs, configure the neutron port mac address and use dhclient to get dynamic ip from opendaylight controller.
    ${cmd}=    Set Variable If    '${ip}' != '${EMPTY}'    ${NETNS_EXEC} ${ns_name} ${IFCONF} ${tap_name} ${ip}/24 ${HW_ETHER} ${port_mac}    ${NETNS_EXEC} ${ns_name} ${IFCONF} ${tap_name} ${HW_ETHER} ${port_mac}
    Exec Command    ${conn_id}    ${cmd}
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Should Contain    ${output}    ${port_mac}
    Run Keyword If    '${vlan_id}'!='${EMPTY}'    Attach Vlan To Namespace    ${ns_name}    ${tap_name}    ${vlan_id}    ${conn_id}

Namespace Dhclient Verify
    [Arguments]    ${ns_name}    ${ns_tap}    ${ns_port_ip}    ${conn_id}=${hwvtep_conn_id}    ${hwvtep_ip}=${HWVTEP_IP}
    [Documentation]    Keyword to run dhclient for the tap port ${ns_tap} and verify if it has got assigned with ${ns_port_ip}.
    Start Command In Hwvtep    ${NETNS_EXEC} ${ns_name} dhclient ${ns_tap}    ${hwvtep_ip}
    Wait Until Keyword Succeeds    60s    2s    Verify Strings In Command Output    ${conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}    ${ns_port_ip}

Verify Strings In Command Output
    [Arguments]    ${conn_id}    ${command}    @{string_list}
    [Documentation]    Keyword to run the ${command} in ${conn_id} and verify if the output contains the list @{string_list}.
    ${output}=    Exec Command    ${conn_id}    ${command}
    : FOR    ${item}    IN    @{string_list}
    \    Should Contain    ${output}    ${item}

Verify Ping In Namespace Extra Timeout
    [Arguments]    ${ns_name}    ${ns_port_mac}    ${vm_ip}    ${conn_id}=${hwvtep_conn_id}
    [Documentation]    Keyword to ping the IP ${vm_ip} from ${ns_name} and verify MCAS Local Table contains ${ns_port_mac}.
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ${IFCONF}
    Log    ${output}
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ping -c3 ${vm_ip}    30s
    Log    ${output}
    Verify Ping Is Successful    ${output}
    Wait Until Keyword Succeeds    30s    2s    L2GatewayOperations.Verify Macs Local Table While Ping    ${ns_port_mac}    ${conn_id}

Verify Ping Fails In Namespace
    [Arguments]    ${ns_name}    ${ns_port_mac}    ${vm_ip}    ${conn_id}=${hwvtep_conn_id}    ${hwvtep_ip}=${HWVTEP_IP}
    [Documentation]    Keyword to ping the IP ${vm_ip} from ${ns_name} and should verify that it fails
    ${output}=    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ping -c3 ${vm_ip}    30s
    Log    ${output}
    Verify If Ping Failed    ${output}

Verify Macs Local Table While Ping
    [Arguments]    ${mac}    ${conn_id}
    [Documentation]    Keyword to check if ${mac} is available under UCAST_MACS_LOCALE_TABLE of HWVTEP dump table.
    ${mac_list}=    Create List    ${mac}
    Verify Vtep List    ${conn_id}    ${UCAST_MACS_LOCALE_TABLE}    ${mac_list}

Verify Nova VM IP
    [Arguments]    ${port_ips}    @{vm_names}
    [Documentation]    Keyword to verify if the VM has received IP, and to verify it is not null.
    @{vm_ips}    ${dhcp_ip} =    Get VM IPs    @{vm_names}
    Should Not Contain    ${vm_ips}    None
    Should Not Contain    ${dhcp_ip}    None
    : FOR    ${vm_ip}    IN    @{vm_ips}
    \    Log    ${vm_ip}
    \    ${vm_ip_string}=    Encode String To Bytes    ${vm_ip}    UTF-8
    \    List Should Contain Value    ${port_ips}    ${vm_ip_string}

Get L2gw Debug Info
    [Arguments]    ${index}=1
    [Documentation]    Keyword to collect the general debug information required for HWVTEP Test Suite.
    Exec Command    ${hwvtep_conn_id}    ${OVSDB_CLIENT_DUMP}
    Run Keyword If    ${index}==2    Exec Command    ${hwvtep2_conn_id}    ${OVSDB_CLIENT_DUMP}
    OpenStackOperations.Get Test Teardown Debugs
    Run Keyword And Ignore Error    Get Model Dump    ${HA_PROXY_IP}    ${l2gw_data_models}

Start Command In Hwvtep
    [Arguments]    ${command}    ${hwvtep_ip}
    [Documentation]    Keyword to execute Start Command in HWVTEP IP.
    ${conn_id}=    SSHLibrary.Open Connection    ${hwvtep_ip}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=30s
    Log    ${conn_id}
    Flexible SSH Login    ${DEFAULT_USER}    ${DEFAULT_PASSWORD}
    Start Command    ${command}
    Close Connection

Verify Vtep List
    [Arguments]    ${conn_id}    ${table_name}    ${list}
    [Documentation]    Keyword to run vtep-ctl list for the table ${table_name} and verify the list @{list} contents exists in output.
    ${output}=    Exec Command    ${conn_id}    ${VTEP LIST} ${table_name}
    : FOR    ${item}    IN    @{list}
    \    Should Contain    ${output}    ${item}

Get Vtep List
    [Arguments]    ${table_name}    ${conn_id}=${hwvtep_conn_id}
    [Documentation]    Keyword to return the contents of vtep-ctl list for table ${table_name}.
    ${output}=    Exec Command    ${conn_id}    ${VTEP LIST} ${table_name}
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
    [Arguments]    ${hwvtep_ip}    ${ovs_ip}    ${seg_id}=${NET_1_SEGID}    ${conn_id}=${hwvtep_conn_id}    ${conn_ovs_id}=${OS_CMP1_CONN_ID}
    [Documentation]    Keyword to verify that the OVS tunnel entries are configured for OVS and HWVTEP.
    ${output}=    Exec Command    ${conn_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key="${seg_id}", remote_ip="${ovs_ip}"
    ${output}=    Exec Command    ${conn_ovs_id}    ${OVS_SHOW}
    Log    ${output}
    Should Contain    ${output}    key=flow, local_ip="${ovs_ip}", remote_ip="${hwvtep_ip}"

Get Vtep Field Values From Table
    [Arguments]    ${table_name}    ${column_name}    ${conn_id}=${hwvtep_conn_id}
    [Documentation]    Keyword to return specific field value received in ${column_name} from the vtep-ctl list for ${table_name}.
    ${output}=    Exec Command    ${conn_id}    ${VTEP_LIST_COLUMN}${column_name} list ${table_name} | awk '{print $3}'
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
    Set Default Configuration    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    ${output}=    DevstackUtils.Write Commands Until Prompt    ${command}    ${timeout}
    Log    ${output}
    [Return]    ${output}

Verify Elan Flow Entries
    [Arguments]    ${ip}    ${srcMacAddrs}    ${destMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN service
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=50
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=50
    Log    ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    dl_src=${sMacAddr}
    Should Contain    ${flow_output}    table=51
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=51
    Log    ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{destMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    dl_dst=${dMacAddr}
    Should Contain    ${flow_output}    table=52
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=52
    Log    ${sMac_output}

Cleanup L2GW Optional Resources
    [Documentation]    Cleanup resources that are only allocated on certain combos...
    BuiltIn.Pass_Execution_If    "skip_if_${OPENSTACK_BRANCH}" in @{TEST_TAGS}    Not supported in Ocata/Pike
    CompareStream.Run_Keyword_If_At_Most_Nitrogen    BuiltIn.Pass_Execution    Only run on oxygen and later
    OpenStackOperations.Delete Port    ${HWVTEP_PORT_3}

Verify Flow And Group Entries
    [Arguments]    ${conn_id}    ${destMacAddrs}    ${NET_SEGID}    ${flag}    ${N_Nodes}=1
    [Documentation]    Verifies mac addresses in destination mac table flow rules
    ...    and vxlan ids in group entries.
    ${table_id}=    Set Variable    ${DEST_MAC_TABLE}
    Wait Until Keyword Succeeds    30s    2s    Verify Entries In Flow Table    ${conn_id}    ${table_id}    ${flag}
    ...    ${destMacAddrs}
    Wait Until Keyword Succeeds    30s    2s    Verify BC Group Entries For Hwvtep    ${conn_id}    ${flag}    ${NET_SEGID}
    ...    ${N_Nodes}

Verify Ping Is Successful
    [Arguments]    ${output}
    [Documentation]    Validation of ping output .
    ${PACKET LOSS}=    Get Regexp Matches    ${output}    ${PING_REGEXP}
    ${data}=    Convert to String    ${PACKET LOSS}
    Should Contain    ${data}    0% packet loss

Verify If Ping Failed
    [Arguments]    ${output}
    [Documentation]    Validate ping failure with more checks.
    Should Contain Any    ${output}    100% packet loss    Network is unreachable

Verify Entries in Hwvtep DB Dump
    [Arguments]    ${hwvtep_conn_id}    ${LS_name}    ${bridge_name}    ${vlan}    ${mac_list}    ${port_list}
    [Documentation]    Opendaylight controller configures entries in hwvtep database on l2gateway connection creation.
    ...
    ...    This keyword validates these entries.
    Wait Until Keyword Succeeds    30s    5s    Verify Logical Switch In Hwvtep DB    ${hwvtep_conn_id}    ${LS_name}
    Wait Until Keyword Succeeds    15s    5s    Verify Remote Macs In Hwvtep DB    ${hwvtep_conn_id}    ${LS_name}    ${mac_list}
    : FOR    ${port}    IN    @{port_list}
    \    Verify Vlan Bindings In Hwvtep DB    ${hwvtep_conn_id}    ${bridge_name}    ${port}    ${vlan}

Verify Entries Not in Hwvtep DB Dump
    [Arguments]    ${hwvtep_conn_id}    ${LS_name}    ${bridge_name}    ${vlan}    ${mac_list}    ${port_list}
    [Documentation]    Keyword to validate if the hwvtep database has no entries relevant to the l2gateway connection configuration
    Wait Until Keyword Succeeds    2 min    20s    Verify Logical Switch Not In Hwvtep DB    ${hwvtep_conn_id}    ${LS_name}
    Wait Until Keyword Succeeds    15s    5s    Verify Remote Macs Not In Hwvtep DB    ${hwvtep_conn_id}    ${LS_name}    ${mac_list}
    : FOR    ${port}    IN    @{port_list}
    \    Verify Vlan Bindings Not in Hwvtep DB    ${hwvtep_conn_id}    ${bridge_name}    ${port}    ${vlan}

Verify Logical Switch In Hwvtep DB
    [Arguments]    ${hwvtep_conn_id}    ${LS_name}
    [Documentation]    Keywords checks the hwvtep database if the logical switch entry for a given openstack network is present
    ${entry_list}=    Create List    ${LS_name}    source_node
    Verify Vtep List    ${hwvtep_conn_id}    Logical_Switch    ${entry_list}

Verify Logical Switch Not In Hwvtep DB
    [Arguments]    ${hwvtep_conn_id}    ${LS_name}
    [Documentation]    Keywords checks the hwvtep database if the logical switch entry for the given openstack network is removed
    ${LS_output}=    Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl list-ls
    Should Not Contain    ${LS_output}    ${LS_name}

Verify Vlan Bindings in Hwvtep DB
    [Arguments]    ${hwvtep_conn_id}    ${bridge_name}    ${port_name}    ${vlan}
    [Documentation]    Keywords checks the hwvtep database if the vlan binding for the given port is present
    ${bindings_output}=    Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl list-bindings ${bridge_name} ${port_name}
    @{bindings_list}=    Split String    ${bindings_output}    ${SPACE}    1
    Should Contain    ${bindings_list[0]}    ${vlan}

Verify Vlan Bindings Not in Hwvtep DB
    [Arguments]    ${hwvtep_conn_id}    ${bridge_name}    ${port_name}    ${vlan}
    [Documentation]    Keywords checks the hwvtep database if the vlan binding for the given port is removed
    ${bindings_output}=    Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl list-bindings ${bridge_name} ${port_name}
    @{bindings_list}=    Split String    ${bindings_output}    ${SPACE}    1
    Should Not Contain    ${bindings_list[0]}    ${vlan}

Verify Remote Macs in Hwvtep DB
    [Arguments]    ${hwvtep_conn_id}    ${LS_name}    ${mac_list}
    [Documentation]    Keyword checks \ if the if the given mac entries are present in ucast_mac_remote table in hwvtep database.
    ${remote_macs_output}=    Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl list-remote-macs ${LS_name}
    Log    ${remote_macs_output}
    : FOR    ${mac}    IN    @{mac_list}
    \    Should Contain    ${remote_macs_output}    ${mac}

Verify Remote Macs Not in Hwvtep DB
    [Arguments]    ${hwvtep_conn_id}    ${LS_name}    ${mac_list}
    [Documentation]    Keyword checks \ if the given mac entries are removed in ucast_mac_remote table in hwvtep database.
    ${remote_macs_output}=    Exec Command    ${hwvtep_conn_id}    sudo vtep-ctl list-remote-macs ${LS_name}
    Log    ${remote_macs_output}
    : FOR    ${mac}    IN    @{mac_list}
    \    Should Not Contain    ${remote_macs_output}    ${mac}

Attach Vlan To Namespace
    [Arguments]    ${ns_name}    ${tap_name}    ${vlan_id}    ${conn_id}
    [Documentation]    Configure vlan to the link in namespace
    Switch Connection    ${conn_id}
    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ip link add link ${tap_name} name ${tap_name}.${vlan_id} type vlan id ${vlan_id}
    Exec Command    ${conn_id}    ${NETNS_EXEC} ${ns_name} ip link set ${tap_name}.${vlan_id} up

Verify Entries In Flow Table
    [Arguments]    ${conn_id}    ${table_id}    ${flag}    ${item_list}
    [Documentation]    Keywork verifies entries in flow rules of a table
    ${flow_output} =    Exec Command    ${conn_id}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep table=${table_id}
    Should Contain    ${flow_output}    table=${table_id}
    : FOR    ${item}    IN    @{item_list}
    \    Run Keyword If    '${flag}'=='True'    Should Contain    ${flow_output}    ${item}
    \    ...    ELSE IF    '${flag}'=='False'    Should Not Contain    ${flow_output}    ${item}

Verify BC Group Entries For Hwvtep
    [Arguments]    ${conn_id}    ${flag}    ${VXLAN_SEG_ID}    ${N_Nodes}
    [Documentation]    Keyword verifies the group entries if broadcast path exists from the compute nodes towards the hwvtep nodes.
    ${groups_output} =    Exec Command    ${conn_id}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    ${tunnel_id}=    Convert To Hex    ${VXLAN_SEG_ID}    prefix=0x
    Should Contain X Times    ${groups_output}    ${tunnel_id}    ${N_Nodes}

Set Log Level For L2gw
    [Arguments]    ${error_level}
    [Documentation]    This keyword sets the log level for L2gw.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${error_level} org.opendaylight.netvirt.elan.l2gw
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${error_level} org.opendaylight.ovsdb.hwvtepsouthbound
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${error_level} org.opendaylight.genius.itm
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${error_level} org.opendaylight.genius.interfacemanager
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${error_level} org.opendaylight.netvirt.dhcpservice

Enable Controller Dhcp
    [Documentation]    Sets the flag controlled enabled dhcp as true
    ${body}=    OperatingSystem.Get File    ${L2GW_VAR_BASE}/dhcp_config.json
    RequestsLibrary.Create Session    session    http://${odl_ip}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/    data=${body}
    Run Keyword If    '${resp.status_code}'=='409'    RequestsLibrary.Put Request    session    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/    data=${body}
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/dhcpservice-config:dhcpservice-config/
    Should Contain    ${resp.content}    true
    ClusterManagement.Stop_Members_From_List_Or_All
    ClusterManagement.Start_Members_From_List_Or_All
    Wait Until Keyword Succeeds    30s    2s    Check Service Status    ACTIVE    OPERATIONAL

Get Environment Config
    [Documentation]    Get the relevant l2gw configurations neutron files
    Run Keyword If    0 < ${NUM_OS_SYSTEM}    Open Connection    OS_CNTL_CONN_ID    ${OS_CONTROL_NODE_IP}
    Exec Command    ${OS_CNTL_CONN_ID}    cat /etc/neutron/neutron.conf
    Exec Command    ${OS_CNTL_CONN_ID}    cat /etc/neutron/l2gw_plugin.ini
    Exec Command    ${OS_CNTL_CONN_ID}    ps -ef | grep neutron-server
