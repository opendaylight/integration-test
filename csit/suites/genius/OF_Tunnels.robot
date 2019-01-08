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
${OFT_TUNNEL_TYPE}    odl-interface:tunnel-type-vxlan
${DEFAULT_SUBNET}    255.255.255.255/32
${DEFAULT_VLAN}    ${NO_VLAN}

*** Test Cases ***
Create and Verify OFT TEPs
    [Documentation]    Creates TEPs set to use OF based Tunnels and verifies.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify OFT TEPs
    [Documentation]    Deletes TEPs set to use OF based Tunnels and verifies.
    ${tools_ip_tunnels_map} =    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    OFT Delete Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}
    OFT Verify Vteps Deleted    ${tools_ip_tunnels_map}    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Create and Verify single OFT TEPs
    [Documentation]    Creates single TEPs set to use OF based Tunnels and verifies.
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    -1
    ${dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}
    Collections.Remove From List    ${dpn_ids}    -1
    OFT Create Vteps using Auto Tunnels    @{tools_ips}
    OFT Verify Vteps Created    ${dpn_ids}    ${tools_ips}
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[-1]
    OFT Verify Vteps Created    ${DPN_ID_LIST}    ${TOOLS_SYSTEM_ALL_IPS}

Delete and Verify single OFT TEPs
    [Documentation]    Deletes single TEPs set to use OF based Tunnels and verifies.
    ${tools_ip_tunnels_map} =    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${deleted_tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    @{deleted_tools_ips}
    ${deleted_dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    ${deleted_tools_ip_tunnels_map} =    BuiltIn.Create Dictionary    @{TOOLS_SYSTEM_ALL_IPS}[0]=${tools_ip_tunnels_map["@{TOOLS_SYSTEM_ALL_IPS}[0]"]}
    OFT Verify Vteps Deleted    ${deleted_tools_ip_tunnels_map}    ${deleted_dpn_ids}    ${deleted_tools_ips}

Verify OFT supports only Selective BFD
    [Documentation]    Verifies that only Selective BFD monitoring can be enabled for OF based Tunnels
    ${resp} =    RequestsLibrary.Put Request    session    ${CONFIG_API}/itm-config:tunnel-monitor-params/    data=${ENABLE_MONITORING}
    BuiltIn.Should Not Be Equal As Strings    ${resp.status_code}    201
    BuiltIn.Comment    TODO: Check for error message specifics?

Verify Reference Count with Selective BFD
    [Documentation]    Verifies if Reference Count is increased accordingly for Selective BFD monitoring.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[0]
    ${tools_ip_tunnels_map} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    OFT OVS Set BFD State    ${tools_ip_tunnels_map}    true
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify BFD State    ${tools_ip_tunnels_map}    true
    BuiltIn.Comment    TODO: Verify Reference Count increases by 1
    BuiltIn.Comment    TODO: Verify P2P tunnel is created between the dpns when count goes from 0 to 1

Verify Tunnel State with BFD Enabled and Interface State Down
    [Documentation]    Verifies Tunnel state with BFD Enabled and Interface state as Down.
    ${tools_ip_tunnels_map} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify BFD State    ${tools_ip_tunnels_map}    true
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    0
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    OVSDB.Stop OVS    ${tools_ip}
    BuiltIn.Comment    Any other way to set Interface Down in OVS?
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify No Tunnel Status As Up

Verify Tunnel State with BFD Enabled and Interface State Up
    [Documentation]    Verifies Tunnel state with BFD Enabled and Interface state as Up.
    ${tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}
    Collections.Remove From List    ${tools_ips}    0
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    OVSDB.Start OVS    ${tools_ip}
    BuiltIn.Comment    Any other way to set Interface Up in OVS?
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}

Delete and Verify OFT TEPs with Non-Zero Reference Count
    [Documentation]    Verifies that OFT TEPs can be deleted even if the Reference Count is Non-Zero.
    ${tools_ip_tunnels_map} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify BFD State    ${tools_ip_tunnels_map}    true
    BuiltIn.Comment    TODO: Verify Reference Count is Non-Zero
    ${deleted_tools_ips} =    BuiltIn.Create List    @{TOOLS_SYSTEM_ALL_IPS}[0]
    OFT Delete Vteps using Auto Tunnels    @{deleted_tools_ips}
    ${deleted_dpn_ids} =    BuiltIn.CreateList    @{DPN_ID_LIST}[0]
    ${deleted_tools_ip_tunnels_map} =    BuiltIn.Create Dictionary    @{TOOLS_SYSTEM_ALL_IPS}[0]=${tools_ip_tunnels_map["@{TOOLS_SYSTEM_ALL_IPS}[0]"]}
    OFT Verify Vteps Deleted    ${deleted_tools_ip_tunnels_map}    ${deleted_dpn_ids}    ${deleted_tools_ips}
    BuiltIn.Comment    TODO: Verify P2P tunnel is deleted even if Reference Count is Non-Zero

Verify Reference Count with BFD disable RPC
    [Documentation]    Verifies that Reference Count decreases accordingly when BFD disable RPC is called.
    OFT Create Vteps using Auto Tunnels    @{TOOLS_SYSTEM_ALL_IPS}[0]
    ${tools_ip_tunnels_map} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify BFD State    ${tools_ip_tunnels_map}    true
    OFT OVS Set BFD State    ${tools_ip_tunnels_map}    false
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify BFD State    ${tools_ip_tunnels_map}    false
    BuiltIn.Comment    TODO: Verify Reference Count decreases by 1
    BuiltIn.Comment    TODO: Verify P2P tunnel is deleted

Verify Interface State with BFD Disabled
    [Documentation]    Verifies that Tunnel State remains same even after toggling of interface state once BFD is Disabled.
    ${tools_ip_tunnels_map} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${TOOLS_SYSTEM_ALL_IPS}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify BFD State    ${tools_ip_tunnels_map}    false
    BuiltIn.Comment    TODO: Verify Reference Count as Zero
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Stop OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}
    : FOR    ${tools_ip}    IN    @{TOOLS_SYSTEM_ALL_IPS}
    \    OVSDB.Start OVS    ${tools_ip}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${NUM_TOOLS_SYSTEM}

