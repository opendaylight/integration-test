*** Settings ***
Documentation     This test suite is to verify working of OF based Tunnels
Suite Setup       OF Tunnels Start Suite
Suite Teardown    OF Tunnels Stop Suite
Test Setup        Genius Test Setup
Test Teardown     Genius Test Teardown    ${data_models}
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../libraries/ClusterManagement.robot
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Genius.robot
Resource          ../../libraries/KarafKeywords.robot
Resource          ../../libraries/ODLTools.robot
Resource          ../../libraries/OVSDB.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/VpnOperations.robot
Resource          ../../variables/Variables.robot
Resource          ../../variables/netvirt/Variables.robot
Variables         ../../variables/genius/Modules.py

*** Variables ***
${OFT_OVSIF_REGEX}    SEPARATOR=    Interface\\s\\"(tun\\w+)\\"\\r?\\n    \\s+type\\:\\s(\\w+)\\r?\\n    \\s+options\\:\\s\\{key\\=flow\\,\\slocal_ip\\=\\"(${REGEX_IPV4})\\"\\,\\sremote_ip\\=flow\\}
${OFT_TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan

*** Test Cases ***
Create and Verify TZ with OFT TEPs
    [Documentation]    Creates a TZ with TEPs set to use OF based Tunnels and verify.
    OFT Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify TZ with OFT TEPs
    [Documentation]    Deletes a TZ with TEPs set to use OF based Tunnels and verify.
    ${tools_ip_tunnels_map} =    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    OFT Delete Vteps    ${DPN_ID_LIST}
    OFT Verify Vteps Deleted    ${ovs_tunnel_list}    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Create and Verify TZ with single OFT TEPs
    [Documentation]    Creates a TZ with single TEPs set to use OF based Tunnels and verify.
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    -1
    OFT Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${tools_ips}
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}
    Collections.Remove From List    ${dpn_ids}    -1
    OFT Verify Vteps Created    ${dpn_ids}    ${tools_ips}
    OFT Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify TZ with single OFT TEPs
    [Documentation]    Delete a TZ with single TEPs set to use OF based Tunnels and verify.
    ${tools_ip_tunnels_map} =    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${deleted_dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    OFT Delete Vteps    ${deleted_dpn_ids}
    ${deleted_tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    ${deleted_tools_ip_tunnels_map} =    BuiltIn.Create Dictionary    @{TOOLS_SYSTEM_ALL_IPS}[0]=${tools_ip_tunnels_map["@{TOOLS_SYSTEM_ALL_IPS}[0]"]}
    OFT Verify Vteps Deleted    ${deleted_tools_ip_tunnels_map}    ${deleted_dpn_ids}    ${deleted_tools_ips}

Verify Tunnels with BFD Enabled and Interface Down
    [Documentation]    Verify BFD monitoring can be enabled for OF tunnels.
    OFT Create Vteps    ${NO_VLAN}    ${gateway_ip}    ${TOOLS_SYSTEM_ALL_IPS}
    ${tools_ip_tunnels_map} =    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor true
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Stop OVS    ${tools_ip}
    ${result} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    Should Not Contain    ${result}    UP

Verify Tunnels with BFD Enabled and Interface Up
    [Documentation]    Verify BFD monitoring can be enabled for OF tunnels.
    ${tools_ip_tunnels_map} =    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor true
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Start OVS    ${tools_ip}
    Genius.Verify Tunnel Status As Up

Verify Reference Count with BFD Disable RPC
    [Documentation]    Verify BFD monitoring can be enabled for OF tunnels.
    Comment    TODO

Delete VTEP with Non-Zero Reference Count and Verify
    [Documentation]    Verify BFD monitoring can be enabled for OF tunnels.
    Comment    TODO

Disable BFD Monitoring
    [Documentation]    Verify BFD monitoring can be disabled for OF tunnels
    ${tools_ip_tunnels_map} =    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    KarafKeywords.Issue_Command_On_Karaf_Console    tep:enable-tunnel-monitor false
    Comment    TODO

*** Keywords ***
OFT Create Vteps
    [Arguments]    ${vlan_id}    ${gateway_ip}    ${tools_ips}
    [Documentation]    Creates VTEPs for selected tools systems in ODL.
    ${body} =    OFT Set Json    ${vlan_id}    ${gateway_ip}    ${SUBNET}    @{tools_ips}
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm:transport-zones/transport-zone/@{itm_created}[0]    data=${body}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

OFT Set Json
    [Arguments]    ${vlan}    ${gateway_ip}    ${subnet}    ${dpn_ids}    ${tools_ips}
    [Documentation]    Sets JSON for TZ for selected tools systems.
    ${vteps_json} =    BuiltIn.Create List
    ${vteps_len} =    BuiltIn.Get Length    ${tools_ips}
    : FOR    ${num}    IN RANGE    @{vteps_len}
    \    ${vtep_json} =    BuiltIn.Create Dictionary
    \    ${dpn_id} =    BuiltIn.Evaluate    long(@{dpn_ids}[${num}])
    \    Collections.Set To Dictionary    ${vtep_json}    dpn-id=${dpn_id}
    \    Collections.Set To Dictionary    ${vtep_json}    ip-address=@{tools_ips}[${num}]
    \    Collections.Set To Dictionary    ${vtep_json}    portname=${port_name}
    \    Collections.Append To List    ${vteps_json}    ${vtep_json}
    ${subnets_json} =    BuiltIn.Create List
    ${subnet_json} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${subnet_json}    gateway-ip=${gateway_ip}
    Collections.Set To Dictionary    ${subnet_json}    prefix=${subnet}/16
    ${vlan} =    BuiltIn.Convert To Integer    ${vlan}
    Collections.Set To Dictionary    ${subnet_json}    vlan-id=${vlan}
    Collections.Set To Dictionary    ${subnet_json}    vteps=${vteps_json}
    Collections.Append To List    ${subnets_json}    ${subnet_json}
    ${transport_zones_json} =    BuiltIn.Create List
    ${transport_zone_json} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${transport_zone_json}    subnets=${subnets_json}
    Collections.Set To Dictionary    ${transport_zone_json}    tunnel-type=${OFT_TUNNEL_TYPE}
    Collections.Set To Dictionary    ${transport_zone_json}    zone-name=@{itm_created}[0]
    Collections.Append To List    ${transport_zones_json}    ${transport_zone_json}
    ${root_json} =    BuiltIn.Create Dictionary
    Collections.Set To Dictionary    ${root_json}    transport-zone=${transport_zones_json}
    ${result} =    BuiltIn.Evaluate    json.dumps(${root_json}, indent=4)    json
    BuiltIn.Log    ${result}
    [Return]    ${result}

OFT Verify Vteps Created
    [Arguments]    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    Wait Until Keyword Succeeds    60    5    OFT Verify TZ Created    ${NO_VLAN}    ${gateway_ip}    ${SUBNET}
    ...    ${dpn_ids}    ${tools_ips}
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Created at Tep Show    ${NO_VLAN}    ${gateway_ip}    ${SUBNET}
    ...    ${dpn_ids}    ${tools_ips}
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Created at Dpn Teps State    ${dpn_ids}
    Comment    TODO: Check itm-state:tunnel-state in ODL
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Created at Dpn Endpoints    ${dpn_ids}
    ${tools_ip_tunnels_map} =    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${tools_ips}
    ${num_switches} =    BuiltIn.Get Length    ${dpn_ids}
    Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${num_switches}
    ${port_list} =    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    Comment    TODO: Check parent-child interface mapping in ODL
    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Created    ${tools_ips}
    Comment    TODO: Check egress flows (table 95)

OFT Verify TZ Created
    [Arguments]    ${vlan}    ${gateway_ip}    ${subnet}    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if TZ is created for selected tools systems in ODL.
    ${switch_data} =    BuiltIn.Create List    ${gateway_ip}    @{dpn_ids}    @{tools_ips}
    Genius.Get ITM    @{itm_created}[0]    ${subnet}    ${vlan}    ${switch_data}

OFT Verify Vteps Created at Tep Show
    [Arguments]    ${vlan}    ${gateway_ip}    ${subnet}    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if vteps are created at tep:show for selected tools systems in ODL.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    @{itm_created}[0]
    BuiltIn.Should Contain    ${output}    ${vlan}
    BuiltIn.Should Contain    ${output}    ${gateway_ip}
    BuiltIn.Should Contain    ${output}    ${subnet}
    BuiltIn.Should Contain    ${output}    VXLAN
    BuiltIn.Should Contain    ${output}    ${port_name}
    ${len} =    BuiltIn.Get Length    ${dpn_ids}
    : FOR    ${num}    IN RANGE    ${len}
    \    BuiltIn.Should Contain    ${output}    @{dpn_ids}[${num}]
    \    BuiltIn.Should Contain    ${output}    @{tools_ips}[${num}]

OFT Verify Vteps Created at Dpn Teps State per Source
    [Arguments]    ${src_dpn_id}    ${dst_dpn_ids}
    [Documentation]    Verifies if vteps are created at dpn-teps-state for selected tools systems in ODL per source.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_ids}
    \    ${tunnel} =    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    ${OFT_TUNNEL_TYPE}    dpn-teps-state

OFT Verify Vteps Created at Dpn Teps State
    [Arguments]    ${dpn_ids}
    [Documentation]    Verifies if vteps are created at dpn-teps-state for selected tools systems in ODL.
    : FOR    ${dpn_id}    IN    @{dpn_ids}
    \    ${src_dpn_id} =    BuiltIn.Set Variable    ${dpn_id}
    \    ${dst_dpn_ids} =    BuiltIn.Create List    @{dpn_ids}
    \    Collections.Remove Values From List    ${dst_dpn_ids}    ${src_dpn_id}
    \    OFT Verify Vteps Created at Dpn Teps State per Source    ${src_dpn_id}    ${dst_dpn_ids}

OFT Verify Vteps Created at Dpn Endpoints
    [Arguments]    ${dpn_ids}
    [Documentation]    Verifies if vteps are created at itm-state:dpn-endpoints for selected tools systems in ODL.
    : FOR    ${dpn_id}    IN    @{dpn_ids}
    \    Utils.Get Data From URI    session    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id}/

