*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           SSHLibrary
Resource          CompareStream.robot
Resource          Utils.robot
Resource          TemplatedRequests.robot
Resource          KarafKeywords.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Library           Collections
Library           String
Library           OperatingSystem

*** Variables ***
&{ITM_CREATE_DEFAULT}    tunneltype=vxlan    vlanid=0    prefix=1.1.1.1/24    gateway=0.0.0.0    dpnid1=1    portname1=BR1-eth1    ipaddress1=2.2.2.2
...               dpnid2=2    portname2= BR2-eth1    ipaddress2=3.3.3.3
&{L3VPN_CREATE_DEFAULT}    vpnid=4ae8cd92-48ca-49b5-94e1-b2921a261111    name=vpn1    rd=["2200:1"]    exportrt=["2200:1","8800:1"]    importrt=["2200:1","8800:1"]    tenantid=6c53df3a-3456-11e5-a151-feff819cdc9f
${VAR_BASE}       ${CURDIR}/../variables/vpnservice/
${ODL_FLOWTABLE_L3VPN}    21
${STATE_UP}       UP
${STATE_DOWN}     DOWN
${STATE_UNKNOWN}    UNKNOWN
${STATE_ENABLE}    ENABLED
${STATE_DISABLE}    DISABLE
${SESSION_TIMEOUT}    10

*** Keywords ***
Basic Suite Setup
    OpenStackOperations.OpenStack Suite Setup
    TemplatedRequests.Create Default Session    timeout=${SESSION_TIMEOUT}

Basic Vpnservice Suite Cleanup
    [Arguments]    ${vpn_instance_ids}=@{EMPTY}    ${vms}=@{EMPTY}    ${networks}=@{EMPTY}    ${subnets}=@{EMPTY}    ${ports}=@{EMPTY}    ${sgs}=@{EMPTY}
    FOR    ${vpn_instance_id}    IN    @{vpn_instance_ids}
        BuiltIn.Run Keyword And Ignore Error    VPN Delete L3VPN    vpnid=${vpn_instance_id}
    END
    OpenStackOperations.Neutron Cleanup    ${vms}    ${networks}    ${subnets}    ${ports}    ${sgs}

VPN Create L3VPN
    [Arguments]    &{Kwargs}
    [Documentation]    Create an L3VPN using the Json using the list of optional arguments received.
    Run keyword if    "routerid" in ${Kwargs}    Collections.Set_To_Dictionary    ${Kwargs}    router=, "router-id":"${Kwargs['routerid']}"
    ...    ELSE    Collections.Set_To_Dictionary    ${Kwargs}    router=${empty}
    &{L3vpn_create_actual_val} =    Collections.Copy_Dictionary    ${L3VPN_CREATE_DEFAULT}
    Collections.Set_To_Dictionary    ${L3vpn_create_actual_val}    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/l3vpn_create    mapping=${L3vpn_create_actual_val}    session=default    http_timeout=${SESSION_TIMEOUT}

VPN Get L3VPN
    [Arguments]    &{Kwargs}
    [Documentation]    Will return detailed list of the L3VPN_ID received
    ${resp} =    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/get_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}
    Log    ${resp}
    [Return]    ${resp}

VPN Get L3VPN ID
    [Arguments]    ${vrf_id}
    [Documentation]    Check that sub interface ip has been learnt after ARP request
    ${resp} =    RequestsLibrary.GET On Session    session    ${VPN_REST}
    BuiltIn.Log    ${resp.text}
    @{list_any_matches} =    String.Get_Regexp_Matches    ${resp.text}    \"vpn-instance-name\":\"${VPN_INSTANCE_ID}\",.*"vrf-id":"${vrf_id}",\"vpn-id\":(\\d+)    1
    ${result} =    Evaluate    ${list_any_matches[0]} * 2
    ${vpn_id_hex} =    BuiltIn.Convert To Hex    ${result}
    [Return]    ${vpn_id_hex.lower()}

Verify L3VPN On ODL
    [Arguments]    @{vpns}
    [Documentation]    To verify L3VPN on ODL for given vpn ids
    FOR    ${vpn}    IN    @{vpns}
        ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${vpn}
        BuiltIn.Should Contain    ${resp}    ${vpn}
    END

Associate L3VPN To Network
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a network-id received as dictionary argument
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/assoc_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}

Associate L3VPNs To Networks
    [Arguments]    ${vpnid_list}    ${network_list}
    [Documentation]    Associates multiple networks to L3VPN and verify the same
    FOR    ${network}    ${vpnid}    IN ZIP    ${network_list}    ${vpnid_list}
        ${network_id} =    OpenStackOperations.Get Net Id    ${network}
        VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=${vpnid}
        ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${vpnid}
        BuiltIn.Should Contain    ${resp}    ${network_id}
    END

Dissociate L3VPN From Networks
    [Arguments]    &{Kwargs}
    [Documentation]    Disssociate the already associated networks from L3VPN
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/dissoc_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}