*** Keywords ***
OFT Create Vteps using Auto Tunnels
    [Arguments]    @{tools_ips}
    [Documentation]    Creates VTEPs for selected tools systems in ODL using Auto Tunnels.
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl set O . external_ids:of-tunnel=true
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${SET_LOCAL_IP}${tools_ip}

OFT Verify Vteps Created
    [Arguments]    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${switch_data} =    BuiltIn.Create List    @{dpn_ids}    @{tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Get ITM    ${DEFAULT_TRANSPORT_ZONE}    ${DEFAULT_SUBNET}    ${DEFAULT_VLAN}
    ...    ${switch_data}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Created at Tep Show    ${dpn_ids}    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Update Dpn id List And Get Tunnels    ${OFT_TUNNEL_TYPE}    dpn-teps-state    ${dpn_ids}
    BuiltIn.Comment    TODO: Check itm-state:tunnel-state in ODL
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Response Code Of Dpn End Point Config API    ${dpn_ids}
    ${tools_ip_tunnels_map} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Created    ${tools_ips}
    ${num_switches} =    BuiltIn.Get Length    ${dpn_ids}
    BuiltIn.Wait Until Keyword Succeeds    60    5    Genius.Verify Tunnel Status As Up    ${num_switches}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Created    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Created    ${tools_ips}
    BuiltIn.Comment    TODO: Check egress flows (table 95)

OFT Verify Vteps Created at Tep Show
    [Arguments]    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if vteps are created at tep:show for selected tools systems in ODL.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    BuiltIn.Should Contain    ${output}    ${DEFAULT_TRANSPORT_ZONE}
    BuiltIn.Should Contain    ${output}    VXLAN
    ${len} =    BuiltIn.Get Length    ${dpn_ids}
    : FOR    ${num}    IN RANGE    ${len}
    \    BuiltIn.Should Contain    ${output}    @{dpn_ids}[${num}]
    \    BuiltIn.Should Contain    ${output}    @{tools_ips}[${num}]

OFT OVS Verify Tunnels Created
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies VXLAN encapsulation and remote_ip=flow in OVS for selected tools systems and returns a map of tools ips and tunnels.
    ${num_switches} =    BuiltIn.Get Length    ${tools_ips}
    ${expected_tunnels_count} =    BuiltIn.Set Variable    ${num_switches-1}
    ${tools_ip_tunnels_map} =    BuiltIn.Create Dictionary
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    ${tool_system_index} =    Collections.Get Index From List    ${TOOLS_SYSTEM_ALL_IPS}    ${tools_ip}
    \    ${connection_id} =    BuiltIn.Set Variable    @{TOOLS_SYSTEM_ALL_CONN_IDS}[${tool_system_index}]
    \    ${tunnel_list} =    Get Tunnels On OVS    ${connection_id}    true
    \    BuiltIn.Length Should Be    ${tunnel_list}    ${expected_tunnels_count}
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

OFT Delete Vteps using Auto Tunnels
    [Arguments]    @{tools_ips}
    [Documentation]    Deletes VTEPs for selected tools systems in ODL using Auto Tunnel.
    : FOR    ${tools_ip}    IN    @{tools_ips}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    ${REMOVE_LOCAL_IP}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl set O . external_ids:of-tunnel=false

OFT Verify Vteps Deleted
    [Arguments]    ${tools_ip_tunnels_map}    ${dpn_ids}    ${tools_ips}
    [Documentation]    Verifies if OFT Vteps are created successfully or not for given Tools IPs and DPN-IDs.
    ${num_switches} =    BuiltIn.Get Length    ${dpn_ids}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tep Show    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Teps State    ${dpn_ids}
    BuiltIn.Comment    TODO: Check itm-state:tunnel-state in ODL
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Dpn Endpoints    ${dpn_ids}
    BuiltIn.Wait Until Keyword Succeeds    60    5    OFT Verify Vteps Deleted at Tep Show State    ${tools_ip_tunnels_map}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnels Deleted    ${tools_ip_tunnels_map}
    ${port_list} =    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Tunnel Port Deleted    ${tools_ips}
    BuiltIn.Wait Until Keyword Succeeds    40    10    OFT OVS Verify Ingress Flows Deleted    ${tools_ips}
    BuiltIn.Comment    TODO: Check egress flows (table 95)

OFT Verify Vteps Deleted at Tep Show
    [Arguments]    ${tools_ips}
    [Documentation]    Verifies if vteps are deleted at tep:show for selected tools systems in ODL.
    ${output} =    KarafKeywords.Issue Command On Karaf Console    ${TEP_SHOW}
    : FOR    ${tools_ip}    IN    ${tools_ips}
    \    BuiltIn.Should Not Contain    ${output}    ${tools_ip}

OFT Verify Vteps Deleted at Dpn Teps State per Source
    [Arguments]    ${src_dpn_ids}    ${dst_dpn_id}
    [Documentation]    Verifies if vteps are deleted for given src-dst pair at dpn-teps-state for selected tools systems in ODL per source.
    : FOR    ${src_dpn_id}    IN    @{src_dpn_ids}
    \    ${status} =    Run Keyword And Return Status    Genius.Get Tunnel    ${src_dpn_id}    ${dst_dpn_id}    ${OFT_TUNNEL_TYPE}
    \    ...    dpn-teps-state
    \    BuiltIn.Should Be True    ${status} == ${False}

OFT Verify Vteps Deleted at Dpn Teps State
    [Arguments]    ${dst_dpn_ids}
    [Documentation]    Verifies if vteps are deleted for given src-dst pair at dpn-teps-state for selected tools systems in ODL.
    : FOR    ${dst_dpn_id}    IN    @{dst_dpn_ids}
    \    ${src_dpn_ids} =    BuiltIn.Create List    @{DPN_ID_LIST}
    \    Collections.Remove Values From List    ${src_dpn_ids}    ${dst_dpn_id}
    \    OFT Verify Vteps Deleted at Dpn Teps State per Source    ${src_dpn_ids}    ${dst_dpn_id}

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

OFT OVS Verify BFD State per Switch
    [Arguments]    ${tools_ip}    ${tunnel_list}    ${enable}
    [Documentation]    Verifies BFD State in OVS for selected tools systems per switch.
    : FOR    ${tunnel}    IN    @{tunnel_list}
    \    ${bfd_status} =    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl get interface ${tunnel} bfd_status
    \    Run Keyword If    '${enable}'=='true'    BuiltIn.Should Contain    ${bfd_status}    state=up
    \    ...    ELSE    BuiltIn.Should Not Contain    ${bfd_status}    state=up

OFT OVS Verify BFD State
    [Arguments]    ${tools_ip_tunnels_map}    ${enable}
    [Documentation]    Verifies BFD State in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_tunnels_map.keys()}
    \    OFT OVS Verify BFD per Switch    ${tools_ip}    ${tools_ip_tunnels_map["${tools_ip}"]}    ${enable}

OFT OVS Set BFD State per Switch
    [Arguments]    ${tools_ip}    ${tunnel_list}    ${enable}
    [Documentation]    Sets BFD State in OVS for selected tools systems per switch.
    : FOR    ${tunnel}    IN    @{tunnel_list}
    \    Utils.Run Command On Remote System And Log    ${tools_ip}    sudo ovs-vsctl set interface ${tunnel} bfd:enable="${enable}"

OFT OVS Set BFD State
    [Arguments]    ${tools_ip_tunnels_map}    ${enable}
    [Documentation]    Sets BFD State in OVS for selected tools systems.
    : FOR    ${tools_ip}    IN    @{tools_ip_tunnels_map.keys()}
    \    OFT OVS Set BFD per Switch    ${tools_ip}    ${tools_ip_tunnels_map["${tools_ip}"]}    ${enable}

OFT Verify No Tunnel Status As Up
    [Documentation]    Verifies that no Tunnel status is UP in ODL.
    ${result} =    KarafKeywords.Issue_Command_On_Karaf_Console    ${TEP_SHOW_STATE}
    BuiltIn.Should Not Contain    ${result}    UP

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