OFT OVS Verify Tunnel Created per Switch
    [Arguments]    ${tools_ip}    ${matches}
    [Documentation]    Verifies VXLAN encapsulation and remote_ip=flow in OVS for selected tools systems per Switch and returns tunnel list.
    ${tunnel_list} =    BuiltIn.Create List
    : FOR    ${match}    IN    @{matches}
    \    Collections.Append To List    ${tunnel_list}    @{match}[0]
    \    BuiltIn.Should Be Equal    @{match}[1]    vxlan
    \    BuiltIn.Should Be Equal    @{match}[2]    ${tools_ip}
    [Return]    ${tunnel_list}

OFT OVS Verify Tunnels Created
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies VXLAN encapsulation and remote_ip=flow in OVS for selected tools systems and returns a map of tools ips and tunnels.
    ${num_switches} =    BuiltIn.Get Length    ${tools_ips}
    ${expected_tunnels_count} =    BuiltIn.Set Variable    ${num_switches-1}
    ${tools_ip_tunnels_map} =    BuiltIn.Create Dictionary
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl show
    \    ${matches} =    String.Get Regexp Matches    ${output}    ${OFT_OVSIF_REGEX}    1    2
    \    ...    3
    \    BuiltIn.Log    ${matches}
    \    BuiltIn.Length Should Be    ${matches}    ${expected_tunnels_count}
    \    ${tunnel_list} =    OFT OVS Verify Tunnel Created per Switch    ${tools_ip}    ${matches}
    \    Collections.Set To Dictionary    ${tools_ip_tunnels_map}    ${tools_ip}    ${tunnel_list}
    [Return]    ${tools_ip_tunnels_map}