Associate VPN to Router
    [Arguments]    &{Kwargs}
    [Documentation]    Associate the created L3VPN to a router-id received as argument
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/assoc_two_router_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}
    CompareStream.Run_Keyword_If_At_Most_Oxygen    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/assoc_router_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}

Dissociate VPN to Router
    [Arguments]    &{Kwargs}
    [Documentation]    Dissociate the already associated routers from L3VPN
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/dissoc_two_router_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}
    CompareStream.Run_Keyword_If_At_Most_Oxygen    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/dissoc_router_l3vpn    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}

VPN Delete L3VPN
    [Arguments]    &{Kwargs}
    [Documentation]    Delete the created L3VPN
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/l3vpn_delete    mapping=${Kwargs}    session=default    http_timeout=${SESSION_TIMEOUT}

ITM Create Tunnel
    [Arguments]    &{Kwargs}
    [Documentation]    Creates Tunnel between the two DPNs received in the dictionary argument
    &{Itm_actual_val} =    Collections.Copy_Dictionary    ${ITM_CREATE_DEFAULT}
    Collections.Set_To_Dictionary    ${Itm_actual_val}    &{Kwargs}
    TemplatedRequests.Post_As_Json_Templated    folder=${VAR_BASE}/itm_create    mapping=${Itm_actual_val}    session=default    http_timeout=${SESSION_TIMEOUT}

ITM Get Tunnels
    [Documentation]    Get all Tunnels and return the contents
    ${resp} =    RequestsLibrary.GET On Session    session    ${CONFIG_API}/itm:transport-zones/
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.text}

ITM Delete Tunnel
    [Arguments]    ${zone-name}
    [Documentation]    Delete Tunnels created under the transport-zone
    ${resp} =    RequestsLibrary.DELETE On Session    session    ${CONFIG_API}/itm:transport-zones/transport-zone/${zone-name}/
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    [Return]    ${resp.text}

Verify Flows Are Present For L3VPN
    [Arguments]    ${ip}    ${vm_ips}
    [Documentation]    Verify Flows Are Present For L3VPN
    ${flow_output}=    Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
    Should Contain    ${flow_output}    table=${ODL_FLOWTABLE_L3VPN}
    ${l3vpn_table} =    Get Lines Containing String    ${flow_output}    table=${ODL_FLOWTABLE_L3VPN},
    Log    ${l3vpn_table}
    FOR    ${i}    IN    @{vm_ips}
        ${resp}=    Should Contain    ${l3vpn_table}    ${i}
    END

Verify Flows Are Present For L3VPN On All Compute Nodes
    [Arguments]    ${vm_ips}
    [Documentation]    Verify Flows Are Present For L3VPN On All Compute Nodes
    FOR    ${ip}    IN    @{OS_CMP_IPS}
        BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${ip}    ${vm_ips}
    END

Verify GWMAC Entry On ODL
    [Arguments]    ${GWMAC_ADDRS}
    [Documentation]    get ODL GWMAC table entry
    ${resp} =    RequestsLibrary.GET On Session    session    ${VPN_PORT_DATA_URL}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
        Should Contain    ${resp.text}    ${macAdd}
    END

Verify GWMAC Flow Entry Removed From Flow Table
    [Arguments]    ${cnIp}
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output}=    Run Command On Remote System And Log    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    Log    ${gwmac_table}
    #Verify GWMAC address present in table 19
    FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
        Should Not Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
    END

Verify GWMAC Flow Entry Removed From Flow Table On All Compute Nodes
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    FOR    ${ip}    IN    @{OS_CMP_IPS}
        BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry Removed From Flow Table    ${ip}
    END

Verify ARP REQUEST in groupTable
    [Arguments]    ${group_output}    ${Group-ID}
    [Documentation]    get flow dump for group ID
    Should Contain    ${group_output}    group_id=${Group-ID}
    ${arp_group} =    Get Lines Containing String    ${group_output}    group_id=${Group-ID}
    Log    ${arp_group}
    CompareStream.Run_Keyword_If_At_Most_Oxygen    BuiltIn.Should Match Regexp    ${arp_group}    ${ARP_REQUEST_GROUP_REGEX}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    BuiltIn.Should Match Regexp    ${arp_group}    ${ARP_REQUEST_GROUP_REGEX_FLUORINE}

Verify Tunnel Status as UP
    [Documentation]    Verify that the tunnels are UP
    BuiltIn.Return From Keyword If    ${OS_NODE_CNT} == ${1}    ${True}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}
    Should Not Contain    ${output}    ${STATE_UNKNOWN}

Verify Tunnel Status as DOWN
    [Documentation]    Verify that the tunnels are DOWN
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_DOWN}
    Should Not Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_UNKNOWN}

Verify Tunnel Status as UNKNOWN
    [Documentation]    Verify that the tunnels are in Unknown state
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Not Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}
    Should Contain    ${output}    ${STATE_UNKNOWN}

Verify VXLAN interface
    [Documentation]    Verify that the VXLAN interfaces are Enabled
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Contain    ${output}    ${STATE_ENABLE}
    Should Not Contain    ${output}    ${STATE_DISABLE}