OFT OVS Verify Tunnel Port Created per Switch
    [Arguments]    ${matches}
    [Documentation]    Verifies tunnel port in OVS for selected tools systems per Switch and returns port number.
    ${last} =    BuiltIn.Set Variable    ${EMPTY}
    : FOR    ${match}    IN    @{matches}
    \    ${last} =    Run Keyword If    '${last}'=='${EMPTY}'    BuiltIn.Set Variable    ${match}
    \    ...    ELSE    BuiltIn.Set Variable    ${last}
    \    BuiltIn.Should Be True    '${last}'=='${match}'
    [Return]    ${last}

OFT OVS Verify Tunnel Port Created
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies tunnel port is created in OVS for selected tools systems and returns port numbers in order of tools ips.
    ${port_list} =    BuiltIn.Create List
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -O OpenFlow13 dump-ports-desc ${port_name}
    \    ${matches} =    String.Get Regexp Matches    ${output}    (\\d+).tun.*    1
    \    ${port} =    OFT OVS Verify Tunnel Port Created per Switch    ${matches}
    \    Collections.Append To List    ${port_list}    ${port}
    [Return]    ${port_list}

OFT OVS Verify Ingress Flows Created per Switch
    [Arguments]    ${tools_ip}    ${other_tools_ips}
    [Documentation]    Verifies if Ingress flow rules are created in OVS for selected tools systems per switch.
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${other_tools_ip}    IN    @{other_tools_ips}
    \    BuiltIn.Should Contain    ${output}    tun_src=${other_tools_ip}
    \    ${output2} =    Utils.Run Command On Remote System And Log    ${other_tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    \    BuiltIn.Should Contain    ${output2}    tun_src=${tools_ip}

OFT OVS Verify Ingress Flows Created
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies if Ingress flow rules are created in OVS for selected tools systems per switch.
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${other_tools_ips} =    BuiltIn.CreateList    @{tools_ips}
    \    Collections.Remove Values From List    ${other_tools_ips}    ${tools_ip}
    \    OFT Ovs Verify Flow Deleted Per Tools IP    ${tools_ip}    ${other_tools_ips}

OFT Delete Vteps
    [Arguments]    ${dpn_ids}
    [Documentation]    Deletes VTEPs for selected tools systems in ODL.
    : FOR    ${dpn_id}    IN    @{dpn_ids}
    \    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/@{itm_created}[0]/subnets/${SUBNET}%2F16/vteps/${dpn_id}/${port_name}

OFT Verify Vteps Deleted
    [Arguments]    ${tools_ip_tunnels_map}    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${num_switches} =    BuiltIn.Get Length    ${dpn_ids}
    Run Keyword If    '${num_switches}' == '${NUM_TOOLS_SYSTEMS}'    Wait Until Keyword Succeeds    60    5    OFT Verify TZ Deleted
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tep Show    ${tools_ips}
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Teps State    ${dpn_ids}
    Comment    TODO: Check itm-state:tunnel-state in ODL
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Endpoints    ${dpn_ids}
    Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tep Show State    ${tools_ip_tunnels_map}
    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Deleted    ${tools_ip_tunnels_map}
    ${port_list} =    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Deleted    ${tools_ips}
    Comment    TODO: Check parent-child interface mapping in ODL
    Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Deleted    ${tools_ips}
    Comment    TODO: Check egress flows (table 95)

OFT Verify TZ Deleted
    [Documentation]    Verifies if TZ is deleted in ODL.
    Utils.Remove All Elements At URI And Verify    ${CONFIG_API}/itm:transport-zones/transport-zone/@{itm_created}[0]/

OFT Verify Vteps Deleted at Tep Show
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies if vteps are deleted at tep:show for selected tools systems in ODL.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    : FOR    ${tools_ip}    IN    ${tools_ips}
    \    BuiltIn.Should Not Contain    ${output}    ${tools_ip}

OFT Verify Vteps Deleted at Dpn Teps State per Source
    [Arguments]    ${src_dpn_id}    ${dst_dpn_ids}
    [Documentation]    Verifies if vteps are deleted at dpn-teps-state for selected tools systems in ODL per source.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_ids}
    \    ${status} =    Run Keyword And Return Status    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    ${OFT_TUNNEL_TYPE}
    \    ...    dpn-teps-state
    \    BuiltIn.Should Be True    ${status} == ${False}

OFT Verify Vteps Deleted at Dpn Teps State
    [Arguments]    ${dpn_ids}
    [Documentation]    Verifies if vteps are deleted at dpn-teps-state for selected tools systems in ODL.
    : FOR    ${dpn_id}    IN    @{dpn_ids}
    \    ${src_dpn_id} =    BuiltIn.Set Variable    ${dpn_id}
    \    ${dst_dpn_ids} =    BuiltIn.Create List    @{dpn_ids}
    \    Collections.Remove Values From List    ${dst_dpn_ids}    ${src_dpn_id}
    \    OFT Verify Vteps Deleted at Dpn Teps State per Source    ${src_dpn_id}    ${dst_dpn_ids}

OFT Verify Vteps Deleted at Dpn Endpoints
    [Arguments]    ${dpn_ids}
    [Documentation]    Verifies if vteps are deleted at itm-state:dpn-endpoints for selected tools systems in ODL.
    : FOR    ${dpn_id}    IN    @{dpn_ids}
    \    ${resp} =    RequestsLibrary.Get Request    ${CONFIG_API}/itm-state:dpn-endpoints/DPN-TEPs-info/${dpn_id}/
    \    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    404

OFT Verify Vteps Deleted at Tep Show State per Switch
    [Arguments]    ${tunnel_list}
    [Documentation]    Verifies if vteps are deleted at tep:show-state for selected tools systems in ODL per switch.
    : FOR    ${tunnel}    IN    @{tunnel_list}
    \    BuiltIn.Should Not Contain    ${output}    ${tunnel}