Get Fib Entries
    [Arguments]    ${session}
    [Documentation]    Get Fib table entries from ODL session
    ${resp}    RequestsLibrary.GET On Session    ${session}    ${FIB_ENTRIES_URL}
    Log    ${resp.text}
    [Return]    ${resp.text}

Get Gateway MAC And IP Address
    [Arguments]    ${router_Name}    ${ip_regex}=${IP_REGEX}
    [Documentation]    Get Gateway mac and IP Address
    ${output} =    OpenStack CLI    openstack port list --router ${router_Name}
    @{MacAddr-list} =    Get Regexp Matches    ${output}    ${MAC_REGEX}
    @{IpAddr-list} =    Get Regexp Matches    ${output}    ${ip_regex}
    [Return]    ${MacAddr-list}    ${IpAddr-list}

Test Teardown With Tcpdump Stop
    [Arguments]    ${conn_ids}=@{EMPTY}
    OpenStackOperations.Stop Packet Capture On Nodes    ${conn_ids}
    Get Test Teardown Debugs

Verify IPv4 GWMAC Flow Entry On Flow Table
    [Arguments]    ${group_output}    ${group_id}    ${flow_output}
    Verify ARP REQUEST in groupTable    ${group_output}    ${groupID[1]}
    #Verify ARP_RESPONSE_TABLE - 81
    Should Contain    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    ${arpResponder_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    Should Contain    ${arpResponder_table}    priority=0 actions=drop
    FOR    ${macAdd}    ${ipAdd}    IN ZIP    ${GWMAC_ADDRS}    ${GWIP_ADDRS}
        ${ARP_RESPONSE_IP_MAC_REGEX} =    Set Variable    arp_tpa=${ipAdd},arp_op=1 actions=.*,set_field:${macAdd}->eth_src
        Should Match Regexp    ${arpResponder_table}    ${ARP_RESPONSE_IP_MAC_REGEX}
    END

Verify IPv6 GWMAC Flow Entry On Flow Table
    [Arguments]    ${flow_output}
    Should Contain    ${flow_output}    table=${IPV6_TABLE}
    ${icmp_ipv6_flows} =    Get Lines Containing String    ${flow_output}    icmp_type=135
    FOR    ${ip_addr}    IN    @{GWIP_ADDRS}
        ${rule} =    Set Variable    icmp_type=135,icmp_code=0,nd_target=${ip_addr} actions=CONTROLLER:65535
        Should Match Regexp    ${icmp_ipv6_flows}    ${rule}
    END

Verify GWMAC Flow Entry On Flow Table
    [Arguments]    ${cnIp}    ${ipv}=ipv4
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows ${INTEGRATION_BRIDGE}
    ${group_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-groups ${INTEGRATION_BRIDGE}
    Should Contain    ${flow_output}    table=${DISPATCHER_TABLE}
    ${dispatcher_table} =    Get Lines Containing String    ${flow_output}    table=${DISPATCHER_TABLE}
    Should Contain    ${dispatcher_table}    goto_table:${GWMAC_TABLE}
    Should Not Contain    ${dispatcher_table}    goto_table:${ARP_RESPONSE_TABLE}
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    #Verify GWMAC address present in table 19
    FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
        Should Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
        #verify Miss entry
    END
    Should Contain    ${gwmac_table}    actions=resubmit(,17)
    #Verify ARP_CHECK_TABLE - 43
    #arp request and response
    ${arpchk_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_CHECK_TABLE}
    CompareStream.Run_Keyword_If_At_Most_Oxygen    BuiltIn.Should Match Regexp    ${arpchk_table}    ${ARP_RESPONSE_REGEX}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    BuiltIn.Should Match Regexp    ${arpchk_table}    ${ARP_RESPONSE_REGEX_FLUORINE}
    ${arppunt_table} =    String.Get Lines Containing String    ${flow_output}    table=${ARP_PUNT_TABLE}
    CompareStream.Run_Keyword_If_At_Least_Fluorine    BuiltIn.Should Match Regexp    ${arppunt_table}    ${ARP_PUNT_RESPONSE_REGEX}
    ${match} =    Should Match Regexp    ${arpchk_table}    ${ARP_REQUEST_REGEX}
    ${groupID} =    Split String    ${match}    separator=:
    BuiltIn.Run Keyword If    '${ipv}' == 'ipv4'    Verify IPv4 GWMAC Flow Entry On Flow Table    ${group_output}    ${group_id}    ${flow_output}
    ...    ELSE    Verify IPv6 GWMAC Flow Entry On Flow Table    ${flow_output}

Verify GWMAC Flow Entry On Flow Table On All Compute Nodes
    [Arguments]    ${ipv}=ipv4
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    FOR    ${ip}    IN    @{OS_CMP_IPS}
        BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${ip}    ${ipv}
    END

Delete Multiple L3VPNs
    [Arguments]    @{vpns}
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    FOR    ${vpn}    IN    @{vpns}
        VPN Delete L3VPN    vpnid=${vpn}
    END

VNI Test Setup
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing

VNI Test Teardown
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    OpenStackOperations.Get Test Teardown Debugs