OFT Verify Vteps Deleted at Tep Show State
    [Arguments]    ${tools_ip_tunnels_map}
    [Documentation]    Verifies if vteps are deleted at tep:show-state for selected tools systems in ODL.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    : FOR    ${tools_ip}    IN    @{tools_ip_tunnels_map.keys()}
    \    OFT Verify Vteps Deleted at Tep Show State per Switch    ${tools_ip_tunnels_map["${tools_ip}"]}

OFT OVS Verify Tunnels Deleted per Switch
    [Arguments]    ${tools_ip}    ${tunnel_list}
    [Documentation]    Verifies if tunnels are deleted in OVS for selected tools systems per switch.
    ${output} =    Utils.Run Command On Remote System    ${tools_ip}    sudo ovs-vsctl show
    : FOR    ${tunnel}    IN    @{tunnel_list}
    \    BuiltIn.Should Not Contain    ${output}    ${tunnel}

OFT OVS Verify Tunnels Deleted
    [Arguments]    ${tools_ip_tunnels_map}
    [Documentation]    Verifies if tunnels are deleted in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_tunnels_map.keys()}
    \    OFT OVS Verify Tunnels Deleted per Switch    ${tools_ip}    ${tools_ip_tunnels_map["${tools_ip}"]}

OFT OVS Verify Tunnel Port Deleted
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies tunnel port is deleted in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -O OpenFlow13 dump-ports-desc ${port_name}
    \    ${matches} =    String.Get Regexp Matches    ${output}    (\\d+).tun.*    1
    \    BuiltIn.Length Should Be    ${matches}    0

OFT OVS Verify Ingress Flows Deleted per Switch
    [Arguments]    ${tools_ip}    ${other_tools_ips}
    [Documentation]    Verifies if Ingress flow rules are deleted in OVS for selected tools systems per switch.
    ${output} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    : FOR    ${other_tools_ip}    IN    @{other_tools_ips}
    \    BuiltIn.Should Not Contain    ${output}    tun_src=${other_tools_ip}
    \    ${output2} =    Utils.Run Command On Remote System And Log    ${other_tools_ip}    sudo ovs-ofctl -OOpenFlow13 dump-flows ${Bridge} table=0
    \    BuiltIn.Should Not Contain    ${output2}    tun_src=${tools_ip}

OFT OVS Verify Ingress Flows Deleted
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies if Ingress flow rules are deleted in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${other_tools_ips} =    BuiltIn.CreateList    @{tools_ips}
    \    Collections.Remove Values From List    ${other_tools_ips}    ${tools_ip}
    \    OFT Ovs Verify Flows Deleted per Switch    ${tools_ip}    ${other_tools_ips}

OF Tunnels Start Suite
    [Documentation]    Start suite for OF Tunnels.
    ClusterManagement.ClusterManagement_Setup
    ClusterManagement.Stop_Members_From_List_Or_All
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>false/<itm-direct-tunnels>true/g' ${GENIUS_IFM_CONFIG_FLAG}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<use-of-tunnels>false/<use-of-tunnels>true/g' ${GENIUS_ITM_CONFIG_FLAG}
    ClusterManagement.Start_Members_From_List_Or_All
    Genius Suite Setup

OF Tunnels Stop Suite
    [Documentation]    Stop suite for OF Tunnels.
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<itm-direct-tunnels>true/<itm-direct-tunnels>false/g' ${GENIUS_IFM_CONFIG_FLAG}
    \    Run Command On Remote System And Log    ${ODL_SYSTEM_${controller_index+1}_IP}    sed -i -- 's/<use-of-tunnels>true/<use-of-tunnels>false/g' ${GENIUS_ITM_CONFIG_FLAG}
    Genius Suite Teardown
